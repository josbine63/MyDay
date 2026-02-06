//
//  ColorExtensions.swift
//  MyDay
//
//  Created by Assistant on 2025-01-15.
//

import SwiftUI
import UIKit

extension Color {
    /// Crée une Color à partir d'un CGColor
    init(_ cgColor: CGColor) {
        self.init(UIColor(cgColor: cgColor))
    }
}
