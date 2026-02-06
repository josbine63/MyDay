//
//  HoroscopeView.swift
//  MyDay
//
//  Created by Josblais on 2026-01-29.
//

import SwiftUI
import Translation

struct HoroscopeView: View {
    @ObservedObject private var horoscopeService = HoroscopeService.shared
    @State private var showSignPicker = false
    @State private var showProviderPicker = false
    
    var body: some View {
        // Ne rien afficher si l'horoscope est désactivé
        if !horoscopeService.isHoroscopeEnabled {
            EmptyView()
        } else {
            horoscopeContent
        }
    }
    
    @ViewBuilder
    private var horoscopeContent: some View {
        VStack(spacing: 4) {
        VStack(alignment: .leading, spacing: 12) {
            // En-tête avec sélecteur de signe
            HStack {
                Text("🔮")
                    .font(.title2)
                
                Button(action: {
                    showSignPicker = true
                }) {
                    HStack(spacing: 4) {
                        Text(horoscopeService.selectedSign.symbol)
                        Text(horoscopeService.selectedSign.localizedName)
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.down.circle.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // Bouton de sélection du provider
                Button(action: {
                    showProviderPicker = true
                }) {
                    Image(systemName: "globe")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                
                // Bouton de refresh
                Button(action: {
                    Task {
                        await horoscopeService.fetchHoroscope(for: horoscopeService.selectedSign, forceRefresh: true)
                    }
                }) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            
            // Contenu de l'horoscope
            if horoscopeService.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            } else if let error = horoscopeService.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            } else if let horoscope = horoscopeService.currentHoroscope {
                VStack(alignment: .leading, spacing: 8) {
                    // Description principale avec traduction
                    if #available(iOS 18.0, macOS 15.0, *) {
                        Text(horoscope.description)
                            .font(.body)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                            .translationTask(horoscopeService.translationConfiguration) { session in
                                await horoscopeService.handleTranslation(using: session)
                            }
                            .id(horoscopeService.translationTrigger) // Force le rechargement
                    } else {
                        Text(horoscope.description)
                            .font(.body)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Informations supplémentaires (seulement si disponibles)
                    if horoscope.mood != "N/A" || horoscope.color != "N/A" || horoscope.luckyNumber != "N/A" {
                        HStack(spacing: 16) {
                            if horoscope.mood != "N/A" {
                                Label(horoscope.mood, systemImage: "face.smiling")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if horoscope.color != "N/A" {
                                Label(horoscope.color, systemImage: "paintpalette")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if horoscope.luckyNumber != "N/A" {
                                Label(horoscope.luckyNumber, systemImage: "number")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 4)
                    }
                    
                    // Date de validité
                    Text(horoscope.dateRange)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 2)
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
        .padding(.horizontal)

        Text("source: \(horoscopeService.selectedProvider.sourceURL)")
            .font(.caption2)
            .foregroundColor(.secondary)
            .padding(.horizontal)
        }
        .sheet(isPresented: $showSignPicker) {
            ZodiacSignPickerView(selectedSign: horoscopeService.selectedSign) { newSign in
                horoscopeService.selectedSign = newSign
                showSignPicker = false
            }
        }
        .sheet(isPresented: $showProviderPicker) {
            ProviderPickerView(selectedProvider: horoscopeService.selectedProvider) { newProvider in
                horoscopeService.selectedProvider = newProvider
                showProviderPicker = false
            }
        }
        .onAppear {
            // Charger l'horoscope au démarrage seulement si activé
            guard horoscopeService.isHoroscopeEnabled else { return }
            Task {
                await horoscopeService.fetchHoroscope(for: horoscopeService.selectedSign)
            }
        }
    }
}

struct ZodiacSignPickerView: View {
    let selectedSign: ZodiacSign
    let onSelect: (ZodiacSign) -> Void
    @Environment(\.dismiss) private var dismiss
    
    private var navigationTitle: String {
        let lang = Locale.preferredLanguages.first ?? "en"
        return lang.hasPrefix("fr") ? "Signe astrologique" : "Zodiac Sign"
    }
    
    private var closeButtonLabel: String {
        let lang = Locale.preferredLanguages.first ?? "en"
        return lang.hasPrefix("fr") ? "Fermer" : "Close"
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(ZodiacSign.allCases) { sign in
                    Button(action: {
                        onSelect(sign)
                    }) {
                        HStack {
                            Text(sign.emoji)
                                .font(.title2)
                            
                            Text(sign.symbol)
                                .font(.title3)
                            
                            Text(sign.localizedName)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if sign == selectedSign {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(closeButtonLabel) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct ProviderPickerView: View {
    let selectedProvider: HoroscopeProvider
    let onSelect: (HoroscopeProvider) -> Void
    @Environment(\.dismiss) private var dismiss
    
    private var navigationTitle: String {
        let lang = Locale.preferredLanguages.first ?? "en"
        return lang.hasPrefix("fr") ? "Source de l'horoscope" : "Horoscope Source"
    }
    
    private var closeButtonLabel: String {
        let lang = Locale.preferredLanguages.first ?? "en"
        return lang.hasPrefix("fr") ? "Fermer" : "Close"
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(HoroscopeProvider.allCases) { provider in
                    Button(action: {
                        onSelect(provider)
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(provider.displayName)
                                    .foregroundColor(.primary)
                                    .fontWeight(provider == selectedProvider ? .semibold : .regular)
                                
                                Spacer()
                                
                                if provider == selectedProvider {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            Text(provider.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(closeButtonLabel) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    HoroscopeView()
}
