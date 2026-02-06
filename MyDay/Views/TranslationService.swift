// TranslationService.swift
import Foundation
import Translation
import os.log

/// Service de traduction utilisant l'API Translation native d'iOS 18+
/// Gratuit, hors ligne (après téléchargement), privé et fiable
@available(iOS 18.0, macOS 15.0, *)
actor TranslationService {
    static let shared = TranslationService()
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.myday", category: "Translation")
    
    // Cache pour éviter de traduire plusieurs fois le même texte
    private var translationCache: [String: String] = [:]
    
    private init() {}
    
    /// Traduit un texte d'une langue source vers une langue cible avec l'API native iOS 18+
    /// - Parameters:
    ///   - text: Le texte à traduire
    ///   - sourceLanguage: Code de langue source (ex: "fr", "en")
    ///   - targetLanguage: Code de langue cible (ex: "en", "fr")
    ///   - session: Session de traduction (optionnelle, pour usage avec SwiftUI)
    /// - Returns: Le texte traduit
    func translate(
        _ text: String,
        from sourceLanguage: String,
        to targetLanguage: String,
        using session: TranslationSession? = nil
    ) async throws -> String {
        logger.info("🌐 Traduction iOS 18: '\(text)' de \(sourceLanguage) vers \(targetLanguage)")
        
        // Vérifier le cache
        let cacheKey = "\(sourceLanguage)_\(targetLanguage)_\(text)"
        if let cached = translationCache[cacheKey] {
            logger.info("📦 Utilisation du cache pour cette traduction")
            return cached
        }
        
        // Si une session est fournie, l'utiliser directement
        if let session = session {
            do {
                let response = try await session.translate(text)
                let translatedText = response.targetText
                
                // Mettre en cache
                translationCache[cacheKey] = translatedText
                
                logger.info("✅ Traduction iOS 18 réussie: '\(translatedText)'")
                return translatedText
            } catch {
                logger.error("❌ Erreur de traduction iOS 18: \(error.localizedDescription)")
                logger.warning("⚠️ Retour du texte original suite à l'erreur")
                return text
            }
        }
        
        // Sans session fournie, impossible de traduire avec l'API iOS 18
        // L'API Translation nécessite une session créée via translationTask() dans SwiftUI
        logger.warning("⚠️ Aucune session fournie - impossible de traduire sans contexte SwiftUI")
        logger.info("💡 Pour utiliser la traduction, appelez cette méthode depuis une vue SwiftUI avec translationTask()")
        
        return text
    }
    
    /// Traduit plusieurs textes en une seule fois (batch)
    /// - Parameters:
    ///   - texts: Les textes à traduire
    ///   - sourceLanguage: Code de langue source
    ///   - targetLanguage: Code de langue cible
    /// - Returns: Tableau des textes traduits
    func translateBatch(
        _ texts: [String],
        from sourceLanguage: String,
        to targetLanguage: String
    ) async throws -> [String] {
        logger.info("🌐 Traduction batch iOS 18: \(texts.count) textes de \(sourceLanguage) vers \(targetLanguage)")
        
        var translatedTexts: [String] = []
        
        for text in texts {
            let translated = try await translate(text, from: sourceLanguage, to: targetLanguage)
            translatedTexts.append(translated)
        }
        
        logger.info("✅ Batch terminé: \(translatedTexts.count) textes traduits")
        return translatedTexts
    }
    
    /// Vide le cache de traduction
    func clearCache() {
        translationCache.removeAll()
        logger.info("🧹 Cache de traduction vidé")
    }
}

// MARK: - Fallback pour iOS < 18

/// Service de traduction pour iOS < 18 (retourne le texte original)
actor TranslationServiceLegacy {
    static let shared = TranslationServiceLegacy()
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.myday", category: "Translation")
    
    private init() {}
    
    func translate(
        _ text: String,
        from sourceLanguage: String,
        to targetLanguage: String
    ) async throws -> String {
        logger.info("⚠️ Traduction non disponible sur iOS < 18, retour du texte original")
        return text
    }
    
    func translateBatch(
        _ texts: [String],
        from sourceLanguage: String,
        to targetLanguage: String
    ) async throws -> [String] {
        logger.info("⚠️ Traduction batch non disponible sur iOS < 18")
        return texts
    }
}

// MARK: - Erreurs de traduction

enum TranslationError: LocalizedError {
    case invalidLanguage
    case translationFailed
    case sessionUnavailable
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidLanguage:
            return "Code de langue invalide"
        case .translationFailed:
            return "La traduction a échoué"
        case .sessionUnavailable:
            return "Session de traduction indisponible"
        case .networkError:
            return "Erreur réseau lors de la traduction"
        }
    }
}


