import SwiftUI

struct RootView: View {
    @EnvironmentObject var permissionManager: PermissionChecklistManager
    @EnvironmentObject var photoManager: PhotoManager
    @EnvironmentObject var calendarManager: CalendarManager
    @EnvironmentObject var healthManager: HealthManager
    @EnvironmentObject var eventStatusManager: EventStatusManager
    @EnvironmentObject var userSettings: UserSettings

    @AppStorage("hasLaunchedBefore", store: UserDefaults(suiteName: "group.com.josblais.myday")) var hasLaunchedBefore: Bool = false
    @State private var quoteOfTheDay: String = "Chargement..."
    @State private var selectedDate: Date = Date()
    @State private var savedAlbumName: String? = nil

    var body: some View {
        VStack {
            Text("Album: \(savedAlbumName ?? "Aucun")")

            if permissionManager.allGranted && hasLaunchedBefore {
                ContentView(
                    selectedDate: $selectedDate,
                    quoteOfTheDay: $quoteOfTheDay
                )
            } else {
                PermissionChecklistView(
                    manager: permissionManager,
                    onComplete: {
                        initializeApp()
                    }
                )
            }
        }
        .onAppear {
            print("🚀 RootView lancé. allGranted = \(permissionManager.allGranted), hasLaunchedBefore = \(hasLaunchedBefore)")
            
            if permissionManager.allGranted && hasLaunchedBefore {
                initializeApp()
            }

            Task {
                photoManager.loadSavedAlbumName()
                if let album = photoManager.savedAlbumName {
                    try? await photoManager.fetchRandomPhoto(fromAlbum: album)
                }
            }
        }
    }
    
    func initializeApp() {
        Task {
            let start = CFAbsoluteTimeGetCurrent()
            print("📲 initializeApp()")

            // Étape 1 : Statut des permissions
            await permissionManager.updateStatuses()
            print("✅ updateStatuses: allGranted = \(permissionManager.allGranted)")

            // Étape 2 : Albums ou image aléatoire
            if let savedName = photoManager.savedAlbumName {
                try? await photoManager.fetchRandomPhoto(fromAlbum: savedName)
                print("📸 Album par sélectionné : \(savedName)")
            } else {
                photoManager.loadAvailableAlbums()
            }
            print("📍 Étape 2: Albums listés — \(CFAbsoluteTimeGetCurrent() - start)s")

            // Étape 3 : Citation
            do {
                print("📜 Début du chargement de la citation")
                let quote = try await loadQuoteFromInternet()
                quoteOfTheDay = quote
                print("📜 Citation téléchargée : \(quote)")
            } catch {
                print("❌ Erreur citation : \(error.localizedDescription)")
            }

            // Étape 4 : Agenda
            await refreshAgenda()

            // Étape 5 : Santé
            await healthManager.fetchData(for: selectedDate)

            print("📍 Démarrage terminé — \(CFAbsoluteTimeGetCurrent() - start)s")
        }
    }

    func refreshAgenda() async {
        await calendarManager.fetchEvents(for: selectedDate)
        await calendarManager.fetchReminders(for: selectedDate)
    }

    func loadQuoteFromInternet() async throws -> String {
        guard let url = URL(string: "https://zenquotes.io/api/random") else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode([Quote].self, from: data)

        guard let first = decoded.first else {
            throw NSError(domain: "QuoteError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Aucune citation disponible."])
        }

        return "📜 \(first.q) — \(first.a)"
    }

    struct Quote: Codable {
        let q: String
        let a: String
    }
}
