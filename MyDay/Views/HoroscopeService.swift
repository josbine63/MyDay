//
//  HoroscopeService.swift
//  MyDay
//
//  Created by Josblais on 2026-01-29.
//

import Foundation
import os.log
import Translation

extension Logger {
    static let horoscope = Logger(subsystem: "com.myapp.MyDay", category: "horoscope")
}

// MARK: - API Provider Selection

enum HoroscopeProvider: String, CaseIterable, Identifiable {
    case aztro = "aztro"
    case horoscopeAPI = "horoscope-api"
    
    var id: String { rawValue }
    
    var displayName: String {
        let lang = Locale.preferredLanguages.first ?? "en"
        let isFrench = lang.hasPrefix("fr")
        
        switch self {
        case .aztro:
            return isFrench ? "Aztro (Alternatif)" : "Aztro (Alternative)"
        case .horoscopeAPI:
            return isFrench ? "Horoscope API (Par défaut)" : "Horoscope API (Default)"
        }
    }
    
    var sourceURL: String {
        switch self {
        case .aztro: return "aztro.sameerkumar.website"
        case .horoscopeAPI: return "horoscope-app-api.vercel.app"
        }
    }
    
    var description: String {
        let lang = Locale.preferredLanguages.first ?? "en"
        let isFrench = lang.hasPrefix("fr")
        
        switch self {
        case .aztro:
            return isFrench ? "Service principal avec détails complets" : "Main service with full details"
        case .horoscopeAPI:
            return isFrench ? "Service alternatif plus simple" : "Alternative simpler service"
        }
    }
}

// MARK: - Response Models

struct HoroscopeResponse: Codable {
    let dateRange: String
    let currentDate: String
    let description: String
    let compatibility: String
    let mood: String
    let color: String
    let luckyNumber: String
    let luckyTime: String
    
    enum CodingKeys: String, CodingKey {
        case dateRange = "date_range"
        case currentDate = "current_date"
        case description, compatibility, mood, color
        case luckyNumber = "lucky_number"
        case luckyTime = "lucky_time"
    }
}

// Alternative API response model
struct HoroscopeAPIResponse: Codable {
    let data: HoroscopeData
    
    struct HoroscopeData: Codable {
        let date: String
        let horoscope_data: String
    }
}

enum ZodiacSign: String, CaseIterable, Identifiable {
    case aries = "aries"
    case taurus = "taurus"
    case gemini = "gemini"
    case cancer = "cancer"
    case leo = "leo"
    case virgo = "virgo"
    case libra = "libra"
    case scorpio = "scorpio"
    case sagittarius = "sagittarius"
    case capricorn = "capricorn"
    case aquarius = "aquarius"
    case pisces = "pisces"
    
    var id: String { rawValue }
    
    var localizedName: String {
        let lang = Locale.preferredLanguages.first ?? "en"
        let isFrench = lang.hasPrefix("fr")
        
        switch self {
        case .aries: return isFrench ? "Bélier" : "Aries"
        case .taurus: return isFrench ? "Taureau" : "Taurus"
        case .gemini: return isFrench ? "Gémeaux" : "Gemini"
        case .cancer: return isFrench ? "Cancer" : "Cancer"
        case .leo: return isFrench ? "Lion" : "Leo"
        case .virgo: return isFrench ? "Vierge" : "Virgo"
        case .libra: return isFrench ? "Balance" : "Libra"
        case .scorpio: return isFrench ? "Scorpion" : "Scorpio"
        case .sagittarius: return isFrench ? "Sagittaire" : "Sagittarius"
        case .capricorn: return isFrench ? "Capricorne" : "Capricorn"
        case .aquarius: return isFrench ? "Verseau" : "Aquarius"
        case .pisces: return isFrench ? "Poissons" : "Pisces"
        }
    }
    
    var symbol: String {
        switch self {
        case .aries: return "♈"
        case .taurus: return "♉"
        case .gemini: return "♊"
        case .cancer: return "♋"
        case .leo: return "♌"
        case .virgo: return "♍"
        case .libra: return "♎"
        case .scorpio: return "♏"
        case .sagittarius: return "♐"
        case .capricorn: return "♑"
        case .aquarius: return "♒"
        case .pisces: return "♓"
        }
    }
    
