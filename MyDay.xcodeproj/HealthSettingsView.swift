//
//  HealthSettingsView.swift
//  MyDay
//

import SwiftUI
import HealthKit

struct HealthPermissionView: View {
    @ObservedObject var manager: PermissionChecklistManager
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "heart.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Santé")
                            .font(.headline)
                        Text("Statistiques d'activité physique")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    permissionStatusView(status: manager.healthStatus)
                }
                .padding(.vertical, 8)
            } header: {
                Text("Statut")
            } footer: {
                footerText(for: manager.healthStatus)
            }
            
            if manager.healthStatus != .granted {
                Section {
                    Button {
                        if manager.healthStatus == .unknown {
                            manager.requestHealth()
                        } else {
                            openSettings()
                        }
                    } label: {
                        HStack {
                            Image(systemName: manager.healthStatus == .unknown ? "lock.open" : "gear")
                            Text(manager.healthStatus == .unknown ? "Autoriser l'accès" : "Ouvrir les Réglages")
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            
            Section {
                HStack {
                    Image(systemName: "figure.walk")
                        .foregroundColor(.accentColor)
                        .frame(width: 30)
                    Text("Nombre de pas")
                }
                
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.accentColor)
                        .frame(width: 30)
                    Text("Calories actives")
                }
                
                HStack {
                    Image(systemName: "map")
                        .foregroundColor(.accentColor)
                        .frame(width: 30)
                    Text("Distance parcourue")
                }
            } header: {
                Text("Données disponibles")
            } footer: {
                Text("Ces statistiques seront affichées dans votre vue quotidienne.")
            }
        }
        .navigationTitle("Santé")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            manager.updateStatuses()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                manager.updateStatuses()
            }
        }
    }
    
    @ViewBuilder
    private func permissionStatusView(status: PermissionState) -> some View {
        switch status {
        case .unknown:
            HStack(spacing: 4) {
                Image(systemName: "circle")
            }
            .foregroundColor(.gray)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(8)
        case .denied:
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.circle")
            }
            .foregroundColor(.orange)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.orange.opacity(0.15))
            .cornerRadius(8)
        case .granted:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
        }
    }
    
    private func footerText(for status: PermissionState) -> Text {
        switch status {
        case .unknown:
            return Text("L'accès à Santé n'a pas encore été demandé.")
        case .denied:
            return Text("L'accès à Santé a été refusé. Vous pouvez l'activer dans les Réglages de votre appareil.")
        case .granted:
            return Text("L'accès à Santé est autorisé. ✓")
        }
    }
    
    private func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

#Preview {
    NavigationStack {
        HealthPermissionView(manager: PermissionChecklistManager())
    }
}
