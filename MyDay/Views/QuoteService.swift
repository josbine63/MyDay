//
//  QuoteService.swift
//  MyDay
//
//  Created by Assistant on 2026-01-30.
//

import Foundation
import os.log
import Translation

extension Logger {
    static let quote = Logger(subsystem: "com.myapp.MyDay", category: "quote")
}

// MARK: - Quote Model

struct Quote: Codable {
    let q: String  // Quote text
    let a: String  // Author
    let h: String  // HTML format
}

// MARK: - Quote Service

class QuoteService: ObservableObject {
    // Singleton partagé
    static let shared = QuoteService()
    
    @Published var currentQuote: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Translation Properties
    @Published var translationConfiguration: TranslationSession.Configuration?
    @Published var textToTranslate: String?
    @Published var quoteAuthor: String?
    @Published var translationTrigger: UUID = UUID()
    @Published var isTranslationAvailable: Bool = false // Disponibilité de la traduction
    
    private let quoteEnabledKey = "quoteOfTheDayEnabled"
    private let cachedQuoteKey = "cachedQuote"
    private let cachedQuoteDateKey = "cachedQuoteDate"
    private let cachedQuoteTranslatedKey = "cachedQuoteTranslated" // ✅ Cache pour traduction
    private let cachedQuoteLanguageKey = "cachedQuoteLanguage" // ✅ Langue du cache traduit
    
