//
//  SelectableReminder.swift
//  MyDay
//
//  Created by Josblais on 2025-05-13.
//


// Models/SelectableReminder.swift
import EventKit

struct SelectableReminderList: Identifiable {
    let calendar: EKCalendar
    var isSelected: Bool

    var id: String { calendar.calendarIdentifier }
    var title: String { calendar.title }
    var account: String { calendar.source.title }
}
