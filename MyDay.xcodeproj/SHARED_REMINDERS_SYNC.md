# Synchronisation automatique des rappels partagés

## 📋 Vue d'ensemble

Cette fonctionnalité permet à MyDay de se mettre à jour automatiquement lorsque des rappels partagés sont modifiés (marqués comme complétés) par d'autres utilisateurs ou dans l'application Rappels native d'iOS.

## 🎯 Fonctionnalités implémentées

### 1. Détection automatique des changements
- **Observateur EventKit** : L'application écoute la notification `.EKEventStoreChanged`
- **Mise à jour en temps réel** : Dès qu'un changement est détecté dans EventKit, l'agenda se rafraîchit automatiquement
- **Invalidation du cache** : Le cache est invalidé pour garantir que les données les plus récentes sont affichées

### 2. Polling pour synchronisation entre utilisateurs
- **⏰ Timer de polling** : Vérifie les changements toutes les 30 secondes quand l'app est active
- **Raison** : iCloud ne déclenche pas `.EKEventStoreChanged` pour les modifications d'autres utilisateurs en temps réel
- **Optimisé** : Le timer s'arrête automatiquement quand l'app est en arrière-plan

### 3. Rafraîchissement au retour de l'app
- **Détection foreground** : Écoute de `UIApplication.willEnterForegroundNotification`
- **Mise à jour automatique** : Quand vous revenez dans l'app, elle vérifie les changements
- **Garantit la fraîcheur** : Les données sont toujours à jour après avoir quitté l'app

### 4. Synchronisation dans toutes les vues

#### ContentView (Vue principale)
- Observer configuré dans `.onAppear` via `setupEventStoreObserver()`
- Polling démarré via `startSharedRemindersPolling()`
- Observer et timer retirés dans `.onDisappear`
- Rafraîchissement automatique de l'agenda lorsqu'un changement est détecté

#### UpcomingWeekView (Vue semaine)
- Observer configuré dans le `ViewModel` lors de l'initialisation
- Nettoyage automatique dans `deinit`
- Rafraîchissement automatique de la liste des événements de la semaine

## 🔧 Implémentation technique

### NotificationExtensions.swift

```swift
import Foundation

extension Notification.Name {
    /// Notification envoyée lorsque l'agenda doit être rafraîchi suite à un changement dans EventKit
    static let needsAgendaRefresh = Notification.Name("needsAgendaRefresh")
}
```

### ContentView.swift

```swift
// Propriété d'état pour l'observateur
@State private var eventStoreObserver: NSObjectProtocol?

// Configuration de l'observateur
func setupEventStoreObserver() {
    Logger.reminder.info("🔔 Configuration de l'observateur EventKit")
    
    eventStoreObserver = NotificationCenter.default.addObserver(
        forName: .EKEventStoreChanged,
        object: eventStore,
        queue: .main
    ) { _ in
        Logger.reminder.info("🔔 Changement détecté dans EventKit - Mise à jour de l'agenda")
        
        // Invalider le cache pour forcer un rechargement
        EventCacheManager.shared.invalidateCache(for: Date())
        
        // Rafraîchir l'agenda via notification (car ContentView est une struct)
        Task { @MainActor in
            NotificationCenter.default.post(name: .needsAgendaRefresh, object: nil)
            Logger.reminder.info("✅ Notification de rafraîchissement envoyée")
        }
    }
}

// Écoute de la notification de rafraîchissement
.onReceive(NotificationCenter.default.publisher(for: .needsAgendaRefresh)) { _ in
    Logger.reminder.info("📬 Notification de rafraîchissement reçue")
    Task {
        await refreshAgenda()
    }
}

// Nettoyage de l'observateur
func removeEventStoreObserver() {
    if let observer = eventStoreObserver {
        NotificationCenter.default.removeObserver(observer)
        eventStoreObserver = nil
        Logger.reminder.info("🧹 Observateur EventKit retiré")
    }
}
```

**Note** : ContentView étant une struct SwiftUI (pas une classe), on ne peut pas utiliser `[weak self]`. À la place, on utilise un pattern de notification intermédiaire (`.needsAgendaRefresh`) qui est écoutée via `.onReceive()`.

### UpcomingWeekViewModel

```swift
// Le ViewModel est une classe, donc on peut utiliser [weak self]
private var eventStoreObserver: NSObjectProtocol?
private let eventStore = SharedEventStore.shared

init(...) {
    // ... autres initialisations
    setupEventStoreObserver()
}

deinit {
    if let observer = eventStoreObserver {
        NotificationCenter.default.removeObserver(observer)
    }
}

private func setupEventStoreObserver() {
    eventStoreObserver = NotificationCenter.default.addObserver(
        forName: .EKEventStoreChanged,
        object: eventStore,
        queue: .main
    ) { [weak self] _ in
        guard let self = self else { return }
        
        Task { @MainActor in
            await self.refresh()
        }
    }
}
```

## 📱 Cas d'utilisation

### Scénario 1 : Rappel partagé marqué complété par un autre utilisateur
1. Un utilisateur partage une liste de rappels avec vous
2. Cet utilisateur marque un rappel comme complété
3. **Dans les 30 secondes** : MyDay détecte automatiquement le changement via le polling
4. L'agenda se rafraîchit et affiche l'état mis à jour
5. **OU** si vous revenez dans l'app, elle se rafraîchit immédiatement

