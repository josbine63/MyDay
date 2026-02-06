# 🎯 NOUVEAU FLUX D'ONBOARDING - Guide d'Installation

## ✨ Ce qui a été ajouté

### **Fichiers créés :**

1. **`OnboardingFlowView.swift`** ⭐ NOUVEAU
   - Flux complet en 5 étapes
   - Vue de bienvenue
   - Sélection de permissions
   - **Sélection des calendriers** (après permission calendrier)
   - **Sélection des listes de rappels** (après permission rappels)
   - Vue de complétion

2. **`PermissionChecklistManager.swift`**
   - Gestionnaire centralisé des permissions
   - Support pour Calendrier, Rappels, Photos, Santé

3. **`CalendarManager.swift`**
   - Gestion des événements calendrier
   - Requête de permissions

4. **`CalendarSelectionManager.swift`** ⭐ NOUVEAU
   - Sélection des calendriers à afficher
   - Sauvegarde dans App Group

5. **`ReminderSelectionManager.swift`** ⭐ NOUVEAU
   - Sélection des listes de rappels
   - Sauvegarde dans App Group

6. **`RootView.swift`**
   - Vue racine avec détection d'onboarding
   - Affiche OnboardingFlowView au premier lancement

7. **`LoggerExtensions.swift`**
   - Extensions Logger pour toute l'app

8. **`LocalizableKeys.swift`**
   - Clés de localisation

9. **`StringExtensions.swift`**
   - Extension SHA256 pour les IDs

---

## 🔧 Étapes pour corriger l'erreur de compilation

### **1. Nettoyer le build**
```
Product → Clean Build Folder (⇧⌘K)
```

### **2. Vérifier que TOUS les nouveaux fichiers sont dans le target MyDay**

Pour chaque fichier créé, vérifiez dans **File Inspector** (panneau droit) :

#### **Target MyDay UNIQUEMENT :**
- ✅ `OnboardingFlowView.swift`
- ✅ `PermissionChecklistManager.swift`
- ✅ `CalendarManager.swift`
- ✅ `CalendarSelectionManager.swift`
- ✅ `ReminderSelectionManager.swift`
- ✅ `RootView.swift`
- ✅ `UserSettings.swift`
- ✅ `EventStatusManager.swift`
- ✅ `MyDayApp.swift`
- ✅ `LocalizableKeys.swift`
- ✅ `StringExtensions.swift`

#### **Target MyDay + MyDayWidget (les deux) :**
- ✅ `LoggerExtensions.swift`
- ✅ `AppGroup.swift`
- ✅ `SelectableCalendar.swift`
- ✅ `AppGroupStorage.swift`

### **3. Vérifier les erreurs de compilation spécifiques**

Ouvrez le **Report Navigator** (⌘9) et cherchez les erreurs spécifiques.

Les erreurs courantes :
- ❌ `Cannot find type 'X' in scope` → Le fichier n'est pas dans le target
- ❌ `Use of unresolved identifier` → Import manquant
- ❌ `No such module` → Framework manquant

---

## 📱 Flux d'onboarding utilisateur

```
┌─────────────────────────────────────────┐
│  1️⃣  Écran de bienvenue                  │
│     "Bienvenue dans MyDay"              │
│     Présentation des fonctionnalités    │
│                                         │
│     [Commencer] →                       │
└─────────────────────────────────────────┘
                ↓
┌─────────────────────────────────────────┐
│  2️⃣  Permissions                         │
│     ☑️ Calendrier                        │
│     ☑️ Rappels                           │
│     ☑️ Photos                            │
│     ☑️ Santé                             │
│                                         │
│     [Continuer] →                       │
└─────────────────────────────────────────┘
                ↓
┌─────────────────────────────────────────┐
│  3️⃣  Sélection des calendriers ⭐ NOUVEAU│
│     (Seulement si permission accordée)  │
│                                         │
│     ☑️ Travail                          │
│     ☑️ Personnel                        │
│     ☐ Anniversaires                     │
│     ☑️ Famille                          │
│                                         │
│     [Continuer] →                       │
└─────────────────────────────────────────┘
                ↓
┌─────────────────────────────────────────┐
│  4️⃣  Sélection des rappels ⭐ NOUVEAU    │
│     (Seulement si permission accordée)  │
│                                         │
│     ☑️ Tâches                           │
│     ☑️ Courses                          │
│     ☐ Idées                             │
│                                         │
│     [Continuer] →                       │
└─────────────────────────────────────────┘
                ↓
┌─────────────────────────────────────────┐
│  5️⃣  Complétion                          │
│     🎉 "Tout est prêt !"                │
│                                         │
│     [Commencer à utiliser MyDay] →      │
└─────────────────────────────────────────┘
                ↓
         ContentView (App principale)
```

---

## 🔍 Résolution d'erreur : Étapes détaillées

### **Si l'erreur persiste après Clean Build :**

#### **Étape A : Identifier le fichier problématique**

