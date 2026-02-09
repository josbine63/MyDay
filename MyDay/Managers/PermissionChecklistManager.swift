
import Foundation
import EventKit
import HealthKit
import Photos
import os.log

enum PermissionState {
    case unknown
    case granted
    case denied
}

@MainActor
class PermissionChecklistManager: ObservableObject {
    @Published var calendarStatus: PermissionState = .unknown
    @Published var reminderStatus: PermissionState = .unknown
    @Published var photoStatus: PermissionState = .unknown
    @Published var healthStatus: PermissionState = .unknown

    @Published var allGrantedState: Bool = false

    private let eventStore = SharedEventStore.shared
    private let healthStore = HKHealthStore()
    
    private let logger = Logger(subsystem: "com.yourapp.myday", category: "Permissions")

    func updateStatuses() {
        // Calendrier
        let calendarAuth = EKEventStore.authorizationStatus(for: .event)
        switch calendarAuth {
        case .notDetermined: calendarStatus = .unknown
        case .fullAccess: calendarStatus = .granted
        default: calendarStatus = .denied
        }

        // Rappels
        let reminderAuth = EKEventStore.authorizationStatus(for: .reminder)
        switch reminderAuth {
        case .notDetermined: reminderStatus = .unknown
        case .fullAccess: reminderStatus = .granted
        default: reminderStatus = .denied
        }

        // Photos
        let photoAuth = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch photoAuth {
        case .notDetermined: photoStatus = .unknown
        case .authorized: photoStatus = .granted
        default: photoStatus = .denied
        }
        
        // Pour HealthKit, on teste l'accès réel aux données
        // (Cette méthode appelle refreshAllGranted() quand elle termine)
        checkHealthDataAccess()
    }
    
    private func checkHealthDataAccess(retry: Bool = true) {
        guard HKHealthStore.isHealthDataAvailable() else {
            healthStatus = .denied
            refreshAllGranted()
            return
        }
        
        // ⚠️ STRATÉGIE AMÉLIORÉE : Tester chaque type de données individuellement
        // pour détecter si AU MOINS UNE permission a été retirée
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        
        // Test des 3 types de données requis en parallèle
        let group = DispatchGroup()
        var stepGranted = false
        var distanceGranted = false
        var caloriesGranted = false
        var hasTimedOut = false
        
        // 🕐 Timeout global de 2 secondes
        let timeoutWorkItem = DispatchWorkItem { [weak self] in
            guard let self = self, !hasTimedOut else { return }
            hasTimedOut = true
            Task { @MainActor in
                // Si timeout, on considère que l'accès est refusé
                self.healthStatus = .denied
                self.refreshAllGranted()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: timeoutWorkItem)
        
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: yesterday, end: now, options: .strictStartDate)
        
        // Test 1: Steps
        group.enter()
        let stepsQuery = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            stepGranted = (error == nil)
            group.leave()
        }
        healthStore.execute(stepsQuery)
        
        // Test 2: Distance
        group.enter()
        let distanceQuery = HKStatisticsQuery(
            quantityType: distanceType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            distanceGranted = (error == nil)
            group.leave()
        }
        healthStore.execute(distanceQuery)
        
        // Test 3: Calories
        group.enter()
        let caloriesQuery = HKStatisticsQuery(
            quantityType: caloriesType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            caloriesGranted = (error == nil)
            group.leave()
        }
        healthStore.execute(caloriesQuery)
        
