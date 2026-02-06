//
//  LocalizableKeys.swift
//  MyDay
//
//  Created by Assistant on 2025-01-15.
//

import Foundation

/// Keys for localized strings throughout the app
enum LocalizableKeys {
    // MARK: - General
    static let appName = "MyDay"
    static let ok = "OK"
    static let cancel = "Cancel"
    static let done = "Done"
    static let save = "Save"
    static let delete = "Delete"
    static let edit = "Edit"
    static let close = "Close"
    
    // MARK: - Permissions
    static let permissionsTitle = "Permissions"
    static let calendarPermission = "Calendar Access"
    static let reminderPermission = "Reminder Access"
    static let photoPermission = "Photo Access"
    static let healthPermission = "Health Access"
    
    // MARK: - Widget
    static let nextItem = "Next Item"
    static let noReminder = "No Reminder"
    static let nextReminder = "Next Reminder"
    
    // MARK: - Errors
    static let errorTitle = "Error"
    static let permissionDenied = "Permission Denied"
    static let permissionRequired = "This permission is required for the app to function properly."
}
