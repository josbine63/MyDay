import Foundation

enum AppGroup {
    static let id = "group.com.josblais.myday"

    static var userDefaults: UserDefaults {
        return UserDefaults(suiteName: id)!
    }
}

enum UserDefaultsKeys {
    static let albumName = "albumName"
    static let currentImage = "currentImage"
    static let nextWidgetItem = "nextItem"
    static let hasLaunchedBefore = "hasLaunchedBefore"
    static let completedEventsPrefix = "completedEvents_" // à concaténer avec une date
}

enum DateFormat {
    static let widgetDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    static let storageKey: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}