import Foundation
@testable import MEGA
import MEGADomain

struct MockThumbnailRepository: ThumbnailRepositoryProtocol {
    var hasCachedThumbnail = false
    var hasCachedPreview = false
    var hasOriginalPreview = false
    var cachedThumbnailURL = URL(string: "https://MEGA.NZ")!
    var cachedPreviewURL = URL(string: "https://MEGA.NZ")!
    var cachedOriginalURL = URL(string: "https://MEGA.NZ")!
    var loadThumbnailResult: Result<URL, ThumbnailErrorEntity> = .failure(.generic)
    var loadPreviewResult: Result<URL, ThumbnailErrorEntity> = .failure(.generic)
    
    func hasCachedThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> Bool {
        switch type {
        case .thumbnail:
            return hasCachedThumbnail
        case .preview:
            return hasCachedPreview
        case .original:
            return hasOriginalPreview
        }
    }
    
    func cachedThumbnailURL(for node: NodeEntity, type: ThumbnailTypeEntity) -> URL {
        switch type {
        case .thumbnail:
            return cachedThumbnailURL
        case .preview:
            return cachedPreviewURL
        case .original:
            return cachedOriginalURL
        }
    }
    
    func cachedThumbnailURL(for base64Handle: Base64HandleEntity, type: ThumbnailTypeEntity) -> URL {
        switch type {
        case .thumbnail:
            return cachedThumbnailURL
        case .preview:
            return cachedPreviewURL
        case .original:
            return cachedOriginalURL
        }
    }

    func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            loadThumbnail(for: node, type: type) {
                continuation.resume(with: $0)
            }
        }
    }
    
    func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void) {
        switch type {
        case .thumbnail:
            completion(loadThumbnailResult)
        case .preview, .original:
            completion(loadPreviewResult)
        }
    }
    
    func cachedPreviewOrOriginalPath(for node: NodeEntity) -> String? {
        nil
    }
}
