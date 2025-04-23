import Foundation

class EventStatusManager: ObservableObject {
    static let shared = EventStatusManager()

    private let iCloudStore = NSUbiquitousKeyValueStore.default
    private let userDefaults = UserDefaults(suiteName: "group.com.josblais.myday")!

    @Published var completedEventIDs: Set<String> = []

    private let key = "completedEvents"

    private init() {
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

    // MARK: - Storage

    private func saveToStorage() {
        let idsArray = Array(completedEventIDs)
        userDefaults.set(idsArray, forKey: key)
        iCloudStore.set(idsArray, forKey: key)
        iCloudStore.synchronize()
    }

    private func loadFromStorage() {
        // iCloud first
        if let cloudArray = iCloudStore.array(forKey: key) as? [String] {
            completedEventIDs = Set(cloudArray)
        }
        // Fallback to local if iCloud is empty
        else if let localArray = userDefaults.array(forKey: key) as? [String] {
            completedEventIDs = Set(localArray)
        }
    }

    @objc private func iCloudDidChange(notification: Notification) {
        loadFromStorage()
    }
}