        // Attendre la fin de tous les tests
        group.notify(queue: .main) { [weak self] in
            guard let self = self, !hasTimedOut else { return }
            hasTimedOut = true
            timeoutWorkItem.cancel()
            
            Task { @MainActor in
                self.logger.info("📊 Résultats vérification Santé - Steps: \(stepGranted), Distance: \(distanceGranted), Calories: \(caloriesGranted)")
                
                // ✅ TOUS les types doivent être autorisés pour considérer l'accès comme accordé
                if stepGranted && distanceGranted && caloriesGranted {
                    self.logger.info("✅ Santé: Tous les accès accordés")
                    self.healthStatus = .granted
                } else if !stepGranted && !distanceGranted && !caloriesGranted {
                    if retry {
                        // Première tentative échouée — réessayer après un délai (iPhone peut avoir besoin de temps)
                        self.logger.info("⚠️ Santé: Aucun accès - Réessai après 500ms...")
                        try? await Task.sleep(for: .milliseconds(500))
                        self.checkHealthDataAccess(retry: false)
                    } else {
                        // Deuxième tentative échouée — test final avec authorizationStatus
                        self.logger.info("⚠️ Santé: Aucun accès après réessai - Test final...")
                        self.performFinalHealthCheck()
                    }
                    return
                } else {
                    // Si au moins un type est refusé mais pas tous, c'est "denied"
                    self.logger.warning("❌ Santé: Accès partiel refusé")
                    self.healthStatus = .denied
                }
                self.refreshAllGranted()
            }
        }
    }
    
    /// Test final pour distinguer entre "not determined" et "denied"
    private func performFinalHealthCheck() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let status = healthStore.authorizationStatus(for: stepType)
        
        logger.info("🔍 Test final Santé - Status API: \(String(describing: status))")
        
        // Si le statut est explicitement "sharingDenied", c'est refusé
        if status == .sharingDenied {
            logger.warning("❌ Santé: Explicitement refusé")
            healthStatus = .denied
        } else {
            // Sinon, on considère que ce n'est pas encore déterminé
            logger.info("❓ Santé: Non déterminé")
            healthStatus = .unknown
        }
        refreshAllGranted()
    }
    
    func requestCalendar() {
        requestCalendarPermission()
    }

    func requestReminders() {
        requestRemindersPermission()
    }

    func requestPhotos() {
        requestPhotosPermission()
    }
    
    func requestHealth() {
        requestHealthPermission()
    }
    
    /// Force une mise à jour immédiate du statut de santé
    /// Utile après un retour des Réglages système
    func forceHealthStatusRefresh() {
        logger.info("🔄 Forçage du rafraîchissement du statut santé...")
        checkHealthDataAccess()
    }
    
    // Fonctions privées qui font réellement la demande de permission
    private func requestCalendarPermission() {
        eventStore.requestFullAccessToEvents { granted, _ in
            Task { @MainActor in
                self.calendarStatus = granted ? .granted : .denied
                self.refreshAllGranted()
            }
        }
    }

    private func requestRemindersPermission() {
        eventStore.requestFullAccessToReminders { granted, _ in
            Task { @MainActor in
                self.reminderStatus = granted ? .granted : .denied
                self.refreshAllGranted()
            }
        }
    }

    private func requestPhotosPermission() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            Task { @MainActor in
                self.photoStatus = (status == .authorized) ? .granted : .denied
                self.refreshAllGranted()
            }
        }
    }
    
    private func requestHealthPermission() {
        guard HKHealthStore.isHealthDataAvailable() else {
            healthStatus = .denied
            refreshAllGranted()
            return
        }

        let typesToRead: Set = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]

        healthStore.requestAuthorization(toShare: [], read: typesToRead) { [weak self] success, _ in
            Task { @MainActor in
                guard let self = self else { return }
                if !success {
                    // Autorisation refusée (ou déjà refusée) — pas besoin de vérifier
                    self.healthStatus = .denied
                    self.refreshAllGranted()
                } else {
                    // Vérifier immédiatement — le retry dans checkHealthDataAccess
                    // gérera la race condition si les permissions ne sont pas encore propagées
                    self.checkHealthDataAccess()
                    
                    // ✅ IMPORTANT: Activer automatiquement l'affichage Santé quand la permission est accordée
                    // Cela évite le bug où l'utilisateur autorise dans l'onboarding mais ne voit rien
                    UserSettings.shared.setShowHealth(true)
                    self.logger.info("✅ Permission Santé accordée - Affichage automatiquement activé")
                }
            }
        }
    }

    private func refreshAllGranted() {
        // Seules Calendrier et Rappels sont requises au démarrage.
        // Photos et Santé sont demandées à la première activation dans les Réglages.
        let value = [calendarStatus, reminderStatus].allSatisfy { $0 == .granted }
        allGrantedState = value
        UserDefaultsManager.set(value, forKey: UserDefaultsKeys.PermissionsAllGranted)
    }
}
