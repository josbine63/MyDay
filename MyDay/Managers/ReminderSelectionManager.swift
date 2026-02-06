import Foundation
import EventKit
import os.log

@MainActor
class ReminderSelectionManager: ObservableObject {
    @Published var selectableReminderLists: [SelectableReminderList] = []

    private let eventStore = SharedEventStore.shared
    private let userDefaults = UserDefaults.appGroup
    private let selectionKey = UserDefaultsKeys.selectedReminderLists

    func toggleSelection(for calendarID: String) {
        if let index = selectableReminderLists.firstIndex(where: { $0.id == calendarID }) {
            selectableReminderLists[index].isSelected.toggle()
            saveSelection()
        }
    }

    private func saveSelection() {
        let ids = selectableReminderLists.filter { $0.isSelected }.map { $0.id }
        Logger.reminder.info("💾 Sauvegarde des rappels sélectionnés : \(ids, privacy: .public)")
        userDefaults.set(ids, forKey: selectionKey)
    }

    func loadReminderLists() async {
        Logger.reminder.info("📂 Début chargement des rappels")
        
        let calendars = eventStore.calendars(for: .reminder)
        let savedIDs = Set(userDefaults.stringArray(forKey: selectionKey) ?? [])
        
        Logger.reminder.info("📂 \(calendars.count) liste(s) de rappels trouvée(s)")

        selectableReminderLists = calendars.map {
            SelectableReminderList(calendar: $0, isSelected: savedIDs.contains($0.calendarIdentifier))
        }
        
        // Si aucune liste n'est sélectionnée, sélectionner toutes par défaut
        if savedIDs.isEmpty && !selectableReminderLists.isEmpty {
            selectableReminderLists = selectableReminderLists.map {
                var list = $0
                list.isSelected = true
                return list
            }
            saveSelection()
        }
        
        Logger.reminder.info("✅ Rappels chargés")
    }

    var selectedReminderListIDs: Set<String> {
        Set(selectableReminderLists.filter { $0.isSelected }.map { $0.id })
    }
}
