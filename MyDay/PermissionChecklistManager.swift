import Foundation
import EventKit
import Photos
import HealthKit
import SwiftUI

class PermissionChecklistManager: ObservableObject {
    @Published var calendarGranted = false
    @Published var reminderGranted = false
    @Published var photoGranted = false
    @Published var healthGranted = false

    private let eventStore = EKEventStore()
    private let healthStore = HKHealthStore()

    var allGranted: Bool {
        calendarGranted && reminderGranted && photoGranted && healthGranted
    }

    init() {
        checkAllPermissions()
    }

    func checkAllPermissions() {
        checkCalendar()
        checkReminders()
        checkPhotos()
        checkHealth()
    }

    func checkCalendar() {
        let status = EKEventStore.authorizationStatus(for: .event)
        calendarGranted = status == .authorized
    }

    func checkReminders() {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        reminderGranted = status == .authorized
    }

    func checkPhotos() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        photoGranted = status == .authorized || status == .limited
    }

    func checkHealth() {
        guard HKHealthStore.isHealthDataAvailable() else {
            healthGranted = false
            return
        }
        let types: Set = [
            HKObjectType.quantityType(forIdentifier: .stepCount),
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)
        ].compactMap { $0 }

        healthStore.getRequestStatusForAuthorization(toShare: [], read: types) { status, _ in
            DispatchQueue.main.async {
                self.healthGranted = (status == .unnecessary || status == .shouldRequest)
            }
        }
    }

    func requestCalendar() {
        eventStore.requestAccess(to: .event) { granted, _ in
            DispatchQueue.main.async {
                self.calendarGranted = granted
            }
        }
    }

    func requestReminders() {
        eventStore.requestAccess(to: .reminder) { granted, _ in
            DispatchQueue.main.async {
                self.reminderGranted = granted
            }
        }
    }

    func requestPhotos() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                self.photoGranted = status == .authorized || status == .limited
            }
        }
    }

    func requestHealth() {
        let types: Set = [
            HKObjectType.quantityType(forIdentifier: .stepCount),
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)
        ].compactMap { $0 }

        healthStore.requestAuthorization(toShare: [], read: types) { success, _ in
            DispatchQueue.main.async {
                self.healthGranted = success
            }
        }
    }
}