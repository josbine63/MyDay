//
//  CalendarManager.swift
//  MyDay
//
//  Created by Assistant on 2025-01-15.
//

import Foundation
import EventKit
import os.log

@MainActor
class CalendarManager: ObservableObject {
    @Published var events: [EKEvent] = []
    @Published var hasAccess = false
    
    private let eventStore = EKEventStore()
    
    init() {
        checkCalendarAuthorizationStatus()
    }
    
    func checkCalendarAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)
        hasAccess = (status == .fullAccess || status == .writeOnly || status == .authorized)
    }
    
    func requestAccess() async -> Bool {
        do {
            let granted: Bool
            if #available(iOS 17.0, *) {
                granted = try await eventStore.requestFullAccessToEvents()
            } else {
                granted = try await eventStore.requestAccess(to: .event)
            }
            
            await MainActor.run {
                hasAccess = granted
            }
            
            return granted
        } catch {
            Logger.calendar.error("❌ Erreur lors de la demande d'accès au calendrier: \(error.localizedDescription)")
            return false
        }
    }
    
    func fetchEvents(from startDate: Date, to endDate: Date) async {
        guard hasAccess else {
            Logger.calendar.warning("⚠️ Pas d'accès au calendrier")
            return
        }
        
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let fetchedEvents = eventStore.events(matching: predicate)
        
        await MainActor.run {
            events = fetchedEvents
            Logger.calendar.debug("📅 \(fetchedEvents.count) événements récupérés")
        }
    }
}
