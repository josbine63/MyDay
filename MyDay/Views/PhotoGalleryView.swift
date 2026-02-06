//
//  PhotoGalleryView.swift
//  MyDay
//
//  Created by Assistant on 2025-01-15.
//

import SwiftUI

/// Vue affichant la galerie photo avec navigation
struct PhotoGalleryView: View {
    
    @ObservedObject var photoManager: PhotoManager
    @Binding var showFullScreenPhoto: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // Sélecteur d'album
            albumPicker
            
            Divider().padding(.vertical, 1)
            
            // Affichage de l'image
            photoDisplay
            
            // Contrôles de navigation
            navigationControls
            
            // Crédits
            Text("source: zenquotes.io/api/random")
        }
    }
    
    // MARK: - Subviews
    
    private var albumPicker: some View {
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
        }
        .padding()
    }
    
    private var photoDisplay: some View {
        VStack(spacing: 8) {
            if let photo = photoManager.currentImage {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.6), lineWidth: 2))
                    .padding(.horizontal)
                    .id(photo)
                    .onTapGesture(count: 2) {
                        showFullScreenPhoto = true
                    }
                
                // Badge de statut
                if let status = photoManager.photoStatusMessage, !status.isEmpty {
                    Text(status)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
            } else {
                // État de chargement ou erreur
                placeholderView
            }
        }
    }
    
    private var placeholderView: some View {
        VStack(spacing: 8) {
            if let status = photoManager.photoStatusMessage,
               status.contains("Chargement") || status.contains("Téléchargement") {
                ProgressView()
                    .progressViewStyle(.circular)
                Text(status).foregroundColor(.secondary).font(.caption)
            } else {
                Text("Aucune image chargée").foregroundColor(.secondary)
                
                if let status = photoManager.photoStatusMessage {
                    Text(status).foregroundColor(.red).font(.caption)
                }
                
                // Bouton de rechargement
                Button {
                    Task {
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
    }
    
    private var navigationControls: some View {
        HStack(spacing: 12) {
            // Bouton précédent
            Button {
                photoManager.showPreviousImage()
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Compteur
            Text("Photo \(photoManager.currentAssets.indices.contains(photoManager.currentIndex) ? photoManager.currentIndex + 1 : 0)/\(photoManager.currentAssets.count)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Bouton suivant
            Button {
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
}
