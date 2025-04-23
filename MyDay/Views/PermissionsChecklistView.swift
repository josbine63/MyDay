import SwiftUI

struct PermissionChecklistView: View {
    @ObservedObject var manager: PermissionChecklistManager
    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text(L10n.permissionsTitle)
                .font(.title2.bold())

            VStack(spacing: 12) {
                permissionRow(
                    granted: manager.calendarGranted,
                    label: L10n.permissionsCalendar,
                    icon: "calendar",
                    action: manager.requestCalendar
                )

                permissionRow(
                    granted: manager.reminderGranted,
                    label: L10n.permissionsReminders,
                    icon: "checklist",
                    action: manager.requestReminders
                )

                permissionRow(
                    granted: manager.photoGranted,
                    label: L10n.permissionsPhotos,
                    icon: "photo.on.rectangle",
                    action: manager.requestPhotos
                )

                permissionRow(
                    granted: manager.healthGranted,
                    label: L10n.permissionsHealth,
                    icon: "heart.fill",
                    action: manager.requestHealth
                )
            }

            Button(L10n.permissionsContinue) {
                onComplete()
            }
            .disabled(!manager.allGranted)
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    @ViewBuilder
    private func permissionRow(
        granted: Bool,
        label: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 30)
                .foregroundColor(.blue)

            Text(label)
                .frame(maxWidth: .infinity, alignment: .leading)

            if granted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Button(L10n.permissionsAllow, action: action)
                    .buttonStyle(.bordered)
            }
        }
    }
}
