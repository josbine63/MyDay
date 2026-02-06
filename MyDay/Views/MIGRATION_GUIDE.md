# Guide de Migration - MyDay 2.0

## 🎯 Objectif

Ce guide vous aide à intégrer les nouvelles améliorations dans votre ContentView existante.

---

## ✅ Étape 1 : Vérifier les imports

Assurez-vous que ContentView importe tous les fichiers nécessaires (normalement automatique en Swift).

---

## ✅ Étape 2 : Simplifier ContentView

### **Avant** :
```swift
struct ContentView: View {
    @StateObject private var userSettings = UserSettings()
    
    var body: some View {
        // ... 1200+ lignes de code
    }
}
```

### **Après** :
```swift
struct ContentView: View {
    @EnvironmentObject var userSettings: UserSettings  // ✅ Maintenant injecté depuis RootView
    
    var body: some View {
        // ... code simplifié avec sous-vues
    }
}
```

---

## ✅ Étape 3 : Remplacer les sections par les nouvelles vues

### **3.1 Section Santé**

#### Avant :
```swift
var activitySection: some View {
    Button(action: openHealthApp) {
        HStack(spacing: 20) {
            Label("\(Int(healthManager.steps))", systemImage: "figure.walk")
            Label(formattedDistance(healthManager.distance, usesMetric: userSettings.preferences.usesMetric), systemImage: "map")
            Label(String(format: "%.0f", healthManager.calories), systemImage: "flame")
        }.padding()
    }.buttonStyle(PlainButtonStyle())
}
```

#### Après :
```swift
HealthStatsView(
    steps: healthManager.steps,
    distance: healthManager.distance,
    calories: healthManager.calories,
    usesMetric: userSettings.preferences.usesMetric,
    onTap: { DeepLinks.openHealth() }
)
```

#### Supprimer :
```swift
// ❌ Supprimer cette fonction, maintenant dans Utilities.swift
func formattedDistance(_ meters: Double, usesMetric: Bool) -> String { ... }
func openHealthApp() { ... }
```

---

### **3.2 Section Agenda**

#### Avant :
```swift
var agendaSection: some View {
    // ... 200+ lignes avec swipe gestures, icônes, etc.
}
```

#### Après :
```swift
AgendaListView(
    combinedAgenda: combinedAgenda,
    statusManager: statusManager,
    selectedDate: $selectedDate,
    onDateChange: { date in
        fetchAgenda(for: date, 
                    calendarSelectionManager: calendarSelectionManager,
                    reminderSelectionManager: reminderSelectionManager)
    },
    onToggleCompletion: { item in
        statusManager.toggleEventCompletion(id: item.id.uuidString)
        
        // Si c'est un médicament, ouvrir l'app Santé
        if item.title.lowercased().contains("médicament") || 
           item.title.lowercased().contains("medication") {
            DeepLinks.openHealthMedications()
        }
        
        // Si c'est un rappel, le marquer comme complété
        if !item.isEvent, item.reminderID != nil {
            completeAssociatedReminder(for: item)
        }
        
        saveNextAgendaItemForWidget()
    },
    onOpenApp: { item in
        if item.isEvent {
            DeepLinks.openCalendar(for: item.date)
        } else {
            DeepLinks.openReminders()
        }
    }
)
```

#### Supprimer :
```swift
// ❌ Supprimer ces fonctions, maintenant dans AgendaListView.swift
func icon(for item: AgendaItem) -> String { ... }
private func containsAny(_ text: String, keywords: [String]) -> Bool { ... }
func openCorrespondingApp(for item: AgendaItem) { ... }
```

---

### **3.3 Section Photos**

#### Avant :
```swift
var photoPickerSection: some View { ... }
var photoDisplaySection: some View { ... }
// + logique de navigation, placeholder, etc.
```

#### Après :
```swift
PhotoGalleryView(
    photoManager: photoManager,
    showFullScreenPhoto: $showFullScreenPhoto
)
```

---

### **3.4 Formatage de dates**

#### Avant :
```swift
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
```

#### Après :
```swift
// Dans headerSection
let userLocale = Locale(identifier: userSettings.preferences.language)
Text(DateFormatting.dayName(from: selectedDate, locale: userLocale))
    .font(.largeTitle)
    .bold()
Text(DateFormatting.fullDate(from: selectedDate, locale: userLocale))
    .font(.headline)
```

#### Supprimer :
```swift
// ❌ Supprimer ces fonctions
func getDay(from date: Date, locale: Locale) -> String { ... }
func getFullDate(from date: Date, locale: Locale) -> String { ... }
```

---

### **3.5 Deep Links**

#### Avant :
```swift
func openHealthApp() {
    if let healthURL = URL(string: "activitytoday://") {
        UIApplication.shared.open(healthURL)
    }
}

private func openSettings() {
    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(settingsURL)
    }
}
```

#### Après :
```swift
// Utiliser directement
DeepLinks.openHealth()
DeepLinks.openSettings()
DeepLinks.openWeather()
DeepLinks.openCalendar(for: date)
DeepLinks.openReminders()
```

---

## ✅ Étape 4 : Nettoyer le code

### **4.1 Supprimer les logs debug en production**

Encapsuler les logs avec `#if DEBUG` :

```swift
#if DEBUG
Logger.photo.debug("🔄 Chargement image...")
#endif
```

Ou supprimer complètement les logs trop verbeux.

---

### **4.2 Supprimer le code commenté**

```swift
// ❌ Supprimer
// struct SafariView: UIViewControllerRepresentable { ... }
// if let url = URL(string: "shortcuts://run-shortcut?name=fitness") { ... }
```

