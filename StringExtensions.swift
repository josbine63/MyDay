//
//  StringExtensions.swift
//  MyDay
//
//  Created by Assistant on 2025-01-15.
//

import Foundation
import CryptoKit

extension String {
    /// Converts a string to a UUID using SHA256 hashing
    func sha256ToUUID() -> String {
        let inputData = Data(self.utf8)
        let hashed = SHA256.hash(data: inputData)
        let hashString = hashed.compactMap { String(format: "%02x", $0) }.joined()
        
        // Take first 32 characters and format as UUID
        let start = hashString.prefix(8)
        let second = hashString.dropFirst(8).prefix(4)
        let third = hashString.dropFirst(12).prefix(4)
        let fourth = hashString.dropFirst(16).prefix(4)
        let fifth = hashString.dropFirst(20).prefix(12)
        
        return "\(start)-\(second)-\(third)-\(fourth)-\(fifth)"
    }
}
