//
//  CalendarSelectionManager.swift
//  MyDay
//
//  Created by Assistant on 2025-01-15.
//

import Foundation
import EventKit
import os.log

struct SelectableCalendar: Identifiable {
    let id: String
    let title: String
    let account: String
    var isSelected: Bool
    
    init(calendar: EKCalendar, isSelected: Bool = false) {
        self.id = calendar.calendarIdentifier
        self.title = calendar.title
        self.account = calendar.source.title
        self.isSelected = isSelected
    }
}

@MainActor
class CalendarSelectionManager: ObservableObject {
    @Published var selectableCalendars: [SelectableCalendar] = []
    
    private let eventStore = SharedEventStore.shared
    private let userDefaults = UserDefaults(suiteName: AppGroup.id)!
    private let selectionKey = "SelectedCalendars"
    
    func toggleSelection(for calendarID: String) {
        if let index = selectableCalendars.firstIndex(where: { $0.id == calendarID }) {
            selectableCalendars[index].isSelected.toggle()
            saveSelection()
        }
    }
    
    func selectAll() {
        selectableCalendars = selectableCalendars.map {
            var cal = $0
            cal.isSelected = true
            return cal
        }
        saveSelection()
    }
    
    func deselectAll() {
        selectableCalendars = selectableCalendars.map {
            var cal = $0
            cal.isSelected = false
            return cal
        }
        saveSelection()
    }
    
    private func saveSelection() {
        let ids = selectableCalendars.filter { $0.isSelected }.map { $0.id }
        Logger.calendar.info("💾 Sauvegarde des calendriers sélectionnés : \(ids.count) calendriers")
        Logger.calendar.debug("💾 IDs sauvegardés : \(ids)")
        userDefaults.set(ids, forKey: selectionKey)
        
        // ✅ Vérifier immédiatement que la sauvegarde a fonctionné
        if let saved = userDefaults.stringArray(forKey: selectionKey) {
            Logger.calendar.debug("✅ Vérification : \(saved.count) IDs trouvés dans UserDefaults")
        } else {
            Logger.calendar.error("❌ ERREUR : Aucune donnée trouvée dans UserDefaults après sauvegarde !")
        }
    }
    
    func loadCalendars() {
        Logger.calendar.info("📂 Début chargement des calendriers")
        Logger.calendar.debug("📂 Utilisation de la clé : \(selectionKey)")
        Logger.calendar.debug("📂 App Group ID : \(AppGroup.id)")
        
        let calendars = eventStore.calendars(for: .event)
        let savedIDs = Set(userDefaults.stringArray(forKey: selectionKey) ?? [])
        Logger.calendar.info("📂 Chargement des calendriers sauvegardés : \(savedIDs.count) IDs")
        Logger.calendar.debug("📂 IDs chargés : \(Array(savedIDs))")
        
        selectableCalendars = calendars.map {
            let isSelected = savedIDs.contains($0.calendarIdentifier)
            Logger.calendar.debug("📅 \($0.title) (\($0.calendarIdentifier)) -> \(isSelected ? "✅ sélectionné" : "⭕️ non sélectionné")")
            return SelectableCalendar(calendar: $0, isSelected: isSelected)
        }
        
        Logger.calendar.info("📂 \(calendars.count) calendrier(s) trouvé(s)")
        Logger.calendar.info("📂 \(selectableCalendars.filter { $0.isSelected }.count) calendrier(s) sélectionné(s)")
        
        // ⚠️ NE PLUS sélectionner automatiquement tous les calendriers
        // L'utilisateur doit faire son choix pendant l'onboarding
        
        Logger.calendar.info("✅ Calendriers chargés")
    }
    
    var selectedCalendarIDs: Set<String> {
        Set(selectableCalendars.filter { $0.isSelected }.map { $0.id })
    }
    
    var selectedCalendars: [EKCalendar] {
        let ids = selectedCalendarIDs
        return eventStore.calendars(for: .event).filter { ids.contains($0.calendarIdentifier) }
    }
}
