// ContentView.swift
import Foundation
import SwiftUI
import EventKit
import WidgetKit
import UIKit
import Photos
import HealthKit
import CryptoKit

// MARK: - Extensions

extension String {
    func sha256ToUUID() -> String {
        let data = Data(self.utf8)
        let hash = SHA256.hash(data: data)
        let bytes = Array(hash.prefix(16))
        let uuid = UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
        return uuid.uuidString
    }
}
extension UserDefaults {
    static var appGroup: UserDefaults {
        return UserDefaults(suiteName: "group.com.josblais.myday")!
    }
}

// MARK: - PermissionManager
@MainActor
class PermissionManager: ObservableObject {
    @Published var allAccessGranted = false
    private let eventStore = EKEventStore()
    private let healthStore = HKHealthStore()

    func requestAllPermissions() async -> Bool {
        async let calendarGranted = requestFullCalendarAccess()
        async let reminderGranted = requestFullReminderAccess()
        async let photoGranted = requestPhotoAccess()
        async let healthGranted = requestHealthAccess()

        let results = await [calendarGranted, reminderGranted, photoGranted, healthGranted]
        allAccessGranted = results.allSatisfy { $0 }
        return allAccessGranted
    }
    
    private func requestFullCalendarAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            return await withCheckedContinuation { continuation in
                eventStore.requestFullAccessToEvents { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        } else {
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

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

        return await withCheckedContinuation { continuation in
            healthStore.requestAuthorization(toShare: [], read: typesToRead) { success, _ in
                continuation.resume(returning: success)
            }
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
func ensureAppGroupDirectoryExists() {
    if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.josblais.myday") {
        let supportURL = groupURL.appendingPathComponent("Library/Application Support", isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: supportURL.path) {
            do {
                try FileManager.default.createDirectory(at: supportURL, withIntermediateDirectories: true)
                print("✅ Dossier créé :", supportURL.path)
            } catch {
                print("❌ Impossible de créer le dossier :", error)
            }
        }
    }
}


// MARK: - Models

struct AgendaItem: Identifiable {
    var id: UUID {
        UUID(uuidString: "\(title)-\(date.timeIntervalSince1970)".sha256ToUUID()) ?? UUID()
    }
    let title: String
    let date: Date
    let isEvent: Bool
    let reminderID: String?
}

struct ReminderItem: Identifiable {
    let id: String
    let title: String
    var isCompleted: Bool
    var ekReminder: EKReminder
}

// MARK: - Main View

struct ContentView: View {
    @StateObject private var userSettings = UserSettings()
    @StateObject private var healthManager = HealthManager()
    @StateObject private var permissionManager = PermissionManager()
    @StateObject private var photoManager = PhotoManager()
    @ObservedObject var statusManager = EventStatusManager.shared
    
    @AppStorage("albumName", store: .appGroup)
    private var storedAlbumName: String = ""
    
    // MARK: - État de l'application
    @State private var showEventForm = false
    @State private var showReminderForm = false
    @State private var newTitle = ""
    @State private var newDate = Date()
    @State private var selectedDate = Date()
    @State private var showDatePicker = false
    @State private var quoteOfTheDay: String = localizedLoadingText()
    @State private var quoteOpacity = 0.0
    @State private var hasInitialized = false
    @State private var isAlbumReady = false
    @State private var showNoAlbumAlert = false
    @State private var combinedAgenda: [AgendaItem] = []
    @State private var albumName: String = ""
    @State private var showZoomPhoto = false
    
    // MARK: - Constantes
    private let eventStore = EKEventStore()
    private let appGroupID = "group.com.josblais.myday"
//    @State private var currentDateKey: String = ""
    
    var body: some View {
        Group {
            if isAlbumReady {
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        controlButtons
                        if showDatePicker { datePickerSection }
                        quoteSection
                        activitySection
                        agendaSection
                        photoSection
                    }
                }
                .sheet(isPresented: $showEventForm) { eventForm() }
                .sheet(isPresented: $showReminderForm) { reminderForm() }
            } else {
                ProgressView(String(localized: "loading"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)           }
        }
        .onAppear {
            
            if !hasInitialized {
                Task {
                    photoManager.requestPhotoAccess()
                    photoManager.loadAvailableAlbums()
                    
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    
                    let defaults = UserDefaults.appGroup
                    if !defaults.bool(forKey: "hasLaunchedBefore") || storedAlbumName.isEmpty {
                        if let first = photoManager.albumNames.first {
                            storedAlbumName = first
                            albumName = first
                            defaults.set(first, forKey: "albumName")
                            defaults.set(true, forKey: "hasLaunchedBefore")
                            photoManager.fetchRandomPhoto(fromAlbum: first)
                            print("📸 Premier lancement — album par défaut: \(first)")
                        }
                    } else {
                        albumName = storedAlbumName
                        photoManager.fetchRandomPhoto(fromAlbum: albumName)
                    }
                    
                    await initializeApp()
                    isAlbumReady = true
                    hasInitialized = true
                }
            }
        }
        .onChange(of: photoManager.albumNames) { _, newAlbums in
            guard !newAlbums.isEmpty else { return }
            
            let defaults = UserDefaults.appGroup
            if !defaults.bool(forKey: "hasLaunchedBefore") || storedAlbumName.isEmpty {
                let firstAlbum = newAlbums.first!
                albumName = firstAlbum
                storedAlbumName = firstAlbum
                defaults.set(firstAlbum, forKey: "albumName")
                defaults.set(true, forKey: "hasLaunchedBefore")
                photoManager.fetchRandomPhoto(fromAlbum: firstAlbum)
                print("📸 Premier lancement — album par défaut: \(firstAlbum)")
            }
        }
//        .sheet(isPresented: $showEventForm) { eventForm() }
//        .sheet(isPresented: $showReminderForm) { reminderForm() }

        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            selectedDate = Date()
            Task {
                await refreshAgenda()
                healthManager.fetchData(for: selectedDate)
            }
        }

        .alert(Text(String(localized: "noAlbum")), isPresented: $showNoAlbumAlert) {
            Button("OK", role: .cancel) {}
            } message: {
              Text("noAlbum")
            }
    }

    // MARK: - UI Sections
        
        var headerSection: some View {
            VStack(spacing: 0) {
                Button(action: {
                    if let url = URL(string: "weather://"),
                       UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    VStack(spacing: 4) {
                        let userLocale = Locale(identifier: userSettings.preferences.language)
                        Text(getDay(from: selectedDate, locale: userLocale))
                            .font(.largeTitle)
                            .bold()
                        Text(getFullDate(from: selectedDate, locale: userLocale))
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        
        var controlButtons: some View {
            HStack(spacing: 8) {
                Button {
                    Task {
                        await refreshAgenda()
                        healthManager.fetchData(for: selectedDate)
                    }
                } label: {
                    Label("", systemImage: "arrow.clockwise")
                }
                Button { withAnimation { showDatePicker.toggle() } } label: {
                    Label("", systemImage: "calendar")
                }
                Button { showReminderForm = true } label: {
                    Label("", systemImage: "text.badge.plus")
                }
                Button { showEventForm = true } label: {
                    Label("", systemImage: "calendar.badge.plus")
                }
                Button {
                    if photoManager.albumNames.contains(albumName) {
                        print(">>> albumName valide: \(albumName)")
                        photoManager.fetchRandomPhoto(fromAlbum: albumName)
                    } else {
                        print("❌ albumName non valide: \(albumName)")
                    }
                } label: {
                    Label("", systemImage: "camera")
                }
            }.buttonStyle(.bordered)
        }
        
        var datePickerSection: some View {
            DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                .labelsHidden()
                .datePickerStyle(.graphical)
                .frame(minHeight: 320)
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                .onChange(of: selectedDate) { _, _ in
                    fetchAgenda(for: selectedDate)
                    withAnimation { showDatePicker = false }
                }
        }
        
        var quoteSection: some View {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("✨")
                    Text(quoteOfTheDay)
                }.font(.title3).italic().foregroundColor(.primary)
            }
            .padding(1)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemBackground)))
            .padding(.horizontal)
            .opacity(quoteOpacity)
            .onAppear {
                withAnimation(.easeIn(duration: 1.0)) { quoteOpacity = 1.0 }
            }
        }
        
        var activitySection: some View {
            Button(action: openHealthApp) {
                HStack(spacing: 20) {
                    Label("\(Int(healthManager.steps))", systemImage: "figure.walk")
//                    Label(String(format: "%.2f", healthManager.distance), systemImage: "map")
                    Label(formattedDistance(healthManager.distance, usesMetric: userSettings.preferences.usesMetric), systemImage: "map")
                    Label(String(format: "%.0f", healthManager.calories), systemImage: "flame")
                }.padding()
            }.buttonStyle(PlainButtonStyle())
        }
        
    var agendaSection: some View {
        if combinedAgenda.isEmpty {
            return AnyView(Text(String(localized: "noEvents")).foregroundColor(.gray))
        } else {
            return AnyView(LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(combinedAgenda) { item in
                    HStack {
                        Text(icon(for: item))
                            .font(.title3)
                            .frame(width: 30)

                        Button(action: { openCorrespondingApp(for: item) }) {
                            Text(item.title)
                                .strikethrough(statusManager.isCompleted(id: item.id.uuidString), color: .gray)
                                .foregroundColor(statusManager.isCompleted(id: item.id.uuidString) ? .gray : .primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }.buttonStyle(.plain)

                        Text(item.date.formatted(date: .omitted, time: .shortened))
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        Button(action: {
                            statusManager.toggleEventCompletion(id: item.id.uuidString)
                            if icon(for: item) == "💊" {
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
                        }.buttonStyle(.plain)
                    }.padding(.vertical, 4)
                }
            }.padding(.horizontal))
        }
    }
        
    var photoSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            if photoManager.albumNames.isEmpty {
                ProgressView(String(localized: "loading"))
            } else {
                Picker("📸 Album", selection: $albumName) {
                    ForEach(photoManager.albumNames, id: \.self) { album in
                        Text(album).tag(album)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: albumName) { _, newAlbum in
                    UserDefaults.appGroup.set(newAlbum, forKey: "albumName")
                    photoManager.fetchRandomPhoto(fromAlbum: newAlbum)
                }
                .padding()
            }

            Divider().padding(.vertical, 1)

            VStack(spacing: 8) {
              
                if let image = photoManager.randomImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 400)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.6), lineWidth: 2))
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .center)
    
