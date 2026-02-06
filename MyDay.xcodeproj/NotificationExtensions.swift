//
//  NotificationExtensions.swift
//  MyDay
//
//  Created by Assistant on 2026-01-27.
//

import Foundation

extension Notification.Name {
    /// Notification envoyée lorsque l'agenda doit être rafraîchi suite à un changement dans EventKit
    static let needsAgendaRefresh = Notification.Name("needsAgendaRefresh")
}
