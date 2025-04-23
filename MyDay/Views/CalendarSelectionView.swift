// Views/CalendarSelectionView.swift
import SwiftUI

struct CalendarSelectionView: View {
    @ObservedObject var manager: CalendarSelectionManager

    var body: some View {
        List {
            ForEach(manager.selectableCalendars) { calendar in
                HStack {
                    Text(calendar.title)
                    Spacer()
                    if calendar.isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.accentColor)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.gray)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    manager.toggleSelection(for: calendar)
                }
            }
        }
        .navigationTitle("Calendriers")
    }
}