                    HStack(spacing: 4) {

                    Button(action: {
                               photoManager.showPreviousImage()
                           }) {
                               Image(systemName: "chevron.left.circle.fill")
                                   .resizable()
                                   .frame(width: 32, height: 32)
                                   .foregroundColor(.blue)
                           }
                    
                    Button("🔍 Zoom") {
                        showZoomPhoto = true
                    }
                    .buttonStyle(.borderedProminent)
                    .sheet(isPresented: $showZoomPhoto) {
                        ZoomableImage(uiImage: image)
                            .ignoresSafeArea()
                    }
 
                    Button(action: {
                        photoManager.showNextImage()
                        }) {
                        Image(systemName: "chevron.right.circle.fill")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .foregroundColor(.blue)
                    }
                    }
                } else {
                    Text("Aucune image chargée").foregroundColor(.secondary)
                    if let status = photoManager.photoStatusMessage {
                        Text(status).foregroundColor(.red).font(.caption)
                    }
                }
            }
            .padding(.bottom, 30)
        }
    }


        // MARK: - Other Components
    @MainActor
    func fetchAgendaAsync(for date: Date) async {
        await withCheckedContinuation { continuation in
            fetchAgenda(for: date) {
                continuation.resume()
            }
        }
    }

    @MainActor
    func waitForCalendarsReady() async {
        let timeout: TimeInterval = 5
        let start = Date()

        while eventStore.calendars(for: .event).isEmpty && Date().timeIntervalSince(start) < timeout {
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s
        }

        print("🗓️ Calendriers disponibles : \(eventStore.calendars(for: .event).count)")
    }

    func eventForm() -> some View {
        formView(
            title: NSLocalizedString("newCalTitle", comment: ""),
            field: $newTitle,
            date: $newDate,
            onSave: {
                createEvent(title: newTitle, date: newDate)
                Task { @MainActor in
                    showEventForm = false
                }
            },
            onCancel: {
                Task { @MainActor in
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
                    showReminderForm = false
                }
            },
            onCancel: {
                Task { @MainActor in
                    showReminderForm = false
                }
            }
        )
    }
                    func formView(title: String, field: Binding<String>, date: Binding<Date>, onSave: @escaping () -> Void, onCancel: @escaping () -> Void) -> some View {
                        VStack(spacing: 20) {
                            Text(title).font(.title2)
                            TextField(String(localized: "title"), text: field).textFieldStyle(.roundedBorder)
                            DatePicker("Date", selection: date).labelsHidden()
                            Button(String(localized: "save"), action: onSave).buttonStyle(.borderedProminent)
                            Button(String(localized: "cancel"), role: .cancel, action: onCancel).foregroundColor(.red)
                        }.padding()
                    }
                    
    @MainActor
    func initializeApp() async {
        print("📲 initializeApp()")

        ensureAppGroupDirectoryExists()
        
        let granted = await permissionManager.requestAllPermissions()
        print("🔐 permissions requested: \(granted ? "✅ granted" : "❌ denied")")

        guard granted else { return }
        
        // Rafraîchir les albums
        photoManager.requestPhotoAccess()
        photoManager.loadAvailableAlbums()
        try? await Task.sleep(nanoseconds: 500_000_000)

        let defaults = UserDefaults.appGroup

        if !defaults.bool(forKey: "hasLaunchedBefore") || storedAlbumName.isEmpty {
            if let firstAlbum = photoManager.albumNames.first {
                storedAlbumName = firstAlbum
                albumName = firstAlbum
                defaults.set(firstAlbum, forKey: "albumName")
                defaults.set(true, forKey: "hasLaunchedBefore")
                photoManager.fetchRandomPhoto(fromAlbum: firstAlbum)
                print("📸 Premier lancement — album par défaut: \(firstAlbum)")
            }
        } else {
            albumName = storedAlbumName
            photoManager.fetchRandomPhoto(fromAlbum: albumName)
            print("📸 Album par sélectionné : \(albumName)")
        }

        try? await Task.sleep(nanoseconds: 500_000_000)
        await waitForCalendarsReady()
        await fetchAgendaAsync(for: selectedDate)
              healthManager.fetchData(for: selectedDate)
        await loadQuoteFromInternet()
    }
    
        func refreshAgenda() async {
                await withCheckedContinuation { continuation in
                    fetchAgenda(for: selectedDate) {
                        continuation.resume()
                    }
                }
            }
                    
                    func ensureDefaultAlbumSelected() {
                        if albumName.isEmpty, let firstAlbum = photoManager.albumNames.first {
                            albumName = firstAlbum
                            UserDefaults.appGroup.set(firstAlbum, forKey: "albumName")
                            photoManager.fetchRandomPhoto(fromAlbum: firstAlbum)
                            print("📸 Album par défaut sélectionné : \(firstAlbum)")
                            print("📸 Album par défaut sélectionné : \(albumName)")
                        } else {
                            print("📸 Album par défaut sélectionné : \(albumName)")
                            photoManager.fetchRandomPhoto(fromAlbum: albumName)
                        }
                    }
                    
                    func openHealthApp() {
                        if let url = URL(string: "shortcuts://run-shortcut?name=fitness") {
                            UIApplication.shared.open(url)
                        }
                    }
                    
                    func loadQuoteFromInternet() async {
                        guard let url = URL(string: "https://zenquotes.io/api/random") else {
                            quoteOfTheDay = "Erreur de chargement."
                            return
                        }
                        do {
                            let (data, _) = try await URLSession.shared.data(from: url)
                            if let decoded = try? JSONDecoder().decode([Quote].self, from: data), let firstQuote = decoded.first {
                                quoteOfTheDay = "\"\(firstQuote.q)\" — \(firstQuote.a)"
                            } else {
                                quoteOfTheDay = "Aucune pensée disponible."
                            }
                        } catch {
                            quoteOfTheDay = "Erreur de connexion."
                        }
                    }
                    
                    struct Quote: Codable {
                        let q: String
                        let a: String
                    }
    
    func fetchAgenda(for date: Date, completion: (() -> Void)? = nil) {
        print("📅 Début fetchAgenda pour \(date)")
        
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: date)!

        let eventPredicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        let events = eventStore.events(matching: eventPredicate).map {
            AgendaItem(title: $0.title, date: $0.startDate, isEvent: true, reminderID: nil)
        }

        print("📅 Événements trouvés : \(events.count)")
        let reminderPredicate = eventStore.predicateForIncompleteReminders(withDueDateStarting: nil, ending: end, calendars: nil)
