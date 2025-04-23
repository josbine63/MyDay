
import SwiftUI
import Foundation

struct RootView: View {
    @EnvironmentObject var permissionManager: PermissionChecklistManager
    @EnvironmentObject var photoManager: PhotoManager
    @EnvironmentObject var calendarManager: CalendarManager
    @EnvironmentObject var healthManager: HealthManager
    @EnvironmentObject var eventStatusManager: EventStatusManager
    @EnvironmentObject var userSettings: UserSettings

    @AppStorage("hasLaunchedBefore", store: UserDefaults.appGroup) var hasLaunchedBefore: Bool = false
    @State private var quoteOfTheDay: String = "Chargement..."
    @State private var selectedDate: Date = Date()

    var body: some View {
        Group {
            if permissionManager.allGranted && hasLaunchedBefore {
                ContentView(
                    selectedDate: $selectedDate,
                    quoteOfTheDay: $quoteOfTheDay
                )
                .onAppear {
                    print("🚀 RootView lancé. allGranted = true, hasLaunchedBefore = true")
                    initializeApp()
                }
            } else {
                PermissionChecklistView(
                    selectedDate: $selectedDate,
                    quoteOfTheDay: $quoteOfTheDay
                )
                .onAppear {
                    print("🚀 RootView lancé. allGranted = \(permissionManager.allGranted), hasLaunchedBefore = \(hasLaunchedBefore)")
                }
            }
        }
    }

    func initializeApp() {
        Task {
            let start = CFAbsoluteTimeGetCurrent()
            let now = Date()
            print("📲 initializeApp()")

            let defaults = UserDefaults.appGroup
            print("📍 Étape 1: AppGroup prêt — \(CFAbsoluteTimeGetCurrent() - start)s")

            async let permissions = permissionManager.updateStatuses()
            print("🔐 permissions requested: ✅ granted")

            photoManager.loadAvailableAlbums()
            print("📍 Étape 2: Albums listés — \(CFAbsoluteTimeGetCurrent() - start)s")

            async let quote: Void = {
                do {
                    print("📜 Début du chargement de la citation")
                    let result = try await loadQuoteFromInternet()
                    await MainActor.run {
                        self.quoteOfTheDay = result
                    }
                    print("📜 Citation téléchargée : \(result)")
                } catch {
                    print("❌ Erreur lors du chargement de la citation : \(error.localizedDescription)")
                }
            }()

            async let agenda = refreshAgenda()
            async let health = healthManager.fetchData(for: now)

            await permissions

            if let album = photoManager.albumNames.first {
                photoManager.setAssets(from: album)
                _ = try? await photoManager.fetchRandomPhoto(fromAlbum: album)
                print("📸 Album par sélectionné : \(album)")
            }

            print("📍 Étape 3: Albums chargés — \(CFAbsoluteTimeGetCurrent() - start)s")

            _ = await (agenda, health, quote)

            print("📍 Étape 4: Agenda chargé — \(CFAbsoluteTimeGetCurrent() - start)s")
            print("📍 Étape 5: Santé chargée — \(CFAbsoluteTimeGetCurrent() - start)s")
        }
    }

    func refreshAgenda() async {
        print("📅 Début fetchAgenda pour \(selectedDate)")
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

        return "\"\(first.q)\" — \(first.a)"
    }

    struct Quote: Codable {
        let q: String
        let a: String
    }
}
