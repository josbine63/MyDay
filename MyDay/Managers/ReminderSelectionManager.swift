import Foundation
import EventKit

@MainActor
class ReminderSelectionManager: ObservableObject {
    @Published var availableReminderLists: [EKCalendar] = []
    @Published var selectedReminderListIDs: Set<String> = []

    private let eventStore = EKEventStore()
    private let userDefaults = UserDefaults(suiteName: "group.com.josblais.myday")
    private let reminderIDsKey = "selectedReminderListIDs"

    init() {
        Task {
            await requestAccessAndLoadReminderLists()
        }
    }

    func requestAccessAndLoadReminderLists() async {
        let granted = try? await eventStore.requestAccess(to: .reminder)
        if granted == true {
            loadReminderLists()
        } else {
            print("⛔️ Accès aux rappels refusé.")
        }
    }

    func loadReminderLists() {
        let lists = eventStore.calendars(for: .reminder)
        availableReminderLists = lists

        // Charger la sélection précédente
        if let savedIDs = userDefaults?.array(forKey: reminderIDsKey) as? [String] {
            selectedReminderListIDs = Set(savedIDs)
        } else {
            // Par défaut, tout sélectionner
            selectedReminderListIDs = Set(lists.map { $0.calendarIdentifier })
            saveSelection()
        }
    }

    func toggleSelection(for list: EKCalendar) {
        if selectedReminderListIDs.contains(list.calendarIdentifier) {
            selectedReminderListIDs.remove(list.calendarIdentifier)
        } else {
            selectedReminderListIDs.insert(list.calendarIdentifier)
        }
        saveSelection()
    }

    func isSelected(_ list: EKCalendar) -> Bool {
        selectedReminderListIDs.contains(list.calendarIdentifier)
    }

    private func saveSelection() {
        userDefaults?.set(Array(selectedReminderListIDs), forKey: reminderIDsKey)
    }
}