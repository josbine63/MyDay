//
//  CustomLinkManager.swift
//  MyDay
//
//  Created by Assistant on 2025-01-30.
//

import Foundation
import SwiftUI
import os.log

// MARK: - Custom Link Model

struct CustomLink: Codable, Identifiable {
    let id: UUID
    var keyword: String
    var shortcutName: String
    var matchType: MatchType
    var isEnabled: Bool
    
    enum MatchType: String, Codable, CaseIterable {
        case exact = "exact"           // Titre doit être exactement "Gratitude"
        case contains = "contains"     // Titre contient "gratitude" (insensible à la casse)
        case startsWith = "startsWith" // Titre commence par "Gratitude"
        
        var localizedName: String {
            switch self {
            case .exact:
                return String(localized: "Titre exact")
            case .contains:
                return String(localized: "Contient le mot")
            case .startsWith:
                return String(localized: "Commence par")
            }
        }
    }
    
    init(id: UUID = UUID(), keyword: String, shortcutName: String, matchType: MatchType = .contains, isEnabled: Bool = true) {
        self.id = id
        self.keyword = keyword
        self.shortcutName = shortcutName
        self.matchType = matchType
        self.isEnabled = isEnabled
    }
    
    /// Vérifie si ce lien correspond au titre donné
    func matches(title: String) -> Bool {
        guard isEnabled else { return false }
        
        let titleLower = title.lowercased()
        let keywordLower = keyword.lowercased()
        
        switch matchType {
        case .exact:
            return titleLower == keywordLower
        case .contains:
            return titleLower.contains(keywordLower)
        case .startsWith:
            return titleLower.hasPrefix(keywordLower)
        }
    }
}

// MARK: - Custom Link Manager

