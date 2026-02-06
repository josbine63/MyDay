import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userSettings: UserSettings
    
    @ObservedObject var calendarSelectionManager: CalendarSelectionManager
    @ObservedObject var reminderSelectionManager: ReminderSelectionManager
    
    @State private var showCalendarSelection = false
    @State private var showReminderSelection = false
    
    var body: some View {
        Form {
            Section(header: Text("Sources de données")) {
                NavigationLink(destination: CalendarSelectionView(manager: calendarSelectionManager)) {
                    HStack {
                        Image(systemName: "calendar.badge.checkmark")
                            .foregroundColor(.accentColor)
                            .frame(width: 30)
                        Text("Calendriers")
                    }
                }
                
                NavigationLink(destination: ReminderSelectionView(manager: reminderSelectionManager)) {
                    HStack {
                        Image(systemName: "text.badge.checkmark")
                            .foregroundColor(.accentColor)
                            .frame(width: 30)
                        Text("Listes de rappels")
                    }
                }
            }
        }
        .navigationTitle("Réglages")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView(
            calendarSelectionManager: CalendarSelectionManager(),
            reminderSelectionManager: ReminderSelectionManager()
        )
        .environmentObject(UserSettings())
    }
}
