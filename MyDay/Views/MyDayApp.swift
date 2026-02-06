//
//  MyDayApp.swift
//  MyDay
//
//  Created by Assistant on 2025-01-15.
//

import SwiftUI
import os.log

@main
struct MyDayApp: App {
    
    // MARK: - Scene Phase
    
    @Environment(\.scenePhase) private var scenePhase
    
    // MARK: - Initialization
    
    init() {
        setupApp()
    }
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    handleScenePhaseChange(from: oldPhase, to: newPhase)
                }
        }
    }
    
    // MARK: - Setup
    
    private func setupApp() {
        Logger.app.info("🚀 MyDay app démarrage")
        
        // Vérifier l'App Group
        if UserDefaults(suiteName: AppGroup.id) == nil {
            Logger.app.error("⚠️ App Group '\(AppGroup.id)' non configuré")
        } else {
            Logger.app.debug("✅ App Group configuré")
        }
        
        // Nettoyer les anciennes données au démarrage
        Task { @MainActor in
            EventStatusManager.shared.cleanOldCompletedEvents()
        }
    }
    
    // MARK: - Scene Phase Handling
    
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            Logger.app.debug("📱 App active")
            // L'app est au premier plan
            
        case .inactive:
            Logger.app.debug("💤 App inactive")
            // L'app est en transition (ex: Control Center ouvert)
            
        case .background:
            Logger.app.debug("🌙 App en arrière-plan")
            // Sauvegarder les données si nécessaire
            
        @unknown default:
            Logger.app.warning("⚠️ Scene phase inconnue")
        }
    }
}
