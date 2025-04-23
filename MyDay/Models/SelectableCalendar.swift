// Models/SelectableCalendar.swift
import EventKit

struct SelectableCalendar: Identifiable, Hashable {
    let id: String
    let title: String
    let calendar: EKCalendar
    var isSelected: Bool
}