    var emoji: String {
        switch self {
        case .aries: return "🐏"
        case .taurus: return "🐂"
        case .gemini: return "👯"
        case .cancer: return "🦀"
        case .leo: return "🦁"
        case .virgo: return "👰"
        case .libra: return "⚖️"
        case .scorpio: return "🦂"
        case .sagittarius: return "🏹"
        case .capricorn: return "🐐"
        case .aquarius: return "🏺"
        case .pisces: return "🐟"
        }
    }
}

class HoroscopeService: ObservableObject {
    // Singleton partagé
    static let shared = HoroscopeService()
    
    @Published var currentHoroscope: HoroscopeResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Translation Properties
    @Published var translationConfiguration: TranslationSession.Configuration?
    @Published var textToTranslate: String?
    @Published var translatedHoroscope: HoroscopeResponse?
    @Published var translationTrigger: UUID = UUID() // Pour forcer le refresh
    @Published var isTranslating: Bool = false // Pour indiquer qu'une traduction est en cours
    @Published var isTranslationAvailable: Bool = false // Disponibilité de la traduction
    
    private let selectedSignKey = "selectedZodiacSign"
    private let selectedProviderKey = "selectedHoroscopeProvider"
    private let horoscopeEnabledKey = "horoscopeEnabled"
    
    // MARK: - Cache Keys for Translation
    private func translatedCacheKey(for sign: ZodiacSign, language: String) -> String {
        return "cachedHoroscope_\(sign.rawValue)_translated_\(language)"
    }
    
    private init() {
        // Nettoyer les anciennes clés de cache (migration)
        UserDefaults.standard.removeObject(forKey: "cachedHoroscope")
        UserDefaults.standard.removeObject(forKey: "cachedHoroscopeDate")
        
        // Vérifier la disponibilité de la traduction au démarrage
        Task {
            await checkTranslationAvailability()
        }
    }
    
    // MARK: - Translation Availability Check
    
    /// Vérifie si la traduction est disponible sur l'appareil
    @MainActor
    func checkTranslationAvailability() async {
        guard #available(iOS 18.0, macOS 15.0, *) else {
            isTranslationAvailable = false
            Logger.horoscope.info("🌐 Traduction non disponible (iOS < 18)")
            return
        }
        
        let userLanguage = Locale.preferredLanguages.first?.prefix(2).lowercased() ?? "en"
        guard userLanguage != "en" else {
            isTranslationAvailable = false // Pas besoin de traduction pour l'anglais
            return
        }
        
        let availability = LanguageAvailability()
        let sourceLang = Locale.Language(identifier: "en")
        let targetLang = Locale.Language(identifier: String(userLanguage))
        
        let status = await availability.status(from: sourceLang, to: targetLang)
        
