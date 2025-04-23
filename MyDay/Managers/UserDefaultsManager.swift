import Foundation

final class UserDefaultsManager {
    static let suiteName = "group.com.josblais.myday"
    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    // MARK: - Bool
    static func bool(forKey key: String, defaultValue: Bool = false) -> Bool {
        defaults?.bool(forKey: key) ?? defaultValue
    }

    static func set(_ value: Bool, forKey key: String) {
        defaults?.set(value, forKey: key)
    }

    // MARK: - String
    static func string(forKey key: String) -> String? {
        defaults?.string(forKey: key)
    }

    static func set(_ value: String, forKey key: String) {
        defaults?.set(value, forKey: key)
    }

    // MARK: - Codable (struct, array, etc.)
    static func saveCodable<T: Codable>(_ object: T, forKey key: String) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(object) {
            defaults?.set(encoded, forKey: key)
        }
    }

    static func loadCodable<T: Codable>(forKey key: String, type: T.Type) -> T? {
        guard let data = defaults?.data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(T.self, from: data)
    }

    // MARK: - Generic Remove
    static func remove(key: String) {
        defaults?.removeObject(forKey: key)
    }
}
