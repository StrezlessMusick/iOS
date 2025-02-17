import Foundation
import MEGADomain

protocol MEGAAvatarUseCaseProtocol {

    func loadRemoteAvatarImage(completion: @escaping (UIImage?) -> Void)

    func getCachedAvatarImage() -> UIImage?

    func loadCachedAvatarImage(completion: @escaping (UIImage?) -> Void)
}

final class MEGAavatarUseCase: MEGAAvatarUseCaseProtocol {

    private let avatarRepository: SDKAvatarClient

    private let avatarFileSystemClient: FileSystemImageCacheClient

    private let megaUserClient: SDKUserClient

    private var thumbnailRepo: ThumbnailRepositoryProtocol

    init(
        megaAvatarClient: SDKAvatarClient,
        avatarFileSystemClient: FileSystemImageCacheClient,
        megaUserClient: SDKUserClient,
        thumbnailRepo: ThumbnailRepositoryProtocol
    ) {
        self.avatarRepository = megaAvatarClient
        self.avatarFileSystemClient = avatarFileSystemClient
        self.megaUserClient = megaUserClient
        self.thumbnailRepo = thumbnailRepo
    }

    // MARK: - Shared Avatar Caching Path

    private func cachedAvatarFilePath(of userBase64Handle: Base64HandleEntity) -> URL {
        thumbnailRepo.cachedThumbnailURL(for: userBase64Handle, type: .thumbnail)
    }

    // MARK: - Search Local Cached Avatar

    func getCachedAvatarImage() -> UIImage? {
        guard let userBase64Handle = megaUserClient.currentUser()?.base64Handle else {
            return nil
        }

        let localAvatarCachingPath = cachedAvatarFilePath(of: userBase64Handle)
        return avatarFileSystemClient.cachedImage(localAvatarCachingPath).flatMap(UIImage.init(data:))
    }

    func loadCachedAvatarImage(completion: @escaping (UIImage?) -> Void) {
        guard let userBase64Handle = megaUserClient.currentUser()?.base64Handle else {
            completion(nil)
            return
        }

        let localAvatarCachingPath = cachedAvatarFilePath(of: userBase64Handle)
        avatarFileSystemClient.loadCachedImageAsync(localAvatarCachingPath) { imageData in
            completion(imageData.flatMap(UIImage.init(data:)))
        }
    }

    func loadRemoteAvatarImage(completion: @escaping (UIImage?) -> Void) {
        guard let userBase64Handle = megaUserClient.currentUser()?.base64Handle else {
            completion(nil)
            return
        }

        let localAvatarCachingPath = cachedAvatarFilePath(of: userBase64Handle)
        if let userHandle = megaUserClient.currentUser()?.handle {
            avatarRepository.loadUserAvatar(userHandle, localAvatarCachingPath, completion)
        }
    }
}
