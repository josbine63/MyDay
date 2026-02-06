//
//  CustomLinksView.swift
//  MyDay
//
//  Created by Assistant on 2025-01-30.
//

import SwiftUI

// MARK: - Custom Links List View

struct CustomLinksView: View {
    @EnvironmentObject var customLinkManager: CustomLinkManager
    @EnvironmentObject var userSettings: UserSettings // ✅ Pour la préférence iCloud
    @State private var showAddSheet = false
    @State private var editingLink: CustomLink?
    
    var body: some View {
        List {
            // ✅ Section de synchronisation iCloud
            Section {
                Toggle(isOn: Binding(
                    get: { userSettings.preferences.syncCustomLinksWithICloud },
                    set: { newValue in
                        userSettings.setSyncCustomLinksWithICloud(newValue)
                        // Recréer le manager avec la nouvelle préférence
                        // (nécessite un redémarrage pour prendre effet)
                    }
                )) {
                    HStack {
                        Image(systemName: "icloud.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Synchronisation iCloud")
                            Text("Synchroniser entre tous vos appareils")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } footer: {
                if userSettings.preferences.syncCustomLinksWithICloud {
                    Text("Vos liens seront synchronisés automatiquement avec iCloud sur tous vos appareils connectés.")
                } else {
                    Text("Les liens resteront uniquement sur cet appareil.")
                }
            }
            
            Section {
                if customLinkManager.customLinks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "link.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Aucun lien personnalisé")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Créez des raccourcis pour ouvrir automatiquement vos notes, apps ou actions préférées depuis votre agenda.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(customLinkManager.customLinks) { link in
                        CustomLinkRow(link: link) {
                            editingLink = link
                        }
                    }
                    .onDelete(perform: customLinkManager.deleteLinks)
                    .onMove(perform: customLinkManager.moveLinks)
                }
            } header: {
                Text("Liens actifs")
            } footer: {
                if !customLinkManager.customLinks.isEmpty {
                    Text("Balayez pour supprimer ou réorganiser. Touchez un lien pour le modifier.")
                }
            }
            
            // Raccourcis recommandés
            Section {
                ForEach(PresetShortcut.all) { preset in
                    PresetShortcutRow(
                        preset: preset,
                        isConfigured: customLinkManager.customLinks.contains {
                            $0.keyword.lowercased() == preset.keyword.lowercased()
                        },
                        onConfigure: {
                            customLinkManager.addLink(CustomLink(
                                keyword: preset.keyword,
                                shortcutName: preset.shortcutName,
                                matchType: preset.matchType,
                                isEnabled: true
                            ))
                        }
                    )
                }
            } header: {
                Text("Raccourcis recommandés")
            } footer: {
                Text("Tapez \"Configurer\" pour créer le lien dans MyDay. Chaque raccourci doit préalablement exister dans votre app Raccourcis.")
            }

            Section {
                Button(action: { showAddSheet = true }) {
                    Label("Ajouter un lien", systemImage: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
        .navigationTitle("Liens personnalisés")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            EditButton()
        }
        .sheet(isPresented: $showAddSheet) {
            CustomLinkEditView(mode: .add)
                .environmentObject(customLinkManager)
        }
        .sheet(item: $editingLink) { link in
            CustomLinkEditView(mode: .edit(link))
                .environmentObject(customLinkManager)
        }
    }
}

// MARK: - Custom Link Row

struct CustomLinkRow: View {
    let link: CustomLink
    let onEdit: () -> Void
    @EnvironmentObject var customLinkManager: CustomLinkManager
    
    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 12) {
                // Icône
                Image(systemName: link.isEnabled ? "link.circle.fill" : "link.circle")
                    .font(.title2)
                    .foregroundColor(link.isEnabled ? .blue : .gray)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Mot-clé
                    Text(link.keyword)
                        .font(.headline)
                        .foregroundColor(link.isEnabled ? .primary : .secondary)
                    
                    // Type de correspondance
                    Text(link.matchType.localizedName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Raccourci cible
                    HStack(spacing: 4) {
                        Image(systemName: "play.circle.fill")
                            .font(.caption)
                        Text(link.shortcutName)
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                // Bouton de test
                Button(action: {
                    _ = customLinkManager.openShortcut(named: link.shortcutName)
                }) {
                    Image(systemName: "play.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(8)
                        .background(Color.green.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
            .opacity(link.isEnabled ? 1.0 : 0.6)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .leading) {
            Button {
                customLinkManager.toggleLink(link)
            } label: {
                Label(link.isEnabled ? "Désactiver" : "Activer", 
                      systemImage: link.isEnabled ? "pause.circle" : "play.circle")
            }
            .tint(link.isEnabled ? .orange : .green)
        }
    }
}

// MARK: - Preset Shortcuts

struct PresetShortcut: Identifiable {
    let id: String
    let shortcutName: String
    let keyword: String
    let matchType: CustomLink.MatchType
    let description: String
    let icon: String
    var downloadURL: String? = nil

    var iconColor: Color {
        switch id {
        case "album":      return .purple
        case "contact":    return .teal
        default:           return .blue
        }
    }

    static let all: [PresetShortcut] = [
        PresetShortcut(id: "contact",    shortcutName: "Trouver Contact",          keyword: "Contact",   matchType: .startsWith, description: "Rechercher et afficher un contact",                  icon: "person.fill", downloadURL: "https://www.icloud.com/shortcuts/6528e0d83dda4f6e928ff42af98c80ca"),
        PresetShortcut(id: "note",       shortcutName: "Notes avec paramètre",     keyword: "Note",      matchType: .startsWith, description: "Créer une note avec le texte du titre",              icon: "doc.text", downloadURL: "https://www.icloud.com/shortcuts/76708ede6df74412a3be23fef8a78228"),
        PresetShortcut(id: "album",      shortcutName: "Lire Album",              keyword: "Album",     matchType: .startsWith, description: "Lancer la lecture d'un album musical",               icon: "music.note.2", downloadURL: "https://www.icloud.com/shortcuts/e21890e539fb4d49ac29e32e44dc0bca"),
    ]
}

// MARK: - Preset Shortcut Row

struct PresetShortcutRow: View {
    let preset: PresetShortcut
    let isConfigured: Bool
    let onConfigure: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                // Icône avec fond teinté
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(preset.iconColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: preset.icon)
                        .foregroundColor(preset.iconColor)
                        .font(.system(size: 16))
                }

                // Infos
                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.shortcutName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(preset.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Mot-clé : \"\(preset.keyword)\" — \(preset.matchType.localizedName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .opacity(0.7)
                }

                Spacer()

                // Coche si déjà configuré
                if isConfigured {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }

            // Boutons d'action
            HStack(spacing: 8) {
                if let urlString = preset.downloadURL, let url = URL(string: urlString) {
                    // Lien iCloud dispo → télécharger directement
                    Button {
                        UIApplication.shared.open(url)
                    } label: {
                        Label("Télécharger", systemImage: "icloud.and.arrow.down")
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    .controlSize(.small)
                } else {
                    // Pas de lien encore → ouvrir l'app Raccourcis
                    Button {
                        if let url = URL(string: "shortcuts://") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Créer dans Raccourcis", systemImage: "arrow.up.forward.app")
                    }
                    .buttonStyle(.bordered)
                    .tint(.gray)
                    .controlSize(.small)
                }

                if !isConfigured {
                    Button(action: onConfigure) {
                        Label("Configurer", systemImage: "gears")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .controlSize(.small)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Custom Link Edit View

struct CustomLinkEditView: View {
    enum Mode {
        case add
        case edit(CustomLink)
    }
    
    let mode: Mode
    @EnvironmentObject var customLinkManager: CustomLinkManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var keyword: String = ""
    @State private var shortcutName: String = ""
    @State private var matchType: CustomLink.MatchType = .contains
    @State private var isEnabled: Bool = true
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    private var isValid: Bool {
        !keyword.trimmingCharacters(in: .whitespaces).isEmpty &&
        !shortcutName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Mot-clé à détecter", text: $keyword)
                        .autocapitalization(.words)
                    
                    Picker("Type de correspondance", selection: $matchType) {
                        ForEach(CustomLink.MatchType.allCases, id: \.self) { type in
                            Text(type.localizedName).tag(type)
                        }
                    }
                } header: {
                    Text("Détection")
                } footer: {
                    Text(matchTypeDescription)
                }
                
                Section {
                    TextField("Nom du raccourci", text: $shortcutName)
                        .autocapitalization(.words)
                    
                    Button(action: openShortcutsApp) {
                        Label("Ouvrir l'app Raccourcis", systemImage: "arrow.up.forward.app")
                    }
                } header: {
                    Text("Action")
                } footer: {
                    Text("Entrez le nom exact du raccourci à exécuter. Créez-le dans l'app Raccourcis si nécessaire.")
                }
                
                Section {
                    Toggle("Lien actif", isOn: $isEnabled)
                } footer: {
                    Text("Les liens désactivés sont conservés mais ne seront pas utilisés.")
                }
                
                // Section de test
                if case .edit = mode {
                    Section {
                        Button(action: testShortcut) {
                            Label("Tester le raccourci", systemImage: "play.circle.fill")
                                .foregroundColor(.green)
                        }
                        .disabled(shortcutName.isEmpty)
                    } footer: {
                        Text("Vérifiez que le raccourci fonctionne correctement.")
                    }
                }
            }
            .navigationTitle(mode.isAdd ? "Nouveau lien" : "Modifier le lien")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        saveLink()
                    }
                    .disabled(!isValid)
                }
            }
            .alert("Erreur", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                if case .edit(let link) = mode {
                    keyword = link.keyword
                    shortcutName = link.shortcutName
                    matchType = link.matchType
                    isEnabled = link.isEnabled
                }
            }
        }
    }
    
    private var matchTypeDescription: String {
        switch matchType {
        case .exact:
            return "Le titre de l'événement doit être exactement \"\(keyword.isEmpty ? "Gratitude" : keyword)\""
        case .contains:
            return "Le titre doit contenir le mot \"\(keyword.isEmpty ? "gratitude" : keyword.lowercased())\""
        case .startsWith:
            return "Le titre doit commencer par \"\(keyword.isEmpty ? "Gratitude" : keyword)\""
        }
    }
    
    private func saveLink() {
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespaces)
        let trimmedShortcut = shortcutName.trimmingCharacters(in: .whitespaces)
        
        guard !trimmedKeyword.isEmpty && !trimmedShortcut.isEmpty else {
            errorMessage = "Le mot-clé et le nom du raccourci sont requis."
            showError = true
            return
        }
        
        switch mode {
        case .add:
            let newLink = CustomLink(
                keyword: trimmedKeyword,
                shortcutName: trimmedShortcut,
                matchType: matchType,
                isEnabled: isEnabled
            )
            customLinkManager.addLink(newLink)
            
        case .edit(let originalLink):
            let updatedLink = CustomLink(
                id: originalLink.id,
                keyword: trimmedKeyword,
                shortcutName: trimmedShortcut,
                matchType: matchType,
                isEnabled: isEnabled
            )
            customLinkManager.updateLink(updatedLink)
        }
        
        dismiss()
    }
    
    private func testShortcut() {
        let success = customLinkManager.openShortcut(named: shortcutName)
        if !success {
            errorMessage = "Impossible d'ouvrir le raccourci '\(shortcutName)'. Vérifiez qu'il existe dans l'app Raccourcis."
            showError = true
        }
    }
    
    private func openShortcutsApp() {
        if let url = URL(string: "shortcuts://") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Mode Extension

extension CustomLinkEditView.Mode {
    var isAdd: Bool {
        if case .add = self { return true }
        return false
    }
}

// MARK: - Previews

#Preview("Liste vide") {
    NavigationStack {
        CustomLinksView()
            .environmentObject(CustomLinkManager())
    }
}

#Preview("Liste avec données") {
    NavigationStack {
        CustomLinksView()
            .environmentObject(CustomLinkManager.preview)
    }
}

#Preview("Formulaire ajout") {
    CustomLinkEditView(mode: .add)
        .environmentObject(CustomLinkManager.preview)
}

#Preview("Formulaire édition") {
    let manager = CustomLinkManager.preview
    return CustomLinkEditView(mode: .edit(manager.customLinks[0]))
        .environmentObject(manager)
}
