//
//  LoggerExtensions.swift
//  MyDay
//
//  Created by Assistant on 2025-01-15.
//

import Foundation
import os.log

extension Logger {
    /// Logger pour les événements de l'application principale
    static let app = Logger(subsystem: AppGroup.id, category: "app")
    
    /// Logger pour les événements du widget
    static let widget = Logger(subsystem: AppGroup.id, category: "widget")
    
    /// Logger pour les événements de calendrier
    static let calendar = Logger(subsystem: AppGroup.id, category: "calendar")
    
    /// Logger pour les événements de santé
    static let health = Logger(subsystem: AppGroup.id, category: "health")
    
    /// Logger pour les événements de photos
    static let photos = Logger(subsystem: AppGroup.id, category: "photos")
}
