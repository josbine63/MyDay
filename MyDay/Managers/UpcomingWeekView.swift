//
//  UpcomingWeekView.swift
//  MyDay
//
//  Created by Assistant on 2026-01-26.
//
//  Vue affichant tous les événements et rappels des 30 prochains jours

import SwiftUI
import EventKit
import os.log

/// Vue affichant les événements et rappels des 30 prochains jours
struct UpcomingWeekView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userSettings: UserSettings
    
    // MARK: - State
    
    @StateObject private var viewModel: UpcomingWeekViewModel
    @ObservedObject var statusManager = EventStatusManager.shared
    
    // MARK: - Properties
    
    let startDate: Date
    
    // MARK: - Computed Properties
    
    private var navigationTitle: String {
        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: .day, value: 29, to: startDate) ?? startDate
        
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        
        if calendar.isDateInToday(startDate) {
            return "30 prochains jours"
        } else {
            let start = formatter.string(from: startDate)
            let end = formatter.string(from: endDate)
            return "\(start) - \(end)"
        }
    }
    
    // MARK: - Initializer
    
    init(
        startDate: Date = Date(),
        calendarSelectionManager: CalendarSelectionManager,
        reminderSelectionManager: ReminderSelectionManager
    ) {
        self.startDate = startDate
        _viewModel = StateObject(wrappedValue: UpcomingWeekViewModel(
            startDate: startDate,
            calendarSelectionManager: calendarSelectionManager,
            reminderSelectionManager: reminderSelectionManager
        ))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.groupedEvents.isEmpty {
                    emptyView
                } else {
                    eventsList
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await viewModel.refresh()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .task {
                await viewModel.loadEvents()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Chargement des événements...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(emptyTitle)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(emptyMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var emptyTitle: String {
        if Calendar.current.isDateInToday(startDate) {
            return "Aucun événement à venir"
        } else {
            return "Aucun événement ces 30 jours"
        }
    }
    
    private var emptyMessage: String {
        if Calendar.current.isDateInToday(startDate) {
            return "Profitez de votre temps libre pour les 30 prochains jours ! 🎉"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM"
            let start = formatter.string(from: startDate)
            let calendar = Calendar.current
            let endDate = calendar.date(byAdding: .day, value: 29, to: startDate) ?? startDate
            let end = formatter.string(from: endDate)
            return "Rien de prévu du \(start) au \(end) 📅"
        }
    }
    
    private var eventsList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(viewModel.groupedEvents, id: \.date) { group in
                    Section {
                        ForEach(group.items) { item in
                            EventRow(
                                item: item,
                                isCompleted: statusManager.isCompleted(id: item.id.uuidString),
                                onToggle: {
                                    statusManager.toggleEventCompletion(id: item.id.uuidString)
                                    Task {
                                        await viewModel.refresh()
                                    }
                                }
                            )
                            .padding(.horizontal)
                            
                            if item.id != group.items.last?.id {
                                Divider()
                                    .padding(.leading, 60)
                            }
                        }
                    } header: {
                        DateSectionHeader(date: group.date, itemCount: group.items.count)
                    }
                }
            }
        }
    }
}

// MARK: - Date Section Header

struct DateSectionHeader: View {
    let date: Date
    let itemCount: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(dayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(fullDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(itemCount)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor)
                .clipShape(Capsule())
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
    }
    
    private var dayName: String {
        if Calendar.current.isDateInToday(date) {
            return "Aujourd'hui"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Demain"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date).capitalized
        }
    }
    
    private var fullDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Event Row

struct EventRow: View {
    let item: AgendaItem
    let isCompleted: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Heure
            VStack(alignment: .trailing, spacing: 2) {
                Text(item.date.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)
            }
            .frame(width: 50, alignment: .trailing)
            
