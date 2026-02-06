# 🔧 Options de Détection des Calendriers Partagés

## ⚠️ Problème actuel

EventKit sur iOS **ne fournit pas** la propriété `sharees` qui permettrait de savoir avec certitude si un calendrier est partagé. Contrairement à macOS, iOS n'expose pas cette information via l'API publique.

## 🎯 Solutions disponibles

Vous avez **3 options** pour gérer l'indicateur de partage:

---

### **OPTION 1: DÉSACTIVÉ (Actuel - Recommandé)** ✅

**État**: Actuellement actif dans le code

**Comportement**: Aucune icône de partage n'est affichée

**Avantages**:
- ✅ Pas de faux positifs
- ✅ Simple et prévisible
- ✅ Pas de confusion pour l'utilisateur

**Code dans `Utilities.swift`**:
```swift
static func isCalendarShared(_ calendar: EKCalendar) -> Bool {
    // ... filtres système ...
    return false  // ← Ligne actuelle
}
```

**Quand utiliser**: 
- Si vous n'avez pas besoin de cette fonctionnalité
- Si vous voulez éviter toute confusion

---

### **OPTION 2: DÉTECTION EXCHANGE UNIQUEMENT**

**Comportement**: Affiche l'icône uniquement pour les calendriers Exchange d'entreprise

**Avantages**:
- ✅ Précis pour les environnements professionnels
- ✅ Les calendriers Exchange sont souvent partagés
- ✅ Évite les faux positifs iCloud

**Code à utiliser dans `Utilities.swift`**:
```swift
static func isCalendarShared(_ calendar: EKCalendar) -> Bool {
    guard calendar.allowsContentModifications else {
        return false
    }
    
    // Exclure les calendriers système
    let systemTitles = ["Anniversaires", "Birthdays", "Médicaments", 
                        "Medications", "Sommeil", "Sleep", "Jours fériés", "Holidays"]
    if systemTitles.contains(where: { calendar.title.contains($0) }) {
        return false
    }
    
    // Détecter uniquement Exchange
    return calendar.type == .exchange || 
           (calendar.type == .calDAV && calendar.source.title.contains("Exchange"))
}
```

**Quand utiliser**:
- Vous utilisez Exchange au travail
- Vous voulez marquer les calendriers d'entreprise

---

### **OPTION 3: DÉTECTION PAR CONVENTION DE NOMMAGE**

**Comportement**: Détecte les calendriers partagés basé sur des mots-clés dans le titre

**Avantages**:
- ✅ Vous contrôlez quels calendriers sont marqués
- ✅ Peut être personnalisé selon vos besoins
- ✅ Pas de faux positifs si vous nommez bien vos calendriers

**Code à utiliser dans `Utilities.swift`**:
```swift
static func isCalendarShared(_ calendar: EKCalendar) -> Bool {
    guard calendar.allowsContentModifications else {
        return false
    }
    
    // Exclure les calendriers système
    let systemTitles = ["Anniversaires", "Birthdays", "Médicaments", 
                        "Medications", "Sommeil", "Sleep", "Jours fériés", "Holidays"]
    if systemTitles.contains(where: { calendar.title.contains($0) }) {
        return false
    }
    
    // Détecter par convention de nommage
    // Ajoutez vos propres mots-clés ici!
    let sharedKeywords = [
        "Partagé", "Shared",
        "Famille", "Family",
        "Équipe", "Team",
        "Travail", "Work",
        "Couple",
        // Ajoutez d'autres mots-clés selon vos besoins
    ]
    
    let titleLower = calendar.title.lowercased()
    return sharedKeywords.contains { titleLower.contains($0.lowercased()) }
}
```

**Exemples de détection**:
- ✅ "Famille - Partagé" → Détecté
- ✅ "Work Team Calendar" → Détecté  
- ✅ "Calendrier Couple" → Détecté
- ❌ "Personnel" → Non détecté
- ❌ "Médicaments" → Exclu (système)

**Quand utiliser**:
- Vous nommez vos calendriers de manière cohérente
- Vous voulez un contrôle précis
- Vous êtes prêt à renommer vos calendriers existants

---

### **OPTION 4: DÉTECTION AVANCÉE (HEURISTIQUE)**

**Comportement**: Combine plusieurs facteurs pour deviner si c'est partagé

**Avantages**:
- ✅ Essaie de détecter automatiquement
- ✅ Combine plusieurs indices

**Inconvénients**:
- ⚠️ Peut avoir des faux positifs
- ⚠️ Pas 100% fiable

**Code à utiliser dans `Utilities.swift`**:
```swift
static func isCalendarShared(_ calendar: EKCalendar) -> Bool {
    guard calendar.allowsContentModifications else {
        return false
    }
    
    // Exclure les calendriers système
    let systemTitles = ["Anniversaires", "Birthdays", "Médicaments", 
                        "Medications", "Sommeil", "Sleep", "Jours fériés", "Holidays"]
    if systemTitles.contains(where: { calendar.title.contains($0) }) {
        return false
    }
    
    // Calendrier local = jamais partagé
    if calendar.type == .local {
        return false
    }
    
    // Exchange = probablement partagé
    if calendar.type == .exchange {
        return true
    }
    
    // Heuristique pour CalDAV:
    // - Si le calendrier n'est PAS le calendrier par défaut
    // - ET qu'il est dans iCloud
    // - ET qu'il n'est pas dans le compte principal
    // → Possiblement partagé
    
    if calendar.type == .calDAV && calendar.source.title.contains("iCloud") {
        // Vous pouvez affiner ici selon vos besoins
        // Par exemple, vérifier si ce n'est pas le calendrier par défaut
        
        // Pour l'instant, on retourne false pour éviter les faux positifs
        return false
    }
    
    return false
}
```

**Quand utiliser**:
- À vos risques et périls
- Pour expérimenter

---

## 📝 Comment changer d'option

1. Ouvrir **`Utilities.swift`**
2. Trouver la fonction `EventKitHelpers.isCalendarShared()`
3. Remplacer le corps de la fonction par le code de l'option choisie
4. Compiler et tester

---

## 🧪 Test et Debug

Pour voir les propriétés de vos calendriers, ajoutez cette fonction temporaire:

```swift
// Dans ContentView.swift ou n'importe où
func debugCalendars() {
    let eventStore = EKEventStore()
    let calendars = eventStore.calendars(for: .event)
    
    for calendar in calendars {
        print("📅 Calendrier: \(calendar.title)")
        print("   Type: \(calendar.type.rawValue)")
        print("   Source: \(calendar.source.title)")
        print("   Modifiable: \(calendar.allowsContentModifications)")
        print("   Couleur: \(calendar.cgColor)")
        print("   ---")
    }
}
```

Appelez cette fonction pour voir comment vos calendriers sont structurés.

---

## 💡 Recommandation

**Pour la plupart des utilisateurs**: Utilisez **OPTION 1 (Désactivé)** ou **OPTION 3 (Convention de nommage)**

**Pour les entreprises**: Utilisez **OPTION 2 (Exchange uniquement)**

---

## 🔮 Future Solution Idéale

Apple pourrait ajouter dans une future version d'iOS:
- `calendar.sharees` comme sur macOS
- `calendar.isShared` booléen
- `calendar.owner` pour connaître le propriétaire

En attendant, nous devons utiliser des heuristiques. 😔

---

Créé le: 27 janvier 2026  
Auteur: Assistant Claude
