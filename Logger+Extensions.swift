//
//  Logger+Extensions.swift
//  MyDay
//
//  Created by Assistant on 2025-01-15.
//

import Foundation
import os.log

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.yourcompany.MyDay"
    
    static let app = Logger(subsystem: subsystem, category: "App")
    static let ui = Logger(subsystem: subsystem, category: "UI")
    static let calendar = Logger(subsystem: subsystem, category: "Calendar")
    static let reminder = Logger(subsystem: subsystem, category: "Reminder")
    static let photo = Logger(subsystem: subsystem, category: "Photo")
    static let health = Logger(subsystem: subsystem, category: "Health")
    static let widget = Logger(subsystem: subsystem, category: "Widget")
}
