import Foundation
import Photos
import SwiftUI
import os.log

@MainActor
final class PhotoManager: ObservableObject {
    @AppStorage(UserDefaultsKeys.albumName, store: AppGroup.userDefaults)
    private var storedAlbumName: String = ""
    
    @Published var albumNames: [String] = []
    
    @Published var albumName: String = "" {
        didSet {
            guard !albumName.isEmpty,
                  albumName != oldValue else { return }

            storedAlbumName = albumName
            Task { @MainActor in
                Logger.photo.debug("🔄 albumName modifié: \(self.albumName)")
                await loadAssetsAndShowRandomPhoto(fromAlbum: albumName)
            }
        }
    }
    
    private var assets: [PHAsset] = []
    
    @Published var currentImage: UIImage? = nil
    @Published var photoStatusMessage: String? = nil
    
    // ✅ Publier pour permettre l'observation des changements
    @Published var currentAssets: [PHAsset] = []
    @Published var currentIndex: Int = 0
    
    // 🚀 OPTIMISATION: Cache d'images pour éviter rechargements
    private var imageCache: [String: UIImage] = [:]
    private let maxCacheSize = 10 // Limite pour éviter surconsommation mémoire
    
    // 🚀 OPTIMISATION: Taille d'écran pour images adaptatives
    private lazy var screenTargetSize: CGSize = {
        let screenScale = UIScreen.main.scale
        return CGSize(
            width: UIScreen.main.bounds.width * screenScale,
            height: UIScreen.main.bounds.height * screenScale
        )
    }()
    
    // DEBUG-only verbose logging toggle via App Group defaults
    private var verboseLogging: Bool {
        #if DEBUG
        return AppGroup.userDefaults.bool(forKey: "VerboseLogging")
        #else
        return false
        #endif
    }
    
    private func logVerbose(_ message: String) {
        #if DEBUG
        if verboseLogging {
            Logger.photo.debug("\(message)")
        }
        #endif
    }
    
    var currentAsset: PHAsset? {
        guard !currentAssets.isEmpty, currentIndex >= 0, currentIndex < currentAssets.count else {
            return nil
        }
        return currentAssets[currentIndex]
    }
        
    func setAssets(from albums: [String]) {
        let sortedAlbums = albums.sorted()

        // ✅ Comparaison par contenu réel, pas pointeur
        if Set(sortedAlbums) == Set(albumNames) {
            return
        }
        
        guard !sortedAlbums.isEmpty else {
            albumNames = []
            albumName = ""
            return
        }

        albumNames = sortedAlbums

        let newAlbumName: String
        if albumName.isEmpty || !sortedAlbums.contains(albumName) {
            if sortedAlbums.contains(storedAlbumName) {
                newAlbumName = storedAlbumName
            } else if let preferred = sortedAlbums.first(where: { $0 == "Favoris" }) {
                newAlbumName = preferred
            } else {
                newAlbumName = sortedAlbums.first!
            }

            if albumName != newAlbumName {
                albumName = newAlbumName
            }
        }
    }
    
    @MainActor
    func loadAlbums() async {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        if status != .authorized && status != .limited {
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            guard newStatus == .authorized || newStatus == .limited else {
                photoStatusMessage = "Permission non accordée"
                return
            }
        }
        
        let verbose = self.verboseLogging
        let loadedAlbums: [String] = await Task.detached(priority: .utility) {
            var names: [String] = []
            let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
            userAlbums.enumerateObjects { collection, _, _ in
                if let name = collection.localizedTitle {
                    names.append(name)
                    if verbose {
                        Logger.photo.debug("📷 Album: \(name), count estimé: \(collection.estimatedAssetCount)")
                    }
                }
            }
            return names
        }.value
        
        #if DEBUG
        Logger.photo.debug("📸 Albums disponibles (count): \(loadedAlbums.count)")
        if !loadedAlbums.isEmpty {
            let preview = loadedAlbums.prefix(5).joined(separator: ", ")
            let remaining = max(0, loadedAlbums.count - 5)
            if remaining > 0 {
                Logger.photo.debug("📸 Exemples: \(preview) … (+\(remaining) autres)")
            } else {
                Logger.photo.debug("📸 Exemples: \(preview)")
            }
        }
        #endif
        
        let finalAlbums = loadedAlbums.isEmpty ? ["Library"] : loadedAlbums
        let sortedAlbums = finalAlbums.sorted()
        setAssets(from: sortedAlbums)
    }
    
    func loadAlbumNames() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else {
            Logger.photo.error("⛔️ Accès photo refusé ou non demandé")
            return
        }
        
