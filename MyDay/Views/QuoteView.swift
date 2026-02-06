//
//  QuoteView.swift
//  MyDay
//
//  Created by Assistant on 2026-01-30.
//

import SwiftUI
import Translation

struct QuoteView: View {
    @ObservedObject private var quoteService = QuoteService.shared
    @State private var quoteOpacity = 0.0
    
    var body: some View {
        // Ne rien afficher si la pensée du jour est désactivée
        if !quoteService.isQuoteEnabled {
            EmptyView()
        } else {
            quoteContent
        }
    }
    
    @ViewBuilder
    private var quoteContent: some View {
        VStack(spacing: 4) {
            VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("✨")
                    .font(.title2)
                
                // Déclencheur invisible pour la traduction (iOS 18+)
                // Séparé du texte affiché pour pouvoir s'exécuter pendant le chargement
                if #available(iOS 18.0, macOS 15.0, *), quoteService.translationConfiguration != nil {
                    Text("")
                        .translationTask(quoteService.translationConfiguration) { session in
                            await quoteService.handleTranslation(using: session)
                        }
                        .id(quoteService.translationTrigger)
                        .frame(width: 0, height: 0)
                }
                
                if quoteService.isLoading {
                    ProgressView()
                        .padding(.leading, 4)
                } else {
                    Text(quoteService.currentQuote)
                        .font(.title3)
                        .italic()
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                // Bouton de refresh
                Button(action: {
                    Task {
                        await quoteService.fetchQuote(forceRefresh: true)
                    }
                }) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
            
            if let error = quoteService.errorMessage {
                Text(error)
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
        .padding(.horizontal)
        .opacity(quoteOpacity)
        .onAppear {
            // Animation d'apparition
            withAnimation(.easeIn(duration: 1.0)) {
                quoteOpacity = 1.0
            }
            
            // Charger la pensée du jour si activée
            guard quoteService.isQuoteEnabled else { return }
            Task {
                await quoteService.fetchQuote()
            }
        }
        
        Text("source: zenquotes.io/api/random")
            .font(.caption2)
            .foregroundColor(.secondary)
        }
    }
}

// MARK: - Quote View With Source (Wrapper for ContentView)

struct QuoteViewWithSource: View {
    var body: some View {
        QuoteView()
    }
}

#Preview {
    QuoteView()
}
