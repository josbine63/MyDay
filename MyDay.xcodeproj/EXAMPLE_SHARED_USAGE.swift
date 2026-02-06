// EXAMPLE_SHARED_USAGE.swift
// EXAMPLE_SHARED_USAGE.swift
// Exemples d'utilisation de la fonctionnalité de partage

/*
 
 ═══════════════════════════════════════════════════════════════════
 COMMENT TESTER LA FONCTIONNALITÉ D'INDICATEUR DE PARTAGE
 ═══════════════════════════════════════════════════════════════════
 
 ⚠️ NOTE IMPORTANTE:
 EventKit sur iOS ne fournit PAS directement la propriété `sharees`.
 Cette implémentation utilise une HEURISTIQUE basée sur le type de calendrier.
 
 1️⃣ CRÉER UN CALENDRIER PARTAGÉ
 ────────────────────────────────
 
 Sur iPhone/iPad:
 1. Ouvrir l'app Calendrier (📅)
 2. Taper sur "Calendriers" en bas
 3. Taper sur "Ajouter un calendrier" ou "+"
 4. Créer un nouveau calendrier iCloud (ex: "Famille", "Travail partagé")
 5. Taper sur le (i) à côté du calendrier
 6. Taper sur "Ajouter une personne..."
 7. Ajouter un contact avec qui partager
 8. Taper sur "Ajouter"
 
 Sur Mac:
 1. Ouvrir l'app Calendrier
 2. Clic droit sur un calendrier existant
 3. Sélectionner "Partager le calendrier..."
 4. Ajouter des personnes
 
 
 2️⃣ CRÉER UNE LISTE DE RAPPELS PARTAGÉE
 ────────────────────────────────────────
 
 Sur iPhone/iPad:
 1. Ouvrir l'app Rappels (✅)
 2. Taper sur "Ajouter une liste" ou créer une nouvelle liste
 3. Taper sur "..." à côté du nom de la liste
 4. Taper sur "Partager la liste"
 5. Choisir comment partager (Messages, Mail, etc.)
 6. Inviter des personnes
 
 
 3️⃣ RÉSULTAT ATTENDU DANS MYDAY
 ────────────────────────────────
 
 Calendrier LOCAL (non partagé):
 ┌─────────────────────────────────────┐
 │ 📅  Rendez-vous dentiste    14:30  ✓│
 └─────────────────────────────────────┘
 
 Calendrier iCloud/CalDAV (potentiellement partagé):
 ┌─────────────────────────────────────┐
 │ 📅 👥 Réunion famille       16:00  ✓│
 │    └─ icône bleue                   │
 └─────────────────────────────────────┘
 
 Liste de rappels locale (non partagée):
 ┌─────────────────────────────────────┐
 │ 🗓️  Acheter du lait         08:00  ✓│
 └─────────────────────────────────────┘
 
 Liste de rappels iCloud (potentiellement partagée):
 ┌─────────────────────────────────────┐
 │ 🗓️ 👥 Courses familiales    10:00  ✓│
 │    └─ icône bleue                   │
 └─────────────────────────────────────┘
 
 
 4️⃣ CODE TECHNIQUE - DÉTECTION DU PARTAGE
 ──────────────────────────────────────────
 
 ⚠️ IMPORTANT: EventKit sur iOS ne fournit PAS `sharees`!
 On utilise une heuristique basée sur le type de calendrier.
 */

import EventKit

func isCalendarShared(_ calendar: EKCalendar) -> Bool {
    // Vérifier si on peut modifier le calendrier
    guard calendar.allowsContentModifications else {
        return false // Les calendriers en lecture seule ne sont pas partagés
    }
    
    // Détecter les calendriers CalDAV (iCloud, Exchange)
    // qui sont souvent utilisés pour le partage
    if calendar.type == .calDAV {
        // Vérifier si c'est un calendrier iCloud ou Exchange
        return calendar.source.title.contains("iCloud") || 
               calendar.source.title.contains("Exchange")
    }
    
    return false
}
    // 2. Ce n'est pas un abonnement (lecture seule)
    // 3. Il y a des personnes avec qui c'est partagé
    return calendar.allowsContentModifications &&
           calendar.isSubscribed == false &&
           calendar.sharees != nil &&
           !calendar.sharees!.isEmpty
}

/*
 Pour les rappels (EKReminder):
 */

func isReminderShared(_ reminder: EKReminder) -> Bool {
    let calendar = reminder.calendar
    
    // Conditions:
    // 1. On peut modifier le calendrier/liste
    // 2. Il y a des personnes avec qui c'est partagé
    return calendar.allowsContentModifications &&
           calendar.sharees != nil &&
           !calendar.sharees!.isEmpty
}

