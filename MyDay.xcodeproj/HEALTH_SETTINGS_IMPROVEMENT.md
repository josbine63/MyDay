# Amélioration : Redemander les permissions Santé depuis les Réglages

## 🎯 Objectif

Permettre à l'utilisateur de **redemander les permissions Santé** directement depuis l'écran Réglages > Santé de MyDay, exactement comme lors de l'onboarding.

## ✨ Nouvelle fonctionnalité

### Avant
- L'utilisateur devait aller dans **Réglages iOS > MyDay > Santé** pour activer les permissions
- Pas de moyen simple de redemander l'autorisation système

### Après
- Un bouton "**Demander l'accès à Santé**" apparaît quand les permissions ne sont pas accordées
- Fonctionne exactement comme dans l'onboarding
- Ouvre la fenêtre système de HealthKit pour autoriser l'accès

## 📱 Interface utilisateur

### Quand afficher le bouton ?

Le bouton apparaît uniquement quand `healthStatus != .granted`, c'est-à-dire :
- ❓ **`.unknown`** : L'utilisateur n'a jamais été demandé
- ❌ **`.denied`** : L'utilisateur a refusé ou certaines permissions sont désactivées

### Quand masquer le bouton ?

Le bouton est masqué quand `healthStatus == .granted` :
- ✅ **Toutes les permissions sont accordées** → Pas besoin de redemander

## 🎨 Design de la section

```
┌─────────────────────────────────────────────┐
│  [Badge de statut actuel]                   │
│  ❌ ou ⚠️ Santé                            │
│  Statistiques d'activité physique           │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│  Données disponibles                         │
│  • Nombre de pas                            │
│  • Calories actives                         │
│  • Distance parcourue                       │
└─────────────────────────────────────────────┘

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

┌─────────────────────────────────────────────┐
│              💡 Astuce                      │
│                                              │
│  Vous pouvez redemander l'accès aux         │
│  données de santé en cliquant ci-dessous.   │
│                                              │
│  ┌───────────────────────────────────────┐  │
│  │  ❤️  Demander l'accès à Santé        │  │
│  └───────────────────────────────────────┘  │
│                                              │
│  Cette action ouvrira la fenêtre système    │
│  pour autoriser l'accès.                    │
└─────────────────────────────────────────────┘
```

## 💻 Code implémenté

```swift
// Dans HealthPermissionView (SettingsView.swift)

// ✨ Section pour redemander les permissions
if manager.healthStatus != .granted {
    VStack(spacing: 12) {
        Divider()
            .padding(.vertical, 8)
        
        VStack(spacing: 8) {
            Text("💡 Astuce")
                .font(.headline)
                .foregroundColor(.accentColor)
            
            Text("Vous pouvez redemander l'accès aux données de santé en cliquant ci-dessous.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
        
        Button {
            // Redemander les permissions comme dans l'onboarding
            manager.requestHealth()
        } label: {
            HStack {
                Image(systemName: "heart.fill")
                Text("Demander l'accès à Santé")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding(.horizontal)
        
        Text("Cette action ouvrira la fenêtre système pour autoriser l'accès.")
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }
    .padding(.top, 8)
}
```

## 🔄 Flux utilisateur

### Scénario 1 : Première demande d'autorisation

1. Utilisateur va dans **MyDay > Réglages > Santé**
2. Badge affiche **❓ (unknown)**
3. Une section "Astuce" apparaît avec le bouton
4. Utilisateur clique sur "**Demander l'accès à Santé**"
5. **Popup système HealthKit** s'affiche
6. Utilisateur active **Pas, Distance, Calories**
7. Badge devient **✅ (granted)**
8. Section "Astuce" disparaît automatiquement

### Scénario 2 : Réautorisation après refus

1. Utilisateur a refusé les permissions précédemment
2. Badge affiche **❌ (denied)**
3. Section "Astuce" est visible
4. Utilisateur clique sur "**Demander l'accès à Santé**"
5. **Popup système** s'affiche à nouveau
6. Utilisateur active les permissions
7. Badge devient **✅ (granted)**

### Scénario 3 : Permissions déjà accordées

