//
//  EventCacheManager.swift
//  MyDay
//
//  Created by Assistant on 2026-01-26.
//
//  Gestionnaire de cache pour les événements et rappels
//  Réduit les appels répétés à EventKit et améliore les performances

import Foundation
import EventKit
import os.log

/// Cache intelligent pour les événements et rappels
@MainActor
final class EventCacheManager: ObservableObject {
    
    static let shared = EventCacheManager()
    
    // MARK: - Published Properties
    
    @Published private(set) var isLoading = false
    @Published private(set) var lastUpdateDate: Date?
    @Published private(set) var cacheVersion = 0 // ✨ Pour forcer le rafraîchissement des vues
    
    // MARK: - Cache Storage
    
    private var eventCache: [String: [AgendaItem]] = [:] // Clé = date (yyyy-MM-dd)
    private var reminderCache: [String: [EKReminder]] = [:] // Clé = date (yyyy-MM-dd)
    private var cacheExpiration: [String: Date] = [:] // Clé = date, Valeur = date d'expiration
    
    // MARK: - Configuration
    
    private let cacheLifetime: TimeInterval = 1800 // 30 minutes - Optimisé pour réduire les rechargements
    private let preloadDays = 7 // Nombre de jours à précharger
    
    // MARK: - Logger
    
    private let logger = Logger(subsystem: "com.josblais.myday", category: "EventCache")
    
    // MARK: - Initializer
    
    private init() {
        logger.info("📦 EventCacheManager initialisé")
    }
    
    // MARK: - Cache Management
    
    /// Vérifie si le cache est valide pour une date donnée
    func isCacheValid(for date: Date) -> Bool {
        let key = dateKey(for: date)
        guard let expiration = cacheExpiration[key] else {
            return false
        }
        return Date() < expiration
    }
    
    /// Récupère les événements depuis le cache si disponible
    func getCachedEvents(for date: Date) -> [AgendaItem]? {
        let key = dateKey(for: date)
        guard isCacheValid(for: date) else {
            logger.debug("⚠️ Cache expiré pour \(key)")
            return nil
        }
        logger.debug("✅ Cache hit pour \(key)")
        return eventCache[key]
    }
    
    /// Stocke les événements dans le cache
    func cacheEvents(_ events: [AgendaItem], for date: Date) {
        let key = dateKey(for: date)
        eventCache[key] = events
        cacheExpiration[key] = Date().addingTimeInterval(cacheLifetime)
        cacheVersion += 1 // ✨ Incrémenter pour notifier les observateurs
        logger.debug("💾 Cache mis à jour pour \(key) (\(events.count) items)")
    }
    
    /// Invalide le cache pour une date spécifique
    func invalidateCache(for date: Date) {
        let key = dateKey(for: date)
        eventCache.removeValue(forKey: key)
        reminderCache.removeValue(forKey: key)
        cacheExpiration.removeValue(forKey: key)
        logger.debug("🗑️ Cache invalidé pour \(key)")
    }
    
    /// Invalide tout le cache
    func invalidateAllCache() {
        eventCache.removeAll()
        reminderCache.removeAll()
        cacheExpiration.removeAll()
        logger.info("🗑️ Tout le cache a été invalidé")
    }
    
    /// Nettoie les caches expirés
    func cleanExpiredCache() {
        let now = Date()
        let expiredKeys = cacheExpiration.filter { $0.value < now }.map { $0.key }
        
        for key in expiredKeys {
            eventCache.removeValue(forKey: key)
            reminderCache.removeValue(forKey: key)
            cacheExpiration.removeValue(forKey: key)
        }
        
        if !expiredKeys.isEmpty {
            logger.info("🧹 \(expiredKeys.count) entrées de cache expirées nettoyées")
        }
    }
    
    // MARK: - Preloading
    
    /// Précharge les événements pour les N prochains jours à partir d'une date donnée
    func preloadEvents(
        from startDate: Date,
        days: Int = 7,
        calendarSelectionManager: CalendarSelectionManager,
        reminderSelectionManager: ReminderSelectionManager
    ) async {
        guard !isLoading else {
            logger.warning("⚠️ Préchargement déjà en cours")
            return
        }
        
        isLoading = true
        logger.info("🔄 Début du préchargement (\(days) jours depuis \(self.dateKey(for: startDate)))")
        
        let calendar = Calendar.current
        
        // ✨ Charger tous les jours en parallèle avec TaskGroup
        await withTaskGroup(of: (Date, [AgendaItem]).self) { group in
            for dayOffset in 0..<days {
                guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else {
                    continue
                }
                
                // Vérifier si le cache est déjà valide
                if isCacheValid(for: targetDate) {
                    logger.debug("✅ Cache déjà valide pour jour +\(dayOffset)")
                    continue
                }
                
                // Charger les événements pour cette date en parallèle
                group.addTask {
                    let items = await self.loadEventsForDate(
                        date: targetDate,
                        calendarSelectionManager: calendarSelectionManager,
                        reminderSelectionManager: reminderSelectionManager
                    )
                    return (targetDate, items)
                }
            }
            
            // ✨ Collecter tous les résultats et mettre le cache à jour d'un coup
            for await (date, items) in group {
                let key = dateKey(for: date)
                eventCache[key] = items
                cacheExpiration[key] = Date().addingTimeInterval(cacheLifetime)
                logger.debug("💾 Cache collecté pour \(key) (\(items.count) items)")
            }
        }
        
        // ✨ Une seule notification après tout le chargement
        cacheVersion += 1
        isLoading = false
        lastUpdateDate = Date()
        logger.info("✅ Préchargement terminé - \(days) jours chargés depuis \(self.dateKey(for: startDate))")
    }
    
