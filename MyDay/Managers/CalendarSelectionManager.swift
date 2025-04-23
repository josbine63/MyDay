// Managers/CalendarSelectionManager.swift
import EventKit
import Foundation

class CalendarSelectionManager: ObservableObject {
    @Published var selectableCalendars: [SelectableCalendar] = []
    
    private let eventStore = EKEventStore()
    private let selectionKey = "selectedCalendarIDs"
    
    init() {
        loadCalendars()
    }
    
    func loadCalendars() {
        let savedIDs = UserDefaults.standard.stringArray(forKey: selectionKey) ?? []

        let calendars = eventStore.calendars(for: .event).filter {
            let title = $0.title.lowercased()
            return !title.contains("férié") && !title.contains("holiday")
        }

        self.selectableCalendars = calendars.map { calendar in
            SelectableCalendar(
                id: calendar.calendarIdentifier,
                title: calendar.title,
                calendar: calendar,
                isSelected: savedIDs.contains(calendar.calendarIdentifier)
            )
        }
    }
    
    func toggleSelection(for calendar: SelectableCalendar) {
        guard let index = selectableCalendars.firstIndex(of: calendar) else { return }
        selectableCalendars[index].isSelected.toggle()
        saveSelection()
    }
    
    func saveSelection() {
        let selectedIDs = selectableCalendars
            .filter { $0.isSelected }
            .map { $0.id }
        
        UserDefaults.standard.set(selectedIDs, forKey: selectionKey)
    }
    
    func selectedCalendars() -> [EKCalendar] {
        selectableCalendars.filter { $0.isSelected }.map { $0.calendar }
    }
}