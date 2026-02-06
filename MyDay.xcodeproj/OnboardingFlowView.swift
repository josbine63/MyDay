//
//  OnboardingFlowView.swift
//  MyDay
//
//  Created by Assistant on 2025-01-15.
//

import SwiftUI

/// Vue principale du flux d'onboarding en plusieurs étapes
struct OnboardingFlowView: View {
    @StateObject private var permissionManager = PermissionChecklistManager()
    @StateObject private var calendarSelectionManager = CalendarSelectionManager()
    @StateObject private var reminderSelectionManager = ReminderSelectionManager()
    
    @State private var currentStep: OnboardingStep = .welcome
    @State private var showOnboarding = true
    
    var onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Fond dégradé
            LinearGradient(
                colors: [Color.accentColor.opacity(0.1), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Contenu de l'étape actuelle
            Group {
                switch currentStep {
                case .welcome:
                    WelcomeStepView {
                        withAnimation {
                            currentStep = .permissions
                        }
                    }
                    
                case .permissions:
                    PermissionChecklistView(manager: permissionManager) {
                        withAnimation {
                            if permissionManager.calendarStatus == .granted {
                                currentStep = .calendarSelection
                            } else if permissionManager.reminderStatus == .granted {
                                currentStep = .reminderSelection
                            } else {
                                completeOnboarding()
                            }
                        }
                    }
                    
                case .calendarSelection:
                    CalendarSelectionView(manager: calendarSelectionManager) {
                        withAnimation {
                            if permissionManager.reminderStatus == .granted {
                                currentStep = .reminderSelection
                            } else {
                                currentStep = .completion
                            }
                        }
                    }
                    
                case .reminderSelection:
                    ReminderSelectionView(manager: reminderSelectionManager) {
                        withAnimation {
                            currentStep = .completion
                        }
                    }
                    
                case .completion:
                    CompletionStepView {
                        completeOnboarding()
                    }
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
        }
    }
    
    private func completeOnboarding() {
        // Marquer l'onboarding comme terminé
        UserDefaults.appGroup.set(true, forKey: UserDefaultsKeys.hasLaunchedBefore)
        onComplete()
    }
}

// MARK: - Étapes de l'onboarding

enum OnboardingStep {
    case welcome
    case permissions
    case calendarSelection
    case reminderSelection
    case completion
}

// MARK: - Vue de bienvenue

struct WelcomeStepView: View {
    var onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Logo ou icône de l'app
            VStack(spacing: 16) {
                Text("📅")
                    .font(.system(size: 80))
                
                Text("Bienvenue dans MyDay")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                
                Text("Votre assistant quotidien pour gérer événements, rappels et bien plus")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                // Aperçu des fonctionnalités
                FeatureRow(icon: "calendar", title: "Calendriers", description: "Tous vos événements en un coup d'œil")
                FeatureRow(icon: "checklist", title: "Rappels", description: "Ne manquez jamais une tâche")
                FeatureRow(icon: "photo.on.rectangle", title: "Photos", description: "Vos souvenirs du jour")
                FeatureRow(icon: "heart.fill", title: "Santé", description: "Suivez votre activité")
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Bouton continuer
            Button {
                onContinue()
            } label: {
                HStack {
                    Text("Commencer")
                    Image(systemName: "arrow.right")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Vue de sélection des calendriers

struct CalendarSelectionView: View {
    @ObservedObject var manager: CalendarSelectionManager
    var onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // En-tête
            VStack(spacing: 12) {
                Text("📅")
                    .font(.system(size: 60))
                
                Text("Sélectionnez vos calendriers")
                    .font(.title2.bold())
                
                Text("Choisissez les calendriers que vous souhaitez voir dans MyDay")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 40)
            
            // Liste des calendriers
            ScrollView {
                VStack(spacing: 12) {
                    if manager.availableCalendars.isEmpty {
                        VStack(spacing: 16) {
                            ProgressView()
                            Text("Chargement des calendriers...")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(manager.availableCalendars) { calendar in
                            CalendarRow(calendar: calendar) {
                                manager.toggleCalendar(calendar)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Bouton continuer
            Button {
                onContinue()
            } label: {
                HStack {
                    Text("Continuer")
                    Image(systemName: "arrow.right")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            manager.loadAvailableCalendars()
        }
    }
}

struct CalendarRow: View {
    let calendar: SelectableCalendar
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                // Couleur du calendrier
                Circle()
                    .fill(Color(calendar.calendar.cgColor))
                    .frame(width: 24, height: 24)
                
                // Informations
                VStack(alignment: .leading, spacing: 4) {
                    Text(calendar.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(calendar.account)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Checkmark
                Image(systemName: calendar.isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(calendar.isSelected ? .accentColor : .gray)
                    .font(.title3)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

// MARK: - Vue de sélection des rappels

struct ReminderSelectionView: View {
    @ObservedObject var manager: ReminderSelectionManager
    var onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // En-tête
            VStack(spacing: 12) {
                Text("✅")
                    .font(.system(size: 60))
                
                Text("Sélectionnez vos listes")
                    .font(.title2.bold())
                
                Text("Choisissez les listes de rappels à afficher")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 40)
            
            // Liste des listes de rappels
            ScrollView {
                VStack(spacing: 12) {
                    if manager.availableLists.isEmpty {
                        VStack(spacing: 16) {
                            ProgressView()
                            Text("Chargement des listes...")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(manager.availableLists) { list in
                            ReminderListRow(list: list) {
                                manager.toggleList(list)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Bouton continuer
            Button {
                onContinue()
            } label: {
                HStack {
                    Text("Continuer")
                    Image(systemName: "arrow.right")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            manager.loadAvailableLists()
        }
    }
}

struct ReminderListRow: View {
    let list: SelectableCalendar
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                // Couleur de la liste
                Circle()
                    .fill(Color(list.calendar.cgColor))
                    .frame(width: 24, height: 24)
                
                // Informations
                VStack(alignment: .leading, spacing: 4) {
                    Text(list.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(list.account)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Checkmark
                Image(systemName: list.isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(list.isSelected ? .accentColor : .gray)
                    .font(.title3)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

// MARK: - Vue de complétion

struct CompletionStepView: View {
    var onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Animation de succès
            VStack(spacing: 24) {
                Text("🎉")
                    .font(.system(size: 80))
                
                Text("Tout est prêt !")
                    .font(.largeTitle.bold())
                
                Text("Vous pouvez maintenant profiter de MyDay")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            
            // Bouton pour commencer
            Button {
                onComplete()
            } label: {
                HStack {
                    Text("Commencer à utiliser MyDay")
                    Image(systemName: "arrow.right")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingFlowView {
        print("Onboarding terminé")
    }
}
