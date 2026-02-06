//
//  AppGroupStorage.swift
//  MyDay
//
//  Created by Josblais on 2025-05-09.
//


import Foundation

@propertyWrapper
struct AppGroupStorage<T: Codable> {
    private let key: String
    private let defaultValue: T
    private let userDefaults: UserDefaults

    var wrappedValue: T {
        get {
            if T.self == Bool.self {
                return (userDefaults.bool(forKey: key) as? T) ?? defaultValue
            } else if T.self == String.self {
                return (userDefaults.string(forKey: key) as? T) ?? defaultValue
            } else if let data = userDefaults.data(forKey: key),
                      let decoded = try? JSONDecoder().decode(T.self, from: data) {
                return decoded
            }
            return defaultValue
        }
        set {
            if let boolValue = newValue as? Bool {
                userDefaults.set(boolValue, forKey: key)
            } else if let stringValue = newValue as? String {
                userDefaults.set(stringValue, forKey: key)
            } else if let encoded = try? JSONEncoder().encode(newValue) {
                userDefaults.set(encoded, forKey: key)
            }
        }
    }

    init(wrappedValue: T, key: String) {
        self.key = key
        self.defaultValue = wrappedValue
        // Use AppGroup.userDefaults which safely falls back to .standard if unavailable
        self.userDefaults = AppGroup.userDefaults
    }
}
