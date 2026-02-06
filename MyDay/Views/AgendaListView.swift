//
//  AgendaListView.swift
//  MyDay
//
//  Created by Assistant on 2025-01-15.
//

import SwiftUI
import EventKit

/// Vue affichant la liste des événements et rappels de l'agenda
struct AgendaListView: View {
    
    // MARK: - Properties
    
    let combinedAgenda: [AgendaItem]
    let statusManager: EventStatusManager
    let onDateChange: (Date) -> Void
    let onToggleCompletion: (AgendaItem) -> Void
    let onOpenApp: (AgendaItem) -> Void
    
    @Binding var selectedDate: Date
    
    // MARK: - Body
    
    var body: some View {
        if combinedAgenda.isEmpty {
            emptyView
        } else {
            agendaList
        }
    }
    
    // MARK: - Subviews
    
    private var emptyView: some View {
        Text(String(localized: "noEvents"))
            .foregroundColor(.gray)
            .gesture(swipeGesture)
    }
    
    private var agendaList: some View {
        LazyVStack(alignment: .leading, spacing: 8) {
            ForEach(combinedAgenda) { item in
                AgendaItemRow(
                    item: item,
                    isCompleted: statusManager.isCompleted(id: item.id.uuidString),
                    onTap: { onOpenApp(item) },
                    onToggle: { onToggleCompletion(item) }
                )
            }
        }
        .padding(.horizontal)
        .gesture(swipeGesture)
    }
    
    // MARK: - Gestures
    
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 24, coordinateSpace: .local)
            .onEnded { value in
                if abs(value.translation.width) > abs(value.translation.height) {
                    if value.translation.width < 0 {
                        // Swipe gauche → jour suivant
                        withAnimation {
                            if let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) {
                                selectedDate = nextDay
                                onDateChange(nextDay)
                            }
                        }
                    } else if value.translation.width > 0 {
                        // Swipe droite → jour précédent
                        withAnimation {
                            if let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) {
                                selectedDate = previousDay
                                onDateChange(previousDay)
                            }
                        }
                    }
                }
            }
    }
}

// MARK: - Agenda Item Row

