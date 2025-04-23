// PermissionChecklistManager.swift
import Foundation
import EventKit
import HealthKit
import Photos

@MainActor
class PermissionChecklistManager: ObservableObject {
    @Published var calendarGranted = false
    @Published var reminderGranted = false
    @Published var photoGranted = false
    @Published var healthGranted = false

    var allGranted: Bool {
        calendarGranted && reminderGranted && photoGranted && healthGranted
    }

    private let eventStore = EKEventStore()
    private let healthStore = HKHealthStore()

    init() {
        updateStatuses()
    }

    func updateStatuses() {
        objectWillChange.send() // 🔔 Force une mise à jour SwiftUI

        calendarGranted = EKEventStore.authorizationStatus(for: .event) == .fullAccess
        reminderGranted = EKEventStore.authorizationStatus(for: .reminder) == .fullAccess
        photoGranted = {
            let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            return status == .authorized || status == .limited
        }()
        healthGranted = HKHealthStore.isHealthDataAvailable() &&
                        UserDefaults.appGroup.bool(forKey: "healthPermissionGranted")
        
        print("✅ updateStatuses: allGranted = \(allGranted)")
    }
    
    func requestCalendar() {
        Task {
            if #available(iOS 17, *) {
                let granted = try? await eventStore.requestFullAccessToEvents()
                print("📅 Accès calendrier accordé : \(granted == true)")
            } else {
                let granted = await withCheckedContinuation { continuation in
                    eventStore.requestAccess(to: .event) { granted, _ in
                        continuation.resume(returning: granted)
                    }
                }
                print("📅 Accès calendrier accordé (iOS<17) : \(granted)")
            }
            updateStatuses()
        }
    }

    func requestReminders() {
        Task {
            if #available(iOS 17, *) {
                let granted = try? await eventStore.requestFullAccessToReminders()
                print("📋 Accès rappels accordé : \(granted == true)")
            } else {
                let granted = await withCheckedContinuation { continuation in
                    eventStore.requestAccess(to: .reminder) { granted, _ in
                        continuation.resume(returning: granted)
                    }
                }
                print("📋 Accès rappels accordé (iOS<17) : \(granted)")
            }
            updateStatuses()
        }
    }

    func requestPhotos() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            print("📸 Statut photo : \(status.rawValue)")
            DispatchQueue.main.async {
                self.updateStatuses()
            }
        }
    }

    func requestHealth() {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let typesToRead: Set = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]

        healthStore.requestAuthorization(toShare: [], read: typesToRead) { success, _ in
            print("💊 Accès santé accordé : \(success)")
            if success {
                UserDefaults.appGroup.set(true, forKey: "healthPermissionGranted")
            }
            DispatchQueue.main.async {
                self.updateStatuses()
            }
        }
    }
}
