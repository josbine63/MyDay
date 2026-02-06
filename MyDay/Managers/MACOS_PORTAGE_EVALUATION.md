# 🖥️ Évaluation du Portage MyDay vers macOS

**Date:** 1er février 2026  
**Version cible:** macOS 15+ (Sequoia)  
**Status:** 📊 Analyse préliminaire

---

## 📋 Vue d'ensemble

Cette évaluation analyse l'effort nécessaire pour porter l'application **MyDay** (actuellement iOS/iPadOS) vers **macOS** sans modification de code pour le moment. L'objectif est d'identifier les obstacles techniques, les incompatibilités et les adaptations nécessaires.

---

## ✅ Points Positifs (Facilite le portage)

### 1. **Architecture SwiftUI native** 🎯
- ✅ L'application utilise **SwiftUI** comme framework principal
- ✅ Pas de dépendance lourde à UIKit dans la structure principale
- ✅ Utilisation de `@StateObject`, `@EnvironmentObject` (compatible multiplateforme)
- ✅ Architecture MVVM avec managers indépendants

**Impact:** 🟢 Faible effort - La base SwiftUI est déjà multiplateforme

---

### 2. **Frameworks Apple standards** 📦
L'app utilise des frameworks disponibles sur macOS:

| Framework | iOS | macOS | Notes |
|-----------|-----|-------|-------|
| SwiftUI | ✅ | ✅ | Natif |
| EventKit | ✅ | ✅ | Calendrier/Rappels identiques |
| HealthKit | ✅ | ⚠️ | Disponible mais UI différente |
| Photos | ✅ | ✅ | PhotoKit identique |
| WidgetKit | ✅ | ✅ | Widgets supportés sur macOS |
| CryptoKit | ✅ | ✅ | Identique |
| os.log | ✅ | ✅ | Logging unifié |
| Translation | ✅ | ✅ | iOS 18+ / macOS 15+ |

**Impact:** 🟢 Faible effort - Tous les frameworks clés sont disponibles

---

### 3. **Pas d'AppDelegate ni SceneDelegate** ✨
- ✅ Utilise `@main struct MyDayApp: App` moderne
- ✅ Gestion du cycle de vie avec `@Environment(\.scenePhase)`
- ✅ Pas de code UIKit legacy à migrer

**Impact:** 🟢 Aucun effort - Architecture moderne déjà compatible

---

## ⚠️ Points d'Attention (Nécessitent des adaptations)

### 1. **Dépendances UIKit critiques** 🔴

#### A. Import UIKit explicite
```swift
// ContentView.swift, ligne 6
import UIKit
```

**Problème:** UIKit n'existe pas sur macOS (équivalent = AppKit)