    private init() {
        let userLanguage = Locale.preferredLanguages.first?.prefix(2).lowercased() ?? "en"
        
        // D'abord essayer le cache traduit si non anglophone
        if userLanguage != "en",
           let cacheDate = UserDefaults.standard.object(forKey: cachedQuoteDateKey) as? Date,
           Calendar.current.isDateInToday(cacheDate),
           let cachedLanguage = UserDefaults.standard.string(forKey: cachedQuoteLanguageKey),
           cachedLanguage == userLanguage,
           let translatedQuote = UserDefaults.standard.string(forKey: cachedQuoteTranslatedKey),
           !translatedQuote.isEmpty {
            Logger.quote.debug("✅ Cache TRADUIT valide pour aujourd'hui (\(cachedLanguage))")
            self.currentQuote = translatedQuote
        }
        // Sinon essayer le cache normal
        else if let cacheDate = UserDefaults.standard.object(forKey: cachedQuoteDateKey) as? Date,
           Calendar.current.isDateInToday(cacheDate),
           let cachedQuote = UserDefaults.standard.string(forKey: cachedQuoteKey),
           !cachedQuote.isEmpty {
            Logger.quote.debug("✅ Cache valide pour aujourd'hui")
            self.currentQuote = cachedQuote
        } else {
            let lang = Locale.preferredLanguages.first ?? "en"
            self.currentQuote = lang.hasPrefix("fr") ? "Chargement…" : "Loading…"
        }
        
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
            Logger.quote.info("🌐 Traduction non disponible (iOS < 18)")
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
            Logger.quote.info("✅ Traduction installée et prête (en → \(userLanguage))")
        case .supported:
            isTranslationAvailable = true
            Logger.quote.info("⚠️ Traduction supportée mais nécessite téléchargement (en → \(userLanguage))")
        case .unsupported:
            isTranslationAvailable = false
            Logger.quote.warning("❌ Traduction non supportée pour en → \(userLanguage)")
        @unknown default:
            isTranslationAvailable = false
            Logger.quote.warning("❌ Statut de traduction inconnu")
        }
    }
    
    var isQuoteEnabled: Bool {
        get {
            // Par défaut désactivé jusqu'à activation manuelle
            if UserDefaults.standard.object(forKey: quoteEnabledKey) == nil {
                return false
            }
            return UserDefaults.standard.bool(forKey: quoteEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: quoteEnabledKey)
            objectWillChange.send()
        }
    }
    
    // MARK: - Fetch Quote
    
    @MainActor
    func fetchQuote(forceRefresh: Bool = false) async {
        // Ne pas charger si désactivé
        guard isQuoteEnabled else {
            Logger.quote.debug("📴 Pensée du jour désactivée")
            return
        }
        
        let userLanguage = Locale.preferredLanguages.first?.prefix(2).lowercased() ?? "en"
        
        // Vérifier le cache si on ne force pas le refresh
        if !forceRefresh {
            // D'abord essayer le cache traduit si non anglophone
            if userLanguage != "en",
               let cacheDate = UserDefaults.standard.object(forKey: cachedQuoteDateKey) as? Date,
               Calendar.current.isDateInToday(cacheDate),
               let cachedLanguage = UserDefaults.standard.string(forKey: cachedQuoteLanguageKey),
               cachedLanguage == userLanguage,
               let translatedQuote = UserDefaults.standard.string(forKey: cachedQuoteTranslatedKey),
               !translatedQuote.isEmpty {
                Logger.quote.debug("📦 Utilisation de la citation TRADUITE en cache (aujourd'hui)")
                self.currentQuote = translatedQuote
                return
            }
            
            // Sinon essayer le cache normal
            if let cacheDate = UserDefaults.standard.object(forKey: cachedQuoteDateKey) as? Date,
               Calendar.current.isDateInToday(cacheDate),
               let cachedQuote = UserDefaults.standard.string(forKey: cachedQuoteKey),
               !cachedQuote.isEmpty {
                Logger.quote.debug("📦 Utilisation de la citation en cache (aujourd'hui)")
                self.currentQuote = cachedQuote
                
                // ✅ Préparer la traduction seulement si disponible et nécessaire
                if userLanguage != "en" && isTranslationAvailable {
                    // Extraire le texte original pour traduction
                    // Le format est "\"quote\" — author"
                    if let quoteText = extractQuoteText(from: cachedQuote),
                       let author = extractAuthor(from: cachedQuote) {
                        prepareTranslation(quoteText: quoteText, author: author, to: String(userLanguage))
                    }
                }
                return
            }
        }
        
        isLoading = true
        errorMessage = nil
        
        Logger.quote.info("💭 Récupération de la pensée du jour depuis ZenQuotes")
        
        guard let url = URL(string: "https://zenquotes.io/api/random") else {
            currentQuote = localizedError("Erreur de chargement", "Loading error")
            isLoading = false
            return
        }
        
        // userLanguage déjà défini plus haut dans la fonction
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.timeoutInterval = 10
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                Logger.quote.debug("📡 ZenQuotes API réponse: \(httpResponse.statusCode)")
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    Logger.quote.error("❌ Erreur HTTP \(httpResponse.statusCode) de ZenQuotes")
                    currentQuote = localizedError("Citation indisponible", "Quote unavailable")
                    isLoading = false
                    return
                }
            }
            
            if let decoded = try? JSONDecoder().decode([Quote].self, from: data),
               let firstQuote = decoded.first {
                // Citation originale en anglais
                let originalQuote = "\"\(firstQuote.q)\" — \(firstQuote.a)"
                
                // Toujours sauvegarder l'original en cache
                saveToCache(originalQuote)
                
                // Préparer la traduction si nécessaire et disponible
                if userLanguage != "en" && isTranslationAvailable {
                    prepareTranslation(quoteText: firstQuote.q, author: firstQuote.a, to: String(userLanguage))
                    // currentQuote temporaire pendant la traduction
                    currentQuote = originalQuote
                } else {
                    // L'utilisateur préfère l'anglais ou traduction non disponible
                    currentQuote = originalQuote
                    isLoading = false
                }
                
                Logger.quote.info("✅ Pensée du jour récupérée avec succès")
            } else {
                Logger.quote.error("❌ Impossible de décoder la réponse JSON")
                currentQuote = localizedError("Citation indisponible", "Quote unavailable")
            }
            
        } catch {
            Logger.quote.error("❌ Erreur lors du chargement: \(error.localizedDescription)")
            
            // Essayer le cache même expiré
            if let cachedQuote = UserDefaults.standard.string(forKey: cachedQuoteKey),
               !cachedQuote.isEmpty {
                Logger.quote.warning("⚠️ Utilisation du cache expiré en mode dégradé")
                currentQuote = cachedQuote
                errorMessage = localizedError(
                    "⚠️ Service indisponible - Citation d'hier affichée",
                    "⚠️ Service unavailable - Yesterday's quote shown"
                )
            } else {
                currentQuote = localizedError("Citation indisponible", "Quote unavailable")
            }
        }
        
        // Garder isLoading si une traduction est en cours
        if textToTranslate == nil {
            isLoading = false
        }
    }
    
    // MARK: - Translation Preparation
    
    /// Prépare la traduction de la citation
    @MainActor
    private func prepareTranslation(quoteText: String, author: String, to targetLanguage: String) {
        guard isTranslationAvailable else {
            Logger.quote.info("🌐 Traduction non disponible, affichage en anglais")
            isLoading = false
            return
        }
        
        if #available(iOS 18.0, macOS 15.0, *) {
            Logger.quote.debug("🌐 Préparation traduction vers \(targetLanguage)")
            
            // Stocker le texte à traduire
            textToTranslate = quoteText
            quoteAuthor = author
            
            // Créer la configuration de traduction
            let sourceLang = Locale.Language(identifier: "en")
            let targetLang = Locale.Language(identifier: targetLanguage)
            translationConfiguration = TranslationSession.Configuration(
                source: sourceLang,
                target: targetLang
            )
            
            translationTrigger = UUID()
            // isLoading reste true — handleTranslation mettra à jour
        } else {
            isLoading = false
        }
    }
    
    // MARK: - Translation Handler
    
    @available(iOS 18.0, macOS 15.0, *)
    @MainActor
    func handleTranslation(using session: TranslationSession) async {
        guard let textToTranslate = textToTranslate,
              let author = quoteAuthor else {
            Logger.quote.debug("🌐 Aucun texte à traduire")
            return
        }
        
        do {
            Logger.quote.debug("🌐 Traduction en cours avec session iOS 18+")
            
            // Traduire avec la session
            let response = try await session.translate(textToTranslate)
            let translatedText = response.targetText
            
            // Mettre à jour la citation avec la traduction
            await MainActor.run {
                let translatedQuote = "\"\(translatedText)\" — \(author)"
                self.currentQuote = translatedQuote
                
                // ✅ IMPORTANT: Sauvegarder la traduction dans le cache séparé
                let userLanguage = Locale.preferredLanguages.first?.prefix(2).lowercased() ?? "en"
                self.saveTranslatedToCache(translatedQuote, language: String(userLanguage))
                
                self.textToTranslate = nil
                self.quoteAuthor = nil
                self.isLoading = false
                Logger.quote.debug("✅ Citation traduite et mise en cache avec succès")
            }
            
        } catch {
            Logger.quote.error("❌ Erreur lors de la traduction: \(error.localizedDescription)")
            // Fallback : afficher l'original en anglais
            await MainActor.run {
                if let text = self.textToTranslate, let author = self.quoteAuthor {
                    let fallback = "\"\(text)\" — \(author)"
                    self.currentQuote = fallback
                }
                self.textToTranslate = nil
                self.quoteAuthor = nil
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Cache Management
    
    @MainActor
    private func saveToCache(_ quote: String) {
        UserDefaults.standard.set(quote, forKey: cachedQuoteKey)
        UserDefaults.standard.set(Date(), forKey: cachedQuoteDateKey)
        Logger.quote.debug("💾 Citation mise en cache")
    }
    
    /// Sauvegarde la citation traduite dans un cache séparé
    @MainActor
    private func saveTranslatedToCache(_ quote: String, language: String) {
        UserDefaults.standard.set(quote, forKey: cachedQuoteTranslatedKey)
        UserDefaults.standard.set(language, forKey: cachedQuoteLanguageKey)
        Logger.quote.debug("💾 Citation TRADUITE mise en cache (\(language))")
    }
    
    // MARK: - Helper Methods
    
    /// Extrait le texte de la citation du format "\"quote\" — author"
    private func extractQuoteText(from formattedQuote: String) -> String? {
        // Format: "\"quote\" — author"
        if let startIndex = formattedQuote.firstIndex(of: "\""),
           let endIndex = formattedQuote.lastIndex(of: "\""),
           startIndex != endIndex {
            let start = formattedQuote.index(after: startIndex)
            return String(formattedQuote[start..<endIndex])
        }
        return nil
    }
    
    /// Extrait l'auteur du format "\"quote\" — author"
    private func extractAuthor(from formattedQuote: String) -> String? {
        if let dashRange = formattedQuote.range(of: " — ") {
            return String(formattedQuote[dashRange.upperBound...]).trimmingCharacters(in: .whitespaces)
        }
        return nil
    }
    
    private func localizedError(_ french: String, _ english: String) -> String {
        let lang = Locale.preferredLanguages.first ?? "en"
        return lang.hasPrefix("fr") ? french : english
    }
    
    private func localizedLoadingText() -> String {
        let lang = Locale.preferredLanguages.first ?? "en"
        return lang.hasPrefix("fr") ? "Chargement…" : "Loading…"
    }
}