1. Regardez le build log (Report Navigator, ⌘9)
2. Trouvez la ligne qui commence par "SwiftCompile"
3. Notez le nom du fichier qui cause l'erreur

Exemple :
```
SwiftCompile normal arm64 Compiling OnboardingFlowView.swift
error: Cannot find type 'SelectableCalendar' in scope
```

#### **Étape B : Vérifier les dépendances**

Si `OnboardingFlowView.swift` ne trouve pas `SelectableCalendar` :

1. Ouvrez `SelectableCalendar.swift`
2. File Inspector → Target Membership
3. **Cochez MyDay** si pas déjà fait

#### **Étape C : Vérifier les imports**

Chaque fichier doit avoir les imports nécessaires :

**OnboardingFlowView.swift** doit importer :
```swift
import SwiftUI
```

**CalendarSelectionManager.swift** doit importer :
```swift
import Foundation
import EventKit
import os.log
```

**PermissionChecklistManager.swift** doit importer :
```swift
import Foundation
import EventKit
import Photos
import HealthKit
import os.log
```

---

## 🧪 Tester l'onboarding

### **Réinitialiser l'onboarding :**

Dans l'app, ajoutez un bouton de debug (temporaire) :

```swift
Button("🔄 Réinitialiser Onboarding") {
    UserDefaults.appGroup.set(false, forKey: UserDefaultsKeys.hasLaunchedBefore)
    // Relancer l'app
}
```

Ou dans Terminal (avec l'app fermée) :
```bash
defaults delete group.com.josblais.myday hasLaunchedBefore
```

---

## 📋 Checklist de validation

Avant de build :

- [ ] Tous les nouveaux fichiers sont ajoutés au projet
- [ ] Chaque fichier a les bons targets cochés
- [ ] Clean Build Folder effectué (⇧⌘K)
- [ ] Aucune erreur rouge dans l'éditeur
- [ ] `AppGroup.id` est défini
- [ ] `UserDefaultsKeys.hasLaunchedBefore` existe dans AppGroup.swift

Après le build réussi :

- [ ] L'app se lance
- [ ] L'onboarding s'affiche au premier lancement
- [ ] Les permissions se demandent correctement
- [ ] La sélection de calendriers apparaît si permission accordée
- [ ] La sélection de rappels apparaît si permission accordée
- [ ] L'écran de complétion s'affiche
- [ ] ContentView s'affiche après l'onboarding

---

## 🆘 Dépannage avancé

### **Problème : "Use of unresolved identifier 'Logger'"**

**Solution :** Vérifiez que `LoggerExtensions.swift` est dans le target :
1. Sélectionnez `LoggerExtensions.swift`
2. File Inspector → Target Membership
3. Cochez **MyDay**

### **Problème : "Cannot find 'SelectableCalendar' in scope"**

**Solution :** `SelectableCalendar.swift` doit être dans le target MyDay :
1. Sélectionnez `SelectableCalendar.swift`
2. File Inspector → Target Membership
3. Cochez **MyDay**

### **Problème : "No such module 'EventKit'"**

**Solution :** Ajoutez le framework :
1. Sélectionnez le projet MyDay (icône bleue)
2. Target MyDay → General → Frameworks, Libraries, and Embedded Content
3. Cliquez le **+**
4. Ajoutez **EventKit.framework**

Répétez pour :
- HealthKit.framework
- Photos.framework

### **Problème : L'onboarding ne s'affiche pas**

**Solution :** Vérifiez la clé UserDefaults :
```swift
// Dans RootView, ajoutez un print
print("hasLaunchedBefore:", UserDefaults.appGroup.bool(forKey: UserDefaultsKeys.hasLaunchedBefore))
```

Si `true`, réinitialisez :
```swift
UserDefaults.appGroup.set(false, forKey: UserDefaultsKeys.hasLaunchedBefore)
```

---

## 🎉 Fonctionnalités de l'onboarding

### **Animations fluides**
- Transitions entre les étapes
- Feedback visuel pour les sélections

### **Logique intelligente**
- Saute la sélection de calendriers si permission refusée
- Saute la sélection de rappels si permission refusée
- Va directement à la complétion si aucune permission accordée

### **Personnalisation**
- Couleurs des calendriers affichées
- Comptes associés visibles
- Checkmarks animés

### **Persistance**
- Les sélections sont sauvegardées dans App Group
- Partagées entre l'app et le widget
- Réutilisées au prochain lancement

---

## 📝 Prochaines étapes recommandées

1. **Ajouter un bouton "Modifier" dans les réglages**
   - Permet de changer les calendriers/rappels sélectionnés
   - Réutilise `CalendarSelectionView` et `ReminderSelectionView`

2. **Ajouter des animations**
   - Confettis lors de la complétion
   - Transitions plus fluides

3. **Localisation**
   - Ajouter support pour français/anglais
   - Utiliser `LocalizableKeys`

4. **Analytics**
   - Tracker quelles permissions sont accordées
   - Mesurer le taux de complétion

---

**Besoin d'aide ? Partagez l'erreur spécifique du build log !** 🚀
