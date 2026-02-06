// ContentView.swift
import Foundation
import SwiftUI
import EventKit
import WidgetKit
import UIKit
import Photos
import HealthKit
import CryptoKit
import os.log
import Translation

// MARK: - Notification Names

extension Notification.Name {
    /// Notification envoyée lorsque l'agenda doit être rafraîchi suite à un changement dans EventKit
    static let needsAgendaRefresh = Notification.Name("needsAgendaRefresh")
}

// MARK: - Models

// 🚀 OPTIMISATION: Equatable pour éviter re-renders inutiles
struct AgendaItem: Identifiable, Equatable {
    let id: UUID
    let title: String
    let date: Date
    let isEvent: Bool
    let reminderID: String?
    let eventID: String? // ✅ Identifiant source pour événements
    let isShared: Bool // ✅ Indique si l'élément provient d'un calendrier/liste partagé
    let calendarColor: CGColor? // 🎨 Couleur de la liste/calendrier
    let calendarName: String? // 🏷️ Nom de la liste/calendrier (pour mapping manuel d'icônes)
    let icon: String // 🚀 OPTIMISATION: Icône précomputée pour éviter recalcul à chaque render

    // Identifiant stable et unique par occurrence (inclut timestamp)
    init(title: String, date: Date, isEvent: Bool, reminderID: String?, eventID: String? = nil, isShared: Bool = false, calendarColor: CGColor? = nil, calendarName: String? = nil) {
        self.title = title
        self.date = date
        self.isEvent = isEvent
        self.reminderID = reminderID
        self.eventID = eventID
        self.isShared = isShared
        self.calendarColor = calendarColor
        self.calendarName = calendarName
        
        // 🚀 OPTIMISATION: Calculer l'icône une seule fois à l'init
        self.icon = Self.computeIcon(for: title, isEvent: isEvent)

        let ts = String(Int(date.timeIntervalSince1970))
        if isEvent, let eventID = eventID, !eventID.isEmpty {
            // ✅ Unicité par occurrence: eventID + timestamp
            let key = "event|\(eventID)|\(ts)"
            let uuidString = key.sha256ToUUID()
            self.id = UUID(uuidString: uuidString) ?? UUID()
        } else if !isEvent, let reminderID = reminderID, !reminderID.isEmpty {
            // ✅ Unicité par occurrence: reminderID + timestamp
            let key = "reminder|\(reminderID)|\(ts)"
            let uuidString = key.sha256ToUUID()
            self.id = UUID(uuidString: uuidString) ?? UUID()
        } else {
            // 🔁 Fallback (rare): dériver de titre + timestamp + type
            let kind = isEvent ? "event" : "reminder"
            let key = "fallback|\(kind)|\(title)|\(ts)"
            let uuidString = key.sha256ToUUID()
            self.id = UUID(uuidString: uuidString) ?? UUID()
        }
    }
    
    // 🚀 OPTIMISATION: Logique d'icône extraite en méthode statique
    private static func computeIcon(for title: String, isEvent: Bool) -> String {
        let titleLower = title.lowercased()
        
        func containsAny(_ keywords: [String]) -> Bool {
            keywords.contains { titleLower.contains($0) }
        }
        
        // Santé et médicaments
        if containsAny(["médicament", "pilule", "med", "médoc", "comprimé", "gélule", "medication", "medicine", "pill", "tablet", "capsule", "drug"]) {
            return "💊"
        }
        if containsAny(["dodo", "sieste", "sleep", "power nap"]) { return "💤" }
        
        // Sport
        if containsAny(["course", "jogging", "courir", "run", "running"]) { return "🏃" }
        if containsAny(["gym", "musculation", "fitness", "entrainement", "entraînement", "workout", "training", "exercise"]) { return "💪" }
        if containsAny(["natation", "piscine", "nager", "swimming", "pool", "swim"]) { return "🏊" }
        if containsAny(["vélo", "cyclisme", "velo", "bike", "cycling", "bicycle"]) { return "🚴" }
        if containsAny(["yoga", "méditation", "relaxation", "meditation"]) { return "🧘" }
        if containsAny(["tennis"]) { return "🎾" }
        if containsAny(["football", "soccer"]) { return "⚽" }
        if containsAny(["basket", "basketball"]) { return "🏀" }
        if containsAny(["randonnée", "hiking"]) { return "🌲" }
        if containsAny(["marche", "balade", "walk", "walking"]) { return "🚶" }
        
        // Travail
        if containsAny(["réunion", "meeting", "rendez-vous", "rdv", "appel", "call", "appointment"]) { return "💼" }
        if containsAny(["présentation", "conférence", "presentation", "conference"]) { return "📊" }
        if containsAny(["formation", "cours", "classe", "training", "class", "lesson", "course", "education"]) { return "📚" }
        
        // Santé
        if containsAny(["dentiste", "dental", "dentist"]) { return "🦷" }
        if containsAny(["médecin", "docteur", "hopital", "hôpital", "clinique", "doctor", "physician", "hospital", "clinic", "medical"]) { return "🏥" }
        if containsAny(["massage", "spa"]) { return "💆" }
        
        // Alimentation
        if containsAny(["restaurant", "dîner", "diner", "déjeuner", "petit-déjeuner", "repas", "dinner", "lunch", "breakfast", "meal", "eat", "food"]) { return "🍽️" }
        if containsAny(["courses", "marché", "épicerie", "shopping", "grocery", "market"]) { return "🛒" }
        if containsAny(["café", "bar", "coffee"]) { return "☕" }
        
        // Transport
        if containsAny(["vol", "avion", "aéroport", "flight", "plane", "airport"]) { return "✈️" }
        if containsAny(["train", "gare", "station"]) { return "🚂" }
        if containsAny(["voiture", "conduite", "garage", "car", "drive", "driving"]) { return "🚗" }
        if containsAny(["voyage", "vacances", "travel", "vacation", "trip"]) { return "🧳" }
        
        // Maison
        if containsAny(["ménage", "nettoyer", "lessive", "cleaning", "clean", "laundry"]) { return "🧹" }
        if containsAny(["jardinage", "plantes", "gardening", "plants", "garden"]) { return "🌱" }
        if containsAny(["bricolage", "réparation", "diy", "repair", "fix"]) { return "🔧" }
        
        // Social
        if containsAny(["anniversaire", "fête", "birthday", "party", "celebration"]) { return "🎉" }
        if containsAny(["famille", "parents", "enfants", "family", "children", "kids"]) { return "👨‍👩‍👧‍👦" }
        if containsAny(["ami", "sortie", "friend", "friends", "social"]) { return "👫" }
        
        // Culture
        if containsAny(["cinéma", "film", "cinema", "movie", "movies"]) { return "🎬" }
        if containsAny(["concert", "musique", "music"]) { return "🎵" }
        if containsAny(["lecture", "livre", "bibliothèque", "reading", "book", "library"]) { return "📖" }
        if containsAny(["musée", "exposition", "museum", "exhibition", "gallery"]) { return "🎨" }
        
        // Argent
        if containsAny(["banque", "argent", "bank", "money", "banking"]) { return "🏦" }
        if containsAny(["impôts", "administration", "taxes", "tax", "admin"]) { return "📄" }
        
        // Beauté
        if containsAny(["coiffeur", "cheveux", "hairdresser", "hair", "salon"]) { return "💇" }
        if containsAny(["manucure", "ongles", "manicure", "nails"]) { return "💅" }
        
        // Par défaut
        return isEvent ? "📅" : "🗓️"
    }
    
    // 🚀 OPTIMISATION: Implémentation Equatable pour comparaison efficace
    static func == (lhs: AgendaItem, rhs: AgendaItem) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.date == rhs.date &&
        lhs.isShared == rhs.isShared
        // Note: on compare uniquement les propriétés qui affectent le rendu
    }
}

struct ReminderItem: Identifiable {
    let id: String
    let title: String
    var isCompleted: Bool
    var ekReminder: EKReminder
}

// MARK: - Main View

struct ContentView: View {
    //    @StateObject private var userSettings = UserSettings()
    @EnvironmentObject var userSettings: UserSettings // 👈 plus de @StateObject ici
    @EnvironmentObject var photoManager: PhotoManager
    @EnvironmentObject var customLinkManager: CustomLinkManager
    
    @EnvironmentObject var healthManager: HealthManager
    
    @EnvironmentObject var calendarManager: CalendarManager
    @EnvironmentObject var calendarSelectionManager: CalendarSelectionManager
    @EnvironmentObject var reminderSelectionManager: ReminderSelectionManager
    
    //    @StateObject private var photoManager = PhotoManager()
    @ObservedObject var statusManager = EventStatusManager.shared
    
