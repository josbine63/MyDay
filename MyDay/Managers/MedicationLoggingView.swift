//
//  MedicationLoggingView.swift
//  MyDay
//
//  Created by Assistant on 2025-10-15.
//

import SwiftUI
import EventKit

struct MedicationLoggingView: View {
    let reminderList: SelectableReminderList
    @Environment(\.dismiss) private var dismiss
    
    @State private var medicationName = ""
    @State private var dosage = ""
    @State private var notes = ""
    @State private var takenAt = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Informations du médicament") {
                    TextField("Nom du médicament", text: $medicationName)
                    TextField("Dosage", text: $dosage)
                        .keyboardType(.decimalPad)
                }
                
                Section("Détails") {
                    DatePicker("Pris à", selection: $takenAt)
                    TextField("Notes (optionnel)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Liste de rappels") {
                    HStack {
                        Text("Compte:")
                        Spacer()
                        Text(reminderList.account)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Liste:")
                        Spacer()
                        Text(reminderList.title)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Médicament")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Enregistrer") {
                        saveMedicationLog()
                        dismiss()
                    }
                    .disabled(medicationName.isEmpty)
                }
            }
        }
    }
    
    private func saveMedicationLog() {
        // Ici vous pouvez implémenter la logique de sauvegarde
        // Par exemple, créer un rappel, sauvegarder dans Core Data, etc.
        print("📋 Enregistrement du médicament:")
        print("  - Nom: \(medicationName)")
        print("  - Dosage: \(dosage)")
        print("  - Pris à: \(takenAt)")
        print("  - Notes: \(notes)")
        print("  - Liste: \(reminderList.title)")
        
        // TODO: Implémenter la logique de sauvegarde
        // Exemples possibles :
        // - Créer un nouveau rappel dans EventKit
        // - Sauvegarder dans une base de données locale
        // - Envoyer à un service web
    }
}

#Preview {
    // Preview avec des données d'exemple
    let sampleCalendar = EKCalendar(for: .reminder, eventStore: EKEventStore())
    sampleCalendar.title = "Médicaments"
    sampleCalendar.source = EKSource()
    
    let sampleList = SelectableReminderList(
        calendar: sampleCalendar,
        isSelected: false
    )
    
    return MedicationLoggingView(reminderList: sampleList)
}