//        let reminderPredicate = eventStore.predicateForIncompleteReminders(withDueDateStarting: start, ending: end, calendars: nil)

        eventStore.fetchReminders(matching: reminderPredicate) { fetchedReminders in
            let reminders: [AgendaItem] = (fetchedReminders ?? []).compactMap { reminder in
                guard let date = reminder.dueDateComponents?.date else { return nil }
                return AgendaItem(title: reminder.title, date: date, isEvent: false, reminderID: reminder.calendarItemIdentifier)
            }

            print("📅 Rappels trouvés : \(reminders.count)")

            let agenda = (events + reminders).sorted { $0.date < $1.date }

            // ✅ Assurer la mise à jour sur le thread principal
            DispatchQueue.main.async {
                self.combinedAgenda = agenda
                self.saveNextAgendaItemForWidget()
                completion?()
            }
        }
    }
                    func createEvent(title: String, date: Date) {
                        let event = EKEvent(eventStore: eventStore)
                        event.title = title
                        event.startDate = date
                        event.endDate = date.addingTimeInterval(3600)
                        
                        guard let calendar = eventStore.defaultCalendarForNewEvents else {
                            print("❌ Aucun calendrier par défaut.")
                            return
                        }
                        
                        event.calendar = calendar
                        
                        do {
                            try eventStore.save(event, span: .thisEvent)
                            fetchAgenda(for: selectedDate)
                        } catch {
                            print("❌ Erreur lors de l'enregistrement : \(error.localizedDescription)")
                        }
                    }
                    
                    func createReminder(title: String, date: Date) {
                        let reminder = EKReminder(eventStore: eventStore)
                        reminder.title = title
                        reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
                        
                        guard let calendar = eventStore.defaultCalendarForNewReminders() else {
                            print("❌ Aucun calendrier de rappels disponible.")
                            return
                        }
                        
                        reminder.calendar = calendar
                        
                        do {
                            try eventStore.save(reminder, commit: true)
                            fetchAgenda(for: selectedDate)
                        } catch {
                            print("❌ Erreur en sauvegardant le rappel : \(error.localizedDescription)")
                        }
                    }
                    
    func toggleCompletion(for item: AgendaItem) {
        statusManager.toggleEventCompletion(id: item.id.uuidString)

        if icon(for: item) == "💊" {
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
                            print("⚠️ Ignoré : Aucun ID pour ce rappel")
                            return
                        }
                        
                        if let reminder = eventStore.calendarItem(withIdentifier: reminderID) as? EKReminder {
                            reminder.isCompleted = true
                            reminder.completionDate = Date()
                            
                            do {
                                try eventStore.save(reminder, commit: true)
                                //                print("✅ Rappel complété : \(reminder.title)")
                            } catch {
                                print("❌ Erreur de sauvegarde : \(error.localizedDescription)")
                            }
                        } else {
                            print("❌ Rappel introuvable avec l’ID: \(reminderID)")
                        }
                    }
                    
    func saveNextAgendaItemForWidget() {
        let today = Calendar.current.startOfDay(for: Date())
        
        let uncompletedTodayAgenda = combinedAgenda.filter {
            Calendar.current.isDate($0.date, inSameDayAs: today) &&
            !statusManager.isCompleted(id: $0.id.uuidString)        }
        
        guard let next = uncompletedTodayAgenda.first else {
            let defaults = UserDefaults(suiteName: appGroupID)
            defaults?.removeObject(forKey: "nextItem")
            WidgetCenter.shared.reloadAllTimelines()
            return
        }

        let defaults = UserDefaults(suiteName: appGroupID)
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short

        let data: [String: String] = [
            "title": next.title,
            "time": formatter.string(from: next.date)
        ]

        defaults?.set(data, forKey: "nextItem")
        WidgetCenter.shared.reloadAllTimelines()
    }
                    
                    func openCorrespondingApp(for item: AgendaItem) {
                        if item.isEvent {
                            let calendarURL = URL(string: "calshow:\(item.date.timeIntervalSinceReferenceDate)")!
                            UIApplication.shared.open(calendarURL)
                        } else if icon(for: item) == "💊" {
                            if let medURL = URL(string: "x-apple-health://MedicationsHealthAppPlugin.healthplugin") {
                                UIApplication.shared.open(medURL)
                            }
                        } else {
                            if let remindersURL = URL(string: "x-apple-reminderkit://") {
                                UIApplication.shared.open(remindersURL)
                            }
                        }
                    }
                    
                    func icon(for item: AgendaItem) -> String {
                        if item.isEvent {
                            return "📅"
                        } else if item.title.lowercased().contains("médicament") ||
                                    item.title.lowercased().contains("pilule") ||
                                    item.title.lowercased().contains("med") {
                            return "💊"
                        } else {
                            return "🗓️"
                        }
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
                    
                    
                    // MARK: - ZoomableImage
                    
    struct ZoomableImage: View {
        let uiImage: UIImage
        @State private var scale: CGFloat = 1.2
        @State private var lastScale: CGFloat = 1.2
        @State private var offset: CGSize = .zero
        @State private var lastOffset: CGSize = .zero

        var body: some View {
            GeometryReader { geometry in
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let newScale = lastScale * value
                                    if newScale.isFinite && !newScale.isNaN {
                                        scale = max(1.0, newScale)
                                    }
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                },
                            DragGesture()
                                .onChanged { value in
                                    let newOffset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                    if newOffset.width.isFinite && newOffset.height.isFinite {
                                        offset = newOffset
                                    }
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                    )
                    .animation(.easeInOut, value: scale)
                    .animation(.easeInOut, value: offset)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .onTapGesture(count: 2) {
                        withAnimation {
                            scale = 1.2
                            lastScale = 1.2
                            offset = .zero
                            lastOffset = .zero
                        }
                    }
            }
            .frame(height: 400)
            .cornerRadius(12)
            .shadow(radius: 4)
        }
    }
}
    
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
extension EventStatusManager {
    func completedEvents(forDateKey key: String) -> Set<UUID> {
        return completedEvents[key] ?? []
    }
}