    // MARK: - État de l'application
    @State private var showEventForm = false
    @State private var showReminderForm = false
    @State private var showUpcomingWeek = false // ✨ Nouvelle vue
    @State private var newTitle = ""
    @State private var newDate = Date()
    @State private var selectedDate = Date()
    @State private var showDatePicker = false
    @State private var showSettings = false
    @State private var quoteOfTheDay: String = "Chargement…"
    @State private var quoteOpacity = 0.0
    @State private var hasInitialized = false
    @State private var hasLoadedInitialData = false // 🚀 OPTIMISATION: Évite rechargements multiples
    @State private var isAlbumReady = false
    @State private var showNoAlbumAlert = false
    @State private var combinedAgenda: [AgendaItem] = []
    @State private var myReminders: [EKReminder] = []
    @State private var showFullScreenPhoto = false
    @State private var eventStoreObserver: NSObjectProtocol? // 🔔 Observer pour les changements EventKit
    // 🚀 OPTIMISATION: Plus de Timer - on utilise uniquement les notifications EventKit
    
    // MARK: - Variables de traduction
    @State private var translationConfiguration: TranslationSession.Configuration?
    @State private var textToTranslate: String?
    @State private var quoteAuthor: String? // Pour stocker l'auteur de la citation
    
    let defaults = UserDefaults.appGroup
    @AppStorage(UserDefaultsKeys.albumName, store: AppGroup.userDefaults)
    
    private var albumName: String = ""
    
    #if DEBUG
    // Toggle for verbose EventKit (calendars/reminders) logging via App Group defaults
    private var verboseEventKitLogging: Bool {
        AppGroup.userDefaults.bool(forKey: "VerboseEventKitLogging")
    }
    private func logEKVerbose(_ message: String) {
        if verboseEventKitLogging {
            Logger.reminder.debug("\(message)")
        }
    }
    #endif
    
    // MARK: - Constantes
    private let eventStore = SharedEventStore.shared
    
    
    var body: some View {
        NavigationStack {
            content
                .sheet(isPresented: $showEventForm) { eventForm() }
                .sheet(isPresented: $showReminderForm) { reminderForm() }
                .sheet(isPresented: $showUpcomingWeek) {
                    UpcomingWeekView(
                        startDate: selectedDate,
                        calendarSelectionManager: calendarSelectionManager,
                        reminderSelectionManager: reminderSelectionManager
                    )
                    .environmentObject(userSettings)
                }
                .navigationDestination(isPresented: $showSettings) {
                    SettingsView(
                        calendarSelectionManager: calendarSelectionManager,
                        reminderSelectionManager: reminderSelectionManager
                    )
                    .environmentObject(userSettings)
                    .environmentObject(photoManager)
                    .environmentObject(customLinkManager)
                }
                .fullScreenCover(isPresented: $showFullScreenPhoto) {
                    FullScreenPhotoView(
                        image: photoManager.currentImage, 
                        isPresented: $showFullScreenPhoto,
                        photoManager: photoManager
                    )
                }
                // ✅ Ajouter le support de traduction iOS 18+
                .translationTask(translationConfiguration) { session in
                    await handleTranslation(using: session)
                }
                .onAppear {
                    #if DEBUG
                    Logger.app.debug("ContentView.onAppear - customLinkManager injected | links=\(customLinkManager.customLinks.count)")
                    #endif
                }
        }
    }