struct AgendaItemRow: View {
    let item: AgendaItem
    let isCompleted: Bool
    let onTap: () -> Void
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            // Icône avec indicateur de partage
            HStack(spacing: 4) {
                Text(icon(for: item))
                    .font(.title3)
                
                // ✅ Icône de partage si l'élément est partagé
                if item.isShared {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .frame(width: 50, alignment: .leading)
            
            // Titre
            Button(action: onTap) {
                Text(item.title)
                    .strikethrough(isCompleted, color: .gray)
                    .foregroundColor(isCompleted ? .gray : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            
            // Heure
            Text(item.date.formatted(date: .omitted, time: .shortened))
                .font(.subheadline)
                .foregroundColor(.gray)
            
            // Bouton de complétion
            Button(action: onToggle) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "checkmark.circle")
                    .foregroundColor(isCompleted ? .green : .gray)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Icon Logic
    
    private func icon(for item: AgendaItem) -> String {
        let title = item.title.lowercased()
        
        // Santé et médicaments (FR + EN)
        if containsAny(title, keywords: ["médicament", "pilule", "med", "médoc", "comprimé", "gélule",
                                         "medication", "medicine", "pill", "tablet", "capsule", "drug"]) {
            return "💊"
        }
        
        // Sommeil (FR + EN)
        if containsAny(title, keywords: ["dodo", "sieste", "sleep", "power nap"]) {
            return "💤"
        }
        
        // Sport et activités physiques (FR + EN)
        if containsAny(title, keywords: ["course", "jogging", "courir", "run", "running"]) {
            return "🏃"
        }
        if containsAny(title, keywords: ["gym", "musculation", "fitness", "entrainement", "entraînement",
                                         "workout", "training", "exercise"]) {
            return "💪"
        }
        if containsAny(title, keywords: ["natation", "piscine", "nager", "swimming", "pool", "swim"]) {
            return "🏊"
        }
        if containsAny(title, keywords: ["vélo", "cyclisme", "velo", "bike", "cycling", "bicycle"]) {
            return "🚴"
        }
        if containsAny(title, keywords: ["yoga", "méditation", "relaxation", "meditation"]) {
            return "🧘"
        }
        if containsAny(title, keywords: ["tennis"]) {
            return "🎾"
        }
        if containsAny(title, keywords: ["football", "soccer"]) {
            return "⚽"
        }
        if containsAny(title, keywords: ["basket", "basketball"]) {
            return "🏀"
        }
        if containsAny(title, keywords: ["randonnée", "hiking"]) {
            return "🌲"
        }
        if containsAny(title, keywords: ["marche", "balade", "walk", "walking"]) {
            return "🚶"
        }
        
        // Travail et professionnel (FR + EN)
        if containsAny(title, keywords: ["réunion", "meeting", "rendez-vous", "rdv", "appel", "call",
                                         "appointment"]) {
            return "💼"
        }
        if containsAny(title, keywords: ["présentation", "conférence", "presentation", "conference"]) {
            return "📊"
        }
        if containsAny(title, keywords: ["formation", "cours", "classe", "training", "class", "lesson",
                                         "course", "education"]) {
            return "📚"
        }
        
        // Santé et bien-être (FR + EN)
        if containsAny(title, keywords: ["dentiste", "dental", "dentist"]) {
            return "🦷"
        }
        if containsAny(title, keywords: ["médecin", "docteur", "hopital", "hôpital", "clinique",
                                         "doctor", "physician", "hospital", "clinic", "medical"]) {
            return "🏥"
        }
        if containsAny(title, keywords: ["massage", "spa"]) {
            return "💆"
        }
        
        // Alimentation (FR + EN)
        if containsAny(title, keywords: ["restaurant", "dîner", "diner", "déjeuner", "petit-déjeuner", "repas",
                                         "dinner", "lunch", "breakfast", "meal", "eat", "food"]) {
            return "🍽️"
        }
        if containsAny(title, keywords: ["courses", "marché", "épicerie", "shopping", "grocery", "market"]) {
            return "🛒"
        }
        if containsAny(title, keywords: ["café", "bar", "coffee"]) {
            return "☕"
        }
        
        // Transport et déplacements (FR + EN)
        if containsAny(title, keywords: ["vol", "avion", "aéroport", "flight", "plane", "airport"]) {
            return "✈️"
        }
        if containsAny(title, keywords: ["train", "gare", "station"]) {
            return "🚂"
        }
        if containsAny(title, keywords: ["voiture", "conduite", "garage", "car", "drive", "driving"]) {
            return "🚗"
        }
        if containsAny(title, keywords: ["voyage", "vacances", "travel", "vacation", "trip"]) {
            return "🧳"
        }
        
        // Maison et tâches (FR + EN)
        if containsAny(title, keywords: ["ménage", "nettoyer", "lessive", "cleaning", "clean", "laundry"]) {
            return "🧹"
        }
        if containsAny(title, keywords: ["jardinage", "plantes", "gardening", "plants", "garden"]) {
            return "🌱"
        }
        if containsAny(title, keywords: ["bricolage", "réparation", "diy", "repair", "fix"]) {
            return "🔧"
        }
        
        // Social et famille (FR + EN)
        if containsAny(title, keywords: ["anniversaire", "fête", "birthday", "party", "celebration"]) {
            return "🎉"
        }
        if containsAny(title, keywords: ["famille", "parents", "enfants", "family", "children", "kids"]) {
            return "👨‍👩‍👧‍👦"
        }
        if containsAny(title, keywords: ["ami", "sortie", "friend", "friends", "social"]) {
            return "👫"
        }
        
        // Culture et loisirs (FR + EN)
        if containsAny(title, keywords: ["cinéma", "film", "cinema", "movie", "movies"]) {
            return "🎬"
        }
        if containsAny(title, keywords: ["concert", "musique", "music"]) {
            return "🎵"
        }
        if containsAny(title, keywords: ["lecture", "livre", "bibliothèque", "reading", "book", "library"]) {
            return "📖"
        }
        if containsAny(title, keywords: ["musée", "exposition", "museum", "exhibition", "gallery"]) {
            return "🎨"
        }
        
        // Argent et administration (FR + EN)
        if containsAny(title, keywords: ["banque", "argent", "bank", "money", "banking"]) {
            return "🏦"
        }
        if containsAny(title, keywords: ["impôts", "administration", "taxes", "tax", "admin"]) {
            return "📄"
        }
        
        // Beauté et soins (FR + EN)
        if containsAny(title, keywords: ["coiffeur", "cheveux", "hairdresser", "hair", "salon"]) {
            return "💇"
        }
        if containsAny(title, keywords: ["manucure", "ongles", "manicure", "nails"]) {
            return "💅"
        }
        
        // Par défaut selon le type
        return item.isEvent ? "📅" : "🗓️"
    }
    
    private func containsAny(_ text: String, keywords: [String]) -> Bool {
        return keywords.contains { keyword in
            text.contains(keyword)
        }
    }
}
