//
//  SettingsView.swift
//  MyDay
//
//  Created by Assistant on 2025-01-15.
//

import SwiftUI
import Photos
import HealthKit
import os.log

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var permissionManager = PermissionChecklistManager()
    @ObservedObject private var horoscopeService = HoroscopeService.shared
    @ObservedObject private var quoteService = QuoteService.shared
    @EnvironmentObject var customLinkManager: CustomLinkManager
    @EnvironmentObject var userSettings: UserSettings // ✅ Accès aux paramètres utilisateur
    @EnvironmentObject var photoManager: PhotoManager // ✅ Pour charger les albums à l'activation
    
    #if DEBUG
    @AppStorage("VerboseLogging", store: AppGroup.userDefaults) private var verboseLogging: Bool = false
    @AppStorage("VerboseEventKitLogging", store: AppGroup.userDefaults) private var verboseEventKitLogging: Bool = false
    #endif
    
    var calendarSelectionManager: CalendarSelectionManager
    var reminderSelectionManager: ReminderSelectionManager
    
    @State private var showPhotoPermissionExplanation = false
    @State private var showHealthPermissionExplanation = false
    @State private var pendingPhotoActivation = false
    @State private var pendingHealthActivation = false
    
    var body: some View {
        List {
            Section {
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
                
                NavigationLink(destination:
                    CustomLinksView()
                        .environmentObject(customLinkManager)
                        .environmentObject(userSettings) // ✅ Injecter userSettings pour la préférence iCloud
                        .onAppear {
                            #if DEBUG
                            Logger.app.debug("SettingsView → CustomLinksView appeared - links=\(customLinkManager.customLinks.count)")
                            #endif
                        }
                ) {
                    HStack {
                        Image(systemName: "link.circle.fill")
                            .foregroundColor(.purple)
                            .frame(width: 30)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Liens personnalisés")
                            HStack(spacing: 8) {
                                Text("\(customLinkManager.customLinks.filter(\.isEnabled).count) actif(s)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                // ✅ Badge iCloud si activé
                                if userSettings.preferences.syncCustomLinksWithICloud {
                                    Image(systemName: "icloud.fill")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                NavigationLink(destination: PhotoPermissionView(manager: permissionManager)) {
                    HStack(spacing: 12) {
                        Image(systemName: "photo")
                            .foregroundColor(.accentColor)
                            .frame(width: 30)
                        Text("Photos")
                        Spacer()
                        permissionBadge(status: permissionManager.photoStatus)
                    }
                }
                
                NavigationLink(destination: HealthPermissionView(manager: permissionManager)) {
                    HStack(spacing: 12) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.accentColor)
                            .frame(width: 30)
                        Text("Santé")
                        Spacer()
                        permissionBadge(status: permissionManager.healthStatus)
                    }
                }
            } header: {
                Text("Sources de données")
            }
            
            Section {
                // ✅ Option pour afficher/masquer les photos
                Toggle(isOn: Binding(
                    get: { userSettings.preferences.showPhotos },
                    set: { newValue in
                        if newValue {
                            let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
                            if status == .notDetermined {
                                // Montrer l'explication avant de demander
                                showPhotoPermissionExplanation = true
                            } else if status == .authorized || status == .limited {
                                // Permission déjà accordée → activer et charger directement
                                userSettings.setShowPhotos(true)
                                Task {
                                    await photoManager.loadAlbums()
                                    let album = photoManager.albumName.isEmpty ? "Library" : photoManager.albumName
                                    await photoManager.loadAssetsAndShowRandomPhoto(fromAlbum: album)
                                }
                            } else {
                                // Refusée → ouvrir les Réglages système, ne pas activer
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                        } else {
                            userSettings.setShowPhotos(false)
                        }
                    }
                )) {
                    HStack {
                        Image(systemName: "photo.fill")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        Text("Afficher les photos")
                    }
                }
                
                // ✅ Option pour afficher/masquer la section Santé
                Toggle(isOn: Binding(
                    get: { userSettings.preferences.showHealth },
                    set: { newValue in
                        if newValue {
                            if permissionManager.healthStatus == .granted {
                                // Permission déjà accordée → activer directement
                                userSettings.setShowHealth(true)
                            } else {
                                // Pas encore accordée ou inconnue → montrer explication
                                showHealthPermissionExplanation = true
                            }
                        } else {
                            userSettings.setShowHealth(false)
                        }
                    }
                )) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .frame(width: 30)
                        Text("Afficher la santé")
                    }
                }
                
                Toggle(isOn: $quoteService.isQuoteEnabled) {
                    HStack {
                        Image(systemName: "sparkle")
                            .foregroundColor(.yellow)
                            .frame(width: 30)
                        Text("Pensée du jour")
                    }
                }
                
                Toggle(isOn: $horoscopeService.isHoroscopeEnabled) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                            .frame(width: 30)
                        Text("Horoscope quotidien")
                    }
                }
                
                if horoscopeService.isHoroscopeEnabled {
                    HStack {
                        Image(systemName: "star.circle")
                            .foregroundColor(.purple)
                            .frame(width: 30)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Signe actuel")
                                .font(.subheadline)
                            Text("\(horoscopeService.selectedSign.emoji) \(horoscopeService.selectedSign.localizedName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    NavigationLink(destination: HoroscopeSettingsView(horoscopeService: horoscopeService)) {
                        HStack {
                            Image(systemName: "gear")
                                .foregroundColor(.purple)
                                .frame(width: 30)
                            Text("Configuration horoscope")
                        }
                    }
                }
            } header: {
                Text("Fonctionnalités")
            } footer: {
                if quoteService.isQuoteEnabled && horoscopeService.isHoroscopeEnabled {
                    Text("• La pensée du jour s'affiche en haut de votre vue principale.\n• L'horoscope quotidien s'affiche en bas de votre vue principale.")
                } else if quoteService.isQuoteEnabled {
                    Text("La pensée du jour s'affiche en haut de votre vue principale.")
                } else if horoscopeService.isHoroscopeEnabled {
                    Text("L'horoscope quotidien s'affiche en bas de votre vue principale.")
                } else {
                    Text("Activez ces options pour personnaliser votre expérience quotidienne.")
                }
            }
            
            Section {
                NavigationLink(destination: SharedItemsInfoView()) {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        Text("Icône de partage")
                    }
                }
            } header: {
                Text("Informations")
            } footer: {
                Text("L'icône 👥 apparaît à côté des rappels et événements partagés.")
            }
            
            #if DEBUG
            Section {
                Toggle(isOn: $verboseLogging) {
                    HStack {
                        Image(systemName: "ladybug.fill")
                            .foregroundColor(.red)
                            .frame(width: 30)
                        Text("Logs verbeux Photos")
                    }
                }
                
                Toggle(isOn: $verboseEventKitLogging) {
                    HStack {
                        Image(systemName: "calendar.badge.checkmark")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        Text("Logs verbeux Calendriers/Rappels")
                    }
                }
            } header: {
                Text("Debug")
            } footer: {
                Text("Active les logs détaillés pour la galerie photos et EventKit (calendriers, rappels).")
            }
            #endif
        }
        .navigationTitle("Réglages")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Terminé") {
                    dismiss()
                }
            }
        }
        .onAppear {
            permissionManager.updateStatuses()
            #if DEBUG
            Logger.app.debug("SettingsView.onAppear - customLinks=\(customLinkManager.customLinks.count)")
            #endif
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                // Rafraîchir immédiatement
                permissionManager.updateStatuses()
                // Forcer une mise à jour spécifique pour la santé après un délai
                // (pour laisser le temps à iOS de mettre à jour les permissions)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    permissionManager.forceHealthStatusRefresh()
                }
            }
        }
        // Alerte d'explication avant la demande de permission Photos
        .alert("Accès aux photos", isPresented: $showPhotoPermissionExplanation) {
            Button("D'accord") {
                pendingPhotoActivation = true
                permissionManager.requestPhotos()
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Pour afficher vos photos sur l'écran principal, MyDay a besoin de l'autorisation d'accéder à votre bibliothèque de photos. Aucune photo ne sera modifiée ou supprimée.")
        }
        // Alerte d'explication avant la demande de permission Santé
        .alert("Accès aux données Santé", isPresented: $showHealthPermissionExplanation) {
            Button("D'accord") {
                pendingHealthActivation = true
                permissionManager.requestHealth()
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Pour afficher les pas, la distance parcourue pendant la journée et les calories dépensées, MyDay a besoin de l'autorisation d'accéder aux données Santé. Aucune mise à jour des données de Santé ne sera effectuée.")
        }
        // Activation de la fonctionnalité une fois la permission accordée
        .onChange(of: permissionManager.photoStatus) { _, newStatus in
            guard pendingPhotoActivation else { return }
            pendingPhotoActivation = false
            if newStatus == .granted {
                userSettings.setShowPhotos(true)
                Task {
                    await photoManager.loadAlbums()
                    let album = photoManager.albumName.isEmpty ? "Library" : photoManager.albumName
                    await photoManager.loadAssetsAndShowRandomPhoto(fromAlbum: album)
                }
            }
        }
        .onChange(of: permissionManager.healthStatus) { _, newStatus in
            guard pendingHealthActivation else { return }
            switch newStatus {
            case .granted:
                pendingHealthActivation = false
                userSettings.setShowHealth(true)
            case .denied:
                pendingHealthActivation = false
                // Permission refusée → ouvrir les Réglages système
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            case .unknown:
                // Ne pas réinitialiser — attendre que le retry donne une réponse définitive
                break
            }
        }
    }
    
    @ViewBuilder
    private func permissionBadge(status: PermissionState) -> some View {
        switch status {
        case .granted:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
        case .denied:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.orange)
                .font(.title3)
        case .unknown:
            Image(systemName: "circle")
                .foregroundColor(.gray)
                .font(.title3)
        }
    }
}

