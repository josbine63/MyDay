//
//  EventStatusManager.swift
//  MyDay
//
//  Created by Josblais on 2025-05-04.
//


import Foundation

class EventStatusManager: ObservableObject {
    static let shared = EventStatusManager()

    private let iCloudStore = NSUbiquitousKeyValueStore.default
    private let userDefaults = UserDefaults.appGroup
    
    private let idSchemeVersionKey = "completedEvents_idSchemeVersion"
    private let currentIdSchemeVersion = 2

    @Published var completedEventIDs: Set<String> = []

    private let key = "completedEvents"

    init() {
        migrateIfNeeded()
        loadFromStorage()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(iCloudDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: iCloudStore
        )
    }

    // MARK: - Public API

    func toggleEventCompletion(id: String) {
        if completedEventIDs.contains(id) {
            completedEventIDs.remove(id)
        } else {
            completedEventIDs.insert(id)
        }
        saveToStorage()
    }

    func isCompleted(id: String) -> Bool {
        return completedEventIDs.contains(id)
    }
    
    /// Marque un événement/rappel comme complété (sans toggle)
    func markEventAsCompleted(id: String) {
        guard !completedEventIDs.contains(id) else { return }
        completedEventIDs.insert(id)
        saveToStorage()
    }
    
    /// Marque un événement/rappel comme incomplet (sans toggle)
    func markEventAsIncomplete(id: String) {
        guard completedEventIDs.contains(id) else { return }
        completedEventIDs.remove(id)
        saveToStorage()
    }

    // MARK: - Storage

    private func saveToStorage() {
        let idsArray = Array(completedEventIDs)
        userDefaults.set(idsArray, forKey: key)
        iCloudStore.set(idsArray, forKey: key)
        iCloudStore.synchronize()
    }

    private func loadFromStorage() {
        let cloudArray = (iCloudStore.array(forKey: key) as? [String]) ?? []
        let localArray = (userDefaults.array(forKey: key) as? [String]) ?? []
        let merged = Set(cloudArray).union(localArray)
        DispatchQueue.main.async {
            self.completedEventIDs = merged
        }
    }
    
    private func migrateIfNeeded() {
        let storedVersion = userDefaults.integer(forKey: idSchemeVersionKey)
        guard storedVersion < currentIdSchemeVersion else { return }

        // Clear old stored data to avoid mixing unstable IDs with new stable IDs
        userDefaults.removeObject(forKey: key)
        iCloudStore.removeObject(forKey: key)
        iCloudStore.synchronize()

        userDefaults.set(currentIdSchemeVersion, forKey: idSchemeVersionKey)
    }
    
    @objc private func iCloudDidChange(notification: Notification) {
        loadFromStorage()
    }
    
    // MARK: - Cleanup
    
    /// Nettoie les événements complétés anciens (plus de 7 jours)
    func cleanOldCompletedEvents() {
        // Cette méthode peut être implémentée plus tard si nécessaire
        // Pour l'instant, on garde tous les événements complétés
    }
}

