//
//  Utilities.swift
//  MyDay
//
//  Created by Assistant on 2025-01-15.
//

import Foundation
import UIKit
import EventKit

// MARK: - EventKit Helpers

/// Utilitaires pour EventKit
enum EventKitHelpers {
    
    /// Détermine si un calendrier EventKit est partagé
    /// Note: EventKit ne fournit pas directement `sharees` sur iOS
    /// Cette implémentation utilise une détection par convention de nommage
    /// Les calendriers contenant certains mots-clés dans leur titre seront marqués comme partagés
    static func isCalendarShared(_ calendar: EKCalendar) -> Bool {
        // Exclure les calendriers en lecture seule (abonnements)
        guard calendar.allowsContentModifications else {
            return false
        }
        
        // Exclure les calendriers système (Anniversaires, Médicaments, etc.)
        let systemCalendarTitles = [
            "Anniversaires", "Birthdays",
            "Jours fériés", "Holidays", "Holiday",
            "Médicaments", "Medications",
            "Sommeil", "Sleep",
            "Siri Suggestions"
        ]
        
        if systemCalendarTitles.contains(where: { calendar.title.contains($0) }) {
            return false
        }
        
        // Exclure les calendriers de type "Birthday" (anniversaires système)
        if calendar.type == .birthday {
            return false
        }
        
        // ✅ OPTION 3: Détection par convention de nommage
        // Les calendriers contenant ces mots-clés seront marqués comme partagés
        let sharedKeywords = [
            // Français
            "Partagé", "Partage",
            "Famille", "Familial",
            "Équipe", "Equipe",
            "Couple",
            "Travail", "Bureau",
            "Groupe",
            "Collectif",
            "Commun",
            // Anglais
            "Shared", "Share",
            "Family",
            "Team",
            "Work", "Office",
            "Group",
            "Collective",
            "Common",
            "Together"
        ]
        
        let titleLower = calendar.title.lowercased()
        return sharedKeywords.contains { titleLower.contains($0.lowercased()) }
    }
}

// MARK: - Date Formatting

/// Utilitaires de formatage de dates
enum DateFormatting {
    
    /// Retourne le nom du jour (ex: "Lundi")
    static func dayName(from date: Date, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date).capitalized
    }
    
    /// Retourne la date complète (ex: "15 janvier 2026")
    static func fullDate(from date: Date, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    /// Retourne la clé de date pour le stockage (ex: "2026-01-15")
    static func storageKey(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - Deep Links

/// Gestion des liens profonds vers les apps système
enum DeepLinks {
    
    /// Ouvre l'app Météo
    static func openWeather() {
        if let url = URL(string: "weather://"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    /// Ouvre l'app Santé (page principale)
    static func openHealth() {
        if let url = URL(string: "activitytoday://") {
            UIApplication.shared.open(url)
        }
    }
    
    /// Ouvre l'app Santé (page médicaments)
    static func openHealthMedications() {
        if let url = URL(string: "x-apple-health://MedicationsHealthAppPlugin.healthplugin") {
            UIApplication.shared.open(url)
        }
    }
    
    /// Ouvre l'app Calendrier pour une date spécifique
    static func openCalendar(for date: Date) {
        let url = URL(string: "calshow:\(date.timeIntervalSinceReferenceDate)")!
        UIApplication.shared.open(url)
    }
    
    /// Ouvre l'app Rappels
    static func openReminders() {
        if let url = URL(string: "x-apple-reminderkit://") {
            UIApplication.shared.open(url)
        }
    }
    
    /// Ouvre les Réglages de l'app
    static func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Distance Formatting

/// Utilitaires de formatage de distances
enum DistanceFormatting {
    
    /// Formate une distance en mètres selon le système d'unités
    static func format(meters: Double, usesMetric: Bool) -> String {
        if meters < 1 {
            return usesMetric ? "0 m" : "0 ft"
        }
        
        if usesMetric {
            return formatMetric(meters: meters)
        } else {
            return formatImperial(meters: meters)
        }
    }
    
    private static func formatMetric(meters: Double) -> String {
        if meters < 1000 {
            return String(format: "%.0f m", meters)
        } else {
            let km = meters / 1000
            return String(format: "%.2f km", km)
        }
    }
    
    private static func formatImperial(meters: Double) -> String {
        let feet = meters * 3.28084
        if feet < 2500 {
            return String(format: "%.0f ft", feet)
        } else {
            let miles = meters / 1609.34
            return String(format: "%.2f mi", miles)
        }
    }
}

// MARK: - Localization Helpers

/// Aide pour la localisation
enum LocalizationHelpers {
    
    /// Retourne le texte "Chargement..." dans la langue préférée
    static var loadingText: String {
        let lang = Locale.preferredLanguages.first ?? "en"
        return lang.hasPrefix("fr") ? "Chargement..." : "Loading..."
    }
    
    /// Vérifie si la langue actuelle est le français
    static var isFrench: Bool {
        let lang = Locale.preferredLanguages.first ?? "en"
        return lang.hasPrefix("fr")
    }
    
    /// Vérifie si la langue actuelle est l'anglais
    static var isEnglish: Bool {
        let lang = Locale.preferredLanguages.first ?? "en"
        return lang.hasPrefix("en")
    }
}

// MARK: - Validation

/// Utilitaires de validation
enum Validation {
    
    /// Vérifie si un texte n'est pas vide après trim
    static func isNotEmpty(_ text: String) -> Bool {
        return !text.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    /// Vérifie si un UUID est valide
    static func isValidUUID(_ string: String) -> Bool {
        return UUID(uuidString: string) != nil
    }
}

// MARK: - Network Helpers

/// Aide pour les requêtes réseau
enum NetworkHelpers {
    
    /// URL de l'API de citations
    static let quoteAPIURL = URL(string: "https://zenquotes.io/api/random")!
    
    /// Timeout par défaut pour les requêtes
    static let defaultTimeout: TimeInterval = 10.0
}
