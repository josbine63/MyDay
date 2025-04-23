import Foundation
import Photos
import SwiftUI

class PhotoManager: ObservableObject {
    @Published var randomImage: UIImage?
    private let imageManager = PHImageManager.default()

    func requestPhotoAccess() {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized || status == .limited {
                DispatchQueue.main.async {
                    self.fetchRandomPersonPhoto()
                }
            } else {
                print("❌ Accès aux photos refusé.")
            }
        }
    }

    func fetchRandomPersonPhoto() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil)

        var peopleAlbum: PHAssetCollection?

        smartAlbums.enumerateObjects { collection, _, _ in
            if collection.localizedTitle == "People" || collection.localizedTitle == "Personnes" {
                peopleAlbum = collection
            }
        }

        guard let album = peopleAlbum else {
            print("❌ Album 'Personnes' introuvable.")
            return
        }

        let assets = PHAsset.fetchAssets(in: album, options: fetchOptions)

        guard assets.count > 0 else {
            print("❌ Aucun asset trouvé dans 'Personnes'.")
            return
        }

        let randomIndex = Int.random(in: 0..<assets.count)
        let randomAsset = assets.object(at: randomIndex)

        loadUIImage(from: randomAsset)
    }

    private func loadUIImage(from asset: PHAsset) {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat

        imageManager.requestImage(for: asset, targetSize: CGSize(width: 600, height: 600), contentMode: .aspectFill, options: options) { image, _ in
            DispatchQueue.main.async {
                self.randomImage = image
            }
        }
    }
}
