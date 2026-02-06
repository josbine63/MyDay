//
//  CalendarSelectionManager.swift
//  MyDay
//
//  Created by Assistant on 2025-01-15.
//

import Foundation
import EventKit
import os.log

@MainActor
class CalendarSelectionManager: ObservableObject {
    @Published var selectedCalendars: [EKCalendar] = []
    @Published var availableCalendars: [SelectableCalendar] = []
    
    private let eventStore = EKEventStore()
    private let defaults = UserDefaults.appGroup
    private let selectedCalendarsKey = "selectedCalendarIDs"
    
    init() {
        loadSelectedCalendars()
    }
    
    func loadAvailableCalendars() {
        let calendars = eventStore.calendars(for: .event)
        let selectedIDs = getSelectedCalendarIDs()
        
        availableCalendars = calendars.map { calendar in
            SelectableCalendar(
                calendar: calendar,
                isSelected: selectedIDs.contains(calendar.calendarIdentifier)
            )
        }
        
        Logger.calendar.debug("📅 \(calendars.count) calendriers disponibles")
    }
    
    func toggleCalendar(_ calendar: SelectableCalendar) {
        if let index = availableCalendars.firstIndex(where: { $0.id == calendar.id }) {
            availableCalendars[index].isSelected.toggle()
            saveSelectedCalendars()
        }
    }
    
    private func saveSelectedCalendars() {
        let selectedIDs = availableCalendars
            .filter { $0.isSelected }
            .map { $0.id }
        
        defaults.set(selectedIDs, forKey: selectedCalendarsKey)
        loadSelectedCalendars()
        
        Logger.calendar.debug("💾 \(selectedIDs.count) calendriers sauvegardés")
    }
    
    private func loadSelectedCalendars() {
        let selectedIDs = getSelectedCalendarIDs()
        let calendars = eventStore.calendars(for: .event)
        
        selectedCalendars = calendars.filter { selectedIDs.contains($0.calendarIdentifier) }
    }
    
    private func getSelectedCalendarIDs() -> Set<String> {
        if let ids = defaults.array(forKey: selectedCalendarsKey) as? [String] {
            return Set(ids)
        }
        return []
    }
}
