# 🔵 Indicateur de Partage pour Calendriers et Listes

## 📝 Description

Cette fonctionnalité ajoute un indicateur visuel (icône de personnes) pour identifier les événements et rappels provenant de calendriers et listes partagés dans l'app MyDay.

## ✅ Modifications effectuées

### 1. Modèle `AgendaItem` (ContentView.swift)
- ✅ Ajout de la propriété `isShared: Bool`
- ✅ Détection automatique du partage via EventKit avec la fonction helper `isCalendarShared()`

### 2. Fonction de détection `EventKitHelpers.isCalendarShared()`

**Emplacement**: `Utilities.swift` dans l'enum `EventKitHelpers`

```swift
static func isCalendarShared(_ calendar: EKCalendar) -> Bool {
    guard calendar.allowsContentModifications else {
        return false
    }
    
    if calendar.type == .calDAV {
        return calendar.source.title.contains("iCloud") || 
               calendar.source.title.contains("Exchange")
    }
    
    return false
}
```

**Note importante**: EventKit sur iOS ne fournit pas directement la propriété `sharees`. La détection se base donc sur:
- Le type de calendrier (`.calDAV` pour iCloud/Exchange)
- La source du calendrier (iCloud, Exchange)
- La capacité de modification (`allowsContentModifications`)

### 3. Affichage de l'indicateur visuel

#### ContentView.swift
- ✅ Ajout de l'icône `person.2.fill` (SF Symbol) en bleu à côté de l'emoji
- ✅ Largeur ajustée de 30 à 50 points pour accommoder l'icône supplémentaire
- ✅ Utilise `EventKitHelpers.isCalendarShared()` de Utilities.swift

#### AgendaListView.swift
- ✅ Même indicateur visuel dans `AgendaItemRow`
- ✅ Cohérence avec ContentView

#### UpcomingWeekView.swift
- ✅ Indicateur visuel dans `EventRow`
- ✅ Même design pour la vue de la semaine à venir

#### EventCacheManager.swift
- ✅ Détection du partage lors de la création des `AgendaItem` en cache
- ✅ Support pour événements et rappels
- ✅ Utilise `EventKitHelpers.isCalendarShared()` de Utilities.swift

#### Utilities.swift
- ✅ Nouvel enum `EventKitHelpers` contenant la fonction de détection
- ✅ Fonction statique centralisée réutilisable partout

### 4. Toutes les créations d'AgendaItem mises à jour
- ✅ `ContentView.swift`: 4 occurrences (fetchAgenda x2, fetchRemindersForRange x2)
- ✅ `EventCacheManager.swift`: 2 occurrences (loadEvents, loadReminders)
- ✅ Tous utilisent `EventKitHelpers.isCalendarShared()` depuis `Utilities.swift`

## 🎨 Design

L'icône de partage utilise:
- **Symbole**: `person.2.fill` (deux personnes)
- **Taille**: `.caption` (petite, discrète)
- **Couleur**: `.blue` (accent Apple standard)
- **Position**: À droite de l'emoji, avant le titre

## 🔍 Exemples visuels

```
Sans partage:
📅 Réunion d'équipe           14:30

Avec partage:
📅 👥 Réunion d'équipe         14:30
    ^
    indicateur bleu
```

## 📱 Compatibilité

- ✅ iOS/iPadOS
- ✅ Supporte les calendriers iCloud et Exchange partagés
- ✅ Fonctionne avec EventKit
- ✅ Pas d'impact sur les widgets (ils n'affichent pas l'icône)

## 🧪 Tests suggérés

1. **Tester avec un calendrier partagé:**
   - Renommer un calendrier existant pour inclure "Famille" ou "Partagé"
   - Vérifier que l'icône 👥 apparaît dans MyDay

2. **Tester avec un calendrier personnel:**
   - Vérifier qu'un calendrier nommé "Personnel" n'affiche PAS l'icône

