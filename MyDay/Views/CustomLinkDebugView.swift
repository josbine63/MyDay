//
//  CustomLinkDebugView.swift
//  MyDay
//
//  Created by Assistant on 2025-01-30.
//  Vue de debug pour tester et diagnostiquer les liens personnalisés
//

import SwiftUI

#if DEBUG
struct CustomLinkDebugView: View {
    @EnvironmentObject var customLinkManager: CustomLinkManager
    @State private var testTitle: String = ""
    @State private var matchResults: [(link: CustomLink, matches: Bool)] = []
    @State private var testShortcutName: String = ""
    @State private var testResult: String = ""
    
    var body: some View {
        Form {
            Section("Test de matching") {
                TextField("Titre à tester", text: $testTitle)
                
                Button("Tester le matching") {
                    testMatching()
                }
                .disabled(testTitle.isEmpty)
                
                if !matchResults.isEmpty {
                    ForEach(matchResults, id: \.link.id) { result in
                        HStack {
                            Image(systemName: result.matches ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(result.matches ? .green : .red)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.link.keyword)
                                    .font(.headline)
                                Text(result.link.matchType.localizedName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if result.matches {
                                Text("MATCH ✓")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .bold()
                            }
                        }
                    }
                }
            }
            
            Section("Test de raccourci") {
                TextField("Nom du raccourci", text: $testShortcutName)
                
                Button("Tester l'ouverture") {
                    testShortcut()
                }
                .disabled(testShortcutName.isEmpty)
                
                if !testResult.isEmpty {
                    Text(testResult)
                        .font(.caption)
                        .foregroundColor(testResult.contains("✅") ? .green : .red)
                }
            }
            
            Section("Informations") {
                LabeledContent("Nombre de liens", value: "\(customLinkManager.customLinks.count)")
                LabeledContent("Liens actifs", value: "\(customLinkManager.customLinks.filter(\.isEnabled).count)")
                
                if let firstLink = customLinkManager.customLinks.first {
                    LabeledContent("Premier lien", value: firstLink.keyword)
                }
            }
            
            Section("URLs générées") {
                ForEach(customLinkManager.customLinks) { link in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(link.keyword)
                            .font(.headline)
                        
                        if let encodedName = link.shortcutName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                            Text("shortcuts://run-shortcut?name=\(encodedName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .textSelection(.enabled)
                        }
                    }
                }
            }
            
            Section("Actions rapides") {
                Button("Ajouter lien de test") {
                    addTestLink()
                }
                
                Button("Nettoyer les liens de test", role: .destructive) {
                    cleanTestLinks()
                }
                
                Button("Réinitialiser tout", role: .destructive) {
                    customLinkManager.reset()
                }
            }
        }
        .navigationTitle("Debug Liens")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func testMatching() {
        matchResults = customLinkManager.customLinks.map { link in
            (link: link, matches: link.matches(title: testTitle))
        }
    }
    
    private func testShortcut() {
        let success = customLinkManager.openShortcut(named: testShortcutName)
        testResult = success 
            ? "✅ Ouverture réussie de '\(testShortcutName)'"
            : "❌ Échec de l'ouverture de '\(testShortcutName)'"
    }
    
    private func addTestLink() {
        let testLink = CustomLink(
            keyword: "Test \(Date().timeIntervalSince1970)",
            shortcutName: "TestShortcut",
            matchType: .contains
        )
        customLinkManager.addLink(testLink)
    }
    
    private func cleanTestLinks() {
        customLinkManager.customLinks.removeAll { link in
            link.keyword.hasPrefix("Test ") && link.shortcutName == "TestShortcut"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CustomLinkDebugView()
            .environmentObject(CustomLinkManager.preview)
    }
}

// MARK: - Extension pour ajouter Debug View dans Settings (DEBUG only)

extension SettingsView {
    var debugSection: some View {
        Section("Debug") {
            NavigationLink(destination: CustomLinkDebugView()) {
                HStack {
                    Image(systemName: "ladybug.fill")
                        .foregroundColor(.red)
                        .frame(width: 30)
                    Text("Debug Liens Personnalisés")
                }
            }
        }
    }
}
#endif
