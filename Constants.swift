//
//  Constants.swift
//  MyDay
//
//  Created by Assistant on 2025-01-15.
//
//  ⚠️ NOTE: Ce fichier a été créé temporairement
//  Toutes les constantes sont maintenant dans AppGroup.swift
//  Ce fichier peut être supprimé si plus utilisé

import Foundation
import CryptoKit

// MARK: - Extensions

extension String {
    func sha256ToUUID() -> String {
        let data = Data(self.utf8)
        let hash = SHA256.hash(data: data)
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        
        // Prendre les premiers 32 caractères hexadécimaux pour créer un UUID
        let uuid = String(hashString.prefix(32))
        let formatted = String(format: "%@-%@-%@-%@-%@",
                              String(uuid.prefix(8)),
                              String(uuid.dropFirst(8).prefix(4)),
                              String(uuid.dropFirst(12).prefix(4)),
                              String(uuid.dropFirst(16).prefix(4)),
                              String(uuid.dropFirst(20).prefix(12)))
        return formatted
    }
}
