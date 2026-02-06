
import SwiftUI

enum PermissionType {
    case calendar
    case reminder
    case photo
    case health
}

struct PermissionChecklistView: View {
    @ObservedObject var manager: PermissionChecklistManager
    var onComplete: () -> Void
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var showHealthInstructions = false
    @State private var showCalendarExplanation = false
    @State private var showReminderExplanation = false

    var body: some View {
        VStack(spacing: 24) {
            // En-tête
            VStack(spacing: 12) {
                Text("🔐")
                    .font(.system(size: 60))
                
                Text("Autorisations requises")
                    .font(.title2.bold())
                
                Text("Pour vous offrir la meilleure expérience, nous avons besoin d'accéder à ces fonctionnalités.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 40)

            // Liste des permissions (Calendrier et Rappels uniquement)
            // Photos et Santé sont demandées à la première activation dans les Réglages
            VStack(spacing: 12) {
                permissionRow(
                    status: manager.calendarStatus,
                    label: "Calendrier",
                    icon: "calendar",
                    description: "Lire vos événements du jour",
                    permissionType: .calendar,
                    action: { showCalendarExplanation = true }
                )
                
                permissionRow(
                    status: manager.reminderStatus,
                    label: "Rappels",
                    icon: "checklist",
                    description: "Gérer vos tâches importantes",
                    permissionType: .reminder,
                    action: { showReminderExplanation = true }
                )
            }
            .padding(.horizontal)

            Spacer()

            // Bouton de continuation
            VStack(spacing: 12) {
                Button {
                    onComplete()
                } label: {
                    HStack {
                        Image(systemName: manager.allGrantedState ? "checkmark.circle.fill" : "arrow.right.circle.fill")
                        Text(manager.allGrantedState ? "Continuer" : "Passer")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                if !manager.allGrantedState {
                    VStack(spacing: 4) {
                        Text("\(grantedCount)/2 accordées")
                            .font(.caption.bold())
                            .foregroundColor(.accentColor)
                        
                        Text("Vous pourrez activer ces permissions plus tard dans les Réglages")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.bottom, 40)
        }
        .onAppear {
            manager.updateStatuses()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // Rafraîchir les statuts quand l'utilisateur revient des Réglages
            if newPhase == .active {
                manager.updateStatuses()
                // Forcer un rafraîchissement de la santé après un délai
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    manager.forceHealthStatusRefresh()
                }
            }
        }
        .alert("Activer les données de santé", isPresented: $showHealthInstructions) {
            Button("Ouvrir Santé") {
                // Ouvrir l'app Santé (page principale)
                if let healthURL = URL(string: "x-apple-health://") {
                    UIApplication.shared.open(healthURL)
                }
            }
            Button("Annuler", role: .cancel) { }
        } message: {
            Text("Pour activer les permissions de santé:\n\n1. Ouvrez l'app Santé\n2. Allez dans Partage\n3. Sélectionnez Apps\n4. Trouvez et ouvrez MyDay\n5. Activez les données souhaitées")
        }
        // Explication avant la demande de permission Calendrier
        .alert("Accès au Calendrier", isPresented: $showCalendarExplanation) {
            Button("D'accord") {
                manager.requestCalendar()
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("MyDay a besoin de cette autorisation pour lire vos calendriers et afficher vos événements du jour. iOS ne propose pas d'accès en lecture seule au Calendrier, mais l'application ne créera, modifiera ni supprimera aucun événement.")
        }
        // Explication avant la demande de permission Rappels
        .alert("Accès aux Rappels", isPresented: $showReminderExplanation) {
            Button("D'accord") {
                manager.requestReminders()
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("MyDay a besoin de l'autorisation complète sur vos rappels pour les afficher et marquer des rappels comme complétés. Aucune nouvelle liste ne sera créée par l'application.")
        }
    }

    private var grantedCount: Int {
        let statuses = [manager.calendarStatus, manager.reminderStatus]
        return statuses.filter { $0 == .granted }.count
    }
    
    private func openSettings(for permissionType: PermissionType) {
        if permissionType == .health {
            // Pour la santé, afficher les instructions détaillées
            showHealthInstructions = true
        } else {
            // Pour les autres permissions, ouvrir les Réglages de l'app
            Task { @MainActor in
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    await UIApplication.shared.open(settingsURL)
                }
            }
        }
    }

    private func permissionRow(
        status: PermissionState,
        label: String,
        icon: String,
        description: String,
        permissionType: PermissionType,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 16) {
            // Icône de la permission
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 40)
            
            // Texte
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Bouton ou indicateur de statut
            switch status {
            case .unknown:
                Button(action: action) {
                    HStack(spacing: 4) {
                        Image(systemName: iconFor(status))
                    }
                    .foregroundColor(colorFor(status))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(colorFor(status).opacity(0.15))
                    .cornerRadius(8)
                }
            case .denied:
                Button(action: { openSettings(for: permissionType) }) {
                    HStack(spacing: 4) {
                        Image(systemName: "gear")
                        Text("Réglages")
                            .font(.caption.bold())
                    }
                    .foregroundColor(colorFor(status))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(colorFor(status).opacity(0.15))
                    .cornerRadius(8)
                }
            case .granted:
                Image(systemName: iconFor(status))
                    .foregroundColor(colorFor(status))
                    .font(.title3)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private func iconFor(_ status: PermissionState) -> String {
        switch status {
        case .unknown: return "circle"
        case .granted: return "checkmark.circle.fill"
        case .denied: return "exclamationmark.circle"
        }
    }

    private func colorFor(_ status: PermissionState) -> Color {
        switch status {
        case .unknown: return .gray
        case .granted: return .green
        case .denied: return .orange
        }
    }
}
