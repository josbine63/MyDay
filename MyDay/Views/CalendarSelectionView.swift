import SwiftUI

struct CalendarSelectionView: View {
    @ObservedObject var manager: CalendarSelectionManager

    var body: some View {
        List {
            Text("Total: \(manager.selectableCalendars.count) calendriers")
            ForEach(manager.selectableCalendars) { calendar in
                HStack {
                    Text(calendar.account)
                    Text(calendar.title)
                    Spacer()
                    Image(systemName: calendar.isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(calendar.isSelected ? .accentColor : .gray)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    manager.toggleSelection(for: calendar.id)
                }
            }
        }
        .navigationTitle("Calendriers")
    }
}