    /// Précharge les événements pour les N prochains jours (à partir d'aujourd'hui)
    func preloadEvents(
        calendarSelectionManager: CalendarSelectionManager,
        reminderSelectionManager: ReminderSelectionManager
    ) async {
        await preloadEvents(
            from: Date(),
            days: preloadDays,
            calendarSelectionManager: calendarSelectionManager,
            reminderSelectionManager: reminderSelectionManager
        )
    }
    
    /// Charge les événements pour une date spécifique et retourne le résultat
    private func loadEventsForDate(
        date: Date,
        calendarSelectionManager: CalendarSelectionManager,
        reminderSelectionManager: ReminderSelectionManager
    ) async -> [AgendaItem] {
        let eventStore = SharedEventStore.shared
        let selectedCalendarIDs = calendarSelectionManager.selectedCalendarIDs
        
        let calendars = eventStore.calendars(for: .event).filter {
            selectedCalendarIDs.contains($0.calendarIdentifier)
        }
        
        let startDate = Calendar.current.startOfDay(for: date)
        let endDate = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: date) ?? startDate
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        
        let events = eventStore.events(matching: predicate)
            .filter { Calendar.current.isDate($0.startDate, inSameDayAs: date) }
            .map {
                AgendaItem(
                    title: $0.title,
                    date: $0.startDate,
                    isEvent: true,
                    reminderID: nil,
                    eventID: $0.eventIdentifier,
                    isShared: EventKitHelpers.isCalendarShared($0.calendar)
                )
            }
        
        // Charger les rappels
        let reminders = await loadReminders(
            for: date,
            reminderSelectionManager: reminderSelectionManager
        )
        
        let reminderItems: [AgendaItem] = reminders.compactMap { reminder in
            guard let components = reminder.dueDateComponents else { return nil }
            
            var fixedComponents = components
            if fixedComponents.hour == nil { fixedComponents.hour = 8 }
            if fixedComponents.minute == nil { fixedComponents.minute = 0 }
            if fixedComponents.second == nil { fixedComponents.second = 0 }
            
            guard let reminderDate = Calendar.current.date(from: fixedComponents) else { return nil }
            
            return AgendaItem(
                title: reminder.title ?? "Rappel",
                date: reminderDate,
                isEvent: false,
                reminderID: reminder.calendarItemIdentifier,
                isShared: EventKitHelpers.isCalendarShared(reminder.calendar)
            )
        }
        
        let allItems = (events + reminderItems).sorted { $0.date < $1.date }
        logger.debug("📦 Items préparés pour \(self.dateKey(for: date)): \(events.count) événements + \(reminderItems.count) rappels = \(allItems.count) items")
        
