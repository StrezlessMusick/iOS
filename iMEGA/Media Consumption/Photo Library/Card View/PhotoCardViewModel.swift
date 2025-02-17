import Foundation
import Combine
import SwiftUI
import MEGASwiftUI
import MEGADomain
import MEGASwift

@available(iOS 14.0, *)
class PhotoCardViewModel: ObservableObject {
    private let coverPhoto: NodeEntity?
    private let thumbnailUseCase: ThumbnailUseCaseProtocol
    private var placeholderImageContainer = ImageContainer(image: Image("photoCardPlaceholder"), isPlaceholder: true)
    
    @Published var thumbnailContainer: any ImageContaining
    
    init(coverPhoto: NodeEntity?, thumbnailUseCase: ThumbnailUseCaseProtocol) {
        self.coverPhoto = coverPhoto
        self.thumbnailUseCase = thumbnailUseCase
        thumbnailContainer = placeholderImageContainer
    }
    
    func loadThumbnail() {
        guard let photo = coverPhoto else {
            return
        }
        
        guard isShowingThumbnail(placeholderImageContainer) else {
            return
        }
        
        if let container = thumbnailUseCase.cachedThumbnailImageContainer(for: photo, type: .preview) {
            thumbnailContainer = container
        } else {
            loadThumbnailFromRemote(for: photo)
        }
    }
    
    // MARK: - Private
    private func loadThumbnailFromRemote(for photo: NodeEntity) {
        thumbnailUseCase
            .requestPreview(for: photo)
            .map { url in
                URLImageContainer(imageURL: url)
            }
            .replaceError(with: nil)
            .compactMap { $0 }
            .filter { [weak self] in
                self?.isShowingThumbnail($0) == false
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$thumbnailContainer)
    }
    
    private func isShowingThumbnail(_ container: some ImageContaining) -> Bool {
        thumbnailContainer.isEqual(container)
    }
}
