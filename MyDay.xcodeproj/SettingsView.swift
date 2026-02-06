import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userSettings: UserSettings
    
    var body: some View {
        Form {
            Section(header: Text("Paramètres")) {
                Text("Interface des réglages à venir...")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Réglages")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(UserSettings())
    }
}
