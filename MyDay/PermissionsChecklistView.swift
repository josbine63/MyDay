import SwiftUI
import EventKit
import HealthKit
import Photos

struct PermissionsChecklistView: View {
    @EnvironmentObject var onboardingManager: OnboardingManager

    var body: some View {
        VStack(spacing: 24) {
            Text("Permissions requises")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 16) {
                permissionRow(icon: "calendar", text: "Calendrier", granted: onboardingManager.calendarGranted) {
                    Task { await onboardingManager.requestCalendar() }
                }

                permissionRow(icon: "checklist", text: "Rappels", granted: onboardingManager.reminderGranted) {
                    Task { await onboardingManager.requestReminders() }
                }

                permissionRow(icon: "photo", text: "Photos", granted: onboardingManager.photosGranted) {
                    Task { await onboardingManager.requestPhotos() }
                }

                permissionRow(icon: "heart", text: "Santé", granted: onboardingManager.healthGranted) {
                    Task { await onboardingManager.requestHealth() }
                }
            }

            if onboardingManager.allGranted {
                Button("Continuer") {
                    onboardingManager.completeOnboarding()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }

    @ViewBuilder
    func permissionRow(icon: String, text: String, granted: Bool, action: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)

            Text(text)

            Spacer()

            if granted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Button("Autoriser", action: action)
                    .buttonStyle(.bordered)
            }
        }
    }
}

#Preview {
    PermissionsChecklistView()
        .environmentObject(OnboardingManager())
}