import Foundation
import MEGADomain

struct AlbumRepository: AlbumRepositoryProtocol {
    static var newRepo: AlbumRepository {
        AlbumRepository()
    }
    
    func loadCameraUploadNode() async throws -> NodeEntity? {
        try await withCheckedThrowingContinuation { continuation in
            CameraUploadNodeAccess.shared.loadNode { (node, error) in
                guard Task.isCancelled == false else { continuation.resume(throwing: CancellationError()); return }
                
                if let error = error {
                    MEGALogWarning("Couldn't load CU: \(error)")
                    continuation.resume(throwing: error)
                    return
                }
                
                continuation.resume(returning: node?.toNodeEntity())
            }
        }
    }
}
