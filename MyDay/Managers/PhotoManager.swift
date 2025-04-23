import SwiftUI
import Photos
import Combine

@MainActor
class PhotoManager: ObservableObject {
    @Published var albumNames: [String] = []
    @Published var currentImage: UIImage?
    @Published var photoStatusMessage: String?
    @Published var randomImage: UIImage?
    
    private var assets: [PHAsset] = []
    private var currentIndex: Int = 0
    
    private let userDefaults = UserDefaults(suiteName: "group.com.josblais.myday")
    private let albumKey = "savedAlbumName"
    
    @Published var savedAlbumName: String? = nil

    func loadSavedAlbumName() {
        self.savedAlbumName = UserDefaults.appGroup.string(forKey: "albumName")
    }
    
    func requestPhotoAccess(completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status == .authorized || status == .limited)
            }
        }
    }

    func loadAvailableAlbums() {
        var names: [String] = []
        let options = PHFetchOptions()
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options)
        collections.enumerateObjects { collection, _, _ in
            names.append(collection.localizedTitle ?? "Sans nom")
        }
        albumNames = names
    }

    func setAssets(forAlbumNamed name: String) {
        userDefaults?.set(name, forKey: albumKey)

        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "localizedTitle = %@", name)

        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        guard let album = collections.firstObject else {
            photoStatusMessage = "❌ Aucun album trouvé nommé '\(name)'"
            return
        }

        let assetsFetch = PHAsset.fetchAssets(in: album, options: nil)
        var newAssets: [PHAsset] = []
        assetsFetch.enumerateObjects { asset, _, _ in
            newAssets.append(asset)
        }

        if newAssets.isEmpty {
            photoStatusMessage = "❌ Aucun média dans l'album '\(name)'"
        } else {
            assets = newAssets
            currentIndex = 0
            loadImage(at: currentIndex)
        }
    }

    func fetchRandomPhoto(fromAlbum name: String) async throws {
        setAssets(forAlbumNamed: name)
        guard !assets.isEmpty else { throw NSError(domain: "PhotoManager", code: 1) }
        currentIndex = Int.random(in: 0..<assets.count)
        try await loadImage(at: currentIndex)
    }

    func showNextImage() {
        guard !assets.isEmpty else { return }
        currentIndex = (currentIndex + 1) % assets.count
        loadImage(at: currentIndex)
    }

    func showPreviousImage() {
        guard !assets.isEmpty else { return }
        currentIndex = (currentIndex - 1 + assets.count) % assets.count
        loadImage(at: currentIndex)
    }

    private func loadImage(at index: Int) {
        let asset = assets[index]
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true

        manager.requestImage(for: asset, targetSize: CGSize(width: 800, height: 800),
                             contentMode: .aspectFit, options: options) { image, _ in
            self.currentImage = image
        }
    }
}