**Occurrences identifiées:**
- ✅ `ContentView.swift` - 1 import + 12 utilisations
- ✅ `SettingsView.swift` - 3 utilisations (pas d'import)
- ⚠️ `PermissionChecklistManager.swift` - Possiblement haptic feedback

---

#### B. UIApplication.shared (13 occurrences)

| Fichier | Ligne(s) | Utilisation | Complexité |
|---------|----------|-------------|------------|
| ContentView.swift | 263 | `.significantTimeChangeNotification` | 🟡 Moyenne |
| ContentView.swift | 339-340 | `.canOpenURL()` + `.open()` | 🟡 Moyenne |
| ContentView.swift | 573, 610, 1577 | `.open()` (Health app) | 🟡 Moyenne |
| ContentView.swift | 778 | `.open()` (Documentation URL) | 🟡 Moyenne |
| ContentView.swift | 1109 | `.open()` (Health app) | 🟡 Moyenne |
| ContentView.swift | 1774 | `.open()` (Calendar deeplink) | 🟡 Moyenne |
| SettingsView.swift | 595-596 | `.openSettingsURLString` + `.open()` | 🟡 Moyenne |
| SettingsView.swift | 756 | `.open()` (Health app) | 🟡 Moyenne |

**Solutions possibles:**
```swift
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// Wrapper multiplateforme
extension View {
    func openURL(_ url: URL) {
        #if os(iOS)
        UIApplication.shared.open(url)
        #elseif os(macOS)
        NSWorkspace.shared.open(url)
        #endif
    }
}
```

**Impact:** 🟡 Effort moyen - Nécessite des wrappers conditionnels

---

### 2. **Notifications système iOS-spécifiques** 📲

```swift
// ContentView.swift
.onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification))
.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification))
```

**Problème:** Ces notifications UIKit n'existent pas sur macOS

**Équivalents macOS:**
- `NSApplication.willBecomeActiveNotification` (≈ willEnterForeground)
- `NSWorkspace.screensDidWakeNotification` (≈ significantTimeChange)
- `NSApplication.didBecomeActiveNotification`

**Impact:** 🟡 Effort moyen - Nécessite abstraction des notifications

---

### 3. **Feedback haptique** 📳

**Document analysé:** `PERMISSIONS_IMPROVEMENTS_PLANNED.md`

Le document suggère l'ajout de feedback haptique:
```swift
// Section "Feedback haptique"
import UIKit
private let haptics = UIImpactFeedbackGenerator(style: .medium)
```

**Problème:** 
- ⚠️ Les haptiques **n'existent pas** sur macOS (pas de Taptic Engine)
- ❌ `UIImpactFeedbackGenerator` non disponible

**Solution:** Utiliser `NSSound.beep()` ou désactiver sur macOS

**Impact:** 🟢 Faible - Fonctionnalité non encore implémentée, facile à conditionner

---

### 4. **Interface utilisateur adaptative** 🎨

#### A. Navigation et présentation
```swift
// ContentView utilise:
.sheet(isPresented:)          // ✅ Compatible macOS
.fullScreenCover(isPresented:) // ⚠️ Différent sur macOS (fenêtre modale)
.navigationDestination()       // ✅ Compatible mais style différent
```

**Adaptations nécessaires:**
- 🔹 Navigation Stack → Sidebar (recommandé pour macOS)
- 🔹 Sheets → Windows ou Popovers
- 🔹 Taille des boutons et espacement (macOS plus compact)

**Impact:** 🟡 Effort moyen - L'UI fonctionne mais pas optimale

---

#### B. Gestures et interactions
```swift
// Gestes tactiles iOS
.swipe(), .longPress(), .drag()
```

**Sur macOS:**
- ⚠️ Pas de swipe (utiliser clavier/menu)
- ✅ Click droit pour longPress
- ✅ Drag & drop supporté

**Impact:** 🟢 Faible - SwiftUI gère automatiquement

---

### 5. **Gestion des permissions** 🔐

#### Permissions avec comportement différent:

| Permission | iOS | macOS | Différence |
|------------|-----|-------|------------|
| Calendrier/Rappels | ✅ | ✅ | Identique |
| Photos | ✅ | ✅ | Identique (PhotoKit) |
| Santé | ✅ | ⚠️ | **UI différente** (pas d'app Santé native) |
| Notifications | ✅ | ✅ | Identique (UserNotifications) |

**Problèmes identifiés:**

##### A. HealthKit sur macOS
```swift
// PermissionChecklistManager.swift
private let healthStore = HKHealthStore()

// ContentView.swift - Lignes 573, 610, etc.
let healthURL = URL(string: "x-apple-health://...") // ❌ N'existe pas sur macOS
UIApplication.shared.open(healthURL)
```

**Impact:** 🔴 Élevé - L'app Santé n'existe pas sur macOS
- ✅ HealthKit fonctionne (lecture/écriture)
- ❌ Aucune app système pour gérer les permissions
- ⚠️ Les URL schemes `x-apple-health://` ne fonctionnent pas

**Solutions:**
1. Conditionner tout le code Santé avec `#if os(iOS)`
2. Proposer une UI in-app pour les données Santé sur macOS
3. Désactiver la section Santé sur macOS

---

##### B. Ouverture de l'app Réglages
```swift
// SettingsView.swift, ligne 595
let settingsURL = URL(string: UIApplication.openSettingsURLString)
```

**Équivalent macOS:**
```swift
// Ouvrir Préférences Système → Confidentialité
NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/PreferencePanes/Security.prefPane"))
```

**Impact:** 🟡 Moyen - Nécessite code conditionnel

---

### 6. **App Group et partage de données** 📦

```swift
// AppGroup utilisé pour:
- UserDefaults partagés
- Synchronisation widgets
```

**Sur macOS:**
- ✅ App Groups supportés
- ⚠️ Nécessite configuration Xcode (Capabilities)
- ⚠️ Bundle ID différent (ex: `com.josblais.MyDay.macos`)

**Impact:** 🟡 Moyen - Configuration Xcode nécessaire

---

### 7. **Widgets** 🧩

```swift
import WidgetKit // Présent dans ContentView.swift
```

**Sur macOS:**
- ✅ Widgets supportés (Centre de notifications)
- ⚠️ Tailles différentes d'iOS
- ⚠️ Placement différent (pas de Home Screen)

**Adaptations:**
- Créer des configurations spécifiques macOS
- Adapter les `WidgetFamily` supportées
- Tester dans le Centre de notifications

**Impact:** 🟡 Moyen - Widgets fonctionnent mais nécessitent adaptation

---

## 🔍 Analyse des Managers Clés

### PhotoManager
- ✅ Utilise PhotoKit (compatible macOS)
- ⚠️ `PHPhotoLibrary` sur macOS accède à Photos.app
- ✅ Permissions identiques

**Impact:** 🟢 Faible

---

### HealthManager
- ⚠️ HealthKit disponible mais limité sur macOS
- ❌ Pas d'app Santé système
- ❌ Deeplinks ne fonctionnent pas

**Impact:** 🔴 Élevé - Nécessite refonte ou désactivation

---

### CalendarManager / ReminderSelectionManager
- ✅ EventKit identique sur macOS
- ✅ Calendrier.app et Rappels.app existent
- ✅ Permissions identiques

**Impact:** 🟢 Faible

---

### UserSettings / CustomLinkManager
- ✅ SwiftUI + UserDefaults (compatible)
- ✅ Pas de dépendance UIKit détectée

**Impact:** 🟢 Aucun

---

## 📊 Estimation de l'Effort

### Répartition par complexité:

| Catégorie | Effort | % du projet | Tâches |
|-----------|--------|-------------|---------|
| 🟢 **Faible** | 1-2 jours | ~70% | - Frameworks de base<br>- Architecture SwiftUI<br>- Managers |
| 🟡 **Moyen** | 3-5 jours | ~25% | - Wrappers UIKit→AppKit<br>- Notifications système<br>- Widgets<br>- UI adaptative |
| 🔴 **Élevé** | 5-10 jours | ~5% | - Refonte HealthKit<br>- Tests multi-plateformes<br>- Optimisations macOS |

---

### Phases de portage recommandées:

#### Phase 1: Compatibilité de base (3-5 jours) 🎯
1. ✅ Créer une cible macOS dans Xcode
2. ✅ Ajouter les `#if os(macOS)` pour UIKit
3. ✅ Créer des wrappers pour `openURL()`
4. ✅ Adapter les notifications système
5. ✅ Tester la compilation

**Livrables:** App compile et lance sur macOS

---

#### Phase 2: Adaptations UI/UX (5-7 jours) 🎨
1. ✅ Adapter la navigation (Sidebar recommandé)
2. ✅ Ajuster les tailles et espacements
3. ✅ Optimiser pour clavier/souris
4. ✅ Tester les sheets et fullScreenCovers
5. ✅ Adapter les widgets

**Livrables:** UI native macOS

---

#### Phase 3: Fonctionnalités avancées (3-5 jours) 🚀
1. ⚠️ Décider du sort de HealthKit:
   - Option A: Désactiver sur macOS
   - Option B: UI in-app simplifiée
2. ✅ Configurer App Groups
3. ✅ Tester synchronisation widgets
4. ✅ Optimiser performances macOS

**Livrables:** Parité fonctionnelle iOS ↔ macOS

---

#### Phase 4: Tests et polish (3-5 jours) 🧪
1. ✅ Tests sur plusieurs versions macOS
2. ✅ Tests de permissions
3. ✅ Tests EventKit/Photos
4. ✅ Optimisations spécifiques macOS
5. ✅ Documentation

**Livrables:** App production-ready

---

## 📈 Effort Total Estimé

### Scénario Minimal (Sans HealthKit)
- **Durée:** 10-15 jours
- **Complexité:** Moyenne
- **Risques:** Faibles

### Scénario Complet (Avec HealthKit adapté)
- **Durée:** 15-20 jours
- **Complexité:** Moyenne-Élevée
- **Risques:** Moyens

---

## 🎯 Recommandations Stratégiques

### Option A: Portage Direct (Recommandé) ✅
**Approche:** Créer une cible macOS Catalyst/native

**Avantages:**
- 🎯 Code partagé (~90%)
- ⚡ Maintenance simplifiée
- 🔄 Synchronisation automatique des fonctionnalités
- 📦 Codebase unifié

**Inconvénients:**
- ⚠️ UI pas optimale pour macOS initialement
- 🎨 Nécessite du design adaptatif

**Effort:** 10-15 jours

---

### Option B: App macOS Optimisée
**Approche:** Créer une cible macOS avec UI spécifique

**Avantages:**
- 🎨 UI native macOS (Sidebar, Toolbar, etc.)
- ⚡ Performances optimales
- 🖥️ Expérience utilisateur premium

**Inconvénients:**
- ⏱️ Développement plus long
- 🔧 Maintenance de 2 UI différentes
- 💰 Coût plus élevé

**Effort:** 20-30 jours

---

## 🚧 Points de Blocage Identifiés

### 1. HealthKit (🔴 Critique)
**Problème:** L'app Santé n'existe pas sur macOS

**Solutions:**
- ✅ **Court terme:** Conditionner avec `#if os(iOS)` et désactiver sur macOS
- ⚠️ **Moyen terme:** Créer une UI in-app pour afficher les données Santé
- 🚀 **Long terme:** Utiliser CloudKit pour sync iOS → macOS

**Décision requise:** Avant de commencer le portage

---

### 2. URL Schemes iOS-spécifiques
**Problème:** 8 occurrences de deeplinks iOS:
- `weather://`
- `x-apple-health://...`
- `activitytoday://`
- `calshow:...`

**Solutions:**
```swift
#if os(iOS)
let url = URL(string: "x-apple-health://...")
#elseif os(macOS)
// Ouvrir dans l'app ou afficher un message
#endif
```

**Impact:** 2-3 jours de refactoring

---

### 3. Test de régression iOS
**Risque:** Les changements pour macOS peuvent casser iOS

**Mitigation:**
- ✅ Utiliser des `#if os()` plutôt que modifier le code
- ✅ Tests automatisés (Swift Testing)
- ✅ Revue de code stricte

---

## 🛠️ Plan d'Action Technique

### Étape 1: Audit complet du code (1 jour)
```bash
# Rechercher toutes les dépendances UIKit
grep -r "import UIKit" .
grep -r "UIApplication" .
grep -r "UIViewController" .
grep -r "UIView\." .

# Rechercher les URL schemes
grep -r "URL(string:" . | grep -E "(weather://|x-apple-health://)"

# Rechercher les API iOS-only
grep -r "UIImpactFeedbackGenerator" .
grep -r "PHPhotoLibrary" .
```

---

### Étape 2: Créer des abstractions (2-3 jours)

#### A. Wrapper pour ouverture d'URL
```swift
// Shared/Utilities/URLOpener.swift
import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct URLOpener {
    static func open(_ url: URL, completion: ((Bool) -> Void)? = nil) {
        #if os(iOS)
        UIApplication.shared.open(url) { success in
            completion?(success)
        }
        #elseif os(macOS)
        let success = NSWorkspace.shared.open(url)
        completion?(success)
        #endif
    }
    
    static func canOpen(_ url: URL) -> Bool {
        #if os(iOS)
        return UIApplication.shared.canOpenURL(url)
        #elseif os(macOS)
        return true // macOS peut ouvrir n'importe quel URL
        #endif
    }
}
```

#### B. Wrapper pour notifications système
```swift
// Shared/Utilities/AppLifecycle.swift
import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

extension Notification.Name {
    static var appDidBecomeActive: Notification.Name {
        #if os(iOS)
        return UIApplication.didBecomeActiveNotification
        #elseif os(macOS)
        return NSApplication.didBecomeActiveNotification
        #endif
    }
    
    static var appWillEnterForeground: Notification.Name {
        #if os(iOS)
        return UIApplication.willEnterForegroundNotification
        #elseif os(macOS)
        return NSApplication.willBecomeActiveNotification
        #endif
    }
}
```

#### C. Feedback haptique conditionnel
```swift
// Shared/Utilities/HapticFeedback.swift
struct HapticFeedback {
    enum Style {
        case light, medium, heavy, success, error
    }
    
    static func generate(_ style: Style) {
        #if os(iOS)
        let generator: UIFeedbackGenerator
        switch style {
        case .light:
            generator = UIImpactFeedbackGenerator(style: .light)
        case .medium:
            generator = UIImpactFeedbackGenerator(style: .medium)
        case .heavy:
            generator = UIImpactFeedbackGenerator(style: .heavy)
        case .success:
            generator = UINotificationFeedbackGenerator()
            (generator as! UINotificationFeedbackGenerator).notificationOccurred(.success)
            return
        case .error:
            generator = UINotificationFeedbackGenerator()
            (generator as! UINotificationFeedbackGenerator).notificationOccurred(.error)
            return
        }
        generator.prepare()
        (generator as! UIImpactFeedbackGenerator).impactOccurred()
        #elseif os(macOS)
        // Pas d'haptique sur macOS
        // Optionnel: NSSound.beep()
        #endif
    }
}
```

---

### Étape 3: Adapter l'UI (3-5 jours)

#### Proposition d'architecture macOS:

```
┌─────────────────────────────────────────┐
│           MyDay - macOS                  │
├──────────────┬──────────────────────────┤
│              │                          │
│   Sidebar    │    Contenu Principal     │
│              │                          │
│  📅 Agenda   │  ┌──────────────────┐   │
│  ✓ Rappels   │  │  Événements      │   │
│  📊 Santé    │  │  du jour         │   │
│  📸 Photos   │  └──────────────────┘   │
│  🔗 Liens    │                          │
│  ⚙️ Réglages │  ┌──────────────────┐   │
│              │  │  Photo du jour   │   │
│              │  └──────────────────┘   │
└──────────────┴──────────────────────────┘
```

#### Code SwiftUI:
```swift
#if os(macOS)
struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            // Sidebar
            List {
                NavigationLink("Agenda", destination: AgendaView())
                NavigationLink("Rappels", destination: RemindersView())
                NavigationLink("Santé", destination: HealthView())
                NavigationLink("Photos", destination: PhotosView())
                NavigationLink("Liens", destination: LinksView())
                NavigationLink("Réglages", destination: SettingsView())
            }
        } detail: {
            // Vue principale
            AgendaView()
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}
#endif
```

---

### Étape 4: Configuration Xcode (1 jour)

#### Cible macOS à créer:
```
Target: MyDay (macOS)
- Bundle ID: com.josblais.MyDay.macos
- Minimum macOS: 15.0 (Sequoia)
- Capabilities:
  ✅ App Groups
  ✅ iCloud
  ✅ Calendrier
  ✅ Rappels
  ✅ Photos
  ⚠️ HealthKit (tester disponibilité)
```

#### Structure de fichiers recommandée:
```
MyDay/
├── Shared/              # Code commun iOS/macOS
│   ├── Models/
│   ├── Managers/
│   ├── Utilities/
│   └── Extensions/
├── iOS/                 # Code spécifique iOS
│   ├── ContentView.swift
│   ├── PermissionsChecklistView.swift
│   └── ...
├── macOS/               # Code spécifique macOS
│   ├── ContentView.swift
│   ├── Sidebar.swift
│   └── ...
└── Widgets/
    ├── iOS/
    └── macOS/
```

---

## 📊 Matrice de Risques

| Risque | Probabilité | Impact | Mitigation |
|--------|-------------|--------|------------|
| HealthKit incompatible | 🔴 Élevée | 🔴 Élevé | Désactiver sur macOS |
| Régression iOS | 🟡 Moyenne | 🔴 Élevé | Tests automatisés |
| UI non optimale | 🟢 Faible | 🟡 Moyen | Iteration UX |
| Performances | 🟢 Faible | 🟢 Faible | SwiftUI optimisé |
| Widgets cassés | 🟡 Moyenne | 🟡 Moyen | Tests manuels |

---

## ✅ Checklist de Portage

### Avant de commencer:
- [ ] Décider du sort de HealthKit sur macOS
- [ ] Valider la stratégie UI (Direct vs Optimisé)
- [ ] Configurer l'environnement de test macOS
- [ ] Créer une branche Git dédiée

### Phase 1: Compilation
- [ ] Créer la cible macOS
- [ ] Ajouter les imports conditionnels
- [ ] Créer les wrappers UIKit→AppKit
- [ ] Résoudre les erreurs de compilation
- [ ] App lance sur macOS

### Phase 2: Fonctionnalités
- [ ] Tester EventKit (Calendrier/Rappels)
- [ ] Tester PhotoKit
- [ ] Adapter/Désactiver HealthKit
- [ ] Tester App Groups
- [ ] Vérifier synchronisation widgets

### Phase 3: UI/UX
- [ ] Adapter la navigation
- [ ] Tester sheets et fullScreenCovers
- [ ] Optimiser pour clavier/souris
- [ ] Adapter les widgets
- [ ] Tests de régression iOS

### Phase 4: Production
- [ ] Tests sur macOS 15+
- [ ] Documentation
- [ ] Préparer App Store Connect
- [ ] Build de release

---

## 🎓 Ressources Utiles

### Documentation Apple:
- [Bringing Your App to macOS](https://developer.apple.com/documentation/xcode/bringing-your-app-to-macos)
- [Mac Catalyst](https://developer.apple.com/mac-catalyst/)
- [SwiftUI on macOS](https://developer.apple.com/documentation/swiftui/macos-support)
- [Human Interface Guidelines - macOS](https://developer.apple.com/design/human-interface-guidelines/macos)

### Tutoriels recommandés:
- WWDC: "What's new in SwiftUI for macOS"
- Hacking with Swift: "SwiftUI on macOS"
- Paul Hudson: "Building Mac Apps with SwiftUI"

---

## 🎉 Conclusion

### Verdict: 🟢 **PORTAGE FAISABLE AVEC EFFORT RAISONNABLE**

#### Résumé:
- ✅ **70% du code** est déjà compatible
- 🟡 **25% nécessite** des adaptations mineures (wrappers)
- 🔴 **5% nécessite** des décisions architecturales (HealthKit)

#### Effort total estimé:
- **Minimum:** 10-15 jours (sans HealthKit)
- **Optimal:** 15-20 jours (HealthKit simplifié)
- **Maximum:** 20-30 jours (UI macOS native complète)

#### Recommandation:
**Démarrer avec le Scénario Minimal:**
1. Créer la cible macOS
2. Ajouter les wrappers UIKit→AppKit
3. Désactiver HealthKit temporairement avec `#if os(iOS)`
4. Tester et itérer sur l'UI

**Ensuite, évaluer:**
- Si l'UI SwiftUI de base est suffisante → Ship
- Si optimisations nécessaires → Phase 2

---

**Date de création:** 1er février 2026  
**Auteur:** Assistant  
**Version:** 1.0  
**Status:** ✅ Prêt pour validation

---

## 📞 Prochaines Étapes

1. **Validation:** Revoir ce document avec l'équipe
2. **Décision HealthKit:** Désactiver ou adapter?
3. **Priorisation:** Quelle phase en premier?
4. **Planning:** Allouer les ressources

**Note:** Ce document est une **estimation sans modification de code**. Les chiffres peuvent varier selon:
- L'expérience de l'équipe avec macOS
- Les décisions architecturales prises
- Les tests et bugs découverts
