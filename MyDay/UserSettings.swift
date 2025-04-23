import SwiftUI

class UserSettings: ObservableObject {
    @Published var preferences: UserLocalePreferences

    init() {
        let languageCode = Locale.preferredLanguages.first?.prefix(2) ?? "en"
        let measurementSystem = Locale.current.measurementSystem
        let usesMetric = measurementSystem == .metric

        self.preferences = UserLocalePreferences(
            language: String(languageCode),
            usesMetric: usesMetric
        )

        print("🌍 Langue : \(languageCode), système : \(measurementSystem.rawValue)")
    }
}

struct UserLocalePreferences {
    let language: String
    let usesMetric: Bool
}