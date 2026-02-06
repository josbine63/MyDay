import SwiftUI
import os.log

struct RootView: View {
    @AppStorage(UserDefaultsKeys.hasLaunchedBefore, store: AppGroup.userDefaults)
    private var hasLaunchedBefore: Bool = false
    
    // Pour tester l'onboarding à nouveau, exécutez ceci dans le Simulator ou sur device :
    // UserDefaults(suiteName: "group.com.myday")?.set(false, forKey: "hasLaunchedBefore")
    // Ou supprimez l'app et réinstallez-la
  
    // 🚀 OPTIMISATION: Tous les managers créés ici pour éviter réinitialisation dans ContentView
    @StateObject private var userSettings = UserSettings()
    @StateObject private var calendarManager = CalendarManager()
    @StateObject private var calendarSelectionManager = CalendarSelectionManager()
    @StateObject private var reminderSelectionManager = ReminderSelectionManager()
    @StateObject private var photoManager = PhotoManager()
    @StateObject private var customLinkManager = CustomLinkManager()
    @StateObject private var healthManager = HealthManager()
    
    var body: some View {
        if hasLaunchedBefore {
            ContentView()
                .environmentObject(userSettings)
                .environmentObject(photoManager)
                .environmentObject(calendarManager)
                .environmentObject(calendarSelectionManager)
                .environmentObject(reminderSelectionManager)
                .environmentObject(customLinkManager)
                .environmentObject(healthManager)
                .onAppear {
                    #if DEBUG
                    Logger.app.debug("RootView: ContentView appeared - customLinks=\(customLinkManager.customLinks.count)")
                    #endif
                }
        } else {
            OnboardingFlowView {
                hasLaunchedBefore = true
            }
            .environmentObject(photoManager)
        }
    }
}