            // 🎨 Icône de calendrier/liste + Icône de type + Indicateur de partage
            HStack(spacing: 4) {
                // Cercle de couleur
                if let color = item.calendarColor {
                    Circle()
                        .fill(Color(cgColor: color))
                        .frame(width: 8, height: 8)
                }
                
                // Icône du calendrier/liste (devinée depuis le nom)
                if let calendarName = item.calendarName,
                   let symbol = symbolForCalendar(named: calendarName) {
                    Image(systemName: symbol)
                        .font(.caption2)
                        .foregroundColor(item.calendarColor.map { Color(cgColor: $0) } ?? .secondary)
                }
                
                Text(icon(for: item))
                    .font(.title3)
                
                // ✅ Icône de partage si l'élément est partagé
                if item.isShared {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            // Titre
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.body)
                    .strikethrough(isCompleted, color: .gray)
                    .foregroundColor(isCompleted ? .secondary : .primary)
                
                Text(item.isEvent ? "Événement" : "Rappel")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Bouton de complétion
            Button(action: onToggle) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isCompleted ? .green : .gray)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
    
    private func icon(for item: AgendaItem) -> String {
        let title = item.title.lowercased()
        
        // Utiliser la même logique d'icônes que AgendaItemRow
        if containsAny(title, keywords: ["médicament", "pilule", "medication", "medicine", "pill"]) {
            return "💊"
        }
        if containsAny(title, keywords: ["course", "jogging", "run", "running"]) {
            return "🏃"
        }
        if containsAny(title, keywords: ["gym", "workout", "fitness"]) {
            return "💪"
        }
        if containsAny(title, keywords: ["réunion", "meeting", "rendez-vous", "rdv"]) {
            return "💼"
        }
        if containsAny(title, keywords: ["dentiste", "dental", "dentist"]) {
            return "🦷"
        }
        if containsAny(title, keywords: ["restaurant", "dîner", "dinner", "lunch"]) {
            return "🍽️"
        }
        if containsAny(title, keywords: ["anniversaire", "birthday", "party"]) {
            return "🎉"
        }
        
        return item.isEvent ? "📅" : "🗓️"
    }
    
    private func containsAny(_ text: String, keywords: [String]) -> Bool {
        keywords.contains { text.contains($0) }
    }
    
    // 🏷️ Helper pour deviner une icône SF Symbol basée sur le nom de la liste/calendrier
    private func symbolForCalendar(named name: String) -> String? {
        let lowercaseName = name.lowercased()
        
        // Courses / Shopping
        if containsAny(lowercaseName, keywords: ["course", "shopping", "marché", "market", "grocery", "épicerie"]) {
            return "cart.fill"
        }
        // Travail / Work
        if containsAny(lowercaseName, keywords: ["travail", "work", "bureau", "office", "boulot", "job"]) {
            return "briefcase.fill"
        }
        // Famille / Family
        if containsAny(lowercaseName, keywords: ["famille", "family", "familial"]) {
            return "house.fill"
        }
        // Anniversaires / Birthdays
        if containsAny(lowercaseName, keywords: ["anniversaire", "birthday", "fête", "party"]) {
            return "gift.fill"
        }
        // École / School
        if containsAny(lowercaseName, keywords: ["école", "school", "étude", "study", "cours", "class"]) {
            return "book.fill"
        }
        // Sport / Fitness
        if containsAny(lowercaseName, keywords: ["sport", "fitness", "gym", "exercise"]) {
            return "figure.run"
        }
        // Santé / Health
        if containsAny(lowercaseName, keywords: ["santé", "health", "médical", "medical", "médecin", "doctor"]) {
            return "cross.case.fill"
        }
        // Voyage / Travel
        if containsAny(lowercaseName, keywords: ["voyage", "travel", "vacances", "vacation", "trip"]) {
            return "airplane"
        }
        // Maison / Home
        if containsAny(lowercaseName, keywords: ["maison", "home", "ménage", "house"]) {
            return "house.fill"
        }
        // Personnel / Personal
        if containsAny(lowercaseName, keywords: ["personnel", "personal", "perso"]) {
            return "person.fill"
        }
        
        // Par défaut, pas d'icône spécifique
        return nil
    }
}

// MARK: - View Model

@MainActor
final class UpcomingWeekViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var groupedEvents: [DayGroup] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    // MARK: - Properties
    
