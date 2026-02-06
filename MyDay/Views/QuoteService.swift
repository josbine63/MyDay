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
    
    private let quoteEnabledKey = "quoteOfTheDayEnabled"
    private let cachedQuoteKey = "cachedQuote"
    private let cachedQuoteDateKey = "cachedQuoteDate"
    
    private init() {
        // Charger le cache directement sans @MainActor (init est toujours sur le main thread pour ObservableObject)
        if let cacheDate = UserDefaults.standard.object(forKey: cachedQuoteDateKey) as? Date,
           Calendar.current.isDateInToday(cacheDate),
           let cachedQuote = UserDefaults.standard.string(forKey: cachedQuoteKey),
           !cachedQuote.isEmpty {
            Logger.quote.debug("✅ Cache valide pour aujourd'hui")
            self.currentQuote = cachedQuote
        } else {
            let lang = Locale.preferredLanguages.first ?? "en"
            self.currentQuote = lang.hasPrefix("fr") ? "Chargement…" : "Loading…"
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
        
        // Vérifier le cache si on ne force pas le refresh
        if !forceRefresh {
            if let cacheDate = UserDefaults.standard.object(forKey: cachedQuoteDateKey) as? Date,
               Calendar.current.isDateInToday(cacheDate),
               let cachedQuote = UserDefaults.standard.string(forKey: cachedQuoteKey),
               !cachedQuote.isEmpty {
                Logger.quote.debug("📦 Utilisation de la citation en cache (aujourd'hui)")
                self.currentQuote = cachedQuote
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
        
        // Obtenir la langue de l'utilisateur
        let userLanguage = Locale.preferredLanguages.first?.prefix(2).lowercased() ?? "en"
        
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
                
                // Préparer la traduction si nécessaire
                if userLanguage != "en" {
                    if #available(iOS 18.0, macOS 15.0, *) {
                        Logger.quote.debug("🌐 Préparation traduction vers \(userLanguage)")
                        
                        // Stocker le texte à traduire
                        textToTranslate = firstQuote.q
                        quoteAuthor = firstQuote.a
                        
                        // Créer la configuration de traduction
                        let sourceLang = Locale.Language(identifier: "en")
                        let targetLang = Locale.Language(identifier: String(userLanguage))
                        translationConfiguration = TranslationSession.Configuration(
                            source: sourceLang,
                            target: targetLang
                        )
                        
                        translationTrigger = UUID()
                        // isLoading reste true — handleTranslation mettra à jour
                        // currentQuote et le cache après traduction
                    } else {
                        // iOS < 18 : traduction indisponible, afficher en anglais
                        Logger.quote.info("ℹ️ Traduction nécessite iOS 18+, affichage en anglais")
                        currentQuote = originalQuote
                        saveToCache(originalQuote)
                    }
                } else {
                    // L'utilisateur préfère l'anglais
                    currentQuote = originalQuote
                    saveToCache(originalQuote)
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
                self.saveToCache(translatedQuote)
                
                self.textToTranslate = nil
                self.quoteAuthor = nil
                self.isLoading = false
                Logger.quote.debug("✅ Citation traduite avec succès")
            }
            
        } catch {
            Logger.quote.error("❌ Erreur lors de la traduction: \(error.localizedDescription)")
            // Fallback : afficher l'original en anglais
            await MainActor.run {
                if let text = self.textToTranslate, let author = self.quoteAuthor {
                    let fallback = "\"\(text)\" — \(author)"
                    self.currentQuote = fallback
                    self.saveToCache(fallback)
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
    
    // MARK: - Helper Methods
    
    private func localizedError(_ french: String, _ english: String) -> String {
        let lang = Locale.preferredLanguages.first ?? "en"
        return lang.hasPrefix("fr") ? french : english
    }
    
    private func localizedLoadingText() -> String {
        let lang = Locale.preferredLanguages.first ?? "en"
        return lang.hasPrefix("fr") ? "Chargement…" : "Loading…"
    }
}
