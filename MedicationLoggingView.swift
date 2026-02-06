//
//  MedicationLoggingView.swift
//  MyDay
//
//  Created by Assistant on 2025-01-15.
//

import SwiftUI
import UIKit

struct MedicationLoggingView: View {
    let reminderList: SelectableReminderList
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Suivi des médicaments")
                .font(.title)
                .padding()
            
            Text("Liste : \(reminderList.title)")
                .font(.headline)
            
            Text("Cette fonctionnalité permet de suivre vos médicaments.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
            
            Button("Ouvrir Santé") {
                if let healthURL = URL(string: "x-apple-health://MedicationsHealthAppPlugin.healthplugin") {
                    UIApplication.shared.open(healthURL)
                }
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .navigationTitle("Médicaments")
    }
}
