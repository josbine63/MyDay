//
//  LoggerExtensions.swift
//  MyDay
//
//  Created by Assistant on 2025-10-15.
//

import Foundation
import os.log

// MARK: - Logger Extensions

extension Logger {
    /// Logger pour l'application MyDay
    private static let subsystem = "com.josblais.myday"
    
    /// Logger pour la gestion des calendriers
    static let calendar = Logger(subsystem: subsystem, category: "Calendar")
    
    /// Logger pour la gestion des rappels
    static let reminder = Logger(subsystem: subsystem, category: "Reminder")
    
    /// Logger pour la gestion des photos
    static let photo = Logger(subsystem: subsystem, category: "Photo")
    
    /// Logger pour l'initialisation de l'app
    static let app = Logger(subsystem: subsystem, category: "App")
    
    /// Logger pour l'interface utilisateur
    static let ui = Logger(subsystem: subsystem, category: "UI")
    
    /// Logger pour la santé
    static let health = Logger(subsystem: subsystem, category: "Health")
    
    /// Logger pour les permissions
    static let permission = Logger(subsystem: subsystem, category: "Permission")
}