final class CustomLinkManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var customLinks: [CustomLink] = [] {
        didSet {
            saveLinksDebounced()
        }
    }
    
    // MARK: - Private Properties
    
    private let defaults = UserDefaults.appGroup
    private let iCloudStore = NSUbiquitousKeyValueStore.default
    private let linksKey = "customLinks"
    private let useICloudSync: Bool
    
    // 🚀 OPTIMISATION: Debounce pour éviter trop de sauvegardes
    private var saveTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init(useICloudSync: Bool = true) {
        // ✅ Lire la préférence depuis UserDefaults au démarrage
        let prefs = UserDefaults.appGroup
        if let data = prefs.data(forKey: "userPreferences"),
           let decoded = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            self.useICloudSync = decoded.syncCustomLinksWithICloud
        } else {
            self.useICloudSync = useICloudSync
        }
        
        // Observer les changements iCloud
        if self.useICloudSync {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleICloudChange),
                name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                object: iCloudStore
            )
        }
        
        // ✅ Observer les changements de préférence
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSyncPreferenceChange),
            name: .customLinksSyncPreferenceChanged,
            object: nil
        )
        
        loadLinks()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - iCloud Sync
    
    @objc private func handleSyncPreferenceChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let syncEnabled = userInfo["syncEnabled"] as? Bool else {
            return
        }
        
        Logger.app.info("⚙️ Changement de préférence sync détecté: \(syncEnabled)")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if syncEnabled {
                // Activer iCloud : migrer les données locales vers iCloud
                Logger.app.info("☁️ Activation de la sync iCloud - Migration des données...")
                self.saveLinksToICloud(self.customLinks)
                
                // Commencer à observer iCloud
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(self.handleICloudChange),
                    name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                    object: self.iCloudStore
                )
            } else {
                // Désactiver iCloud : garder les données locales
                Logger.app.info("📦 Désactivation de la sync iCloud - Utilisation locale uniquement")
                
                // Arrêter d'observer iCloud
                NotificationCenter.default.removeObserver(
                    self,
                    name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                    object: self.iCloudStore
                )
            }
        }
    }
    
    @objc private func handleICloudChange(_ notification: Notification) {
        Logger.app.info("☁️ Changement iCloud détecté pour les liens personnalisés")
        
        // Récupérer les changements depuis iCloud
        guard let userInfo = notification.userInfo,
              let reason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int else {
            return
        }
        
        // Ne synchroniser que si les données ont changé sur un autre appareil
        if reason == NSUbiquitousKeyValueStoreServerChange || 
           reason == NSUbiquitousKeyValueStoreInitialSyncChange {
            
            DispatchQueue.main.async { [weak self] in
                self?.loadLinksFromICloud()
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Trouve le premier lien qui correspond au titre de l'agenda item
    func findLink(for title: String) -> CustomLink? {
        // Retourne le premier lien actif qui matche
        return self.customLinks.first { $0.matches(title: title) }
    }
    
    /// Vérifie si un item a un lien personnalisé
    func hasLink(for title: String) -> Bool {
        return findLink(for: title) != nil
    }
    
    /// Ouvre le raccourci associé à un titre
    @MainActor
    func openShortcut(for title: String) -> Bool {
        guard let link = findLink(for: title) else {
            Logger.app.debug("🔗 Aucun lien personnalisé trouvé pour '\(title)'")
            return false
        }
        
        // ✨ NOUVEAU : Extraire les paramètres après ":"
        let parameter = extractParameter(from: title)
        
        return openShortcut(named: link.shortcutName, withParameter: parameter)
    }
    
    /// Ouvre un raccourci par son nom
    @MainActor
    func openShortcut(named shortcutName: String) -> Bool {
        return openShortcut(named: shortcutName, withParameter: nil)
    }
    
    /// Ouvre un raccourci par son nom avec un paramètre optionnel
    @MainActor
    func openShortcut(named shortcutName: String, withParameter parameter: String?) -> Bool {
        // Encoder le nom du raccourci pour l'URL
        guard let encodedName = shortcutName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            Logger.app.error("❌ Impossible d'encoder le nom du raccourci '\(shortcutName)'")
            return false
        }
        
        // Construire l'URL avec ou sans paramètre
        var urlString = "shortcuts://run-shortcut?name=\(encodedName)"
        
        // ✨ NOUVEAU : Ajouter le paramètre s'il existe
        if let parameter = parameter, !parameter.isEmpty {
            guard let encodedParameter = parameter.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                Logger.app.error("❌ Impossible d'encoder le paramètre '\(parameter)'")
                return false
            }
            urlString += "&input=text&text=\(encodedParameter)"
            Logger.app.info("📝 Paramètre détecté: '\(parameter)'")
        }
        
        guard let url = URL(string: urlString) else {
            Logger.app.error("❌ Impossible de créer l'URL pour le raccourci '\(shortcutName)'")
            return false
        }
        
        // Vérifier si Shortcuts est disponible
        guard UIApplication.shared.canOpenURL(url) else {
            Logger.app.error("❌ L'app Raccourcis n'est pas disponible")
            return false
        }
        
        if let parameter = parameter {
            Logger.app.info("🚀 Ouverture du raccourci '\(shortcutName)' avec paramètre '\(parameter)'")
        } else {
            Logger.app.info("🚀 Ouverture du raccourci '\(shortcutName)'")
        }
        
        UIApplication.shared.open(url)
        return true
    }
    
    // MARK: - Parameter Extraction
    
    /// Extrait le paramètre après ":" dans un titre
    /// Exemple: "Appeler: Louisette Bouchard" → "Louisette Bouchard"
    private func extractParameter(from title: String) -> String? {
        // Chercher le séparateur ":"
        guard let colonIndex = title.firstIndex(of: ":") else {
            return nil
        }
        
        // Extraire tout ce qui est après le ":"
        let parameterStartIndex = title.index(after: colonIndex)
        let parameter = String(title[parameterStartIndex...])
        
        // Nettoyer les espaces au début et à la fin
        let cleanedParameter = parameter.trimmingCharacters(in: .whitespaces)
        
        // Retourner nil si le paramètre est vide après nettoyage
        return cleanedParameter.isEmpty ? nil : cleanedParameter
    }
    
    /// Ajoute un nouveau lien
    func addLink(_ link: CustomLink) {
        self.customLinks.append(link)
        Logger.app.info("➕ Lien ajouté: '\(link.keyword)' → '\(link.shortcutName)'")
    }
    
    /// Met à jour un lien existant
    func updateLink(_ link: CustomLink) {
        if let index = self.customLinks.firstIndex(where: { $0.id == link.id }) {
            self.customLinks[index] = link
            Logger.app.info("✏️ Lien mis à jour: '\(link.keyword)' → '\(link.shortcutName)'")
        }
    }
    
    /// Supprime un lien
    func deleteLink(_ link: CustomLink) {
        self.customLinks.removeAll { $0.id == link.id }
        Logger.app.info("🗑️ Lien supprimé: '\(link.keyword)'")
    }
    
    /// Supprime des liens par leurs IDs
    func deleteLinks(at offsets: IndexSet) {
        self.customLinks.remove(atOffsets: offsets)
    }
    
    /// Déplace des liens
    func moveLinks(from source: IndexSet, to destination: Int) {
        self.customLinks.move(fromOffsets: source, toOffset: destination)
    }
    
    /// Active/désactive un lien
    func toggleLink(_ link: CustomLink) {
        if let index = self.customLinks.firstIndex(where: { $0.id == link.id }) {
            self.customLinks[index].isEnabled.toggle()
            Logger.app.info("🔄 Lien \(self.customLinks[index].isEnabled ? "activé" : "désactivé"): '\(link.keyword)'")
        }
    }
    
    /// Réinitialise tous les liens
    func reset() {
        self.customLinks = []
        Logger.app.info("🔄 Tous les liens supprimés")
    }
    
    // MARK: - Private Methods
    
    /// 🚀 OPTIMISATION: Sauvegarde avec debounce pour éviter trop d'écritures disque/iCloud
    private func saveLinksDebounced() {
        saveTask?.cancel()
        saveTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
            guard !Task.isCancelled else { return }
            self?.saveLinks()
        }
    }
    
    private func loadLinks() {
        // Priorité 1 : iCloud (si activé et disponible)
        if useICloudSync {
            loadLinksFromICloud()
        } else {
            // Priorité 2 : UserDefaults local
            loadLinksFromUserDefaults()
        }
    }
    
    private func loadLinksFromICloud() {
        if let data = iCloudStore.data(forKey: linksKey),
           let decoded = try? JSONDecoder().decode([CustomLink].self, from: data) {
            self.customLinks = decoded
            Logger.app.debug("☁️ \(decoded.count) lien(s) chargé(s) depuis iCloud")
            
            // Sauvegarder aussi en local comme backup
            saveLinksToUserDefaults(decoded)
        } else {
            // Fallback : essayer de charger depuis UserDefaults
            Logger.app.debug("☁️ Aucune donnée iCloud, tentative UserDefaults...")
            loadLinksFromUserDefaults()
        }
    }
    
    private func loadLinksFromUserDefaults() {
        if let data = defaults.data(forKey: linksKey),
           let decoded = try? JSONDecoder().decode([CustomLink].self, from: data) {
            self.customLinks = decoded
            Logger.app.debug("📦 \(decoded.count) lien(s) chargé(s) depuis UserDefaults")
            
            // Si iCloud est activé, synchroniser vers iCloud
            if useICloudSync {
                saveLinksToICloud(decoded)
            }
        } else {
            self.customLinks = []
            Logger.app.debug("📦 Aucun lien personnalisé existant")
        }
    }
    
    private func saveLinks() {
        if useICloudSync {
            // Sauvegarder dans iCloud ET localement
            saveLinksToICloud(self.customLinks)
            saveLinksToUserDefaults(self.customLinks)
        } else {
            // Sauvegarder uniquement localement
            saveLinksToUserDefaults(self.customLinks)
        }
    }
    
    private func saveLinksToICloud(_ links: [CustomLink]) {
        if let encoded = try? JSONEncoder().encode(links) {
            iCloudStore.set(encoded, forKey: linksKey)
            iCloudStore.synchronize() // Force la sync immédiate
            Logger.app.debug("☁️ \(links.count) lien(s) sauvegardé(s) dans iCloud")
        } else {
            Logger.app.error("❌ Erreur lors de l'encodage pour iCloud")
        }
    }
    
    private func saveLinksToUserDefaults(_ links: [CustomLink]) {
        if let encoded = try? JSONEncoder().encode(links) {
            defaults.set(encoded, forKey: linksKey)
            Logger.app.debug("💾 \(links.count) lien(s) sauvegardé(s) en local")
        } else {
            Logger.app.error("❌ Erreur lors de la sauvegarde locale")
        }
    }
}

// MARK: - Preview Helper

extension CustomLinkManager {
    /// Crée un manager avec des données de test
    static var preview: CustomLinkManager {
        let manager = CustomLinkManager()
        manager.customLinks = [
            CustomLink(keyword: "Gratitude", shortcutName: "Journal Gratitude", matchType: .contains),
            CustomLink(keyword: "Épicerie", shortcutName: "Liste Courses", matchType: .contains),
            CustomLink(keyword: "Méditation", shortcutName: "Méditation Guidée", matchType: .startsWith),
        ]
        return manager
    }
}
