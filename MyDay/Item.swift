//
//  Item.swift
//  MyDay
//
//  Created by Josblais on 2025-04-23.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
