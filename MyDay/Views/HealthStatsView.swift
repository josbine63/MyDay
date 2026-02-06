//
//  HealthStatsView.swift
//  MyDay
//
//  Created by Assistant on 2025-01-15.
//

import SwiftUI

/// Vue affichant les statistiques de santé
struct HealthStatsView: View {
    
    let steps: Double
    let distance: Double
    let calories: Double
    let usesMetric: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 20) {
                // Pas
                Label("\(Int(steps))", systemImage: "figure.walk")
                
                // Distance
                Label(formattedDistance, systemImage: "map")
                
                // Calories
                Label(String(format: "%.0f", calories), systemImage: "flame")
            }
            .padding()
        }
        .buttonStyle(.plain)
    }
    
    private var formattedDistance: String {
        if distance < 1 {
            return usesMetric ? "0 m" : "0 ft"
        }
        
        if usesMetric {
            if distance < 1000 {
                return String(format: "%.0f m", distance)
            } else {
                let km = distance / 1000
                return String(format: "%.2f", km)
            }
        } else {
            let feet = distance * 3.28084
            if feet < 2500 {
                return String(format: "%.0f ft", feet)
            } else {
                let miles = distance / 1609.34
                return String(format: "%.2f", miles)
            }
        }
    }
}
