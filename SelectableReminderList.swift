//
//  SelectableReminderList.swift
//  MyDay
//
//  Created by Assistant on 2025-01-15.
//

import Foundation
import EventKit
import SwiftUI

struct SelectableReminderList: Identifiable {
    let id: String
    let title: String
    let account: String
    let color: CGColor
    var isSelected: Bool
    let calendar: EKCalendar
    
    init(calendar: EKCalendar, isSelected: Bool = false) {
        self.id = calendar.calendarIdentifier
        self.title = calendar.title
        self.account = calendar.source.title
        self.color = calendar.cgColor
        self.isSelected = isSelected
        self.calendar = calendar
    }
}
