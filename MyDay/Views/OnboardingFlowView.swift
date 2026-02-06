//
//  OnboardingFlowView.swift
//  MyDay
//
//  Created by Assistant on 2025-01-15.
//

import SwiftUI

struct OnboardingFlowView: View {
    var onComplete: () -> Void
    
    @StateObject private var permissionManager = PermissionChecklistManager()
    @StateObject private var calendarSelectionManager = CalendarSelectionManager()
    @StateObject private var reminderSelectionManager = ReminderSelectionManager()
    
    @State private var currentStep: OnboardingStep = .welcome
    
    enum OnboardingStep {
        case welcome
        case permissions
        case calendars
        case reminders
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Indicateur de progression
            progressIndicator
            
            // Contenu de l'étape actuelle
            Group {
                switch currentStep {
                case .welcome:
                    WelcomeView {
                        withAnimation {
                            currentStep = .permissions
                        }
                    }
                    .task {
                        // Précharger TOUT pendant que l'utilisateur lit l'écran d'accueil
                        if calendarSelectionManager.selectableCalendars.isEmpty {
                            await calendarSelectionManager.loadCalendars()
                        }
                        if reminderSelectionManager.selectableReminderLists.isEmpty {
                            await reminderSelectionManager.loadReminderLists()
                        }
                    }
                case .permissions:
                    PermissionChecklistView(manager: permissionManager) {
                        // Précharger les calendriers pendant la transition (seulement si pas déjà chargés)
                        if calendarSelectionManager.selectableCalendars.isEmpty {
                            Task {
                                await calendarSelectionManager.loadCalendars()
                            }
                        }
                        withAnimation {
                            currentStep = .calendars
                        }
                    }
                case .calendars:
                    OnboardingCalendarSelectionView(manager: calendarSelectionManager) {
                        // Précharger les rappels pendant la transition (seulement si pas déjà chargés)
                        if reminderSelectionManager.selectableReminderLists.isEmpty {
                            Task {
                                await reminderSelectionManager.loadReminderLists()
                            }
                        }
                        withAnimation {
                            currentStep = .reminders
                        }
                    }
                case .reminders:
                    OnboardingReminderSelectionView(manager: reminderSelectionManager) {
                        completeOnboarding()
                    }
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<4) { index in
                Capsule()
                    .fill(index <= stepIndex ? Color.accentColor : Color.gray.opacity(0.3))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    private var stepIndex: Int {
        switch currentStep {
        case .welcome: return 0
        case .permissions: return 1
        case .calendars: return 2
        case .reminders: return 3
        }
    }
    
    private func completeOnboarding() {
        // Marquer l'onboarding comme terminé
        UserDefaults.appGroup.set(true, forKey: UserDefaultsKeys.hasLaunchedBefore)
        
        // Appeler le callback
        withAnimation {
            onComplete()
        }
    }
}

// MARK: - Welcome View

struct WelcomeView: View {
    var onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Logo/Icône
            VStack(spacing: 12) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 70))
                    .foregroundStyle(.linearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                
                Text("Bienvenue dans MyDay")
                    .font(.title2.bold())
                
                Text("Votre journée, organisée simplement")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Fonctionnalités - Version compacte
            VStack(spacing: 16) {
                FeatureRow(
                    icon: "calendar",
                    title: "Calendrier unifié",
                    description: "Tous vos événements au même endroit"
                )
                
                FeatureRow(
                    icon: "checklist",
                    title: "Rappels intelligents",
                    description: "Ne manquez plus vos tâches importantes"
                )
                
                FeatureRow(
                    icon: "photo.on.rectangle",
                    title: "Souvenirs du jour",
                    description: "Revivez vos meilleurs moments"
                )
                
                FeatureRow(
                    icon: "heart.fill",
                    title: "Activité physique",
                    description: "Suivez vos statistiques de santé"
                )
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Note de confidentialité
            VStack(spacing: 8) {
                Text("🔒 Confidentialité garantie")
                    .font(.caption.bold())
                    .foregroundColor(.accentColor)
                
                Text("Toutes vos données restent sur votre appareil")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
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
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 36, height: 36)
                .background(Color.accentColor.opacity(0.15))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Onboarding Calendar Selection View

struct OnboardingCalendarSelectionView: View {
    @ObservedObject var manager: CalendarSelectionManager
    var onContinue: () -> Void
    
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 0) {
            // En-tête
            VStack(spacing: 12) {
                Text("📅")
                    .font(.system(size: 60))
                
                Text("Vos calendriers")
                    .font(.title2.bold())
                
                Text("Sélectionnez les calendriers que vous souhaitez afficher dans MyDay.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            // Liste des calendriers
            ScrollView {
                VStack(spacing: 12) {
                    if isLoading {
                        // Skeleton loading avec des placeholders
                        ForEach(0..<3, id: \.self) { _ in
                            skeletonRow
                        }
                    } else if manager.selectableCalendars.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            Text("Aucun calendrier disponible")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Assurez-vous d'avoir accordé les permissions nécessaires.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                    } else {
                        ForEach(manager.selectableCalendars) { calendar in
                            calendarRow(calendar)
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .animation(.easeOut(duration: 0.3), value: isLoading)
            }
            
            // Footer avec compteur
            VStack(spacing: 16) {
                HStack {
                    Text("\(manager.selectableCalendars.filter { $0.isSelected }.count) calendrier(s) sélectionné(s)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button {
                        if manager.selectableCalendars.allSatisfy({ $0.isSelected }) {
                            manager.deselectAll()
                        } else {
                            manager.selectAll()
                        }
                    } label: {
                        Text(manager.selectableCalendars.allSatisfy({ $0.isSelected }) ? "Tout désélectionner" : "Tout sélectionner")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(.horizontal, 20)
                
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
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 24)
            .background(Color(.systemBackground))
        }
        .background(Color(.systemGroupedBackground))
        .task {
            // Charger seulement si pas déjà chargé
            guard manager.selectableCalendars.isEmpty else {
                isLoading = false
                return
            }
            await manager.loadCalendars()
            isLoading = false
        }
    }
    
    private func calendarRow(_ calendar: SelectableCalendar) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(cgColor: calendar.calendar.cgColor))
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(calendar.title)
                    .font(.body)
                
                if !calendar.account.isEmpty {
                    Text(calendar.account)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: calendar.isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(calendar.isSelected ? .accentColor : .gray)
                .font(.title3)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture {
            manager.toggleSelection(for: calendar.id)
        }
    }
    
    private var skeletonRow: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 12)
            }
            
            Spacer()
            
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                .frame(width: 24, height: 24)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .redacted(reason: .placeholder)
        .shimmering()
    }
}

// MARK: - Onboarding Reminder Selection View

struct OnboardingReminderSelectionView: View {
    @ObservedObject var manager: ReminderSelectionManager
    var onComplete: () -> Void
    
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 0) {
            // En-tête
            VStack(spacing: 12) {
                Text("✅")
                    .font(.system(size: 60))
                
                Text("Vos rappels")
                    .font(.title2.bold())
                
                Text("Sélectionnez les listes de rappels que vous souhaitez voir dans MyDay.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            // Liste des rappels
            ScrollView {
                VStack(spacing: 12) {
                    if isLoading {
                        // Skeleton loading avec des placeholders
                        ForEach(0..<3, id: \.self) { _ in
                            skeletonRow
                        }
                    } else if manager.selectableReminderLists.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "checklist")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            Text("Aucune liste de rappels disponible")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Assurez-vous d'avoir accordé les permissions nécessaires.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                    } else {
                        ForEach(manager.selectableReminderLists) { list in
                            reminderRow(list)
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .animation(.easeOut(duration: 0.3), value: isLoading)
            }
            
            // Footer avec compteur
            VStack(spacing: 16) {
                selectionFooter
                .padding(.horizontal, 20)
                
                Button {
                    onComplete()
                } label: {
                    HStack {
                        Text("Terminer")
                        Image(systemName: "checkmark")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 24)
            .background(Color(.systemBackground))
        }
        .background(Color(.systemGroupedBackground))
        .task {
            // Charger seulement si pas déjà chargé
            guard manager.selectableReminderLists.isEmpty else {
                isLoading = false
                return
            }
            await manager.loadReminderLists()
            isLoading = false
        }
    }
    
    private var selectionFooter: some View {
        HStack {
            Text("\(selectedListCount) liste(s) sélectionnée(s)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: toggleAllSelection) {
                Text(allListsSelected ? "Tout désélectionner" : "Tout sélectionner")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
        }
    }
    
    private var selectedListCount: Int {
        manager.selectableReminderLists.filter { $0.isSelected }.count
    }
    
    private var allListsSelected: Bool {
        !manager.selectableReminderLists.isEmpty && manager.selectableReminderLists.allSatisfy { $0.isSelected }
    }
    
    private func toggleAllSelection() {
        if allListsSelected {
            deselectAllLists()
        } else {
            selectAllLists()
        }
    }
    
    private func selectAllLists() {
        for list in manager.selectableReminderLists where !list.isSelected {
            manager.toggleSelection(for: list.id)
        }
    }
    
    private func deselectAllLists() {
        for list in manager.selectableReminderLists where list.isSelected {
            manager.toggleSelection(for: list.id)
        }
    }
    
    private func reminderRow(_ list: SelectableReminderList) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(cgColor: list.calendar.cgColor))
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(list.title)
                    .font(.body)
                
                if !list.account.isEmpty {
                    Text(list.account)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: list.isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(list.isSelected ? .accentColor : .gray)
                .font(.title3)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture {
            manager.toggleSelection(for: list.id)
        }
    }
    
    private var skeletonRow: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 12)
            }
            
            Spacer()
            
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                .frame(width: 24, height: 24)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .redacted(reason: .placeholder)
        .shimmering()
    }
}

// MARK: - Preview

#Preview("Welcome") {
    WelcomeView {
        print("Continue tapped")
    }
}

#Preview("Full Onboarding") {
    OnboardingFlowView {
        print("Onboarding completed")
    }
}
// MARK: - Shimmering Effect

extension View {
    @ViewBuilder
    func shimmering(active: Bool = true) -> some View {
        if active {
            self.modifier(ShimmeringModifier())
        } else {
            self
        }
    }
}

struct ShimmeringModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        Color.white.opacity(0.3),
                        .clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(70))
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 400
                }
            }
    }
}

