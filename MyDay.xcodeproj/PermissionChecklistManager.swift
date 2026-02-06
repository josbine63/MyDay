//
//  PermissionChecklistManager.swift
//  MyDay
//
//  Created by Assistant on 2025-01-15.
//

import Foundation
import EventKit
import Photos
import HealthKit
import os.log

enum PermissionState {
    case unknown
    case granted
    case denied
}

@MainActor
class PermissionChecklistManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var calendarStatus: PermissionState = .unknown
    @Published var reminderStatus: PermissionState = .unknown
    @Published var photoStatus: PermissionState = .unknown
    @Published var healthStatus: PermissionState = .unknown
    
    var allGrantedState: Bool {
        calendarStatus == .granted &&
        reminderStatus == .granted &&
        photoStatus == .granted &&
        healthStatus == .granted
    }
    
    // MARK: - Private Properties
    
    private let eventStore = EKEventStore()
    private let healthStore = HKHealthStore()
    private let defaults = UserDefaults.appGroup
    
    // MARK: - Initialization
    
    init() {
        updateStatuses()
    }
    
    // MARK: - Status Update
    
    func updateStatuses() {
        updateCalendarStatus()
        updateReminderStatus()
        updatePhotoStatus()
        updateHealthStatus()
    }
    
    // MARK: - Calendar
    
    private func updateCalendarStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .fullAccess, .writeOnly, .authorized:
            calendarStatus = .granted
        case .denied, .restricted:
            calendarStatus = .denied
        case .notDetermined:
            calendarStatus = .unknown
        @unknown default:
            calendarStatus = .unknown
        }
    }
    
    func requestCalendar() {
        Task {
            do {
                let granted: Bool
                if #available(iOS 17.0, *) {
                    granted = try await eventStore.requestFullAccessToEvents()
                } else {
                    granted = try await eventStore.requestAccess(to: .event)
                }
                
                await MainActor.run {
                    calendarStatus = granted ? .granted : .denied
                    defaults.set(granted, forKey: UserDefaultsKeys.CalendarPermission)
                    Logger.app.info("📅 Calendrier: \(granted ? "accordé" : "refusé")")
                }
            } catch {
                Logger.app.error("❌ Erreur calendrier: \(error.localizedDescription)")
                await MainActor.run {
                    calendarStatus = .denied
                }
            }
        }
    }
    
    // MARK: - Reminders
    
    private func updateReminderStatus() {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        switch status {
        case .fullAccess, .writeOnly, .authorized:
            reminderStatus = .granted
        case .denied, .restricted:
            reminderStatus = .denied
        case .notDetermined:
            reminderStatus = .unknown
        @unknown default:
            reminderStatus = .unknown
        }
    }
    
    func requestReminders() {
        Task {
            do {
                let granted: Bool
                if #available(iOS 17.0, *) {
                    granted = try await eventStore.requestFullAccessToReminders()
                } else {
                    granted = try await eventStore.requestAccess(to: .reminder)
                }
                
                await MainActor.run {
                    reminderStatus = granted ? .granted : .denied
                    defaults.set(granted, forKey: UserDefaultsKeys.ReminderPermission)
                    Logger.app.info("✅ Rappels: \(granted ? "accordé" : "refusé")")
                }
            } catch {
                Logger.app.error("❌ Erreur rappels: \(error.localizedDescription)")
                await MainActor.run {
                    reminderStatus = .denied
                }
            }
        }
    }
    
    // MARK: - Photos
    
    private func updatePhotoStatus() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            photoStatus = .granted
        case .denied, .restricted:
            photoStatus = .denied
        case .notDetermined:
            photoStatus = .unknown
        @unknown default:
            photoStatus = .unknown
        }
    }
    
    func requestPhotos() {
        Task {
            let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            
            await MainActor.run {
                switch status {
                case .authorized, .limited:
                    photoStatus = .granted
                    defaults.set(true, forKey: UserDefaultsKeys.PhotoPermission)
                    Logger.app.info("🖼️ Photos: accordées")
                default:
                    photoStatus = .denied
                    defaults.set(false, forKey: UserDefaultsKeys.PhotoPermission)
                    Logger.app.info("🖼️ Photos: refusées")
                }
            }
        }
    }
    
    // MARK: - Health
    
    private func updateHealthStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            healthStatus = .denied
            return
        }
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let status = healthStore.authorizationStatus(for: stepType)
        
        switch status {
        case .sharingAuthorized:
            healthStatus = .granted
        case .sharingDenied:
            healthStatus = .denied
        case .notDetermined:
            healthStatus = .unknown
        @unknown default:
            healthStatus = .unknown
        }
    }
    
    func requestHealth() {
        guard HKHealthStore.isHealthDataAvailable() else {
            healthStatus = .denied
            return
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        Task {
            do {
                try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
                
                await MainActor.run {
                    // Revérifier le statut après la demande
                    updateHealthStatus()
                    defaults.set(healthStatus == .granted, forKey: UserDefaultsKeys.HealthPermission)
                    Logger.app.info("❤️ Santé: \(healthStatus == .granted ? "accordé" : "refusé")")
                }
            } catch {
                Logger.app.error("❌ Erreur santé: \(error.localizedDescription)")
                await MainActor.run {
                    healthStatus = .denied
                }
            }
        }
    }
}