/*
 5️⃣ AFFICHAGE DE L'ICÔNE
 ────────────────────────
 
 L'icône utilisée est un SF Symbol:
 - Nom: "person.2.fill"
 - Style: Rempli (fill)
 - Signification: Deux personnes (partage/collaboration)
 - Couleur: Bleu (accent Apple standard pour le partage)
 - Taille: .caption (petite et discrète)
 
 
 6️⃣ EXEMPLES D'UTILISATION PRATIQUE
 ────────────────────────────────────
 
 Scénarios où c'est utile:
 
 👨‍👩‍👧‍👦 FAMILLE:
 - Calendrier "Famille" partagé entre parents
 - Liste "Courses" partagée avec conjoint
 - Événements visibles par tous les membres
 
 💼 TRAVAIL:
 - Calendrier "Équipe Marketing" partagé
 - Liste "Projets Q1" partagée avec collègues
 - Réunions d'équipe visibles
 
 👥 AMIS:
 - Calendrier "Vacances" partagé entre amis
 - Liste "Organisation soirée" partagée
 - Événements sociaux coordonnés
 
 
 7️⃣ PROPRIÉTÉS EVENTKIT UTILISÉES
 ──────────────────────────────────
 
 EKCalendar:
 - allowsContentModifications: Bool
   → true si on peut ajouter/modifier des événements
   
 - isSubscribed: Bool
   → true si c'est un abonnement (lecture seule)
   
 - sharees: [EKParticipant]?
   → Liste des personnes avec qui le calendrier est partagé
   → nil si non partagé
   
 EKParticipant:
 - name: String?
 - emailAddress: String?
 - isCurrentUser: Bool
 
 
 8️⃣ LIMITATIONS CONNUES
 ───────────────────────
 
 ⚠️ L'icône n'apparaît PAS si:
 - Le calendrier est en lecture seule (abonnement)
 - Le calendrier n'a pas de sharees
 - Les permissions EventKit ne sont pas accordées
 - Le calendrier est local (pas iCloud)
 
 ✅ L'icône apparaît UNIQUEMENT si:
 - Le calendrier est modifiable
 - Le calendrier a au moins une personne avec qui il est partagé
 - Le calendrier n'est pas un abonnement
 
 
 9️⃣ DEBUG ET DÉPANNAGE
 ──────────────────────
 
 Si l'icône n'apparaît pas:
 
 1. Vérifier que le calendrier est bien partagé dans l'app Calendrier
 2. Vérifier que la personne a accepté l'invitation
 3. Vérifier les permissions EventKit de MyDay
 4. Vérifier que iCloud est activé
 5. Redémarrer l'app MyDay
 
 Pour debugger dans Xcode:
 */

func debugCalendarSharing(calendar: EKCalendar) {
    print("📋 Calendrier: \(calendar.title)")
    print("   - Type: \(calendar.type.rawValue)")
    print("   - Modifiable: \(calendar.allowsContentModifications)")
    print("   - Abonnement: \(calendar.isSubscribed)")
    print("   - Nombre de sharees: \(calendar.sharees?.count ?? 0)")
    
    if let sharees = calendar.sharees {
        for (index, sharee) in sharees.enumerated() {
            print("   - Sharee \(index + 1): \(sharee.name ?? "Sans nom") (\(sharee.emailAddress ?? "Pas d'email"))")
            print("     → Utilisateur actuel: \(sharee.isCurrentUser)")
        }
    }
}

/*
 🔟 ALTERNATIVES D'ICÔNES (AU CAS OÙ)
 ─────────────────────────────────────
 
 Autres SF Symbols possibles pour le partage:
 
 - "person.2.fill"          ← Actuellement utilisé ✅
 - "person.2"               (version outline)
 - "person.2.circle.fill"   (avec cercle)
 - "person.3.fill"          (trois personnes)
 - "square.and.arrow.up"    (icône de partage iOS)
 - "shared.with.you"        (icône "Partagé avec vous" iOS 15+)
 - "person.2.wave.2.fill"   (personnes qui se saluent)
 
 Pour changer l'icône, modifier dans les fichiers:
 - ContentView.swift (ligne ~420)
 - AgendaListView.swift (ligne ~103)
 - UpcomingWeekView.swift (ligne ~256)
 
 Exemple:
 Image(systemName: "person.2.fill")  // Icône actuelle
 Image(systemName: "shared.with.you") // Alternative
 
 
 ═══════════════════════════════════════════════════════════════════
 FIN DES EXEMPLES
 ═══════════════════════════════════════════════════════════════════
 */
