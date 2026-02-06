import Foundation
import HealthKit

@MainActor
class HealthManager: ObservableObject {
    private let healthStore = HKHealthStore()

    @Published var steps: Double = 0
    @Published var distance: Double = 0
    @Published var calories: Double = 0
 
    @MainActor
    func fetchData(for date: Date) {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("❌ HealthKit non disponible")
            return
        }
        
        // ✅ Si la date est dans le futur, mettre les stats à zéro
        let calendar = Calendar.current
        if calendar.startOfDay(for: date) > calendar.startOfDay(for: Date()) {
            print("📅 Date dans le futur - Stats à zéro")
            self.steps = 0
            self.distance = 0
            self.calories = 0
            return
        }

        let typesToRead: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]

        healthStore.requestAuthorization(toShare: [], read: typesToRead) { success, error in
            if success {
                // 🚀 OPTIMISATION: Requêtes parallèles au lieu de séquentielles
                Task { @MainActor in
                    async let stepsTask = self.fetchStepsAsync(for: date)
                    async let distanceTask = self.fetchDistanceAsync(for: date)
                    async let caloriesTask = self.fetchCaloriesAsync(for: date)
                    
                    // Attendre que toutes les requêtes se terminent
                    await (stepsTask, distanceTask, caloriesTask)
                }
            } else if let error = error {
                print("❌ Erreur d'autorisation HealthKit: \(error.localizedDescription)")
            }
        }
    }

    private func predicate(for date: Date) -> NSPredicate {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!

        return HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
    }

    private func fetchSteps(for date: Date) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }

        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate(for: date), options: .cumulativeSum) { _, result, _ in
            guard let result, let sum = result.sumQuantity() else { return }
            DispatchQueue.main.async {
                self.steps = sum.doubleValue(for: HKUnit.count())
            }
        }

        healthStore.execute(query)
    }
    
    // 🚀 OPTIMISATION: Version async pour parallélisation
    private func fetchStepsAsync(for date: Date) async {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate(for: date), options: .cumulativeSum) { _, result, _ in
                if let result, let sum = result.sumQuantity() {
                    DispatchQueue.main.async {
                        self.steps = sum.doubleValue(for: HKUnit.count())
                    }
                }
                continuation.resume()
            }
            healthStore.execute(query)
        }
    }

    func fetchDistance(for date: Date) {
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            print("❌ Type distance non disponible")
            return
        }

        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                DispatchQueue.main.async {
                    self.distance = 0.0
                }
                return
            }

            let meters = sum.doubleValue(for: .meter())
            DispatchQueue.main.async {
                self.distance = meters
            }
        }

        healthStore.execute(query)
    }
    
    // 🚀 OPTIMISATION: Version async pour parallélisation
    private func fetchDistanceAsync(for date: Date) async {
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            print("❌ Type distance non disponible")
            return
        }

        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
                if let result = result, let sum = result.sumQuantity() {
                    let meters = sum.doubleValue(for: .meter())
                    DispatchQueue.main.async {
                        self.distance = meters
                    }
                } else {
                    DispatchQueue.main.async {
                        self.distance = 0.0
                    }
                }
                continuation.resume()
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchCalories(for date: Date) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }

        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate(for: date), options: .cumulativeSum) { _, result, _ in
            guard let result, let sum = result.sumQuantity() else { return }
            DispatchQueue.main.async {
                self.calories = sum.doubleValue(for: HKUnit.kilocalorie())
            }
        }

        healthStore.execute(query)
    }
    
    // 🚀 OPTIMISATION: Version async pour parallélisation
    private func fetchCaloriesAsync(for date: Date) async {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        
        await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate(for: date), options: .cumulativeSum) { _, result, _ in
                if let result, let sum = result.sumQuantity() {
                    DispatchQueue.main.async {
                        self.calories = sum.doubleValue(for: HKUnit.kilocalorie())
                    }
                }
                continuation.resume()
            }
            healthStore.execute(query)
        }
    }
}
