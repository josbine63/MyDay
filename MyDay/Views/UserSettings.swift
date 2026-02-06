//
//  UserSettings.swift
//  MyDay
//
//  Created by Assistant on 2025-01-15.
//

import Foundation
import SwiftUI
import os.log

// MARK: - Notification Names

extension Notification.Name {
    /// Notification envoyée quand la préférence de sync iCloud change
    static let customLinksSyncPreferenceChanged = Notification.Name("customLinksSyncPreferenceChanged")
}

/// Préférences utilisateur de l'application
struct UserPreferences: Codable {
    var language: String
    var usesMetric: Bool
    var showPhotos: Bool // ✅ Option pour afficher/masquer les photos
    var showHealth: Bool // ✅ Option pour afficher/masquer la section Santé
    var syncCustomLinksWithICloud: Bool // ✅ Synchronisation iCloud des liens personnalisés
    
    static let `default` = UserPreferences(
        language: Locale.current.language.languageCode?.identifier ?? "en",
        usesMetric: Locale.current.measurementSystem == .metric,
        showPhotos: false, // Par défaut désactivé jusqu'à activation manuelle
        showHealth: false, // Par défaut désactivé jusqu'à activation manuelle
        syncCustomLinksWithICloud: true // Par défaut, sync iCloud activée
    )
}

/// Gestionnaire des paramètres utilisateur
@MainActor
final class UserSettings: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var preferences: UserPreferences {
        didSet {
            savePreferencesDebounced()
        }
    }
    
    // MARK: - Private Properties
    
    private let defaults = UserDefaults.appGroup
    private let preferencesKey = "userPreferences"
    
    // 🚀 OPTIMISATION: Debounce pour éviter trop de sauvegardes
    private var saveTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init() {
        if let data = defaults.data(forKey: preferencesKey),
           let decoded = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            self.preferences = decoded
            Logger.app.debug("📱 Préférences chargées: langue=\(decoded.language), métrique=\(decoded.usesMetric)")
        } else {
            self.preferences = UserPreferences.default
            Logger.app.debug("📱 Préférences par défaut créées")
            savePreferences()
        }
    }
    
    // MARK: - Public Methods
    
    /// Change la langue de l'application
    func setLanguage(_ languageCode: String) {
        preferences.language = languageCode
        Logger.app.info("🌍 Langue changée: \(languageCode)")
    }
    
    /// Change le système d'unités (métrique/impérial)
    func setUsesMetric(_ usesMetric: Bool) {
        preferences.usesMetric = usesMetric
        Logger.app.info("📏 Unités changées: \(usesMetric ? "métrique" : "impérial")")
    }
    
    /// Active ou désactive l'affichage des photos
    func setShowPhotos(_ showPhotos: Bool) {
        preferences.showPhotos = showPhotos
        Logger.app.info("📸 Affichage des photos: \(showPhotos ? "activé" : "désactivé")")
    }
    
    /// Active ou désactive l'affichage de la section Santé
    func setShowHealth(_ showHealth: Bool) {
        preferences.showHealth = showHealth
        Logger.app.info("❤️ Affichage Santé: \(showHealth ? "activé" : "désactivé")")
    }
    
    /// Active ou désactive la synchronisation iCloud des liens personnalisés
    func setSyncCustomLinksWithICloud(_ syncEnabled: Bool) {
        preferences.syncCustomLinksWithICloud = syncEnabled
        Logger.app.info("☁️ Sync iCloud des liens: \(syncEnabled ? "activée" : "désactivée")")
        
        // ✅ Notifier le changement pour que CustomLinkManager réagisse
        NotificationCenter.default.post(
            name: .customLinksSyncPreferenceChanged,
            object: nil,
            userInfo: ["syncEnabled": syncEnabled]
        )
    }
    
    /// Réinitialise les préférences aux valeurs par défaut
    func resetToDefaults() {
        preferences = UserPreferences.default
        Logger.app.info("🔄 Préférences réinitialisées")
    }
    
    // MARK: - Private Methods
    
    /// 🚀 OPTIMISATION: Sauvegarde avec debounce pour éviter trop d'écritures disque
    private func savePreferencesDebounced() {
        saveTask?.cancel()
        saveTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
            guard !Task.isCancelled else { return }
            self?.savePreferences()
        }
    }
    
    private func savePreferences() {
        if let encoded = try? JSONEncoder().encode(preferences) {
            defaults.set(encoded, forKey: preferencesKey)
            Logger.app.debug("💾 Préférences sauvegardées")
        } else {
            Logger.app.error("❌ Erreur lors de la sauvegarde des préférences")
        }
    }
}
