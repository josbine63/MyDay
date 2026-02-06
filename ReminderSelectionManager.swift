//
//  ReminderSelectionManager.swift
//  MyDay
//
//  Created by Assistant on 2025-01-15.
//

import Foundation
import EventKit
import os.log

@MainActor
class ReminderSelectionManager: ObservableObject {
    @Published var selectableReminderLists: [SelectableReminderList] = []
    @Published var selectedLists: [EKCalendar] = []
    @Published var availableLists: [SelectableCalendar] = []
    @Published var reminders: [EKReminder] = []
    @Published var hasAccess = false
    
    private let eventStore = SharedEventStore.shared
    private let defaults = UserDefaults.appGroup
    private let userDefaults = UserDefaults(suiteName: AppGroup.id)!
    private let selectedListsKey = "selectedReminderListIDs"
    private let selectionKey = "SelectedReminderLists"
    
    init() {
        checkReminderAuthorizationStatus()
        loadSelectedLists()
    }
    
    func checkReminderAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        hasAccess = (status == .fullAccess || status == .writeOnly || status == .authorized)
    }
    
    func requestAccess() async -> Bool {
        do {
            let granted: Bool
            if #available(iOS 17.0, *) {
                granted = try await eventStore.requestFullAccessToReminders()
            } else {
                granted = try await eventStore.requestAccess(to: .reminder)
            }
            
            await MainActor.run {
                hasAccess = granted
            }
            
            return granted
        } catch {
            Logger.calendar.error("❌ Erreur lors de la demande d'accès aux rappels: \(error.localizedDescription)")
            return false
        }
    }
    
    // Nouvelle méthode pour l'onboarding
    func loadReminderLists() async {
        Logger.calendar.info("📂 Début chargement des rappels")
        
        let lists = eventStore.calendars(for: .reminder)
        let savedIDs = Set(userDefaults.stringArray(forKey: selectionKey) ?? [])
        Logger.calendar.info("📂 Chargement des rappels sauvegardés : \(savedIDs.count)")
        
        selectableReminderLists = lists.map {
            SelectableReminderList(calendar: $0, isSelected: savedIDs.contains($0.calendarIdentifier))
        }
        
        Logger.calendar.info("📂 \(lists.count) liste(s) de rappels trouvée(s)")
        
        // ⚠️ NE PLUS sélectionner automatiquement toutes les listes
        // L'utilisateur doit faire son choix pendant l'onboarding
        
        Logger.calendar.info("✅ Rappels chargés")
    }
    
    func toggleSelection(for listID: String) {
        if let index = selectableReminderLists.firstIndex(where: { $0.id == listID }) {
            selectableReminderLists[index].isSelected.toggle()
            saveSelection()
        }
    }
    
    func selectAll() {
        selectableReminderLists = selectableReminderLists.map {
            var list = $0
            list.isSelected = true
            return list
        }
        saveSelection()
    }
    
    func deselectAll() {
        selectableReminderLists = selectableReminderLists.map {
            var list = $0
            list.isSelected = false
            return list
        }
        saveSelection()
    }
    
    private func saveSelection() {
        let ids = selectableReminderLists.filter { $0.isSelected }.map { $0.id }
        Logger.calendar.info("💾 Sauvegarde des rappels sélectionnés : \(ids)")
        userDefaults.set(ids, forKey: selectionKey)
        
        // Aussi sauvegarder dans l'ancien format pour compatibilité
        defaults.set(ids, forKey: selectedListsKey)
        loadSelectedLists()
    }
    
    var selectedReminderListIDs: Set<String> {
        Set(selectableReminderLists.filter { $0.isSelected }.map { $0.id })
    }
    
    var selectedReminderLists: [EKCalendar] {
        let ids = selectedReminderListIDs
        return eventStore.calendars(for: .reminder).filter { ids.contains($0.calendarIdentifier) }
    }
    
    func loadAvailableLists() {
        let lists = eventStore.calendars(for: .reminder)
        let selectedIDs = getSelectedListIDs()
        
        availableLists = lists.map { list in
            SelectableCalendar(
                calendar: list,
                isSelected: selectedIDs.contains(list.calendarIdentifier)
            )
        }
        
        Logger.calendar.debug("📝 \(lists.count) listes de rappels disponibles")
    }
    
    func toggleList(_ list: SelectableCalendar) {
        if let index = availableLists.firstIndex(where: { $0.id == list.id }) {
            availableLists[index].isSelected.toggle()
            saveSelectedLists()
        }
    }
    
    func fetchReminders() async {
        guard hasAccess else {
            Logger.calendar.warning("⚠️ Pas d'accès aux rappels")
            return
        }
        
        let predicate = eventStore.predicateForReminders(in: selectedLists.isEmpty ? nil : selectedLists)
        
        do {
            let fetchedReminders = try await eventStore.reminders(matching: predicate)
            
            await MainActor.run {
                reminders = fetchedReminders
                Logger.calendar.debug("📝 \(fetchedReminders.count) rappels récupérés")
            }
        } catch {
            Logger.calendar.error("❌ Erreur lors de la récupération des rappels: \(error.localizedDescription)")
        }
    }
    
    private func saveSelectedLists() {
        let selectedIDs = availableLists
            .filter { $0.isSelected }
            .map { $0.id }
        
        defaults.set(selectedIDs, forKey: selectedListsKey)
        loadSelectedLists()
        
        Logger.calendar.debug("💾 \(selectedIDs.count) listes de rappels sauvegardées")
    }
    
    private func loadSelectedLists() {
        let selectedIDs = getSelectedListIDs()
        let lists = eventStore.calendars(for: .reminder)
        
        selectedLists = lists.filter { selectedIDs.contains($0.calendarIdentifier) }
    }
    
    private func getSelectedListIDs() -> Set<String> {
        if let ids = defaults.array(forKey: selectedListsKey) as? [String] {
            return Set(ids)
        }
        return []
    }
}
