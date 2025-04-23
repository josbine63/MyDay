import HealthKit

class HealthManager: ObservableObject {
   private var healthStore = HKHealthStore()

   @Published var steps: Double = 0
   @Published var distance: Double = 0
   @Published var calories: Double = 0

   init() {
       requestAuthorization()
   }

   func requestAuthorization() {
       let typesToRead: Set = [
           HKObjectType.quantityType(forIdentifier: .stepCount)!,
           HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
           HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
       ]

       healthStore.requestAuthorization(toShare: [], read: typesToRead) { success, error in
           if !success {
               print("Authorization failed")
           }
       }
   }

   func fetchData(for date: Date) {
       steps = 0
       distance = 0
       calories = 0

       let calendar = Calendar.current
       guard let startOfDay = calendar.startOfDay(for: date) as NSDate?,
             let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay as Date)?.addingTimeInterval(-1) as NSDate? else {
           return
       }

       let predicate = HKQuery.predicateForSamples(withStart: startOfDay as Date, end: endOfDay as Date, options: .strictStartDate)

       fetchQuantity(for: .stepCount, predicate: predicate) { result in
           DispatchQueue.main.async {
               self.steps = result
           }
       }

       fetchQuantity(for: .distanceWalkingRunning, predicate: predicate) { result in
           DispatchQueue.main.async {
               self.distance = result / 1000 // Convert meters to kilometers
           }
       }

       fetchQuantity(for: .activeEnergyBurned, predicate: predicate) { result in
           DispatchQueue.main.async {
               self.calories = result
           }
       }
   }

   private func fetchQuantity(for identifier: HKQuantityTypeIdentifier, predicate: NSPredicate, completion: @escaping (Double) -> Void) {
       guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else {
           completion(0)
           return
       }

       let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
           guard let quantity = result?.sumQuantity() else {
               completion(0)
               return
           }
           let unit: HKUnit
           switch identifier {
           case .stepCount:
               unit = HKUnit.count()
           case .distanceWalkingRunning:
               unit = HKUnit.meter()
           case .activeEnergyBurned:
               unit = HKUnit.kilocalorie()
           default:
               unit = HKUnit.count()
           }
           completion(quantity.doubleValue(for: unit))
       }

       healthStore.execute(query)
   }
}