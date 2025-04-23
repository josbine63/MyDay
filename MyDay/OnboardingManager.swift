// OnboardingManager.swift
import Foundation
import EventKit
import HealthKit
import Photos
import SwiftUI

@MainActor
class OnboardingManager: ObservableObject {
    @Published var calendarGranted = false
    @Published var reminderGranted = false
    @Published var photoGranted = false
    @Published var healthGranted = false

    @Published var isCompleted = false

    private let eventStore = EKEventStore()
    private let healthStore = HKHealthStore()

    func requestCalendar() async {
        let granted = await withCheckedContinuation { continuation in
            if #available(iOS 17, *) {
                eventStore.requestFullAccessToEvents { granted, _ in
                    continuation.resume(returning: granted)
                }
            } else {
                eventStore.requestAccess(to: .event) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
        calendarGranted = granted
        checkIfAllGranted()
    }

    func requestReminder() async {
        let granted = await withCheckedContinuation { continuation in
            if #available(iOS 17, *) {
                eventStore.requestFullAccessToReminders { granted, _ in
                    continuation.resume(returning: granted)
                }
            } else {
                eventStore.requestAccess(to: .reminder) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
        reminderGranted = granted
        checkIfAllGranted()
    }

    func requestPhotos() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        photoGranted = (status == .authorized || status == .limited)
        checkIfAllGranted()
    }

    func requestHealth() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            healthGranted = false
            checkIfAllGranted()
            return
        }

        let typesToRead: Set = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]

        let success = await withCheckedContinuation { continuation in
            healthStore.requestAuthorization(toShare: [], read: typesToRead) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
        healthGranted = success
        checkIfAllGranted()
    }

    private func checkIfAllGranted() {
        if calendarGranted && reminderGranted && photoGranted && healthGranted {
            isCompleted = true
            UserDefaults.appGroup.set(true, forKey: "hasLaunchedBefore")
        }
    }
}