        let verbose = self.verboseLogging
        Task.detached(priority: .utility) {
            var names: [String] = []
            let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
            userAlbums.enumerateObjects { collection, _, _ in
                let title = collection.localizedTitle ?? "Sans nom"
                if collection.estimatedAssetCount > 0 {
                    names.append(title)
                }
                if verbose {
                    Logger.photo.debug("📷 Album: \(title), count estimé: \(collection.estimatedAssetCount)")
                }
            }
            
            await MainActor.run {
                self.albumNames = names.sorted()
                #if DEBUG
                Logger.photo.debug("📸 Albums (loadAlbumNames) count: \(names.count)")
                if !names.isEmpty {
                    let preview = names.prefix(5).joined(separator: ", ")
                    let remaining = max(0, names.count - 5)
                    if remaining > 0 {
                        Logger.photo.debug("📸 Exemples: \(preview) … (+\(remaining) autres)")
                    } else {
                        Logger.photo.debug("📸 Exemples: \(preview)")
                    }
                }
                #endif
            }
        }
    }
   
    private func loadAssetsFromPhotoLibrary() async {
        Logger.photo.debug("📚 Chargement depuis la photothèque complète...")
        photoStatusMessage = "Chargement..."
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let allPhotos = PHAsset.fetchAssets(with: fetchOptions)
        let allAssets = allPhotos.objects(at: IndexSet(0..<allPhotos.count))

        guard !allAssets.isEmpty else {
            photoStatusMessage = "📷 Aucune image dans la photothèque."
            Logger.photo.error("❌ Aucune image trouvée dans la photothèque")
            return
        }

        self.assets = allAssets
        // ✅ Enregistrer tous les assets
        self.currentAssets = allAssets
        let count = self.assets.count
        // Choisir un index aléatoire
        self.currentIndex = count > 1 ? Int.random(in: 0..<count) : 0
        Logger.photo.debug("📸 Photothèque: \(count) images, index choisi: \(self.currentIndex)")
        
        await loadImageLibrary(at: self.currentIndex)
    }
    
    func loadAssetsAndShowRandomPhoto(fromAlbum name: String?) async {
        Logger.photo.debug("🎯 loadAssetsAndShowRandomPhoto appelé avec: '\(name ?? "nil")'")
        
        if name == "Library" {
            await loadAssetsFromPhotoLibrary()
            return
        }
        
        // ✅ Réinitialiser l'état avant de charger
        photoStatusMessage = "Chargement en cours..."
        currentAssets = []
        currentIndex = 0

        // 🧱 Charger la liste des albums
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)

        // 🔎 Trouver la bonne collection
        var targetCollection: PHAssetCollection?

        collections.enumerateObjects { collection, _, stop in
            if collection.localizedTitle == name {
                targetCollection = collection
                stop.pointee = true
            }
        }

        guard let album = targetCollection else {
            Logger.photo.error("❌ Album '\(name ?? "nil")' introuvable")
            photoStatusMessage = "Album introuvable"
            // ✅ Fallback vers Library
            await loadAssetsFromPhotoLibrary()
            return
        }

        let assets = PHAsset.fetchAssets(in: album, options: nil)
        Logger.photo.debug("📊 Album '\(name ?? "nil")' contient \(assets.count) assets")
        
        guard assets.count > 0 else {
            Logger.photo.error("❌ Album '\(name ?? "nil")' est vide")
            photoStatusMessage = "Album vide"
            // ✅ Fallback vers Library
            await loadAssetsFromPhotoLibrary()
            return
        }

        // ✅ Enregistrer tous les assets
        currentAssets = (0..<assets.count).map { assets.object(at: $0) }
        
        // 🖼️ Choisir une image aléatoire
        guard !self.currentAssets.isEmpty else {
            Logger.photo.error("❌ Pas assez d'assets (count: 0)")
            photoStatusMessage = "Aucune photo disponible"
            return
        }
        
        currentIndex = self.currentAssets.count > 1 ? Int.random(in: 0..<self.currentAssets.count) : 0
        let chosenIndex = self.currentIndex
        Logger.photo.debug("📸 Album '\(name ?? "nil")': \(self.currentAssets.count) assets, index choisi: \(chosenIndex)")
        
        if verboseLogging {
            let chosenAsset = self.currentAssets[chosenIndex]
            Logger.photo.debug("🔎 Asset choisi ID: \(chosenAsset.localIdentifier)")
        }
        
        await loadImage(at: self.currentIndex)
    }
    
        /// Change l'album et force le rechargement des photos
    /// Cette fonction est utilisée par l'interface utilisateur (Picker)
    @MainActor
    func changeAlbum(to newAlbum: String) async {
        guard !newAlbum.isEmpty else { return }
        
        Logger.photo.info("🔄 changeAlbum appelé: '\(self.albumName)' → '\(newAlbum)'")
        
        // Mettre à jour le nom stocké
        self.storedAlbumName = newAlbum
        
        // Mettre à jour albumName sans déclencher le didSet
        // en vérifiant d'abord si c'est différent
        let needsReload = (self.albumName != newAlbum)
        self.albumName = newAlbum
        
        // Toujours recharger, même si c'est le même album
        Logger.photo.info("📸 Rechargement forcé pour album: \(newAlbum)")
        await loadAssetsAndShowRandomPhoto(fromAlbum: newAlbum)
    }

    func showNextImage() {
            Logger.photo.debug("🔵 showNextImage appelée")
            
            guard !currentAssets.isEmpty else { 
                Logger.photo.warning("⚠️ Aucun asset disponible pour image suivante")
                return 
            }
            
            Logger.photo.debug("➡️ Navigation demandée - Index actuel: \(self.currentIndex), Assets count: \(self.currentAssets.count)")
            
            let nextIndex = (self.currentIndex + 1) % self.currentAssets.count
            Logger.photo.debug("➡️ Calcul index suivant: \(self.currentIndex) → \(nextIndex)")
            self.currentIndex = nextIndex
            
            // ✅ Indicateur de chargement
            self.photoStatusMessage = "Chargement..."
            
            Logger.photo.debug("🔄 Appel loadImage pour index \(nextIndex)")
            Task {
                await self.loadImage(at: nextIndex)
                Logger.photo.debug("✅ Fin chargement image index \(nextIndex)")
            }
        }
        
        func showPreviousImage() {
            Logger.photo.debug("🔵 showPreviousImage appelée")
            
            guard !currentAssets.isEmpty else { 
                Logger.photo.warning("⚠️ Aucun asset disponible pour image précédente")
                return 
            }
            
            Logger.photo.debug("⬅️ Navigation demandée - Index actuel: \(self.currentIndex), Assets count: \(self.currentAssets.count)")
            
            let prevIndex = (self.currentIndex - 1 + self.currentAssets.count) % self.currentAssets.count
            Logger.photo.debug("⬅️ Calcul index précédent: \(self.currentIndex) → \(prevIndex)")
            self.currentIndex = prevIndex
            
            // ✅ Indicateur de chargement
            self.photoStatusMessage = "Chargement..."
            
            Logger.photo.debug("🔄 Appel loadImage pour index \(prevIndex)")
            Task {
                await self.loadImage(at: prevIndex)
                Logger.photo.debug("✅ Fin chargement image index \(prevIndex)")
            }
        }
    
        private func loadImageLibrary(at index: Int) async {
        guard index >= 0 && index < self.assets.count else {
            Logger.photo.error("❌ Index \(index) invalide (assets count: \(self.assets.count))")
            return
        }

        let asset = self.assets[index]
        
        // 🚀 OPTIMISATION: Vérifier le cache d'abord
        let cacheKey = asset.localIdentifier
        if let cachedImage = imageCache[cacheKey] {
            self.currentImage = cachedImage
            self.photoStatusMessage = nil
            Logger.photo.debug("💾 Image depuis cache (library, index: \(index))")
            return
        }
        
        await Task.detached {
            let options = PHImageRequestOptions()
            options.isSynchronous = false // 🚀 OPTIMISATION: Mode asynchrone
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = true

            var resultImage: UIImage?
            
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: await self.screenTargetSize, // 🚀 OPTIMISATION: Taille adaptative
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                resultImage = image
            }
            
            // Attendre un peu pour s'assurer que l'image est chargée
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            
            await MainActor.run { [resultImage, cacheKey] in
                if let img = resultImage {
                    self.currentImage = img
                    self.photoStatusMessage = nil
                    
                    // 🚀 OPTIMISATION: Mettre en cache
                    self.addToCache(image: img, key: cacheKey)
                    
                    Logger.photo.debug("✅ Image chargée (library, index: \(index))")
                } else {
                    self.photoStatusMessage = "❌ Erreur de chargement."
                    Logger.photo.error("❌ Échec du chargement de l'image")
                }
            }
        }.value
    }
        private func loadImage(at index: Int) async {
            guard index >= 0, index < self.currentAssets.count else {
                Logger.photo.error("❌ Index \(index) hors limites (count: \(self.currentAssets.count))")
                self.photoStatusMessage = "Index invalide"
                return
            }
            
            let asset = self.currentAssets[index]
            
            // 🚀 OPTIMISATION: Vérifier le cache d'abord
            let cacheKey = asset.localIdentifier
            if let cachedImage = imageCache[cacheKey] {
                self.currentImage = cachedImage
                self.photoStatusMessage = nil
                Logger.photo.debug("💾 Image depuis cache (index: \(index))")
                return
            }
            
            let verbose = self.verboseLogging
            
            // ✅ Utiliser une approche détachée pour ne pas bloquer
            await Task.detached {
                let options = PHImageRequestOptions()
                options.isSynchronous = false  // 🚀 OPTIMISATION: Mode asynchrone
                options.deliveryMode = .highQualityFormat
                options.resizeMode = .fast
                options.isNetworkAccessAllowed = true
                
                if verbose {
                    Logger.photo.debug("🔎 Asset ID: \(asset.localIdentifier)")
                }
                
                let targetSize = await self.screenTargetSize // 🚀 OPTIMISATION: Taille adaptative
                var resultImage: UIImage?
                
                PHImageManager.default().requestImage(
                    for: asset,
                    targetSize: targetSize,
                    contentMode: .aspectFit,
                    options: options
                ) { image, info in
                    resultImage = image
                }
                
                // Attendre un peu pour s'assurer que l'image est chargée
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                
                // ✅ Retour au main thread pour la mise à jour
                await MainActor.run { [resultImage, cacheKey] in
                    if let img = resultImage {
                        self.currentImage = img
                        self.photoStatusMessage = nil
                        
                        // 🚀 OPTIMISATION: Mettre en cache
                        self.addToCache(image: img, key: cacheKey)
                        
                        Logger.photo.debug("✅ Image chargée (index: \(index))")
                    } else {
                        self.photoStatusMessage = "Erreur de chargement"
                        Logger.photo.error("❌ Échec du chargement")
                    }
                }
            }.value
        }
      
        func setAssets(fromAlbum albumName: String) {
            guard PHPhotoLibrary.authorizationStatus(for: .readWrite) == .authorized else {
                self.currentAssets = []
                return
            }

            let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
            var matchingAlbum: PHAssetCollection?

            collections.enumerateObjects { collection, _, stop in
               if collection.localizedTitle == albumName {
                    matchingAlbum = collection
                    stop.pointee = true
                }
            }

            guard let album = matchingAlbum else {
                self.currentAssets = []
                return
            }

            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            self.currentAssets = PHAsset.fetchAssets(in: album, options: fetchOptions).objects(at: IndexSet(0..<PHAsset.fetchAssets(in: album, options: fetchOptions).count))
            currentIndex = 0
        }
    
    // MARK: - 🚀 OPTIMISATIONS: Gestion du cache
    
    /// Ajoute une image au cache avec gestion de la taille maximale
    private func addToCache(image: UIImage, key: String) {
        // Si le cache est plein, supprimer la plus ancienne (FIFO)
        if imageCache.count >= maxCacheSize {
            if let firstKey = imageCache.keys.first {
                imageCache.removeValue(forKey: firstKey)
                Logger.photo.debug("🗑️ Cache plein - suppression de l'entrée la plus ancienne")
            }
        }
        imageCache[key] = image
        Logger.photo.debug("💾 Image ajoutée au cache (total: \(self.imageCache.count)/\(self.maxCacheSize))")
    }
    
    /// Vide le cache d'images
    func clearImageCache() {
        imageCache.removeAll()
        Logger.photo.info("🗑️ Cache d'images vidé")
    }
    
    // MARK: - 🚀 NOUVELLE FONCTIONNALITÉ: Chargement haute définition
    
    /// Charge l'image actuelle en haute définition (pour double-clic)
    func loadCurrentImageInHighDefinition() async {
        guard let asset = currentAsset else {
            Logger.photo.warning("⚠️ Aucun asset actuel pour charger en HD")
            return
        }
        
        Logger.photo.info("🔍 Chargement HD demandé pour asset \(asset.localIdentifier)")
        photoStatusMessage = "Chargement HD..."
        
        await Task.detached {
            let options = PHImageRequestOptions()
            options.isSynchronous = false
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .none // 🚀 Pas de redimensionnement = taille originale
            options.isNetworkAccessAllowed = true
            
            var resultImage: UIImage?
            
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize, // 🚀 Taille maximale = HD complète
                contentMode: .aspectFit,
                options: options
            ) { image, info in
                resultImage = image
            }
            
            // Attendre le chargement (peut être plus long pour HD)
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s
            
            await MainActor.run { [resultImage] in
                if let img = resultImage {
                    self.currentImage = img
                    self.photoStatusMessage = nil
                    
                    // Ne pas mettre en cache les images HD (trop volumineuses)
                    
                    Logger.photo.info("✅ Image HD chargée - taille: \(img.size.width)x\(img.size.height)")
                } else {
                    self.photoStatusMessage = "Erreur chargement HD"
                    Logger.photo.error("❌ Échec du chargement HD")
                }
            }
        }.value
    }
}

