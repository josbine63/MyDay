import Foundation
import HealthKit

@MainActor
class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()

    @Published var yesterdayMedications: [HKClinicalRecord] = []

    func requestHealthKitAccess() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("❌ HealthKit non disponible")
            return
        }

        if #available(iOS 17.0, *) {
            guard let medicationType = HKObjectType.clinicalType(forIdentifier: .medicationRecord) else { return }

            do {
                try await healthStore.requestAuthorization(toShare: [], read: [medicationType])
                print("✅ Autorisation HealthKit OK")
                await fetchMedicationRecordsFromYesterday()
            } catch {
                print("❌ Erreur d'autorisation HealthKit : \(error.localizedDescription)")
            }
        }
    }

    func fetchMedicationRecordsFromYesterday() async {
        guard #available(iOS 17.0, *) else { return }
        guard let type = HKObjectType.clinicalType(forIdentifier: .medicationRecord) else { return }

        let calendar = Calendar.current
        let startOfYesterday = calendar.startOfDay(for: Date().addingTimeInterval(-86400))
        let endOfYesterday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: startOfYesterday)!

        let predicate = HKQuery.predicateForSamples(withStart: startOfYesterday, end: endOfYesterday)

        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 100, sortDescriptors: nil) { [weak self] _, results, error in
            guard let self else { return }
            guard let samples = results as? [HKClinicalRecord], error == nil else {
                print("❌ Erreur récupération médicaments : \(error?.localizedDescription ?? "inconnue")")
                return
            }

            DispatchQueue.main.async {
                self.yesterdayMedications = samples
            }
        }

        healthStore.execute(query)
    }
}
