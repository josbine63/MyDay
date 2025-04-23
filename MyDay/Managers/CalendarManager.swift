
import Foundation
import EventKit

@MainActor
class CalendarManager: ObservableObject {
    @Published var events: [EKEvent] = []
    @Published var reminders: [EKReminder] = []

    let eventStore = EKEventStore()

    func requestAccessToEvents() {
        eventStore.requestFullAccessToEvents { granted, error in
            if granted {
                Task {
                    await self.fetchEvents(for: Date())
                }
            } else {
                print("Accès refusé au calendrier")
            }
        }
    }

    @MainActor
    func fetchEvents(for date: Date) async {
        let calendars = eventStore.calendars(for: .event)
        let startDate = Calendar.current.startOfDay(for: date)
        guard let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate) else {
            print("❌ Erreur : endDate invalide")
            return
        }

        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        let fetchedEvents = eventStore.events(matching: predicate)

        self.events = fetchedEvents
    }
    
    func fetchReminders(for date: Date) async {
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: date)!
        let predicate = eventStore.predicateForIncompleteReminders(withDueDateStarting: date, ending: endDate, calendars: nil)

        do {
            let fetched = try await withCheckedThrowingContinuation { continuation in
                eventStore.fetchReminders(matching: predicate) { reminders in
                    continuation.resume(returning: reminders ?? [])
                }
            }
            self.reminders = fetched
        } catch {
            print("❌ Erreur lors de la lecture des rappels : \(error)")
        }
    }
}