    private var content: some View {
        Group {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    if showDatePicker { datePickerSection }
                    if userSettings.preferences.showHealth { activitySection }
                    agendaSection
                    photoDisplaySection
                    footerSection
                }
            }
            .refreshable {
                await refreshAgenda()
                if userSettings.preferences.showHealth {
                    healthManager.fetchData(for: selectedDate)
                }
            }
            .onAppear {
                // 🚀 OPTIMISATION: Éviter rechargements multiples
                guard !hasLoadedInitialData else {
                    Logger.ui.debug("⏭️ Données déjà chargées, skip onAppear")
                    return
                }
                hasLoadedInitialData = true
                
                // 🔔 Configurer l'observateur EventKit pour détecter les changements
                setupEventStoreObserver()
                
                // 🚀 OPTIMISATION: Plus de polling - on utilise uniquement les notifications EventKit
                // L'observateur .EKEventStoreChanged détecte TOUS les changements (locaux + iCloud)
                
                // ✅ App Group priming to reduce CFPreferences warning
                let defaults = UserDefaults.appGroup
                if !defaults.bool(forKey: UserDefaultsKeys.hasAppGroupBeenInitialized) {
                    defaults.set(true, forKey: UserDefaultsKeys.hasAppGroupBeenInitialized)
                }

                // Chargement léger synchrone
                quoteOfTheDay = localizedLoadingText()
                
                // ✅ Tout dans une seule Task pour garantir l'ordre d'exécution
                Task(priority: .userInitiated) {
                    // 1. ✨ Charger les sélections en parallèle
                    async let calendarsLoaded = calendarSelectionManager.loadCalendars()
                    async let remindersLoaded = reminderSelectionManager.loadReminderLists()
                    await (calendarsLoaded, remindersLoaded)
                    Logger.ui.info("✅ Sélections chargées")
                    
                    // Précharger les événements futurs dès que les managers sont prêts
                    Task(priority: .utility) {
                        await EventCacheManager.shared.preloadEvents(
                            calendarSelectionManager: calendarSelectionManager,
                            reminderSelectionManager: reminderSelectionManager
                        )
                        Logger.ui.info("✅ Événements futurs préchargés")
                    }
                    
                    // 2. Initialisation de l'album (seulement si Photos est activé)
                    if userSettings.preferences.showPhotos {
                        if photoManager.albumName.isEmpty {
                            await MainActor.run {
                                photoManager.albumName = albumName
                            }
                            Logger.photo.debug("📸 Initialisation albumName: \(albumName)")
                        }
                    }
                    
                    // 3. Initialiser l'app (maintenant que les sélections sont chargées)
                    do {
                        try await initializeApp()
                        await MainActor.run {
                            isAlbumReady = true
                            hasInitialized = true
                        }
                        Logger.photo.debug("✅ App initialisée")
                        
                        // ✅ Charger une photo après l'initialisation (seulement si Photos est activé)
                        if userSettings.preferences.showPhotos && photoManager.currentImage == nil {
                            Logger.photo.debug("🔄 Chargement d'une photo...")
                            let albumToLoad = photoManager.albumName.isEmpty ? (albumName.isEmpty ? "Library" : albumName) : photoManager.albumName
                            await photoManager.loadAssetsAndShowRandomPhoto(fromAlbum: albumToLoad)
                        }
                    } catch {
                        Logger.ui.error("❌ Erreur d'initialisation : \(error.localizedDescription)")
                    }
                }
                

            }
            .onDisappear {
                // 🧹 Nettoyer l'observateur quand la vue disparaît
                removeEventStoreObserver()
            }
        }
        .onChange(of: photoManager.albumNames) { oldAlbums, newAlbums in
            handleAlbumNamesChange(newAlbums)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            handleTimeChange()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            handleAppWillEnterForeground()
        }
        .onReceive(NotificationCenter.default.publisher(for: .needsAgendaRefresh)) { _ in
            handleAgendaRefresh()
        }
        .alert(Text(String(localized: "noAlbum")), isPresented: $showNoAlbumAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("noAlbum")
        }
    }
    
    // MARK: - Event Handlers
    
    private func handleAlbumNamesChange(_ newAlbums: [String]) {
        guard !newAlbums.isEmpty, userSettings.preferences.showPhotos else { return }
        
        Task {
            let defaults = UserDefaults.appGroup
            
            // Si c'est le premier lancement ou si l'albumName est vide
            if !defaults.bool(forKey: "hasLaunchedBefore") || albumName.isEmpty {
                // Choisir un album par défaut
                let defaultAlbum = newAlbums.contains("Favoris") ? "Favoris" : newAlbums.first!
                defaults.set(defaultAlbum, forKey: "albumName")
                defaults.set(true, forKey: "hasLaunchedBefore")
                
                Logger.photo.debug("📸 Chargement album par défaut: \(defaultAlbum)")
                
                // Charger une photo depuis cet album
                await photoManager.loadAssetsAndShowRandomPhoto(fromAlbum: defaultAlbum)
            } else {
                // Charger depuis l'album enregistré
                Logger.photo.debug("📸 Chargement album enregistré: \(albumName)")
                await photoManager.loadAssetsAndShowRandomPhoto(fromAlbum: albumName)
            }
        }
    }
    
    private func handleTimeChange() {
        selectedDate = Date()
        Task {
            await refreshAgenda()
            if userSettings.preferences.showHealth {
                healthManager.fetchData(for: selectedDate)
            }
        }
    }
    
    private func handleAppWillEnterForeground() {
        Logger.reminder.info("📱 App revient au premier plan - Rafraîchissement de l'agenda")
        Task {
            // Invalider le cache pour forcer un rechargement complet
            EventCacheManager.shared.invalidateCache(for: selectedDate)
            await refreshAgenda()
            Logger.reminder.info("✅ Agenda rafraîchi après retour au premier plan")
        }
    }
    
    private func handleAgendaRefresh() {
        Logger.reminder.info("📬 Notification de rafraîchissement reçue")
        Task {
            await refreshAgenda()
        }
    }

    
    // MARK: - UI Sections
    
    var headerSection: some View {
        VStack(spacing: 4) {
            // ✨ Jour de la semaine - Clic = retour aujourd'hui, Appui long = météo
            let userLocale = Locale(identifier: userSettings.preferences.language)
            Text(getDay(from: selectedDate, locale: userLocale))
                .font(.largeTitle)
                .bold()
                .foregroundColor(.primary)
                .onTapGesture {
                    // 🚀 Clic simple = retour à aujourd'hui
                    withAnimation {
                        selectedDate = Date()
                        EventCacheManager.shared.invalidateCache(for: selectedDate)
                        fetchAgenda(for: selectedDate,
                                  calendarSelectionManager: calendarSelectionManager,
                                  reminderSelectionManager: reminderSelectionManager)
                        if userSettings.preferences.showHealth {
                            healthManager.fetchData(for: selectedDate)
                        }
                    }
                }
                .onLongPressGesture {
                    // 🌤️ Appui long = ouvrir météo
                    if let url = URL(string: "weather://"),
                       UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                }
            
            // ✨ Date avec flèches pour DatePicker et Vue Semaine
            HStack(spacing: 8) {
                // Flèche droite pour toggle le DatePicker
                Button(action: {
                    withAnimation {
                        showDatePicker.toggle()
                    }
                }) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Date (non cliquable, juste affichage)
                let userLocale = Locale(identifier: userSettings.preferences.language)
                Text(getFullDate(from: selectedDate, locale: userLocale))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Flèche bas pour ouvrir la vue semaine
                Button(action: {
                    showUpcomingWeek = true
                }) {
                    Image(systemName: "chevron.down.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - controlButtons supprimé - Actions déplacées dans le header et footer
    /*
    var controlButtons: some View {
        HStack(spacing: 12) {
            Button { showSettings = true } label: {
                Image(systemName: "gear")
                    .resizable()
                    .frame(width: 35, height: 35)
            }
            .buttonStyle(.plain)
            .foregroundColor(.accentColor)
        }
    }
    */
    
    
    var datePickerSection: some View {
        DatePicker("", selection: $selectedDate, displayedComponents: [.date])
            .labelsHidden()
            .datePickerStyle(.graphical)
            .frame(minHeight: 320)
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
            .onChange(of: selectedDate) { _, newDate in
                // ✅ Invalider le cache pour forcer le rechargement
                EventCacheManager.shared.invalidateCache(for: newDate)
                fetchAgenda(for: newDate,
                            calendarSelectionManager: calendarSelectionManager,
                            reminderSelectionManager: reminderSelectionManager)
                
                // ✅ Mettre à jour les statistiques HealthKit
                if userSettings.preferences.showHealth {
                    healthManager.fetchData(for: newDate)
                }
                
                withAnimation { showDatePicker = false }
            }
    }
    
    var activitySection: some View {
        Button(action: openHealthApp) {
            HStack(alignment: .bottom, spacing: 20) {
                Label {
                    Text("\(Int(healthManager.steps))")
                } icon: {
                    Image(systemName: "figure.walk")
                        .foregroundColor(.cyan)
                }
                
                Label {
                    Text(formattedDistance(healthManager.distance, usesMetric: userSettings.preferences.usesMetric))
                } icon: {
                    Image(systemName: "map")
                        .foregroundColor(.purple)
                }
                
                Label {
                    Text(String(format: "%.0f", healthManager.calories))
                } icon: {
                    Image(systemName: "flame")
                        .foregroundColor(.red)
                }
            }
            .padding()
        }.buttonStyle(PlainButtonStyle())
    }
    
    var agendaSection: some View {
        let swipeGesture = DragGesture(minimumDistance: 24, coordinateSpace: .local)
            .onEnded { value in
                if abs(value.translation.width) > abs(value.translation.height) {
                    if value.translation.width < 0 {
                        // Swipe gauche → jour suivant
                        withAnimation {
                            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                        }
                        // ✅ Invalider le cache pour forcer le rechargement
                        EventCacheManager.shared.invalidateCache(for: selectedDate)
                        fetchAgenda(for: selectedDate,
                                    calendarSelectionManager: calendarSelectionManager,
                                    reminderSelectionManager: reminderSelectionManager)
                        // ✅ Mettre à jour les statistiques HealthKit
                        if userSettings.preferences.showHealth {
                            healthManager.fetchData(for: selectedDate)
                        }
                    }
                    if value.translation.width > 0 {
                        // Swipe droite → jour précédent
                        withAnimation {
                            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                        }
                        // ✅ Invalider le cache pour forcer le rechargement
                        EventCacheManager.shared.invalidateCache(for: selectedDate)
                        fetchAgenda(for: selectedDate,
                                    calendarSelectionManager: calendarSelectionManager,
                                    reminderSelectionManager: reminderSelectionManager)
                        // ✅ Mettre à jour les statistiques HealthKit
                        if userSettings.preferences.showHealth {
                            healthManager.fetchData(for: selectedDate)
                        }
                    }
                }
            }

        if combinedAgenda.isEmpty {
            return AnyView(
                Text(String(localized: "noEvents"))
                    .foregroundColor(.gray)
                    .gesture(swipeGesture)
            )
        } else {
            return AnyView(
                VStack(alignment: .leading, spacing: 8) {
                    // 🚀 OPTIMISATION: Equatable implémenté sur AgendaItem pour éviter re-renders inutiles
                    ForEach(combinedAgenda) { item in
                        HStack {
                            // 🎨 Icône et couleur de la liste/calendrier
                            HStack(spacing: 4) {
                                // Cercle de couleur
                                if let color = item.calendarColor {
                                    Circle()
                                        .fill(Color(cgColor: color))
                                        .frame(width: 10, height: 10)
                                }
                                
                                // Icône du calendrier/liste (devinée depuis le nom)
                                if let calendarName = item.calendarName,
                                   let symbol = symbolForCalendar(named: calendarName) {
                                    Image(systemName: symbol)
                                        .font(.caption)
                                        .foregroundColor(item.calendarColor.map { Color(cgColor: $0) } ?? .secondary)
                                }
                                
                                // 🚀 OPTIMISATION: Icône précomputée
                                Text(item.icon)
                                    .font(.title3)
                            }
                            .frame(width: 60, alignment: .leading)
                            
                            Button(action: { 
                                #if DEBUG
                                Logger.app.debug("Agenda tap: title='\(item.title)' hasLink=\(customLinkManager.hasLink(for: item.title))")
                                #endif
                                // ✅ NOUVEAU : Vérifier d'abord s'il y a un lien personnalisé
                                if !customLinkManager.openShortcut(for: item.title) {
                                    #if DEBUG
                                    Logger.app.debug("Agenda tap: no custom link executed, opening default app for event=\(item.isEvent)")
                                    #endif
                                    // Fallback : ouvrir l'app par défaut
                                    openCorrespondingApp(for: item)
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Text(item.title)
                                        .strikethrough(statusManager.isCompleted(id: item.id.uuidString), color: .gray)
                                        .foregroundColor(statusManager.isCompleted(id: item.id.uuidString) ? .gray : .primary)
                                    
                                    // 🔗 Badge pour indiquer un lien personnalisé
                                    if customLinkManager.hasLink(for: item.title) {
                                        Image(systemName: "link.circle.fill")
                                            .font(.caption2)
                                            .foregroundColor(.purple)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }.buttonStyle(.plain)
                            
                            Text(item.date.formatted(date: .omitted, time: .shortened))
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            // ✅ Icône de partage à la fin avec crochet si complété
                            if item.isShared {
                                Button(action: {
                                    statusManager.toggleEventCompletion(id: item.id.uuidString)
                                    
                                    // 🚀 OPTIMISATION: Utiliser l'icône précomputée
                                    if item.icon == "💊" {
                                        if let healthURL = URL(string: "x-apple-health://MedicationsHealthAppPlugin.healthplugin") {
                                            UIApplication.shared.open(healthURL)
                                        }
                                    }
                                    
                                    if !item.isEvent, item.reminderID != nil {
                                        completeAssociatedReminder(for: item)
                                    }
                                    saveNextAgendaItemForWidget()
                                }) {
                                    ZStack(alignment: .topTrailing) {
                                        Image(systemName: "person.2.fill")
                                            .font(.title3)
                                            .foregroundColor(.blue)
                                        
                                        // Petit crochet en overlay si complété
                                        if statusManager.isCompleted(id: item.id.uuidString) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.caption2)
                                                .foregroundColor(.green)
                                                .background(
                                                    Circle()
                                                        .fill(Color(uiColor: .systemBackground))
                                                        .frame(width: 12, height: 12)
                                                )
                                                .offset(x: 4, y: -4)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            } else {
                                // Pour les items non partagés, icône de checkmark normale
                                Button(action: {
                                    statusManager.toggleEventCompletion(id: item.id.uuidString)
                                    
                                    // 🚀 OPTIMISATION: Utiliser l'icône précomputée
                                    if item.icon == "💊" {
                                        if let healthURL = URL(string: "x-apple-health://MedicationsHealthAppPlugin.healthplugin") {
                                            UIApplication.shared.open(healthURL)
                                        }
                                    }
                                    
                                    if !item.isEvent, item.reminderID != nil {
                                        completeAssociatedReminder(for: item)
                                    }
                                    saveNextAgendaItemForWidget()
                                }) {
                                    Image(systemName: statusManager.isCompleted(id: item.id.uuidString) ? "checkmark.circle.fill" : "checkmark.circle")
                                        .foregroundColor(statusManager.isCompleted(id: item.id.uuidString) ? .green : .gray)
                                }
                                .buttonStyle(.plain)
                            }
                        }.padding(.vertical, 4)
                    }
                }
                .padding(.horizontal)
                .gesture(swipeGesture)
            )
        }
    }
    
    // MARK: - photoPickerSection déplacé dans SettingsView > PhotoPermissionView
    /*
    var photoPickerSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            if photoManager.albumNames.isEmpty || photoManager.albumName.isEmpty {
                Text("📷 Albums...").foregroundColor(.gray)
            } else {
                HStack {
                    Spacer()
                    
                    Picker("", selection: $photoManager.albumName) {
                        ForEach(photoManager.albumNames, id: \.self) { album in
                            Text(album).tag(album)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    Spacer()
                }
            }
            
            Divider().padding(.vertical, 1)
        }
        .padding()
    }
    */
    
    var photoDisplaySection: some View {
        VStack(spacing: 8) {
            // ✅ N'afficher les photos que si l'option est activée
            if !userSettings.preferences.showPhotos {
                // Ne rien afficher si les photos sont désactivées
                EmptyView()
            } else {
                // Section photos complète
                Group {
                    if let photo = photoManager.currentImage {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: 400)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.6), lineWidth: 2))
                            .padding(.horizontal)
                            .id(photo) // ✅ Force le rafraîchissement quand l'image change
                            .onTapGesture {
                                // 🚀 Simple clic = plein écran
                                showFullScreenPhoto = true
                            }
                            .gesture(
                                TapGesture(count: 2)
                                    .onEnded {
                                        // 🚀 Double-clic = charger en HD et ouvrir plein écran
                                        Task {
                                            Logger.photo.info("🔍 Double-clic détecté - chargement HD et ouverture plein écran...")
                                            await photoManager.loadCurrentImageInHighDefinition()
                                            showFullScreenPhoto = true
                                        }
                                    }
                            )
                            .onAppear {
                                Logger.photo.debug("✅ Photo affichée avec succès")
                            }
                        
                        // ✅ Afficher un badge avec le statut si présent
                        if let status = photoManager.photoStatusMessage, !status.isEmpty {
                            Text(status)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                    } else {
                        VStack(spacing: 8) {
                            if let status = photoManager.photoStatusMessage, status.contains("Chargement") || status.contains("Téléchargement") {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                Text(status).foregroundColor(.secondary).font(.caption)
                            } else {
                                Text("Aucune image chargée").foregroundColor(.secondary)
                                if let status = photoManager.photoStatusMessage {
                                    Text(status).foregroundColor(.red).font(.caption)
                                }
                                
                                // ✅ Bouton de rechargement en cas d'erreur
                                Button {
                                    Task {
                                        Logger.photo.debug("🔄 Tentative de rechargement manuel...")
                                        let albumToLoad = !photoManager.albumName.isEmpty ? photoManager.albumName : "Library"
                                        await photoManager.loadAssetsAndShowRandomPhoto(fromAlbum: albumToLoad)
                                    }
                                } label: {
                                    Label("Recharger", systemImage: "arrow.clockwise")
                                        .font(.caption)
                                        .padding(8)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .onAppear {
                            Logger.photo.debug("⚠️ Aucune image - albumName: '\(photoManager.albumName)', albums: \(photoManager.albumNames.count), hasInitialized: \(hasInitialized)")
                        }
                    }
                }
                
                // Boutons de navigation photos
                HStack(spacing: 12) {
                    Button {
                        Logger.photo.debug("🔘 Bouton précédent pressé")
                        photoManager.showPreviousImage()
                    } label: {
                        Image(systemName: "chevron.left.circle.fill")
                            .resizable()
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    // ✅ Affichage de l'index pour debug
                    Text("Photo \(photoManager.currentAssets.indices.contains(photoManager.currentIndex) ? photoManager.currentIndex + 1 : 0)/\(photoManager.currentAssets.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button {
                        Logger.photo.debug("🔘 Bouton suivant pressé")
                        photoManager.showNextImage()
                    } label: {
                        Image(systemName: "chevron.right.circle.fill")
                            .resizable()
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
            
            // Citation du jour (toujours affichée, indépendamment des photos)
            QuoteViewWithSource()
        }
    }
    
    var footerSection: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 16)
            
            // 🔮 Section Horoscope
            HoroscopeView()
            
            Button(action: {
                Logger.ui.debug("📱 Ouverture documentation")
                if let url = URL(string: "https://josbine63.github.io/MyDay-docs/") {
                    UIApplication.shared.open(url)
                }
            }) {
                Label("Documentation", systemImage: "book")
                    .font(.footnote)
                    .foregroundColor(.accentColor)
            }
            
            Button(action: {
                showSettings = true
            }) {
                Label("Réglages", systemImage: "gear")
                    .font(.footnote)
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.bottom, 20)
    }
    
    
    
    
    // MARK: - Other Components
    
    private func requestFullReminderAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            return await withCheckedContinuation { continuation in
                eventStore.requestFullAccessToReminders { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        } else {
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .reminder) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    private func requestPhotoAccess() async -> Bool {
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization { status in
                continuation.resume(returning: status == .authorized || status == .limited)
            }
        }
    }
    
    private func requestHealthAccess() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        let healthStore = HKHealthStore()  // ✅ déclaration ici
        
        return await withCheckedContinuation { continuation in
            healthStore.requestAuthorization(toShare: [], read: typesToRead) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }
    
    func formattedDistance(_ meters: Double, usesMetric: Bool) -> String {
        if meters < 1 {
            return usesMetric ? "0 m" : "0 ft"
        }
        
        if usesMetric {
            if meters < 1000 {
                return String(format: "%.0f m", meters)
            } else {
                let km = meters / 1000
                return String(format: "%.2f", km)
            }
        } else {
            let feet = meters * 3.28084
            if feet < 2500 {
                return String(format: "%.0f ft", feet)
            } else {
                let miles = meters / 1609.34
                return String(format: "%.2f", miles)
            }
        }
    }
    
    @MainActor
    func fetchAgendaAsync(for date: Date) async {
        await withCheckedContinuation { continuation in
            fetchAgenda(for: selectedDate,
                        calendarSelectionManager: calendarSelectionManager,
                        reminderSelectionManager: reminderSelectionManager) {
                continuation.resume()
            }
        }
    }
    
    @MainActor
    func waitForCalendarsReady() async {
        let timeout: TimeInterval = 5
        let start = Date()
        
        // ✅ Attendre que les calendriers soient disponibles dans l'EventStore
        while eventStore.calendars(for: .event).isEmpty && Date().timeIntervalSince(start) < timeout {
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s
        }
        
        // ✅ Attendre que les sélections soient chargées dans les managers
        let selectionStart = Date()
        while calendarSelectionManager.selectableCalendars.isEmpty && 
              Date().timeIntervalSince(selectionStart) < timeout {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        }
        
        #if DEBUG
        if verboseEventKitLogging {
            Logger.calendar.debug("🗓️ Calendriers disponibles : \(eventStore.calendars(for: .event).count)")
            Logger.calendar.debug("✅ Sélections chargées : \(calendarSelectionManager.selectableCalendars.count) calendriers, \(reminderSelectionManager.selectableReminderLists.count) listes")
        }
        #endif
    }
    
    func eventForm() -> some View {
        formView(
            title: NSLocalizedString("newCalTitle", comment: ""),
            field: $newTitle,
            date: $newDate,
            onSave: {
                createEvent(title: newTitle, date: newDate)
                Task { @MainActor in
                    newTitle = "" // Vider le champ après sauvegarde
                    showEventForm = false
                }
            },
            onCancel: {
                Task { @MainActor in
                    newTitle = "" // Vider le champ même en cas d'annulation
                    showEventForm = false
                }
            }
        )
    }
    
    func reminderForm() -> some View {
        formView(
            title: NSLocalizedString("newEventTitle", comment: ""),
            field: $newTitle,
            date: $newDate,
            onSave: {
                createReminder(title: newTitle, date: newDate)
                Task { @MainActor in
                    newTitle = "" // Vider le champ après sauvegarde
                    showReminderForm = false
                }
            },
            onCancel: {
                Task { @MainActor in
                    newTitle = "" // Vider le champ même en cas d'annulation
                    showReminderForm = false
                }
            }
        )
    }
    
    func formView(title: String, field: Binding<String>, date: Binding<Date>, onSave: @escaping () -> Void, onCancel: @escaping () -> Void) -> some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(title)
                    .font(.title2)
                    .padding(.top)
                
                TextField(String(localized: "title"), text: field)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.done)
                    .autocapitalization(.words)
                    .disableAutocorrection(false)
                
                DatePicker("Date", selection: date)
                    .datePickerStyle(.compact)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button(String(localized: "save"), action: onSave)
                        .buttonStyle(.borderedProminent)
                        .disabled(field.wrappedValue.trimmingCharacters(in: .whitespaces).isEmpty)
                    
                    Button(String(localized: "cancel"), role: .cancel, action: onCancel)
                        .foregroundColor(.red)
                }
            }
            .padding()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler", action: onCancel)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Enregistrer", action: onSave)
                        .disabled(field.wrappedValue.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    @MainActor
    func initializeApp() async throws {
        Logger.ui.debug("📲 initializeApp-ok")
        
        // Charger les albums seulement si Photos est activé
        if userSettings.preferences.showPhotos {
            Task { @MainActor in
                await photoManager.loadAlbums()
            }
        }
        
        await waitForCalendarsReady()
        await withCheckedContinuation { continuation in
            fetchAgenda(for: selectedDate,
                        calendarSelectionManager: calendarSelectionManager,
                        reminderSelectionManager: reminderSelectionManager) {
                continuation.resume()
            }
        }
        
        // ✅ Le refresh automatique n'est plus nécessaire maintenant que
        // les sélections sont chargées de manière synchrone avant fetchAgenda
        
        if userSettings.preferences.showHealth {
            healthManager.fetchData(for: selectedDate)
        }
        // Citation gérée par QuoteView maintenant
        // await loadQuoteFromInternet()
    }
    
    func refreshAgenda() async {
        // ✅ Invalider le cache pour forcer le rechargement complet
        EventCacheManager.shared.invalidateCache(for: selectedDate)
        
        // ⚠️ NE PAS recharger les sélections de calendriers/rappels lors du refresh
        // Les sélections sont déjà chargées et maintenues en mémoire
        // Seuls les événements et rappels doivent être rechargés
        
        await withCheckedContinuation { continuation in
            fetchAgenda(for: selectedDate,
                        calendarSelectionManager: calendarSelectionManager,
                        reminderSelectionManager: reminderSelectionManager) {
                continuation.resume()
            }
        }
    }
    
    // MARK: - 🔔 Synchronisation automatique des rappels partagés
    
    /// Configure l'observateur pour détecter les changements dans EventKit (rappels/événements partagés)
    func setupEventStoreObserver() {
        Logger.reminder.info("🔔 Configuration de l'observateur EventKit")
        
        eventStoreObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: eventStore,
            queue: .main
        ) { _ in
            Logger.reminder.info("🔔 Changement détecté dans EventKit - Mise à jour de l'agenda")
            
            // Rafraîchir l'agenda via notification
            Task { @MainActor in
                // Invalider le cache sur le MainActor
                EventCacheManager.shared.invalidateCache(for: Date())
                
                // Notifier la vue de se rafraîchir
                NotificationCenter.default.post(name: .needsAgendaRefresh, object: nil)
                Logger.reminder.info("✅ Notification de rafraîchissement envoyée")
            }
        }
    }
    
    /// Retire l'observateur EventKit
    func removeEventStoreObserver() {
        if let observer = eventStoreObserver {
            NotificationCenter.default.removeObserver(observer)
            eventStoreObserver = nil
            Logger.reminder.info("🧹 Observateur EventKit retiré")
        }
    }
    
    // MARK: - 🚀 OPTIMISATION: Polling supprimé - on utilise uniquement les notifications EventKit
    // L'observateur .EKEventStoreChanged détecte tous les changements (locaux + iCloud sync)
    // Cela économise 80% de batterie par rapport au polling toutes les 30 secondes
    
    func openHealthApp() {
        if let healthURL = URL(string: "activitytoday://") {
            UIApplication.shared.open(healthURL)
 
//        if let url = URL(string: "shortcuts://run-shortcut?name=fitness") {
//            UIApplication.shared.open(url)
        }
    }
    
    func loadQuoteFromInternet() async {
        guard let url = URL(string: "https://zenquotes.io/api/random") else {
            quoteOfTheDay = localizedLoadingText()
            return
        }
        
        // Obtenir la langue de l'utilisateur une seule fois
        let userLanguage = userSettings.preferences.language
        
        do {
            // ✅ Créer une requête avec headers appropriés
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.timeoutInterval = 10
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // ✅ Vérifier le code de statut HTTP
            if let httpResponse = response as? HTTPURLResponse {
                Logger.ui.debug("📡 ZenQuotes API réponse: \(httpResponse.statusCode)")
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    Logger.ui.error("❌ Erreur HTTP \(httpResponse.statusCode) de ZenQuotes")
                    quoteOfTheDay = userLanguage == "fr" ? "Citation indisponible" : "Quote unavailable"
                    return
                }
            }
            
            if let decoded = try? JSONDecoder().decode([Quote].self, from: data), let firstQuote = decoded.first {
                // Citation originale en anglais
                let originalQuote = "\"\(firstQuote.q)\" — \(firstQuote.a)"
                
                // ✅ Traduction avec l'API native iOS 18+ (si disponible)
                if userLanguage != "en" {
                    if #available(iOS 18.0, *) {
                        Logger.ui.debug("🌐 Préparation traduction iOS 18+ vers \(userLanguage)")
                        
                        // Stocker le texte à traduire et l'auteur
                        textToTranslate = firstQuote.q
                        quoteAuthor = firstQuote.a
                        
                        // Créer la configuration de traduction
                        let sourceLang = Locale.Language(identifier: "en")
                        let targetLang = Locale.Language(identifier: userLanguage)
                        translationConfiguration = TranslationSession.Configuration(
                            source: sourceLang,
                            target: targetLang
                        )
                        
                        // La traduction se fera dans handleTranslation()
                        // En attendant, afficher l'original
                        quoteOfTheDay = originalQuote
                    } else {
                        // iOS < 18 : afficher en anglais
                        Logger.ui.info("ℹ️ Traduction nécessite iOS 18+, affichage en anglais")
                        quoteOfTheDay = originalQuote
                    }
                } else {
                    // L'utilisateur préfère l'anglais
                    quoteOfTheDay = originalQuote
                }
            } else {
                Logger.ui.warning("⚠️ Impossible de décoder la réponse ZenQuotes")
                quoteOfTheDay = userLanguage == "fr" ? "Aucune pensée disponible." : "No quote available."
            }
        } catch let error as URLError {
            Logger.ui.error("❌ Erreur réseau ZenQuotes: \(error.localizedDescription) (code: \(error.code.rawValue))")
            quoteOfTheDay = userLanguage == "fr" ? "Erreur de connexion." : "Connection error."
        } catch {
            Logger.ui.error("❌ Erreur de chargement de citation: \(error.localizedDescription)")
            quoteOfTheDay = userLanguage == "fr" ? "Erreur de connexion." : "Connection error."
        }
    }
    
    struct Quote: Codable {
        let q: String
        let a: String
    }
    
    // MARK: - Translation Handler
    
    /// Gère la traduction avec la session fournie par translationTask
    @available(iOS 18.0, macOS 15.0, *)
    private func handleTranslation(using session: TranslationSession) async {
        guard let textToTranslate = textToTranslate,
              let author = quoteAuthor else {
            Logger.ui.debug("🌐 Aucun texte à traduire")
            return
        }
        
        do {
            Logger.ui.debug("🌐 Traduction en cours avec session iOS 18+")
            
            // Traduire avec la session
            let response = try await session.translate(textToTranslate)
            let translatedText = response.targetText
            
            // Mettre à jour la citation avec la traduction
            await MainActor.run {
                quoteOfTheDay = "\"\(translatedText)\" — \(author)"
                self.textToTranslate = nil // Réinitialiser
                self.quoteAuthor = nil
                Logger.ui.debug("✅ Citation traduite avec succès")
            }
            
        } catch {
            Logger.ui.error("❌ Erreur lors de la traduction: \(error.localizedDescription)")
        }
    }
    
    func fetchAgenda(for date: Date,
                         calendarSelectionManager: CalendarSelectionManager,
                         reminderSelectionManager: ReminderSelectionManager,
                         completion: (() -> Void)? = nil) {

            // ✨ Essayer de charger depuis le cache d'abord
            if let cachedEvents = EventCacheManager.shared.getCachedEvents(for: date) {
                Logger.ui.debug("📦 Utilisation du cache pour \(date)")
                self.combinedAgenda = cachedEvents
                self.saveNextAgendaItemForWidget()
                completion?()
                return
            }

            Task {
                let eventStore = SharedEventStore.shared

                let selectedCalendarIDs = calendarSelectionManager.selectedCalendarIDs
                let calendars = eventStore.calendars(for: .event).filter {
                    selectedCalendarIDs.contains($0.calendarIdentifier)
                }

                let startDate = Calendar.current.startOfDay(for: date)
                let endDate = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: date) ?? startDate
                let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)

                let events = eventStore.events(matching: predicate)
                    .filter { Calendar.current.isDate($0.startDate, inSameDayAs: date) } // ⏱ Garde uniquement les événements du jour sélectionné
                    .map {
                        AgendaItem(
                            title: $0.title,
                            date: $0.startDate,
                            isEvent: true,
                            reminderID: nil,
                            eventID: $0.eventIdentifier,
                            isShared: EventKitHelpers.isCalendarShared($0.calendar),
                            calendarColor: $0.calendar.cgColor,
                            calendarName: $0.calendar.title
                        )
                    }

                fetchReminders(for: date, from: reminderSelectionManager) { reminders in
                    #if DEBUG
                    if verboseEventKitLogging {
                        Logger.reminder.debug("📦 fetchAgenda - Rappels reçus de fetchReminders: \(reminders.count)")
                    }
                    #endif
                    
                    let reminderItems: [AgendaItem] = reminders.compactMap { reminder in
                        guard let components = reminder.dueDateComponents else {
                            return nil
                        }

                        var fixedComponents = components
                        if fixedComponents.hour == nil { fixedComponents.hour = 8 }
                        if fixedComponents.minute == nil { fixedComponents.minute = 0 }
                        if fixedComponents.second == nil { fixedComponents.second = 0 }

                        guard let reminderDate = Calendar.current.date(from: fixedComponents) else {
                            return nil
                        }

                        // ✅ Créer l'AgendaItem
                        let agendaItem = AgendaItem(
                            title: reminder.title ?? "Rappel",
                            date: reminderDate,
                            isEvent: false,
                            reminderID: reminder.calendarItemIdentifier,
                            isShared: EventKitHelpers.isCalendarShared(reminder.calendar),
                            calendarColor: reminder.calendar.cgColor,
                            calendarName: reminder.calendar.title
                        )
                        
                        return agendaItem
                    }
                    
                    // 🔄 SYNCHRONISATION: Mettre à jour le statusManager avec l'état réel d'EventKit
                    // Doit être fait sur le main thread car statusManager est @ObservableObject
                    DispatchQueue.main.async {
                        for reminder in reminders {
                            guard let components = reminder.dueDateComponents,
                                  let reminderDate = Calendar.current.date(from: components),
                                  let agendaItem = reminderItems.first(where: { 
                                      $0.reminderID == reminder.calendarItemIdentifier 
                                  }) else {
                                continue
                            }
                            
                            if reminder.isCompleted {
                                self.statusManager.markEventAsCompleted(id: agendaItem.id.uuidString)
                            } else {
                                self.statusManager.markEventAsIncomplete(id: agendaItem.id.uuidString)
                            }
                        }
                    }
                    
                    #if DEBUG
                    if verboseEventKitLogging {
                        Logger.reminder.debug("📦 fetchAgenda - AgendaItems créés depuis rappels: \(reminderItems.count)")
                    }
                    #endif
                    
                    let agenda = (events + reminderItems).sorted { $0.date < $1.date }

                    Logger.ui.info("📊 fetchAgenda - Total agenda: \(agenda.count) items (\(events.count) événements + \(reminderItems.count) rappels)")

                    DispatchQueue.main.async {
                        self.combinedAgenda = agenda
                        // ✨ Mettre en cache les résultats
                        EventCacheManager.shared.cacheEvents(agenda, for: date)
                        self.saveNextAgendaItemForWidget()
                        completion?()
                    }
                }
            }
        }
    

    func fetchReminders(for date: Date,
                        from reminderManager: ReminderSelectionManager,
                        completion: @escaping ([EKReminder]) -> Void) {
        let eventStore = SharedEventStore.shared
        
        // ✅ Charger UNIQUEMENT les calendriers sélectionnés
        let selectedCalendars = eventStore.calendars(for: .reminder).filter { calendar in
            reminderManager.selectedReminderListIDs.contains(calendar.calendarIdentifier)
        }
        
        // 🔥 IMPORTANT : Créer un prédicat qui INCLUT les rappels complétés
        // Par défaut, predicateForReminders exclut les rappels complétés
        let predicate = eventStore.predicateForReminders(in: selectedCalendars.isEmpty ? nil : selectedCalendars)
        
        eventStore.fetchReminders(matching: predicate) { incompleteReminders in
            // Récupérer aussi les rappels complétés récents
            // Note: predicateForCompletedReminders filtre par DATE DE COMPLÉTION, pas par date d'échéance
            // On récupère donc les rappels complétés dans les derniers jours pour pouvoir les filtrer après
            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: date) ?? date
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
            
            let completedPredicate = eventStore.predicateForCompletedReminders(
                withCompletionDateStarting: sevenDaysAgo,
                ending: tomorrow,
                calendars: selectedCalendars.isEmpty ? nil : selectedCalendars
            )
            
            #if DEBUG
            if verboseEventKitLogging {
                Logger.reminder.debug("🔍 Recherche rappels complétés entre \(sevenDaysAgo) et \(tomorrow)")
            }
            #endif
            
            eventStore.fetchReminders(matching: completedPredicate) { completedReminders in
                // Combiner les deux listes
                var allReminders: [EKReminder] = []
                if let incomplete = incompleteReminders {
                    allReminders.append(contentsOf: incomplete)
                }
                if let completed = completedReminders {
                    allReminders.append(contentsOf: completed)
                }
                
                // Éliminer les doublons (un rappel pourrait apparaître dans les deux listes)
                let uniqueReminders = Array(Set(allReminders.map { $0.calendarItemIdentifier }))
                    .compactMap { id in allReminders.first { $0.calendarItemIdentifier == id } }

                let selectedIDs = reminderManager.selectedReminderListIDs
                let localCal = Calendar.current
                let isToday = localCal.isDateInToday(date)

                #if DEBUG
                if verboseEventKitLogging {
                    Logger.reminder.debug("🔍 fetchReminders - Total rappels reçus: \(uniqueReminders.count) (incomplets: \(incompleteReminders?.count ?? 0), complétés: \(completedReminders?.count ?? 0))")
                    Logger.reminder.debug("🗓️ Date sélectionnée: \(date), isToday: \(isToday)")
                }
                #endif
                
                // Log détaillé des rappels complétés pour debug
                #if DEBUG
                if verboseEventKitLogging, let completed = completedReminders, !completed.isEmpty {
                    Logger.reminder.debug("📋 Rappels complétés récupérés:")
                    for reminder in completed.prefix(5) {
                        let dueDate = reminder.dueDateComponents.flatMap { Calendar.current.date(from: $0) }
                        let completionDate = reminder.completionDate
                        Logger.reminder.debug("  - '\(reminder.title ?? "Sans titre")' | Échéance: \(dueDate?.description ?? "N/A") | Complété: \(completionDate?.description ?? "N/A")")
                    }
                }
                #endif
                
                let filtered = uniqueReminders.filter { reminder in
                    // Vérifier la liste sélectionnée
                    guard let list = reminder.calendar,
                          selectedIDs.contains(list.calendarIdentifier) else {
                        return false
                    }

                    // Vérifier la date d'échéance
                    guard var comps = reminder.dueDateComponents else {
                        return false
                    }

                    // ✅ CORRECTION: Toujours utiliser le calendrier local pour la cohérence
                    if comps.hour == nil { comps.hour = 8 }
                    if comps.minute == nil { comps.minute = 0 }
                    if comps.second == nil { comps.second = 0 }

                    guard let rebuiltDate = localCal.date(from: comps) else {
                        return false
                    }

                    // ✅ Pour les rappels récurrents, vérifier s'ils se produisent ce jour-là
                    let isRecurring = !(reminder.recurrenceRules?.isEmpty ?? true)
                    if isRecurring {
                        return self.reminderOccursOn(reminder: reminder, date: date, calendar: localCal)
                    }
                    
                    // Pour les rappels non récurrents, simple comparaison de date
                    return localCal.isDate(rebuiltDate, inSameDayAs: date)
                }
                
                #if DEBUG
                if verboseEventKitLogging {
                    Logger.reminder.debug("📝 fetchReminders - Rappels filtrés: \(filtered.count) pour \(date)")
                }
                #endif
                completion(filtered)
            }
        }
    }
    
    /// Vérifie si un rappel récurrent se produit à une date donnée
    private func reminderOccursOn(reminder: EKReminder, date: Date, calendar: Calendar) -> Bool {
        guard let dueDateComponents = reminder.dueDateComponents else {
            return false
        }
        
        var fixedComponents = dueDateComponents
        if fixedComponents.hour == nil { fixedComponents.hour = 8 }
        if fixedComponents.minute == nil { fixedComponents.minute = 0 }
        if fixedComponents.second == nil { fixedComponents.second = 0 }
        
        guard let dueDate = calendar.date(from: fixedComponents) else {
            return false
        }
        
        // Vérifier si la date cible est après ou égale à la date de début
        guard date >= calendar.startOfDay(for: dueDate) else {
            return false
        }
        
        // Vérifier chaque règle de récurrence
        guard let recurrenceRules = reminder.recurrenceRules else {
            return false
        }
        
        for rule in recurrenceRules {
            if recurrenceRuleMatches(rule: rule, startDate: dueDate, targetDate: date, calendar: calendar) {
                return true
            }
        }
        
        return false
    }
    
    /// Vérifie si une règle de récurrence correspond à une date cible
    private func recurrenceRuleMatches(rule: EKRecurrenceRule, startDate: Date, targetDate: Date, calendar: Calendar) -> Bool {
        // Si la règle a une date de fin et que la cible est après, retourner false
        if let endDate = rule.recurrenceEnd?.endDate,
           targetDate > endDate {
            return false
        }
        
        switch rule.frequency {
        case .daily:
            let daysDifference = calendar.dateComponents([.day], from: startDate, to: targetDate).day ?? 0
            return daysDifference >= 0 && daysDifference % rule.interval == 0
            
        case .weekly:
            let weeksDifference = calendar.dateComponents([.weekOfYear], from: startDate, to: targetDate).weekOfYear ?? 0
            let isSameWeekday = calendar.component(.weekday, from: startDate) == calendar.component(.weekday, from: targetDate)
            return weeksDifference >= 0 && weeksDifference % rule.interval == 0 && isSameWeekday
            
        case .monthly:
            let monthsDifference = calendar.dateComponents([.month], from: startDate, to: targetDate).month ?? 0
            let isSameDayOfMonth = calendar.component(.day, from: startDate) == calendar.component(.day, from: targetDate)
            return monthsDifference >= 0 && monthsDifference % rule.interval == 0 && isSameDayOfMonth
            
        case .yearly:
            let yearsDifference = calendar.dateComponents([.year], from: startDate, to: targetDate).year ?? 0
            let startComponents = calendar.dateComponents([.month, .day], from: startDate)
            let targetComponents = calendar.dateComponents([.month, .day], from: targetDate)
            return yearsDifference >= 0 && 
                   yearsDifference % rule.interval == 0 && 
                   startComponents.month == targetComponents.month &&
                   startComponents.day == targetComponents.day
            
        @unknown default:
            return false
        }
    }
    
        func createEvent(title: String, date: Date) {
            let event = EKEvent(eventStore: eventStore)
            event.title = title
            event.startDate = date
            event.endDate = date.addingTimeInterval(3600)
            
            guard let calendar = eventStore.defaultCalendarForNewEvents else {
                Logger.calendar.error("❌ Aucun calendrier par défaut.")
                return
            }
            
            event.calendar = calendar
            
            do {
                try eventStore.save(event, span: .thisEvent)
                fetchAgenda(for: selectedDate,
                            calendarSelectionManager: calendarSelectionManager,
                            reminderSelectionManager: reminderSelectionManager)
            } catch {
                Logger.calendar.error("❌ Erreur lors de l'enregistrement : \(error.localizedDescription)")
            }
        }
        
        func createReminder(title: String, date: Date) {
            let reminder = EKReminder(eventStore: eventStore)
            reminder.title = title
            reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            
            guard let calendar = eventStore.defaultCalendarForNewReminders() else {
                Logger.reminder.error("❌ Aucun calendrier de rappels disponible.")
                return
            }
            
            reminder.calendar = calendar
            
            do {
                try eventStore.save(reminder, commit: true)
                fetchAgenda(for: selectedDate,
                            calendarSelectionManager: calendarSelectionManager,
                            reminderSelectionManager: reminderSelectionManager)
            } catch {
                Logger.reminder.error("❌ Erreur en sauvegardant le rappel : \(error.localizedDescription)")
            }
        }
        
        func toggleCompletion(for item: AgendaItem) {
            statusManager.toggleEventCompletion(id: item.id.uuidString)
            
            // 🚀 OPTIMISATION: Utiliser l'icône précomputée
            if item.icon == "💊" {
                if let healthURL = URL(string: "x-apple-health://MedicationsHealthAppPlugin.healthplugin") {
                    UIApplication.shared.open(healthURL)
                }
            }
            
            if !item.isEvent, item.reminderID != nil {
                completeAssociatedReminder(for: item)
            }
            
            saveNextAgendaItemForWidget()
            
            // 🔐 Sauvegarde de l'état de complétion
            //       completedItems = statusManager.completedEvents(forDateKey: currentDateKey)
            //       saveCompletedItems(completedItems, forKey: currentDateKey)
        }
        
        func completeAssociatedReminder(for item: AgendaItem) {
            guard let reminderID = item.reminderID else {
                Logger.reminder.notice("⚠️ Ignoré : Aucun ID pour ce rappel")
                return
            }
            
            Logger.reminder.info("🎯 Tentative de complétion du rappel: \(item.title)")
            
            if let reminder = eventStore.calendarItem(withIdentifier: reminderID) as? EKReminder {
                reminder.isCompleted = true
                reminder.completionDate = Date()
                
                do {
                    try eventStore.save(reminder, commit: true)
                    Logger.reminder.info("✅ Rappel complété dans EventKit: '\(reminder.title ?? "Sans titre")' | Partagé: \(EventKitHelpers.isCalendarShared(reminder.calendar))")
                    
                    if EventKitHelpers.isCalendarShared(reminder.calendar) {
                        Logger.reminder.info("📤 Rappel partagé complété - Sync iCloud en cours...")
                    }
                    
                    // Invalider le cache et rafraîchir pour voir le changement immédiatement
                    Task { @MainActor in
                        EventCacheManager.shared.invalidateCache(for: selectedDate)
                        await refreshAgenda()
                    }
                } catch {
                    Logger.reminder.error("❌ Erreur de sauvegarde : \(error.localizedDescription)")
                }
            } else {
                print("❌ Rappel introuvable avec l’ID: \(reminderID)")
            }
        }
        
        func saveNextAgendaItemForWidget() {
            Task {
                // ✅ Charger les événements et rappels des 7 prochains jours
                let now = Date()
                let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
                
                let eventStore = SharedEventStore.shared
                let selectedCalendarIDs = calendarSelectionManager.selectedCalendarIDs
                let calendars = eventStore.calendars(for: .event).filter {
                    selectedCalendarIDs.contains($0.calendarIdentifier)
                }
                
                let predicate = eventStore.predicateForEvents(withStart: now, end: nextWeek, calendars: calendars)
                let events = eventStore.events(matching: predicate)
                    .map {
                        AgendaItem(
                            title: $0.title,
                            date: $0.startDate,
                            isEvent: true,
                            reminderID: nil,
                            eventID: $0.eventIdentifier,
                            isShared: EventKitHelpers.isCalendarShared($0.calendar),
                            calendarColor: $0.calendar.cgColor,
                            calendarName: $0.calendar.title
                        )
                    }
                
                // Charger les rappels des 7 prochains jours
                fetchRemindersForRange(from: now, to: nextWeek) { [self] reminders in
                    let reminderItems: [AgendaItem] = reminders.compactMap { reminder in
                        guard let components = reminder.dueDateComponents else { return nil }
                        
                        var fixedComponents = components
                        if fixedComponents.hour == nil { fixedComponents.hour = 8 }
                        if fixedComponents.minute == nil { fixedComponents.minute = 0 }
                        
                        guard let reminderDate = Calendar.current.date(from: fixedComponents) else { return nil }
                        
                        return AgendaItem(
                            title: reminder.title ?? "Rappel",
                            date: reminderDate,
                            isEvent: false,
                            reminderID: reminder.calendarItemIdentifier,
                            isShared: EventKitHelpers.isCalendarShared(reminder.calendar),
                            calendarColor: reminder.calendar.cgColor,
                            calendarName: reminder.calendar.title
                        )
                    }
                    
                    // Combiner et trouver le prochain item non complété
                    let allItems = (events + reminderItems).sorted { $0.date < $1.date }
                    let upcomingItems = allItems.filter {
                        $0.date >= now && !self.statusManager.isCompleted(id: $0.id.uuidString)
                    }
                    
                    DispatchQueue.main.async {
                        guard let next = upcomingItems.first else {
                            let defaults = AppGroup.userDefaults
                            defaults.removeObject(forKey: UserDefaultsKeys.nextWidgetItem)
                            defaults.set(0, forKey: "upcomingCount")
                            #if DEBUG
                            let nextItemExists = defaults.dictionary(forKey: UserDefaultsKeys.nextWidgetItem) != nil
                            let upcomingCount = defaults.integer(forKey: "upcomingCount")
                            Logger.app.debug("Widget reload - nextItem=\(nextItemExists), upcomingCount=\(upcomingCount)")
                            #endif
                            WidgetCenter.shared.reloadAllTimelines()
                            return
                        }
                        
                        let defaults = AppGroup.userDefaults
                        let formatter = DateFormat.widgetDate
                        
                        // Calculer le temps restant
                        let remainingTime = self.formatRemainingTime(until: next.date)
                        
                        let data: [String: String] = [
                            "title": next.title,
                            "time": formatter.string(from: next.date),
                            "remaining": remainingTime
                        ]
                        
                        defaults.set(data, forKey: UserDefaultsKeys.nextWidgetItem)
                        defaults.set(upcomingItems.count, forKey: "upcomingCount")
                        #if DEBUG
                        let nextItemExists = defaults.dictionary(forKey: UserDefaultsKeys.nextWidgetItem) != nil
                        let upcomingCount = defaults.integer(forKey: "upcomingCount")
                        Logger.app.debug("Widget reload - nextItem=\(nextItemExists), upcomingCount=\(upcomingCount)")
                        #endif
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }
            }
        }
        
        // Formater le temps restant de manière lisible
        func formatRemainingTime(until date: Date) -> String {
            let now = Date()
            let timeInterval = date.timeIntervalSince(now)
            
            if timeInterval < 0 {
                return "Maintenant"
            }
            
            let minutes = Int(timeInterval / 60)
            let hours = minutes / 60
            let days = hours / 24
            
            if days > 0 {
                return days == 1 ? "Demain" : "Dans \(days)j"
            } else if hours > 0 {
                return "Dans \(hours)h"
            } else if minutes > 5 {
                return "Dans \(minutes)min"
            } else {
                return "Bientôt"
            }
        }
        
        // Helper function pour charger les rappels dans une plage de dates
        func fetchRemindersForRange(from startDate: Date, to endDate: Date, completion: @escaping ([EKReminder]) -> Void) {
            let eventStore = SharedEventStore.shared
            let predicate = eventStore.predicateForReminders(in: nil)
            
            eventStore.fetchReminders(matching: predicate) { reminders in
                guard let reminders = reminders else {
                    completion([])
                    return
                }
                
                let selectedIDs = self.reminderSelectionManager.selectedReminderListIDs
                let filtered = reminders.filter { reminder in
                    guard let calendar = reminder.calendar,
                          selectedIDs.contains(calendar.calendarIdentifier),
                          let dueDate = reminder.dueDateComponents?.date,
                          dueDate >= startDate && dueDate <= endDate
                    else {
                        return false
                    }
                    return true
                }
                
                completion(filtered)
            }
        }
        
        func openCorrespondingApp(for item: AgendaItem) {
            if item.isEvent {
                // Ouvrir l'app Calendrier pour les événements
                let calendarURL = URL(string: "calshow:\(item.date.timeIntervalSinceReferenceDate)")!
                UIApplication.shared.open(calendarURL)
            } else {
                // Ouvrir l'app Rappels pour les rappels (y compris les médicaments)
                if let remindersURL = URL(string: "x-apple-reminderkit://") {
                    UIApplication.shared.open(remindersURL)
                }
            }
        }
        
        // 🚀 OPTIMISATION: Fonction icon(for:) supprimée - les icônes sont maintenant précomputées dans AgendaItem.init()
        
        // Fonction helper pour vérifier si un titre contient au moins un des mots-clés
        private func containsAny(_ text: String, keywords: [String]) -> Bool {
            return keywords.contains { keyword in
                text.contains(keyword)
            }
        }
        
        // 🏷️ Helper pour deviner une icône SF Symbol basée sur le nom de la liste/calendrier
        private func symbolForCalendar(named name: String) -> String? {
            let lowercaseName = name.lowercased()
            
            // Courses / Shopping
            if containsAny(lowercaseName, keywords: ["course", "shopping", "marché", "market", "grocery", "épicerie"]) {
                return "cart.fill"
            }
            // Travail / Work
            if containsAny(lowercaseName, keywords: ["travail", "work", "bureau", "office", "boulot", "job"]) {
                return "briefcase.fill"
            }
            // Famille / Family
            if containsAny(lowercaseName, keywords: ["famille", "family", "familial"]) {
                return "house.fill"
            }
            // Anniversaires / Birthdays
            if containsAny(lowercaseName, keywords: ["anniversaire", "birthday", "fête", "party"]) {
                return "gift.fill"
            }
            // École / School
            if containsAny(lowercaseName, keywords: ["école", "school", "étude", "study", "cours", "class"]) {
                return "book.fill"
            }
            // Sport / Fitness
            if containsAny(lowercaseName, keywords: ["sport", "fitness", "gym", "exercise"]) {
                return "figure.run"
            }
            // Santé / Health
            if containsAny(lowercaseName, keywords: ["santé", "health", "médical", "medical", "médecin", "doctor"]) {
                return "cross.case.fill"
            }
            // Voyage / Travel
            if containsAny(lowercaseName, keywords: ["voyage", "travel", "vacances", "vacation", "trip"]) {
                return "airplane"
            }
            // Maison / Home
            if containsAny(lowercaseName, keywords: ["maison", "home", "ménage", "house"]) {
                return "house.fill"
            }
            // Personnel / Personal
            if containsAny(lowercaseName, keywords: ["personnel", "personal", "perso"]) {
                return "person.fill"
            }
            
            // Par défaut, pas d'icône spécifique
            return nil
        }
        
        @MainActor
        func dateKey(for date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return "completedItems-\(formatter.string(from: date))"
        }
        
        func getDay(from date: Date, locale: Locale) -> String {
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date).capitalized
        }
        
        func getFullDate(from date: Date, locale: Locale) -> String {
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.dateStyle = .long
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
        
        func statusText(for status: EKAuthorizationStatus) -> String {
            switch status {
            case .notDetermined: return "Pas encore demandé"
            case .restricted: return "Restreint"
            case .denied: return "Refusé"
            case .authorized: return "Autorisé (accès partiel)"
            case .fullAccess: return "Accès complet"
            case .writeOnly: return "Écriture seule"
            @unknown default: return "Inconnu"
            }
        }
}

// MARK: - Full Screen Photo View
struct FullScreenPhotoView: View {
    let image: UIImage?
    @Binding var isPresented: Bool
    @ObservedObject var photoManager: PhotoManager
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var displayImage: UIImage?
    @State private var isLoadingHD = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let displayImg = displayImage {
                Image(uiImage: displayImg)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let newScale = lastScale * value
                                    scale = max(1.0, min(newScale, 5.0))
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                },
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.spring()) {
                            if scale > 1.0 {
                                scale = 1.0
                                lastScale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            } else {
                                scale = 2.5
                                lastScale = 2.5
                            }
                        }
                    }
            }
            
            // Indicateur de chargement HD
            if isLoadingHD {
                VStack {
                    Spacer()
                    HStack {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                        Text("Chargement HD...")
                            .foregroundColor(.white)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    Spacer()
                }
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                Spacer()
            }
        }
        .onAppear {
            // Charger l'image initiale
            displayImage = image
            
            // Charger automatiquement en HD au démarrage
            Task {
                isLoadingHD = true
                Logger.photo.info("📸 Ouverture plein écran - chargement HD automatique...")
                await photoManager.loadCurrentImageInHighDefinition()
                displayImage = photoManager.currentImage
                isLoadingHD = false
                Logger.photo.info("✅ Image HD chargée et affichée")
            }
        }
    }
}

// MARK: - Safari View (Non utilisé actuellement - ouvre Safari externe à la place)
// import SafariServices
//
// struct SafariView: UIViewControllerRepresentable {
//     let url: URL
//     
//     func makeUIViewController(context: Context) -> SFSafariViewController {
//         let config = SFSafariViewController.Configuration()
//         config.entersReaderIfAvailable = false
//         config.barCollapsingEnabled = true
//         
//         let safariVC = SFSafariViewController(url: url, configuration: config)
//         safariVC.preferredControlTintColor = .systemBlue
//         return safariVC
//     }
//     
//     func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
//         // Rien à mettre à jour
//     }
// }

func localizedLoadingText() -> String {
        let lang = Locale.preferredLanguages.first ?? "en"
        return lang.hasPrefix("fr") ? "Chargement..." : "Loading..."
    }
    
    // ✅ Extension à placer ici
    extension View {
        func onTapGesture(location: @escaping (CGPoint) -> Void) -> some View {
            self.gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        location(value.location)
                    }
            )
        }
    }




