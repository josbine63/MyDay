import Foundation

final class UserDefaultsManager {
    static let suiteName = "group.com.josblais.myday"
    static var shared: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    static func bool(forKey key: String, defaultValue: Bool = false) -> Bool {
        shared?.bool(forKey: key) ?? defaultValue
    }

    static func set(_ value: Bool, forKey key: String) {
        shared?.set(value, forKey: key)
    }

    static func string(forKey key: String) -> String? {
        shared?.string(forKey: key)
    }

    static func set(_ value: String, forKey key: String) {
        shared?.set(value, forKey: key)
    }

    static func remove(key: String) {
        shared?.removeObject(forKey: key)
    }
}