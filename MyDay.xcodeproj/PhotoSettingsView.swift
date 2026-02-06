//
//  PhotoSettingsView.swift
//  MyDay
//

import SwiftUI
import Photos

struct PhotoPermissionView: View {
    @ObservedObject var manager: PermissionChecklistManager
    @EnvironmentObject var photoManager: PhotoManager
    @AppStorage(UserDefaultsKeys.albumName, store: AppGroup.userDefaults)
    private var albumName: String = ""
    
    @State private var showingAlbumNameAlert = false
    @State private var newAlbumName = ""
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Photos")
                            .font(.headline)
                        Text("Voir vos souvenirs")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    permissionStatusView(status: manager.photoStatus)
                }
                .padding(.vertical, 8)
            } header: {
                Text("Statut")
            } footer: {
                footerText(for: manager.photoStatus)
            }
            
            if manager.photoStatus != .granted {
                Section {
                    Button {
                        if manager.photoStatus == .unknown {
                            manager.requestPhotos()
                        } else {
                            openSettings()
                        }
                    } label: {
                        HStack {
                            Image(systemName: manager.photoStatus == .unknown ? "lock.open" : "gear")
                            Text(manager.photoStatus == .unknown ? "Autoriser l'accès" : "Ouvrir les Réglages")
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            
            Section {
                HStack {
                    Text("Album actuel")
                    Spacer()
                    Text(albumName.isEmpty ? "Non configuré" : albumName)
                        .foregroundColor(.secondary)
                }
                
                Button {
                    newAlbumName = albumName
                    showingAlbumNameAlert = true
                } label: {
                    Label("Changer d'album", systemImage: "photo.on.rectangle.angled")
                }
            } header: {
                Text("Configuration")
            } footer: {
                Text("Sélectionnez l'album contenant vos photos du jour.")
            }
        }
        .navigationTitle("Photos")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            manager.updateStatuses()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                manager.updateStatuses()
            }
        }
        .alert("Nom de l'album", isPresented: $showingAlbumNameAlert) {
            TextField("Nom de l'album", text: $newAlbumName)
            Button("Annuler", role: .cancel) { }
            Button("OK") {
                albumName = newAlbumName
            }
        } message: {
            Text("Entrez le nom de l'album contenant vos photos.")
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
            return Text("L'accès aux photos n'a pas encore été demandé.")
        case .denied:
            return Text("L'accès aux photos a été refusé. Vous pouvez l'activer dans les Réglages de votre appareil.")
        case .granted:
            return Text("L'accès aux photos est autorisé. ✓")
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
        PhotoPermissionView(manager: PermissionChecklistManager())
            .environmentObject(PhotoManager())
    }
}
