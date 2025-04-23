// MARK: - PermissionManager
@MainActor
class PermissionManager: ObservableObject {
    @Published var allAccessGranted = false
    private let eventStore = EKEventStore()
    private let healthStore = HKHealthStore()

    func requestAllPermissions() async -> Bool {
        async let calendarGranted = requestFullCalendarAccess()
        async let reminderGranted = requestFullReminderAccess()
        async let photoGranted = requestPhotoAccess()
        async let healthGranted = requestHealthAccess()

        let results = await [calendarGranted, reminderGranted, photoGranted, healthGranted]
        allAccessGranted = results.allSatisfy { $0 }
        return allAccessGranted
    }
    
    private func requestFullCalendarAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            return await withCheckedContinuation { continuation in
                eventStore.requestFullAccessToEvents { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        } else {
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    private func requestFullReminderAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            return await withCheckedContinuation { continuation in
                eventStore.requestFullAccessToReminders { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        } else {
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .reminder) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    private func requestPhotoAccess() async -> Bool {
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization { status in
                continuation.resume(returning: status == .authorized || status == .limited)
            }
        }
    }

    private func requestHealthAccess() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]

        return await withCheckedContinuation { continuation in
            healthStore.requestAuthorization(toShare: [], read: typesToRead) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }
}
