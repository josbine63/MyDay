//
//  AppGroup.swift
//  MyDay
//
//  Created by Josblais on 2025-05-12.
//


import Foundation

enum AppGroup {
    static let id = "group.com.josblais.myday"

    static var userDefaults: UserDefaults {
        // Tenter d'utiliser le App Group, sinon utiliser UserDefaults standard
        if let suite = UserDefaults(suiteName: id) {
            return suite
        } else {
            print("⚠️ App Group '\(id)' non disponible, utilisation de UserDefaults standard")
            return .standard
        }
    }
}

enum UserDefaultsKeys {
    static let albumName = "albumName"
    static let currentImage = "currentImage"
    static let nextWidgetItem = "nextItem"
    static let hasLaunchedBefore = "hasLaunchedBefore"
    static let hasAppGroupBeenInitialized = "hasAppGroupBeenInitialized"
    static let PermissionsAllGranted = "PermissionsAllGranted"
    static let CalendarPermission = "CalendarPermission"
    static let ReminderPermission = "ReminderPermission"
    static let PhotoPermission = "PhotoPermission"
    static let HealthPermission = "HealthPermission"
    static let completedEventsPrefix = "completedEvents_" // à concaténer avec une date
    static let selectedCalendars = "SelectedCalendars"
    static let selectedReminderLists = "SelectedReminderLists"
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
// MARK: - Extension pour simplifier l'accès
extension UserDefaults {
    static var appGroup: UserDefaults {
        return AppGroup.userDefaults
    }
}