    let startDate: Date
    private var eventStoreObserver: NSObjectProtocol? // 🔔 Observer pour EventKit
    
    // MARK: - Dependencies
    
    private let calendarSelectionManager: CalendarSelectionManager
    private let reminderSelectionManager: ReminderSelectionManager
    private let cacheManager = EventCacheManager.shared
    private let eventStore = SharedEventStore.shared
    
    // MARK: - Initializer
    
    init(
        startDate: Date = Date(),
        calendarSelectionManager: CalendarSelectionManager,
        reminderSelectionManager: ReminderSelectionManager
    ) {
        self.startDate = startDate
        self.calendarSelectionManager = calendarSelectionManager
        self.reminderSelectionManager = reminderSelectionManager
        
        // 🔔 Configurer l'observateur EventKit dès l'initialisation
        setupEventStoreObserver()
    }
    
    deinit {
        // 🧹 Nettoyer l'observateur
        if let observer = eventStoreObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - 🔔 Synchronisation automatique
    
    private func setupEventStoreObserver() {
        Logger.reminder.info("🔔 Configuration de l'observateur EventKit pour la vue semaine")
        
        eventStoreObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: eventStore,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            
            Logger.reminder.info("🔔 Changement détecté dans EventKit - Mise à jour de la vue semaine")
            
            Task { @MainActor in
                await self.refresh()
                Logger.reminder.info("✅ Vue semaine mise à jour automatiquement")
            }
        }
    }
    
    // MARK: - Methods
    
    func loadEvents() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        // ✅ Forcer le préchargement avec invalidation du cache
        cacheManager.invalidateAllCache()
        
        // ✅ Précharger les événements à partir de startDate (charge tout d'un coup maintenant)
        await cacheManager.preloadEvents(
            from: startDate,
            days: 30,
            calendarSelectionManager: calendarSelectionManager,
            reminderSelectionManager: reminderSelectionManager
        )
        
        // ✅ Mettre à jour les groupes après le chargement complet
        await updateGroupedEvents()
        
        isLoading = false
    }
    
    func refresh() async {
        await loadEvents()
    }
    
    // ✨ Nouvelle fonction pour mettre à jour les groupes
    private func updateGroupedEvents() async {
        var grouped: [DayGroup] = []
        let calendar = Calendar.current
        
        // ✅ Commencer à partir de la date de départ (startDate) au lieu d'aujourd'hui
        for dayOffset in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else {
                continue
            }
            
            // ✅ Récupérer les événements depuis le cache maintenant complet
            let startOfDay = calendar.startOfDay(for: date)
            let events = cacheManager.getCachedEvents(for: date) ?? []
            
            // N'ajouter que si on a des événements
            if !events.isEmpty {
                grouped.append(DayGroup(date: startOfDay, items: events))
            }
        }
        
        groupedEvents = grouped
    }
}

// MARK: - Models

struct DayGroup {
    let date: Date
    let items: [AgendaItem]
}

// MARK: - Previews

#Preview("Avec événements") {
    let calendarManager = CalendarSelectionManager()
    let reminderManager = ReminderSelectionManager()
    
    return UpcomingWeekView(
        startDate: Date(),
        calendarSelectionManager: calendarManager,
        reminderSelectionManager: reminderManager
    )
    .environmentObject(UserSettings())
}

#Preview("Vide") {
    let calendarManager = CalendarSelectionManager()
    let reminderManager = ReminderSelectionManager()
    
    return UpcomingWeekView(
        startDate: Date(),
        calendarSelectionManager: calendarManager,
        reminderSelectionManager: reminderManager
    )
    .environmentObject(UserSettings())
}

#Preview("À partir de demain") {
    let calendarManager = CalendarSelectionManager()
    let reminderManager = ReminderSelectionManager()
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    
    return UpcomingWeekView(
        startDate: tomorrow,
        calendarSelectionManager: calendarManager,
        reminderSelectionManager: reminderManager
    )
    .environmentObject(UserSettings())
}