// MARK: - Shared Items Info View

struct SharedItemsInfoView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                        Text("Icône de partage")
                            .font(.headline)
                    }
                    
                    Text("L'icône 👥 apparaît automatiquement à côté des événements et rappels provenant de calendriers ou listes partagés.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pour qu'un calendrier ou une liste soit reconnu comme partagé, son nom doit contenir l'un des mots-clés suivants :")
                        .font(.body)
                        .padding(.bottom, 4)
                    
                    Text("🇫🇷 Français")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    keywordsList([
                        "Partagé", "Partage",
                        "Famille", "Familial",
                        "Équipe",
                        "Couple",
                        "Travail", "Bureau",
                        "Groupe",
                        "Collectif",
                        "Commun"
                    ])
                    
                    Text("🇬🇧 Anglais")
                        .font(.headline)
                        .padding(.top, 16)
                    
                    keywordsList([
                        "Shared", "Share",
                        "Family",
                        "Team",
                        "Work", "Office",
                        "Group",
                        "Collective",
                        "Common",
                        "Together"
                    ])
                }
                .padding(.vertical, 8)
            } header: {
                Text("Mots-clés de détection")
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text("Exemples")
                            .font(.headline)
                    }
                    
                    exampleRow(listName: "Famille", icon: "👥", showsIcon: true)
                    exampleRow(listName: "Courses Partagées", icon: "👥", showsIcon: true)
                    exampleRow(listName: "Team Tasks", icon: "👥", showsIcon: true)
                    exampleRow(listName: "Bureau - Projets", icon: "👥", showsIcon: true)
                    exampleRow(listName: "Mes tâches", icon: "👥", showsIcon: false)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Icône de partage")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func keywordsList(_ keywords: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(keywords, id: \.self) { keyword in
                HStack {
                    Text("•")
                        .foregroundColor(.accentColor)
                    Text(keyword)
                        .font(.body)
                }
            }
        }
        .padding(.leading, 8)
    }
    
    private func exampleRow(listName: String, icon: String, showsIcon: Bool) -> some View {
        HStack {
            Text("\"\(listName)\"")
                .font(.body)
            Spacer()
            if showsIcon {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text("Affiche l'icône")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("Pas d'icône")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Photo Permission View

struct PhotoPermissionView: View {
    @ObservedObject var manager: PermissionChecklistManager
    @EnvironmentObject var photoManager: PhotoManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedAlbum: String = ""
    
    var body: some View {
        List {
            Section {
                permissionRow(
                    status: manager.photoStatus,
                    label: "Photos",
                    icon: "photo",
                    description: "Voir vos souvenirs",
                    action: { manager.requestPhotos() }
                )
            }
            
            // Section sélecteur d'album (visible seulement si accès accordé)
            if manager.photoStatus == .granted {
                Section {
                    NavigationLink {
                        AlbumSelectionView(
                            albums: photoManager.albumNames,
                            currentAlbum: selectedAlbum,
                            onSelect: { album in
                                Logger.photo.info("🎯 Album sélectionné: \(album)")
                                selectedAlbum = album
                                Task {
                                    await photoManager.changeAlbum(to: album)
                                }
                            }
                        )
                    } label: {
                        HStack {
                            Text("Album")
                                .foregroundColor(.primary)
                            Spacer()
                            if photoManager.albumNames.isEmpty {
                                Text("Chargement...")
                                    .foregroundColor(.secondary)
                            } else {
                                Text(selectedAlbum.isEmpty ? "Aucun" : selectedAlbum)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .disabled(photoManager.albumNames.isEmpty)
                } header: {
                    Text("Album à afficher")
                }
                
                Section {
                    // Aperçu de la photo
                    if let photo = photoManager.currentImage {
                        VStack(spacing: 12) {
                            Image(uiImage: photo)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    } else {
                        VStack {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("Aucune photo")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 200)
                    }
                    
                    // Boutons de navigation photo
                    HStack(spacing: 20) {
                        Button {
                            photoManager.showPreviousImage()
                        } label: {
                            Label("Précédent", systemImage: "chevron.left.circle.fill")
                                .labelStyle(.iconOnly)
                                .font(.title2)
                        }
                        .disabled(photoManager.currentAssets.isEmpty)
                        
                        Spacer()
                        
                        Text("\(photoManager.currentAssets.indices.contains(photoManager.currentIndex) ? photoManager.currentIndex + 1 : 0) / \(photoManager.currentAssets.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button {
                            photoManager.showNextImage()
                        } label: {
                            Label("Suivant", systemImage: "chevron.right.circle.fill")
                                .labelStyle(.iconOnly)
                                .font(.title2)
                        }
                        .disabled(photoManager.currentAssets.isEmpty)
                    }
                } header: {
                    Text("Aperçu")
                }
            }
        }
        .navigationTitle("Photos")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            manager.updateStatuses()
            
            // Initialiser selectedAlbum avec la valeur actuelle
            selectedAlbum = photoManager.albumName
            
            // Charger les albums si nécessaire
            if photoManager.albumNames.isEmpty {
                Task {
                    await photoManager.loadAlbums()
                    // Synchroniser après le chargement
                    selectedAlbum = photoManager.albumName
                }
            }
        }
        .onChange(of: photoManager.albumName) { oldValue, newValue in
            // Synchroniser selectedAlbum si albumName change de l'extérieur
            if newValue != selectedAlbum && !newValue.isEmpty {
                selectedAlbum = newValue
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                manager.updateStatuses()
            }
        }
    }
    
    private func permissionRow(
        status: PermissionState,
        label: String,
        icon: String,
        description: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            if status == .unknown {
                action()
            } else if status == .denied {
                openSettings()
            }
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
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
                        Image(systemName: "gear")
                        Text("Réglages")
                            .font(.caption.bold())
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
            .padding()
        }
        .disabled(status == .granted)
        .buttonStyle(.plain)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

// MARK: - Health Permission View

struct HealthPermissionView: View {
    @ObservedObject var manager: PermissionChecklistManager
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    permissionRow(
                        status: manager.healthStatus,
                        label: "Santé",
                        icon: "heart.fill",
                        description: "Statistiques d'activité physique",
                        action: { manager.requestHealth() }
                    )
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    // Section données disponibles
                    VStack(spacing: 12) {
                        HStack {
                            Text("Données disponibles")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            healthDataRow(icon: "figure.walk", label: "Nombre de pas")
                            Divider().padding(.leading, 60)
                            healthDataRow(icon: "flame.fill", label: "Calories actives")
                            Divider().padding(.leading, 60)
                            healthDataRow(icon: "map", label: "Distance parcourue")
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                        
                        Text("Ces statistiques seront affichées dans votre vue quotidienne.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
        }
        .navigationTitle("Santé")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            manager.updateStatuses()
            // Force un rafraîchissement immédiat de la santé
            manager.forceHealthStatusRefresh()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                manager.updateStatuses()
                // Double vérification pour la santé après retour des Réglages
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    manager.forceHealthStatusRefresh()
                }
            }
        }
    }
    
    private func permissionRow(
        status: PermissionState,
        label: String,
        icon: String,
        description: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            if status == .unknown {
                action()
            } else if status == .denied {
                openHealthSettings()
            }
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
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
                        Image(systemName: "gear")
                        Text("Réglages")
                            .font(.caption.bold())
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
            .padding()
        }
        .disabled(status == .granted)
        .buttonStyle(.plain)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func healthDataRow(icon: String, label: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 30)
            Text(label)
                .font(.body)
            Spacer()
        }
        .padding()
    }
    
    private func openHealthSettings() {
        // Toujours ouvrir l'app Santé sur la page Sources de données
        // où l'utilisateur peut gérer les permissions de MyDay
        message: do {
            Text("Pour activer les permissions de santé:\n\n1. Ouvrez l'app Santé\n2. Allez dans Partage\n3. Sélectionnez Apps\n4. Trouvez et ouvrez MyDay\n5. Activez les données souhaitées")
        }
        if let healthURL = URL(string: "x-apple-health://SharingUI/List:com.josblais.MyDay") {
            UIApplication.shared.open(healthURL)
        }
    }
}

// MARK: - Album Selection View

struct AlbumSelectionView: View {
    let albums: [String]
    let currentAlbum: String
    let onSelect: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            ForEach(albums, id: \.self) { album in
                Button {
                    onSelect(album)
                    dismiss()
                } label: {
                    HStack {
                        Text(album)
                            .foregroundColor(.primary)
                        Spacer()
                        if album == currentAlbum {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
        }
        .navigationTitle("Choisir un album")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Horoscope Settings View

struct HoroscopeSettingsView: View {
    @ObservedObject var horoscopeService: HoroscopeService
    @State private var showSignPicker = false
    @State private var showProviderPicker = false
    
    private var localizedTitle: String {
        let lang = Locale.preferredLanguages.first ?? "en"
        return lang.hasPrefix("fr") ? "Configuration horoscope" : "Horoscope Settings"
    }
    
    private var signSectionHeader: String {
        let lang = Locale.preferredLanguages.first ?? "en"
        return lang.hasPrefix("fr") ? "Signe astrologique" : "Zodiac Sign"
    }
    
    private var providerSectionHeader: String {
        let lang = Locale.preferredLanguages.first ?? "en"
        return lang.hasPrefix("fr") ? "Source des données" : "Data Source"
    }
    
    private var changeButtonLabel: String {
        let lang = Locale.preferredLanguages.first ?? "en"
        return lang.hasPrefix("fr") ? "Modifier" : "Change"
    }
    
    var body: some View {
        List {
            Section {
                HStack {
                    Text(horoscopeService.selectedSign.emoji)
                        .font(.largeTitle)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(horoscopeService.selectedSign.localizedName)
                            .font(.headline)
                        Text(horoscopeService.selectedSign.symbol)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(changeButtonLabel) {
                        showSignPicker = true
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical, 8)
            } header: {
                Text(signSectionHeader)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(horoscopeService.selectedProvider.displayName)
                        .font(.headline)
                    Text(horoscopeService.selectedProvider.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(changeButtonLabel) {
                        showProviderPicker = true
                    }
                    .buttonStyle(.bordered)
                    .padding(.top, 4)
                }
                .padding(.vertical, 8)
            } header: {
                Text(providerSectionHeader)
            }
        }
        .navigationTitle(localizedTitle)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSignPicker) {
            ZodiacSignPickerView(selectedSign: horoscopeService.selectedSign) { newSign in
                horoscopeService.selectedSign = newSign
                showSignPicker = false
            }
        }
        .sheet(isPresented: $showProviderPicker) {
            ProviderPickerView(selectedProvider: horoscopeService.selectedProvider) { newProvider in
                horoscopeService.selectedProvider = newProvider
                showProviderPicker = false
            }
        }
    }
}

// MARK: - Preview

#Preview("Settings") {
    NavigationStack {
        SettingsView(
            calendarSelectionManager: CalendarSelectionManager(),
            reminderSelectionManager: ReminderSelectionManager()
        )
    }
}
#Preview("Shared Items Info") {
    NavigationStack {
        SharedItemsInfoView()
    }
}
#Preview("Album Selection") {
    NavigationStack {
        AlbumSelectionView(
            albums: ["Favoris", "Famille", "Vacances", "Travail"],
            currentAlbum: "Famille",
            onSelect: { album in
                print("Album sélectionné: \(album)")
            }
        )
    }
}

