//
//  Extensions.swift
//  MyDay
//
//  Created by Josblais on 2025-05-11.
//
import Foundation
import CryptoKit

// MARK: - Extensions

extension String {
    func sha256ToUUID() -> String {
        let data = Data(self.utf8)
        let hash = SHA256.hash(data: data)
        let bytes = Array(hash.prefix(16))
        let uuid = UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
        return uuid.uuidString
    }
}

/* extension EventStatusManager {
    func completedEvents(forDateKey key: String) -> Set<UUID> {
        return completedEvents[key] ?? []
    }
}
*/

import UIKit

extension UserDefaults {
    func set(_ image: UIImage, forKey key: String) {
        if let data = image.pngData() {
            set(data, forKey: key)
        }
    }

    func image(forKey key: String) -> UIImage? {
        if let data = data(forKey: key) {
            return UIImage(data: data)
        }
        return nil
    }
}