1. Toutes les permissions sont accordées
2. Badge affiche **✅ (granted)**
3. Section "Astuce" est **masquée** (pas besoin de redemander)

## 🎁 Avantages

### Pour l'utilisateur
- ✅ **Simplicité** : Pas besoin d'aller dans Réglages iOS
- ✅ **Clarté** : Message explicatif sur ce qui va se passer
- ✅ **Confort** : Un seul tap pour redemander l'accès
- ✅ **Consistance** : Même expérience que l'onboarding

### Pour le développeur
- ✅ **Réutilisation** : Utilise la même méthode `manager.requestHealth()`
- ✅ **Automatique** : Le bouton apparaît/disparaît selon l'état
- ✅ **Pas de code dupliqué** : Logique centralisée dans `PermissionChecklistManager`

## 📊 Comportement de `requestHealth()`

Cette méthode (déjà existante dans `PermissionChecklistManager`) :

```swift
private func requestHealthPermission() {
    guard HKHealthStore.isHealthDataAvailable() else {
        healthStatus = .denied
        refreshAllGranted()
        return
    }

    let typesToRead: Set = [
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
    ]

    healthStore.requestAuthorization(toShare: [], read: typesToRead) { success, _ in
        Task { @MainActor in
            // Vérifier l'accès réel aux données
            self.checkHealthDataAccess()
        }
    }
}
```

### Ce qui se passe :
1. Vérifie que HealthKit est disponible
2. Demande l'autorisation pour lire **Pas, Distance, Calories**
3. Affiche la **popup système** HealthKit
4. Après la réponse de l'utilisateur, vérifie l'accès réel
5. Met à jour le `healthStatus` automatiquement

## 🧪 Tests

### Test 1 : Première utilisation
1. **Supprimer l'app** et la réinstaller
2. Aller dans **MyDay > Réglages > Santé**
3. **Vérifier** : Badge = ❓, Section "Astuce" visible
4. Cliquer sur "**Demander l'accès à Santé**"
5. **Résultat attendu** : Popup HealthKit s'affiche
6. Autoriser les permissions
7. **Résultat attendu** : Badge = ✅, Section "Astuce" disparaît

### Test 2 : Après refus
1. Aller dans **Réglages iOS > MyDay > Santé**
2. **Désactiver toutes** les permissions
3. Revenir à **MyDay > Réglages > Santé**
4. **Vérifier** : Badge = ❌, Section "Astuce" visible
5. Cliquer sur "**Demander l'accès à Santé**"
6. **Résultat attendu** : Popup HealthKit s'affiche
7. Réactiver les permissions
8. **Résultat attendu** : Badge = ✅, Section "Astuce" disparaît

### Test 3 : Permissions déjà accordées
1. S'assurer que toutes les permissions sont accordées
2. Aller dans **MyDay > Réglages > Santé**
3. **Vérifier** : Badge = ✅
4. **Vérifier** : Section "Astuce" est **invisible**

## 📝 Notes importantes

### ⚠️ Limitation iOS
Si l'utilisateur a **explicitement refusé** dans la popup système, iOS ne réaffichera **pas** la popup lors d'un nouvel appel à `requestAuthorization()`. Dans ce cas :
- Le bouton "Demander l'accès" ne fera rien
- Le badge "Réglages" reste le moyen principal

### ✅ Solution
Notre implémentation combine les deux :
1. **Bouton "Demander l'accès"** : Pour première demande ou réautorisation après désactivation manuelle
2. **Badge "Réglages"** : Pour modifier les permissions après refus explicite

## 🎯 Résultat final

L'utilisateur dispose maintenant de **deux moyens** pour gérer ses permissions Santé :

1. **Bouton "Demander l'accès à Santé"** (dans MyDay)
   - ✨ Simple et rapide
   - 🎯 Ouvre la popup système HealthKit
   - ✅ Fonctionne comme l'onboarding

2. **Badge "Réglages"** (dans MyDay)
   - 🔧 Ouvre Réglages iOS > MyDay > Santé
   - 📱 Pour gérer finement chaque permission
   - 🔄 Toujours disponible

**Meilleure expérience utilisateur !** 🎉