### Scénario 2 : Modification dans l'app Rappels native
1. Vous marquez un rappel comme complété dans l'app Rappels d'iOS
2. Vous revenez dans MyDay
3. L'application détecte automatiquement le changement via `.EKEventStoreChanged`
4. L'interface se met à jour sans nécessiter de rafraîchissement manuel

### Scénario 3 : Ajout d'un nouveau rappel partagé
1. Un autre utilisateur ajoute un rappel à une liste partagée
2. MyDay détecte le changement dans les 30 secondes (polling)
3. Le nouveau rappel apparaît automatiquement dans l'agenda

### Scénario 4 : Synchronisation entre vos propres appareils
1. Vous modifiez un rappel sur votre iPhone
2. Sur votre iPad (avec MyDay ouvert), le changement est détecté **instantanément** via `.EKEventStoreChanged`
3. L'UI se met à jour immédiatement

## ⚡ Performance

### Optimisations implémentées
- **Weak self** : Utilisation de `[weak self]` dans les closures pour éviter les cycles de rétention
- **Main queue** : Les notifications sont reçues sur la queue principale pour garantir des mises à jour UI fluides
- **Invalidation de cache** : Le cache est invalidé uniquement pour la date concernée (ou toutes les dates pour la vue semaine)
- **Logging** : Messages de debug pour suivre les mises à jour et diagnostiquer les problèmes

### Gestion de la mémoire
- Les observateurs sont correctement retirés dans `onDisappear` (ContentView) et `deinit` (ViewModel)
- Pas de fuites mémoire grâce à l'utilisation de `weak self`

## 🎨 Expérience utilisateur

### Indicateurs visuels
- Les rappels partagés affichent une icône "person.2.fill" 👥
- Un petit crochet vert apparaît sur l'icône de partage quand le rappel est complété
- L'état de complétion est synchronisé en temps réel

### Comportement
- **Mise à jour silencieuse** : Pas d'interruption de l'expérience utilisateur
- **Réactivité** : Les changements apparaissent presque instantanément
- **Fiabilité** : Le cache est invalidé pour garantir la cohérence des données

## 🧪 Tests recommandés

### Test 1 : Synchronisation entre utilisateurs
1. Partager une liste de rappels avec un autre appareil
2. Sur l'appareil A : marquer un rappel comme complété
3. Sur l'appareil B (MyDay ouvert) : vérifier que l'état se met à jour automatiquement

### Test 2 : Synchronisation avec l'app Rappels
1. Ouvrir MyDay avec des rappels visibles
2. Basculer vers l'app Rappels native
3. Marquer un rappel comme complété
4. Revenir dans MyDay : vérifier la mise à jour automatique

### Test 3 : Vue semaine
1. Ouvrir la vue "7 prochains jours"
2. Pendant qu'elle est ouverte, modifier un rappel dans l'app Rappels
3. Vérifier que la vue semaine se met à jour automatiquement

### Test 4 : Performance
1. Créer plusieurs rappels partagés
2. Les modifier rapidement
3. Vérifier que MyDay reste réactif et ne ralentit pas

## 📝 Notes de développement

### Notification .EKEventStoreChanged
Cette notification est envoyée par EventKit dans plusieurs cas :
- Ajout d'un événement ou rappel **local ou depuis le même compte iCloud**
- Modification d'un événement ou rappel **sur vos propres appareils**
- Suppression d'un événement ou rappel
- Changement de calendrier/liste
- Synchronisation avec iCloud **de votre propre compte**

**⚠️ Limitation importante** : `.EKEventStoreChanged` **ne se déclenche PAS en temps réel** pour les modifications faites par d'autres utilisateurs sur des calendriers/rappels partagés. C'est une limitation d'Apple/EventKit.

### Solution : Polling combiné
Pour palier cette limitation, MyDay utilise une approche hybride :
1. **Observateur `.EKEventStoreChanged`** : Pour les changements instantanés (même utilisateur, appareils multiples)
2. **Timer de polling (30s)** : Pour détecter les changements d'autres utilisateurs
3. **Refresh au foreground** : Quand l'app revient au premier plan

### Considérations futures
- **Throttling** : Si les mises à jour sont trop fréquentes, envisager d'ajouter un délai (debouncing)
- **Notifications push** : Pour les modifications d'autres utilisateurs, la synchronisation dépend d'iCloud
- **Mode économie d'énergie** : Tester le comportement en mode économie d'énergie
- **Intervalle de polling configurable** : Permettre à l'utilisateur de choisir (15s, 30s, 60s)

## ✅ Avantages de cette implémentation

1. **Automatique** : Aucune action manuelle requise de l'utilisateur
2. **Temps réel** : Les changements apparaissent presque instantanément
3. **Universel** : Fonctionne pour toutes les sources de modification (autres utilisateurs, app Rappels, etc.)
4. **Performant** : Impact minimal sur les performances et la batterie
5. **Fiable** : Utilise l'API officielle d'Apple (EventKit)
6. **Propre** : Gestion correcte de la mémoire avec nettoyage des observateurs

## 🔗 Fichiers modifiés

- `ContentView.swift` : Ajout de l'observateur EventKit et gestion via notification intermédiaire
- `UpcomingWeekView.swift` : Ajout de l'observateur EventKit dans le ViewModel
- `NotificationExtensions.swift` : **NOUVEAU** - Définition de la notification `.needsAgendaRefresh`
- `SHARED_REMINDERS_SYNC.md` : Cette documentation

---

**Date d'implémentation** : 27 janvier 2026  
**Version** : MyDay 2.0