---

### **4.3 Corriger les noms de variables**

```swift
// ❌ Avant
@State private var showcalendarselection = false
@State private var showreminderselection = false

// ✅ Après
@State private var showCalendarSelection = false
@State private var showReminderSelection = false
```

---

## ✅ Étape 5 : Structure finale de ContentView

Après refactoring, ContentView devrait ressembler à ceci :

```swift
struct ContentView: View {
    // MARK: - Environment Objects
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var photoManager: PhotoManager
    
    // MARK: - State Objects
    @StateObject private var healthManager = HealthManager()
    @StateObject var calendarManager = CalendarManager()
    @StateObject var calendarSelectionManager = CalendarSelectionManager()
    @StateObject var reminderSelectionManager = ReminderSelectionManager()
    @ObservedObject var statusManager = EventStatusManager.shared
    
    // MARK: - State
    @State private var selectedDate = Date()
    @State private var combinedAgenda: [AgendaItem] = []
    @State private var quoteOfTheDay: String = LocalizationHelpers.loadingText
    @State private var showFullScreenPhoto = false
    @State private var showDatePicker = false
    @State private var showCalendarSelection = false
    @State private var showReminderSelection = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    controlButtons
                    if showDatePicker { datePickerSection }
                    quoteSection
                    
                    HealthStatsView(
                        steps: healthManager.steps,
                        distance: healthManager.distance,
                        calories: healthManager.calories,
                        usesMetric: userSettings.preferences.usesMetric,
                        onTap: { DeepLinks.openHealth() }
                    )
                    
                    AgendaListView(
                        combinedAgenda: combinedAgenda,
                        statusManager: statusManager,
                        selectedDate: $selectedDate,
                        onDateChange: handleDateChange,
                        onToggleCompletion: handleToggleCompletion,
                        onOpenApp: handleOpenApp
                    )
                    
                    PhotoGalleryView(
                        photoManager: photoManager,
                        showFullScreenPhoto: $showFullScreenPhoto
                    )
                    
                    footerSection
                }
            }
            .onAppear { initializeView() }
            .navigationDestination(isPresented: $showCalendarSelection) {
                CalendarSelectionView(manager: calendarSelectionManager)
            }
            .navigationDestination(isPresented: $showReminderSelection) {
                ReminderSelectionView(manager: reminderSelectionManager)
            }
            .fullScreenCover(isPresented: $showFullScreenPhoto) {
                FullScreenPhotoView(image: photoManager.currentImage, isPresented: $showFullScreenPhoto)
            }
        }
    }
    
    // MARK: - Handlers
    
    private func handleDateChange(_ date: Date) {
        fetchAgenda(for: date, 
                    calendarSelectionManager: calendarSelectionManager,
                    reminderSelectionManager: reminderSelectionManager)
    }
    
    private func handleToggleCompletion(_ item: AgendaItem) {
        statusManager.toggleEventCompletion(id: item.id.uuidString)
        
        if item.title.lowercased().contains("médicament") || 
           item.title.lowercased().contains("medication") {
            DeepLinks.openHealthMedications()
        }
        
        if !item.isEvent, item.reminderID != nil {
            completeAssociatedReminder(for: item)
        }
        
        saveNextAgendaItemForWidget()
    }
    
    private func handleOpenApp(_ item: AgendaItem) {
        if item.isEvent {
            DeepLinks.openCalendar(for: item.date)
        } else {
            DeepLinks.openReminders()
        }
    }
    
    // ... reste des fonctions (fetchAgenda, createEvent, etc.)
}
```

---

## 📊 Réduction attendue

| Métrique | Avant | Après | Amélioration |
|----------|-------|-------|--------------|
| Lignes ContentView | ~1280 | ~600 | -53% |
| Nombre de vues | 1 | 4+ | Modularité |
| Fichiers manquants | 4 | 0 | Complet ✅ |
| Testabilité | Faible | Haute | ⬆️⬆️⬆️ |

---

## 🐛 Checklist de validation

Après migration, vérifier :

- [ ] L'app compile sans erreurs
- [ ] Les permissions fonctionnent (onboarding)
- [ ] La navigation entre dates fonctionne (swipe)
- [ ] Les statistiques de santé s'affichent
- [ ] La galerie photo fonctionne
- [ ] La sélection de calendriers fonctionne
- [ ] La sélection de rappels fonctionne
- [ ] Le widget se met à jour
- [ ] Les deep links fonctionnent (ouvrir Calendrier, Rappels, Santé)
- [ ] La localisation FR/EN fonctionne
- [ ] Les unités métriques/impériales changent

---

## 🆘 Problèmes courants

### **Erreur : "Cannot find 'DeepLinks' in scope"**
**Solution** : Assurez-vous que `Utilities.swift` est dans votre target

### **Erreur : "Cannot find 'SelectableCalendar' in scope"**
**Solution** : Assurez-vous que `CalendarSelectionView.swift` est dans votre target

### **Erreur : "'userSettings' is not available"**
**Solution** : Vérifiez que RootView injecte bien `.environmentObject(userSettings)`

### **App plante au lancement**
**Solution** : Vérifiez que l'App Group est configuré dans :
- Capabilities → App Groups → `group.com.josblais.myday`
- Cochez pour l'app ET le widget

---

## 📞 Besoin d'aide ?

Si vous rencontrez des problèmes :
1. Vérifiez les logs avec Console.app (filtre : "com.josblais.myday")
2. Consultez `IMPROVEMENTS.md` pour la documentation complète
3. Vérifiez que tous les nouveaux fichiers sont dans votre target Xcode

---

**Bonne migration ! 🚀**