        return allItems
    }
    
    /// Charge les événements pour une date spécifique (ancienne méthode pour compatibilité)
    private func loadEvents(
        for date: Date,
        calendarSelectionManager: CalendarSelectionManager,
        reminderSelectionManager: ReminderSelectionManager
    ) async {
        let items = await loadEventsForDate(
            date: date,
            calendarSelectionManager: calendarSelectionManager,
            reminderSelectionManager: reminderSelectionManager
        )
        cacheEvents(items, for: date)
    }
    
    /// Charge les rappels pour une date spécifique
    private func loadReminders(
        for date: Date,
        reminderSelectionManager: ReminderSelectionManager
    ) async -> [EKReminder] {
        return await withCheckedContinuation { continuation in
            let eventStore = SharedEventStore.shared
            let localCal = Calendar.current
            
            // ✅ Charger UNIQUEMENT les calendriers sélectionnés
            let selectedCalendars = eventStore.calendars(for: .reminder).filter { calendar in
                reminderSelectionManager.selectedReminderListIDs.contains(calendar.calendarIdentifier)
            }
            
            let predicate = eventStore.predicateForReminders(in: selectedCalendars.isEmpty ? nil : selectedCalendars)
            
            eventStore.fetchReminders(matching: predicate) { reminders in
                guard let reminders = reminders else {
                    continuation.resume(returning: [])
                    return
                }
                
                let selectedIDs = reminderSelectionManager.selectedReminderListIDs
                var matchingReminders: [EKReminder] = []
                
                self.logger.debug("🔍 loadReminders - Total rappels reçus pour \(self.dateKey(for: date)): \(reminders.count)")
                
                for reminder in reminders {
                    guard let calendar = reminder.calendar,
                          selectedIDs.contains(calendar.calendarIdentifier)
                    else {
                        continue
                    }
                    
                    let isRecurring = !(reminder.recurrenceRules?.isEmpty ?? true)
                    
                    // ✅ Modification: Garder les rappels complétés le jour sélectionné
                    if reminder.isCompleted {
                        if !isRecurring {
                            // Pour les rappels non-récurrents complétés :
                            // Les garder visibles seulement s'ils ont été complétés le jour sélectionné
                            if let completionDate = reminder.completionDate {
                                let wasCompletedOnSelectedDate = localCal.isDate(completionDate, inSameDayAs: date)
                                if !wasCompletedOnSelectedDate {
                                    continue // Masquer si complété un autre jour
                                }
                            } else {
                                continue // Pas de date de complétion, on masque
                            }
                        }
                    }
                    
                    // Vérifier la date d'échéance
                    guard var comps = reminder.dueDateComponents else {
                        continue
                    }
                    
                    // ✅ Toujours utiliser le calendrier local pour la cohérence
                    if comps.hour == nil { comps.hour = 8 }
                    if comps.minute == nil { comps.minute = 0 }
                    if comps.second == nil { comps.second = 0 }
                    
                    guard let rebuiltDate = localCal.date(from: comps) else {
                        continue
                    }
                    
                    // ✅ Pour les rappels récurrents, vérifier s'ils se produisent ce jour-là
                    let matches = isRecurring ? 
                        self.reminderOccursOn(reminder: reminder, date: date, calendar: localCal) :
                        localCal.isDate(rebuiltDate, inSameDayAs: date)
                    
                    if matches {
                        matchingReminders.append(reminder)
                    }
                }
                
                self.logger.debug("📝 loadReminders - Rappels filtrés: \(matchingReminders.count) pour \(self.dateKey(for: date))")
                continuation.resume(returning: matchingReminders)
            }
        }
    }
    
    /// Vérifie si un rappel récurrent se produit à une date donnée
    private func reminderOccursOn(reminder: EKReminder, date: Date, calendar: Calendar) -> Bool {
        guard let dueDateComponents = reminder.dueDateComponents else {
            return false
        }
        
        var fixedComponents = dueDateComponents
        if fixedComponents.hour == nil { fixedComponents.hour = 8 }
        if fixedComponents.minute == nil { fixedComponents.minute = 0 }
        if fixedComponents.second == nil { fixedComponents.second = 0 }
        
        guard let dueDate = calendar.date(from: fixedComponents) else {
            return false
        }
        
        // Vérifier si la date cible est après ou égale à la date de début
        guard date >= calendar.startOfDay(for: dueDate) else {
            return false
        }
        
        // Vérifier chaque règle de récurrence
        guard let recurrenceRules = reminder.recurrenceRules else {
            return false
        }
        
        for rule in recurrenceRules {
            if recurrenceRuleMatches(rule: rule, startDate: dueDate, targetDate: date, calendar: calendar) {
                return true
            }
        }
        
        return false
    }
    
    /// Vérifie si une règle de récurrence correspond à une date cible
    private func recurrenceRuleMatches(rule: EKRecurrenceRule, startDate: Date, targetDate: Date, calendar: Calendar) -> Bool {
        // Si la règle a une date de fin et que la cible est après, retourner false
        if let endDate = rule.recurrenceEnd?.endDate,
           targetDate > endDate {
            return false
        }
        
        switch rule.frequency {
        case .daily:
            let daysDifference = calendar.dateComponents([.day], from: startDate, to: targetDate).day ?? 0
            return daysDifference >= 0 && daysDifference % rule.interval == 0
            
        case .weekly:
            let weeksDifference = calendar.dateComponents([.weekOfYear], from: startDate, to: targetDate).weekOfYear ?? 0
            let isSameWeekday = calendar.component(.weekday, from: startDate) == calendar.component(.weekday, from: targetDate)
            return weeksDifference >= 0 && weeksDifference % rule.interval == 0 && isSameWeekday
            
        case .monthly:
            let monthsDifference = calendar.dateComponents([.month], from: startDate, to: targetDate).month ?? 0
            let isSameDayOfMonth = calendar.component(.day, from: startDate) == calendar.component(.day, from: targetDate)
            return monthsDifference >= 0 && monthsDifference % rule.interval == 0 && isSameDayOfMonth
            
        case .yearly:
            let yearsDifference = calendar.dateComponents([.year], from: startDate, to: targetDate).year ?? 0
            let startComponents = calendar.dateComponents([.month, .day], from: startDate)
            let targetComponents = calendar.dateComponents([.month, .day], from: targetDate)
            return yearsDifference >= 0 && 
                   yearsDifference % rule.interval == 0 && 
                   startComponents.month == targetComponents.month &&
                   startComponents.day == targetComponents.day
            
        @unknown default:
            return false
        }
    }
    
    // MARK: - Helpers
    
    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

