import Foundation
import EventKit
import os.log

@MainActor
class CalendarSelectionManager: ObservableObject {
    @Published var selectableCalendars: [SelectableCalendar] = []
    
    private let eventStore = SharedEventStore.shared
    private let userDefaults = UserDefaults.appGroup
    private let selectionKey = UserDefaultsKeys.selectedCalendars
    
    func toggleSelection(for calendarID: String) {
        if let index = selectableCalendars.firstIndex(where: { $0.id == calendarID }) {
            selectableCalendars[index].isSelected.toggle()
            saveSelection()
        }
    }
    
    func selectAll() {
        selectableCalendars = selectableCalendars.map {
            var calendar = $0
            calendar.isSelected = true
            return calendar
        }
        saveSelection()
    }
    
    func deselectAll() {
        selectableCalendars = selectableCalendars.map {
            var calendar = $0
            calendar.isSelected = false
            return calendar
        }
        saveSelection()
    }
    
    func loadCalendars(autoSelectAll: Bool = true) async {
        Logger.calendar.info("📂 Début chargement des calendriers")
        
        let calendars = eventStore.calendars(for: .event)
        let savedIDs = Set(userDefaults.stringArray(forKey: selectionKey) ?? [])
        
        Logger.calendar.info("📂 \(calendars.count) calendrier(s) trouvé(s)")
        
        selectableCalendars = calendars.map {
            SelectableCalendar(calendar: $0, isSelected: savedIDs.contains($0.calendarIdentifier))
        }
        
        // Si aucun calendrier n'est sélectionné, sélectionner tous par défaut (sauf pendant l'onboarding)
        if autoSelectAll && savedIDs.isEmpty && !selectableCalendars.isEmpty {
            selectableCalendars = selectableCalendars.map {
                var calendar = $0
                calendar.isSelected = true
                return calendar
            }
            saveSelection()
        }
        
        Logger.calendar.info("✅ Calendriers chargés")
    }
    
    var selectedCalendars: [EKCalendar] {
        selectableCalendars.filter { $0.isSelected }.map { $0.calendar }
    }
    
    var selectedCalendarIDs: Set<String> {
        Set(selectedCalendars.map { $0.calendarIdentifier })
    }
    
    private func saveSelection() {
        let ids = selectableCalendars.filter { $0.isSelected }.map { $0.id }
        Logger.calendar.info("💾 Sauvegarde des calendriers sélectionnés : \(ids, privacy: .public)")
        userDefaults.set(ids, forKey: selectionKey)
    }
}