        switch status {
        case .installed:
            isTranslationAvailable = true
            Logger.horoscope.info("✅ Traduction installée et prête (en → \(userLanguage))")
        case .supported:
            isTranslationAvailable = true
            Logger.horoscope.info("⚠️ Traduction supportée mais nécessite téléchargement (en → \(userLanguage))")
        case .unsupported:
            isTranslationAvailable = false
            Logger.horoscope.warning("❌ Traduction non supportée pour en → \(userLanguage)")
        @unknown default:
            isTranslationAvailable = false
            Logger.horoscope.warning("❌ Statut de traduction inconnu")
        }
    }
    
    var isHoroscopeEnabled: Bool {
        get {
            // Par défaut désactivé jusqu'à activation manuelle
            if UserDefaults.standard.object(forKey: horoscopeEnabledKey) == nil {
                return false
            }
            return UserDefaults.standard.bool(forKey: horoscopeEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: horoscopeEnabledKey)
            objectWillChange.send()
        }
    }
    
    var selectedProvider: HoroscopeProvider {
        get {
            if let providerRawValue = UserDefaults.standard.string(forKey: selectedProviderKey),
               let provider = HoroscopeProvider(rawValue: providerRawValue) {
                return provider
            }
            return .horoscopeAPI // Valeur par défaut
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: selectedProviderKey)
            // Invalider le cache et recharger quand le provider change
            clearCache()
            Task { [weak self] in
                guard let self = self else { return }
                await self.fetchHoroscope(for: self.selectedSign)
            }
        }
    }
    
    var selectedSign: ZodiacSign {
        get {
            if let signRawValue = UserDefaults.standard.string(forKey: selectedSignKey),
               let sign = ZodiacSign(rawValue: signRawValue) {
                return sign
            }
            return .aries // Valeur par défaut
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: selectedSignKey)
            // Invalider le cache et recharger l'horoscope quand le signe change
            clearCache()
            
            // Réinitialiser complètement la traduction
            translationConfiguration = nil
            textToTranslate = nil
            translationTrigger = UUID()
            
            Task { [weak self] in
                guard let self = self else { return }
                // Force le refresh pour obtenir le nouvel horoscope
                await self.fetchHoroscope(for: newValue, forceRefresh: true)
            }
        }
    }
    
    @MainActor
    func fetchHoroscope(for sign: ZodiacSign, forceRefresh: Bool = false) async {
        let userLanguage = Locale.preferredLanguages.first?.prefix(2).lowercased() ?? "en"
        
        // Vérifier le cache si on ne force pas le refresh
        if !forceRefresh {
            // D'abord essayer le cache traduit si l'utilisateur n'est pas anglophone
            if userLanguage != "en" {
                if let translatedCache = loadTranslatedCachedHoroscope(language: userLanguage) {
                    let dateKey = cacheDateKey(for: selectedSign)
                    if let cacheDate = UserDefaults.standard.object(forKey: dateKey) as? Date,
                       Calendar.current.isDateInToday(cacheDate) {
                        Logger.horoscope.debug("📦 Utilisation de l'horoscope TRADUIT en cache (aujourd'hui)")
                        self.currentHoroscope = translatedCache
                        // Pas besoin de préparer la traduction, c'est déjà traduit!
                        return
                    }
                }
            }
            
            // Sinon essayer le cache anglais
            if let cachedHoroscope = loadCachedHoroscope() {
                // Vérifier si le cache est d'aujourd'hui
                let dateKey = cacheDateKey(for: selectedSign)
                if let cacheDate = UserDefaults.standard.object(forKey: dateKey) as? Date,
                   Calendar.current.isDateInToday(cacheDate) {
                    Logger.horoscope.debug("📦 Utilisation de l'horoscope en cache (aujourd'hui)")
                    self.currentHoroscope = cachedHoroscope
                    
                    // ✅ Préparer la traduction pour le cache seulement si disponible
                    if userLanguage != "en" && isTranslationAvailable {
                        prepareTranslation(for: cachedHoroscope, to: String(userLanguage))
                    }
                    
                    return
                }
                // Sinon, on essaiera de récupérer un nouveau, mais on garde celui-ci en backup
            }
        }
        
        isLoading = true
        errorMessage = nil
        
        Logger.horoscope.info("🔮 Récupération de l'horoscope pour \(sign.rawValue) depuis \(self.selectedProvider.displayName)")
        
        // Choisir la bonne API
        switch self.selectedProvider {
        case .aztro:
            await fetchFromAztro(sign: sign)
        case .horoscopeAPI:
            await fetchFromHoroscopeAPI(sign: sign)
        }
    }
    
    // MARK: - Aztro API
    
    @MainActor
    private func fetchFromAztro(sign: ZodiacSign) async {
        var lastStatusCode: Int?
        
        for attempt in 1...3 {
            if attempt > 1 {
                Logger.horoscope.debug("🔄 Tentative \(attempt)/3...")
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
            
            let urlString = "https://aztro.sameerkumar.website/?sign=\(sign.rawValue)&day=today"
            guard let url = URL(string: urlString) else {
                errorMessage = localizedError("URL invalide", "Invalid URL")
                isLoading = false
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 15
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    errorMessage = localizedError("Réponse serveur invalide", "Invalid server response")
                    continue
                }
                
                Logger.horoscope.debug("📡 Code de réponse: \(httpResponse.statusCode)")
                lastStatusCode = httpResponse.statusCode
                
                guard httpResponse.statusCode == 200 else {
                    if httpResponse.statusCode == 503 {
                        Logger.horoscope.warning("⚠️ Service temporairement indisponible (503)")
                        continue
                    }
                    errorMessage = localizedError("Erreur serveur (\(httpResponse.statusCode))", "Server error (\(httpResponse.statusCode))")
                    isLoading = false
                    return
                }
                
                let decoder = JSONDecoder()
                let horoscope = try decoder.decode(HoroscopeResponse.self, from: data)
                
                self.currentHoroscope = horoscope
                saveToCache(horoscope)
                
                // ✅ Préparer la traduction si nécessaire
                let userLanguage = Locale.preferredLanguages.first?.prefix(2).lowercased() ?? "en"
                if userLanguage != "en" {
                    prepareTranslation(for: horoscope, to: String(userLanguage))
                }
                
                Logger.horoscope.info("✅ Horoscope récupéré avec succès")
                isLoading = false
                return
                
            } catch {
                Logger.horoscope.error("❌ Erreur (tentative \(attempt)): \(error.localizedDescription)")
                continue
            }
        }
        
        // Échec - essayer le cache expiré
        await handleFetchFailure(lastStatusCode: lastStatusCode)
    }
    
    // MARK: - Horoscope API (Alternative)
    
    @MainActor
    private func fetchFromHoroscopeAPI(sign: ZodiacSign) async {
        var lastStatusCode: Int?
        
        for attempt in 1...3 {
            if attempt > 1 {
                Logger.horoscope.debug("🔄 Tentative \(attempt)/3...")
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
            
            let urlString = "https://horoscope-app-api.vercel.app/api/v1/get-horoscope/daily?sign=\(sign.rawValue)&day=TODAY"
            guard let url = URL(string: urlString) else {
                errorMessage = localizedError("URL invalide", "Invalid URL")
                isLoading = false
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 15
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    errorMessage = localizedError("Réponse serveur invalide", "Invalid server response")
                    continue
                }
                
                Logger.horoscope.debug("📡 Code de réponse: \(httpResponse.statusCode)")
                lastStatusCode = httpResponse.statusCode
                
                guard httpResponse.statusCode == 200 else {
                    if httpResponse.statusCode == 503 {
                        Logger.horoscope.warning("⚠️ Service temporairement indisponible (503)")
                        continue
                    }
                    errorMessage = localizedError("Erreur serveur (\(httpResponse.statusCode))", "Server error (\(httpResponse.statusCode))")
                    isLoading = false
                    return
                }
                
                let decoder = JSONDecoder()
                let apiResponse = try decoder.decode(HoroscopeAPIResponse.self, from: data)
                
                // Convertir en format unifié
                let horoscope = HoroscopeResponse(
                    dateRange: apiResponse.data.date,
                    currentDate: apiResponse.data.date,
                    description: apiResponse.data.horoscope_data,
                    compatibility: "N/A",
                    mood: "N/A",
                    color: "N/A",
                    luckyNumber: "N/A",
                    luckyTime: "N/A"
                )
                
                self.currentHoroscope = horoscope
                saveToCache(horoscope)
                
                // ✅ Préparer la traduction si nécessaire
                let userLanguage = Locale.preferredLanguages.first?.prefix(2).lowercased() ?? "en"
                if userLanguage != "en" {
                    prepareTranslation(for: horoscope, to: String(userLanguage))
                }
                
                Logger.horoscope.info("✅ Horoscope récupéré avec succès")
                isLoading = false
                return
                
            } catch {
                Logger.horoscope.error("❌ Erreur (tentative \(attempt)): \(error.localizedDescription)")
                continue
            }
        }
        
        // Échec - essayer le cache expiré
        await handleFetchFailure(lastStatusCode: lastStatusCode)
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    private func handleFetchFailure(lastStatusCode: Int?) async {
        if let cachedHoroscope = loadCachedHoroscope() {
            Logger.horoscope.warning("⚠️ Utilisation du cache expiré en mode dégradé")
            self.currentHoroscope = cachedHoroscope
            
            // ✅ Préparer la traduction pour le cache en mode dégradé
            let userLanguage = Locale.preferredLanguages.first?.prefix(2).lowercased() ?? "en"
            if userLanguage != "en" {
                prepareTranslation(for: cachedHoroscope, to: String(userLanguage))
            }
            
            errorMessage = localizedError(
                "⚠️ Service indisponible - Horoscope d'hier affiché",
                "⚠️ Service unavailable - Yesterday's horoscope shown"
            )
            isLoading = false
            return
        }
        
        if lastStatusCode == 503 {
            errorMessage = localizedError(
                "Service temporairement indisponible. Réessayez plus tard.",
                "Service temporarily unavailable. Try again later."
            )
        } else {
            errorMessage = localizedError(
                "Impossible de charger l'horoscope après 3 tentatives",
                "Unable to load horoscope after 3 attempts"
            )
        }
        
        isLoading = false
    }
    
    private func localizedError(_ french: String, _ english: String) -> String {
        let lang = Locale.preferredLanguages.first ?? "en"
        return lang.hasPrefix("fr") ? french : english
    }
    
    // MARK: - Cache Management
    
    private func cacheKey(for sign: ZodiacSign) -> String {
        return "cachedHoroscope_\(sign.rawValue)"
    }
    
    private func cacheDateKey(for sign: ZodiacSign) -> String {
        return "cachedHoroscopeDate_\(sign.rawValue)"
    }
    
    private func saveToCache(_ horoscope: HoroscopeResponse) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(horoscope) {
            let key = cacheKey(for: selectedSign)
            let dateKey = cacheDateKey(for: selectedSign)
            UserDefaults.standard.set(encoded, forKey: key)
            UserDefaults.standard.set(Date(), forKey: dateKey)
            Logger.horoscope.debug("💾 Horoscope mis en cache pour \(self.selectedSign.rawValue)")
        }
    }
    
    private func loadCachedHoroscope() -> HoroscopeResponse? {
        let key = cacheKey(for: selectedSign)
        let dateKey = cacheDateKey(for: selectedSign)
        
        // Vérifier si le cache est encore valide (aujourd'hui)
        if let cacheDate = UserDefaults.standard.object(forKey: dateKey) as? Date {
            let calendar = Calendar.current
            if !calendar.isDateInToday(cacheDate) {
                // Cache expiré mais on le garde pour le mode dégradé
                Logger.horoscope.debug("⚠️ Cache expiré (date: \(cacheDate)) mais disponible en mode dégradé pour \(self.selectedSign.rawValue)")
            } else {
                Logger.horoscope.debug("✅ Cache valide pour aujourd'hui pour \(self.selectedSign.rawValue)")
            }
            
            // Charger depuis le cache même si expiré (utile quand l'API est down)
            if let data = UserDefaults.standard.data(forKey: key) {
                let decoder = JSONDecoder()
                if let horoscope = try? decoder.decode(HoroscopeResponse.self, from: data) {
                    return horoscope
                }
            }
        }
        
        return nil
    }
    
    private func clearCache() {
        // Nettoyer le cache pour le signe actuel (anglais ET traduit)
        let key = cacheKey(for: selectedSign)
        let dateKey = cacheDateKey(for: selectedSign)
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.removeObject(forKey: dateKey)
        
        // Nettoyer aussi le cache traduit pour toutes les langues courantes
        for lang in ["fr", "es", "de", "it", "pt"] {
            let translatedKey = translatedCacheKey(for: selectedSign, language: lang)
            UserDefaults.standard.removeObject(forKey: translatedKey)
        }
        
        Logger.horoscope.debug("🧹 Cache nettoyé pour \(self.selectedSign.rawValue)")
    }
    
    // MARK: - Translated Cache Management
    
    /// Sauvegarde l'horoscope traduit dans le cache
    private func saveTranslatedToCache(_ horoscope: HoroscopeResponse, language: String) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(horoscope) {
            let key = translatedCacheKey(for: selectedSign, language: language)
            UserDefaults.standard.set(encoded, forKey: key)
            Logger.horoscope.debug("💾 Horoscope TRADUIT mis en cache pour \(self.selectedSign.rawValue) (\(language))")
        }
    }
    
    /// Charge l'horoscope traduit depuis le cache
    private func loadTranslatedCachedHoroscope(language: String) -> HoroscopeResponse? {
        let key = translatedCacheKey(for: selectedSign, language: language)
        
        if let data = UserDefaults.standard.data(forKey: key) {
            let decoder = JSONDecoder()
            if let horoscope = try? decoder.decode(HoroscopeResponse.self, from: data) {
                Logger.horoscope.debug("📦 Horoscope TRADUIT chargé depuis le cache (\(language))")
                return horoscope
            }
        }
        
        return nil
    }
    
    // MARK: - Translation Handler
    
    /// Prépare la traduction de l'horoscope
    @MainActor
    func prepareTranslation(for horoscope: HoroscopeResponse, to targetLanguage: String) {
        guard targetLanguage != "en" else {
            // Pas besoin de traduire si l'utilisateur veut l'anglais
            translationConfiguration = nil
            textToTranslate = nil
            return
        }
        
        // ✅ Vérifier si la traduction est disponible
        guard isTranslationAvailable else {
            Logger.horoscope.info("🌐 Traduction non disponible, affichage en anglais")
            return
        }
        
        if #available(iOS 18.0, macOS 15.0, *) {
            Logger.horoscope.debug("🌐 Préparation traduction horoscope vers \(targetLanguage)")
            
            // Stocker le texte à traduire
            textToTranslate = horoscope.description
            
            // Créer la configuration de traduction
            let sourceLang = Locale.Language(identifier: "en")
            let targetLang = Locale.Language(identifier: targetLanguage)
            translationConfiguration = TranslationSession.Configuration(
                source: sourceLang,
                target: targetLang
            )
            
            // ⚠️ IMPORTANT : Changer le trigger pour forcer SwiftUI à réagir
            translationTrigger = UUID()
            
            Logger.horoscope.debug("✅ Configuration de traduction créée avec trigger: \(self.translationTrigger)")
        }
    }
    
    /// Gère la traduction avec la session fournie par translationTask
    @available(iOS 18.0, macOS 15.0, *)
    @MainActor
    func handleTranslation(using session: TranslationSession) async {
        guard let textToTranslate = textToTranslate,
              let originalHoroscope = currentHoroscope else {
            Logger.horoscope.debug("🌐 Aucun texte d'horoscope à traduire")
            return
        }
        
        // Vérifier qu'on n'a pas déjà traduit ce texte
        if originalHoroscope.description != textToTranslate {
            Logger.horoscope.debug("🌐 Texte déjà traduit, skip")
            return
        }
        
        do {
            Logger.horoscope.debug("🌐 Traduction horoscope en cours avec session iOS 18+")
            
            // Traduire avec la session
            let response = try await session.translate(textToTranslate)
            let translatedText = response.targetText
            
            // Créer un nouvel horoscope avec la description traduite
            let translatedHoroscope = HoroscopeResponse(
                dateRange: originalHoroscope.dateRange,
                currentDate: originalHoroscope.currentDate,
                description: translatedText,
                compatibility: originalHoroscope.compatibility,
                mood: originalHoroscope.mood,
                color: originalHoroscope.color,
                luckyNumber: originalHoroscope.luckyNumber,
                luckyTime: originalHoroscope.luckyTime
            )
            
            // Mettre à jour avec la traduction
            await MainActor.run {
                self.currentHoroscope = translatedHoroscope
                self.textToTranslate = nil // Réinitialiser
                
                // ✅ IMPORTANT: Sauvegarder la traduction dans le cache
                let userLanguage = Locale.preferredLanguages.first?.prefix(2).lowercased() ?? "en"
                self.saveTranslatedToCache(translatedHoroscope, language: String(userLanguage))
            }
            Logger.horoscope.debug("✅ Horoscope traduit et mis en cache avec succès")
            
        } catch {
            Logger.horoscope.error("❌ Erreur lors de la traduction de l'horoscope: \(error.localizedDescription)")
        }
    }
}