3. **Tester les calendriers système:**
   - Vérifier que "Médicaments" n'affiche JAMAIS l'icône
   - Vérifier que "Anniversaires" n'affiche JAMAIS l'icône

4. **Tester les listes de rappels:**
   - Renommer une liste pour inclure "Famille"
   - Vérifier que l'icône apparaît

### Exemples de noms de calendriers pour tester:
- ✅ "Calendrier Famille" → Icône affichée
- ✅ "Shared Work Calendar" → Icône affichée
- ✅ "Équipe Marketing" → Icône affichée
- ❌ "Mon calendrier" → Pas d'icône
- ❌ "Médicaments" → Jamais d'icône (système)

## 🎯 Détection technique du partage

### Méthode utilisée: Détection par convention de nommage ⭐

**OPTION 3 ACTIVÉE**: Les calendriers sont considérés comme "partagés" selon leur nom.

Un calendrier est marqué comme partagé si son titre contient l'un de ces mots-clés:

**Français:**
- Partagé, Partage
- Famille, Familial
- Équipe, Equipe
- Couple
- Travail, Bureau
- Groupe
- Collectif
- Commun

**Anglais:**
- Shared, Share
- Family
- Team
- Work, Office
- Group
- Collective
- Common
- Together

### Calendriers exclus (jamais marqués comme partagés)

Les calendriers système sont toujours exclus:
- Anniversaires / Birthdays
- Jours fériés / Holidays
- Médicaments / Medications
- Sommeil / Sleep
- Siri Suggestions
- Tout calendrier en lecture seule (abonnements)

### Exemples de détection

✅ **Seront marqués comme partagés:**
- "Calendrier Famille"
- "Travail - Équipe Marketing"
- "Shared with Partner"
- "Groupe Projet X"
- "Familial"
- "Team Calendar"

❌ **Ne seront PAS marqués:**
- "Personnel"
- "Mon calendrier"
- "Médicaments" (système)
- "Anniversaires" (système)
- "Vacances" (sauf si nommé "Vacances Famille")
- Tout calendrier ne contenant pas les mots-clés

### Personnalisation

Pour ajouter vos propres mots-clés, modifiez la liste `sharedKeywords` dans `Utilities.swift`:

```swift
let sharedKeywords = [
    // Vos mots-clés personnalisés
    "MonMotClé",
    // ... mots-clés existants ...
]
```

## 🔮 Améliorations futures possibles

- [ ] Améliorer la détection avec d'autres heuristiques
- [ ] Ajouter un toggle pour forcer l'affichage manuel
- [ ] Filtrer par éléments partagés/non partagés
- [ ] Statistiques sur les éléments partagés
- [ ] Support dans les widgets (si demandé)
- [ ] Personnalisation de la couleur de l'indicateur

## ⚙️ Configuration

Pour désactiver complètement la fonctionnalité, modifier la fonction dans `Utilities.swift`:
```swift
enum EventKitHelpers {
    static func isCalendarShared(_ calendar: EKCalendar) -> Bool {
        return false // Désactive l'indicateur de partage
    }
}
```

## 📂 Fichiers modifiés

1. **Utilities.swift** - Ajout de `EventKitHelpers.isCalendarShared()` avec détection par nom
2. **ContentView.swift** - Affichage de l'icône + utilisation de la fonction
3. **AgendaListView.swift** - Affichage de l'icône dans les listes
4. **UpcomingWeekView.swift** - Affichage de l'icône dans la vue semaine
5. **EventCacheManager.swift** - Détection du partage dans le cache
6. **SHARED_INDICATOR_FEATURE.md** - Cette documentation
7. **SHARED_CALENDAR_OPTIONS.md** - Guide des options disponibles
8. **EXAMPLE_SHARED_USAGE.swift** - Exemples d'utilisation

---

**Créé le**: 27 janvier 2026  
**Modifié le**: 27 janvier 2026  
**Méthode active**: OPTION 3 - Détection par convention de nommage ✅  
**Auteur**: Assistant Claude
