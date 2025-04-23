//
//  SelectableCalendar.swift
//  MyDay
//
//  Created by Josblais on 2025-05-13.
//


// Models/SelectableCalendar.swift
import EventKit

struct SelectableCalendar: Identifiable, Hashable {
    let id: String
    let title: String
    let calendar: EKCalendar
    var isSelected: Bool
}