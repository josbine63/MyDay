# Correction du problème des permissions Santé

## Problèmes identifiés

### 1. L'icône de santé n'affichait pas l'état réel
- **Symptôme** : Le badge dans Réglages > Santé affichait que tout était OK même après avoir retiré les permissions
- **Cause** : La vérification ne testait pas correctement **tous** les types de données (pas, distance, calories)

### 2. Le bouton "Réglages" ouvrait la mauvaise app
- **Symptôme** : Cliquer sur "Réglages" dans la section Santé ouvrait les Réglages système
- **Problème** : Pour HealthKit, il faut ouvrir l'app **Santé** directement, pas les Réglages système

## Solutions implémentées

### 1. Vérification multi-types améliorée (`PermissionChecklistManager.swift`)

#### Avant (❌)
```swift
// Vérifiait seulement stepCount
let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
let status = healthStore.authorizationStatus(for: stepType)
```

#### Après (✅)
```swift
// Teste LES TROIS types de données en parallèle
let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!

// Exécution de 3 requêtes simultanées avec DispatchGroup
// TOUS les types doivent être accessibles pour .granted
```

### 2. Timeout réduit et plus fiable

- **Avant** : Timeout de 3 secondes
- **Après** : Timeout de 2 secondes avec meilleure gestion des cas limites

### 3. Logique de détection stricte

```swift
if stepGranted && distanceGranted && caloriesGranted {
    // ✅ Accordé uniquement si TOUS les types sont accessibles
    healthStatus = .granted
} else if !stepGranted && !distanceGranted && !caloriesGranted {
    // ❓ Si aucun n'est accessible, vérifier s'il s'agit de "denied" ou "not determined"
    performFinalHealthCheck()
} else {
    // ❌ Si certains sont accessibles mais pas tous = refusé
    healthStatus = .denied
}
```

### 4. Ouverture de l'app Santé (`SettingsView.swift` et `PermissionsChecklistView.swift`)

#### Avant (❌)
```swift
private func openSettings() {
    // Ouvrait les Réglages iOS
    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(settingsURL)
    }
}
```

#### Après (✅)
```swift
private func openHealthSettings() {
    // Ouvre l'app Santé sur la page Sources de données
    if let healthURL = URL(string: "x-apple-health://Sources") {
        UIApplication.shared.open(healthURL)
    }
}
```

**Destination** :
- **App Santé > Sources de données**
- L'utilisateur peut y gérer toutes les apps qui accèdent à ses données de santé
- Il trouve **MyDay** dans la liste et peut activer/désactiver chaque type de données

**Avantage** :
- Accès direct à l'endroit exact où gérer les permissions HealthKit
- Plus intuitif que les Réglages système
- Même comportement que les autres apps de santé

### 5. Rafraîchissement automatique amélioré

Ajout d'un double rafraîchissement lors du retour à l'app :

```swift
.onChange(of: scenePhase) { oldPhase, newPhase in
    if newPhase == .active {
        manager.updateStatuses()
        // Double vérification après un délai pour la santé
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            manager.forceHealthStatusRefresh()
        }
    }
}
```

### 6. Logging pour debug

Ajout de logs détaillés pour comprendre ce qui se passe :

```swift
private let logger = Logger(subsystem: "com.yourapp.myday", category: "Permissions")

logger.info("📊 Résultats vérification Santé - Steps: \(stepGranted), Distance: \(distanceGranted), Calories: \(caloriesGranted)")
```

## URLs spéciales pour l'app Santé

### Ouvrir l'app Santé (page Sources)
```swift
x-apple-health://Sources
```

### Autres URLs utiles
```swift
x-apple-health://                                  // Page d'accueil
x-apple-health://MedicationsHealthAppPlugin.healthplugin  // Médicaments
activitytoday://                                   // Anneaux d'activité (Fitness)
```

## Comment tester

### Test 1 : Vérification du bouton "Réglages"
1. Ouvrir MyDay
2. Aller dans **Réglages > Santé**
3. Si le badge affiche **❌ ou ⚠️**, cliquer sur "Réglages"
4. **Résultat attendu** : L'**app Santé** s'ouvre sur la page "Sources de données"
5. Vous devriez voir **MyDay** dans la liste des apps
6. Cliquer sur **MyDay** pour voir les permissions détaillées :
   - Pas
   - Distance de marche/course
   - Énergie active

### Test 2 : Modification des permissions dans l'app Santé
1. Dans l'app Santé > Sources de données > MyDay
2. **Désactiver** "Pas" ou "Distance"
3. Revenir à MyDay (balayer depuis le bord gauche ou bouton Home)
4. **Résultat attendu** : Le badge Santé devient **❌** dans les 2-3 secondes

### Test 3 : Retrait de toutes les permissions
1. Dans l'app Santé > Sources de données > MyDay
2. **Désactiver TOUTES** les options (Pas, Distance, Énergie active)
3. Revenir à MyDay
4. **Résultat attendu** : Le badge santé devrait être **❌ rouge/orange**

### Test 4 : Réactivation complète
1. Dans l'app Santé > Sources de données > MyDay
2. **Réactiver toutes** les permissions
3. Revenir à MyDay
4. **Résultat attendu** : Le badge devrait redevenir **✅ vert** dans les 2-3 secondes

### Navigation dans l'app Santé

```
🏥 App Santé
  └── 📊 Partage
      └── 📱 Apps et services
          └── Sources de données
              └── 🏠 MyDay                  ← ICI
                  ├── ☑️ Pas
                  ├── ☑️ Distance de marche/course
                  └── ☑️ Énergie active
```

## Limitations connues d'iOS

⚠️ **Apple ne permet pas de distinguer clairement "denied" vs "not determined"** pour HealthKit en lecture seule.

C'est pourquoi on doit :
- Faire des requêtes de test pour vérifier l'accès réel
- Utiliser des timeouts pour ne pas bloquer l'interface
- Vérifier les 3 types de données séparément

## Fichiers modifiés

1. **PermissionChecklistManager.swift**
   - Nouvelle méthode `checkHealthDataAccess()` avec tests multiples
   - Ajout de `performFinalHealthCheck()`
   - Ajout de logging

2. **SettingsView.swift**
   - Modification de `openSettings()` dans `HealthPermissionView`
   - URL spéciale pour ouvrir l'app Santé

3. **PermissionsChecklistView.swift**
   - Ajout de l'enum `PermissionType`
   - Modification de `permissionRow()` pour accepter le type
   - Modification de `openSettings()` pour gérer chaque type différemment

## Prochaines améliorations possibles

1. **Indicateur de chargement** : Afficher un spinner pendant les 2 secondes de vérification
2. **Message explicatif** : Expliquer à l'utilisateur quelle permission spécifique est manquante
3. **Deep link vers la permission spécifique** : Ouvrir directement la page de MyDay dans Santé
4. **Notification de changement** : Alerter l'utilisateur si une permission est révoquée pendant l'utilisation

