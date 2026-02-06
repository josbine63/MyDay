//
//  RootView.swift
//  MyDay
//
//  Created by Assistant on 2025-01-15.
//

import SwiftUI
import os.log

struct RootView: View {
    @State private var showOnboarding: Bool?
    @State private var isInitialized = false
    
    var body: some View {
        ZStack {
            Group {
                if let showOnboarding = showOnboarding {
                    if showOnboarding {
                        OnboardingFlowView {
                            withAnimation {
                                self.showOnboarding = false
                            }
                        }
                        .transition(.opacity)
                    } else {
                        MainAppView()
                            .transition(.opacity)
                    }
                } else {
                    // Splash screen pendant la vérification
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemBackground))
                }
            }
            
            #if DEBUG
            // 🐛 Indicateur de mode DEBUG
            VStack {
                HStack {
                    Spacer()
                    Text("DEBUG")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.8))
                        )
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        .padding(.top, 50)
                        .padding(.trailing, 16)
                }
                Spacer()
            }
            .allowsHitTesting(false) // Ne bloque pas les interactions
            #endif
        }
        .task {
            await checkOnboardingStatus()
        }
    }
    
    private func checkOnboardingStatus() async {
        // Petite pause pour éviter le flash
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconde
        
        // 🧪 POUR FORCER L'ONBOARDING (décommenter temporairement pour tester)
        // UserDefaults.appGroup.set(false, forKey: UserDefaultsKeys.hasLaunchedBefore)
        // UserDefaults.appGroup.removeObject(forKey: "SelectedCalendars")
        // UserDefaults.appGroup.removeObject(forKey: "SelectedReminderLists")
        
        let hasLaunched = UserDefaults.appGroup.bool(forKey: UserDefaultsKeys.hasLaunchedBefore)
        
        await MainActor.run {
            showOnboarding = !hasLaunched
            isInitialized = true
            
            #if DEBUG
            Logger.app.debug("🔍 hasLaunchedBefore: \(hasLaunched)")
            Logger.app.debug("🔍 showOnboarding: \(!hasLaunched)")
            #endif
        }
    }
}

// MARK: - Main App View avec lazy loading

private struct MainAppView: View {
    @StateObject private var userSettings = UserSettings()
    @StateObject private var eventStatusManager = EventStatusManager.shared
    @StateObject private var photoManager = PhotoManager()
    @StateObject private var customLinkManager = CustomLinkManager()
    
    @State private var isReady = false
    
    var body: some View {
        ZStack {
            if isReady {
                ContentView()
                    .environmentObject(userSettings)
                    .environmentObject(eventStatusManager)
                    .environmentObject(photoManager)
                    .environmentObject(customLinkManager)
            } else {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Chargement...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            }
        }
        .onAppear {
            // S'assurer que tous les @StateObject sont initialisés
            // avant de créer ContentView
            Task { @MainActor in
                // Petit délai pour garantir l'initialisation complète
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconde
                isReady = true
            }
        }
    }
}

// Preview supprimé car nécessite un contexte complet avec tous les managers
// Pour tester, lancez l'app directement
