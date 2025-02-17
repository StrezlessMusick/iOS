import UIKit
import MEGADomain

@available(iOS 14.0, *)
struct AlbumContentRouter: Routing {
    private let cameraUploadNode: NodeEntity?
    
    init(cameraUploadNode: NodeEntity?) {
        self.cameraUploadNode = cameraUploadNode
    }
    
    func build() -> UIViewController {
        let sdk = MEGASdkManager.sharedMEGASdk()
        
        let favouriteRepo = FavouriteNodesRepository.newRepo
        let nodesUpdateRepo = SDKNodesUpdateListenerRepository(sdk: sdk)
        let albumContentsRepo = AlbumContentsUpdateNotifierRepository(
            sdk: sdk,
            nodesUpdateListenerRepo: nodesUpdateRepo
        )
        let photoUseCase = PhotoLibraryUseCase(
            photosRepository: PhotoLibraryRepository.newRepo,
            searchRepository: SDKFilesSearchRepository.newRepo
        )
        
        let mediaUseCase = MediaUseCase()
        
        let albumContentsUseCase = AlbumContentsUseCase(
            albumContentsRepo: albumContentsRepo,
            favouriteRepo: favouriteRepo,
            photoUseCase: photoUseCase,
            mediaUseCase: mediaUseCase
        )
        
        let viewModel = AlbumContentViewModel(cameraUploadNode: cameraUploadNode,
                                              albumName: Strings.Localizable.CameraUploads.Albums.Favourites.title,
                                              albumContentsUseCase: albumContentsUseCase,
                                              router: self)
        let vc = AlbumContentViewController(viewModel: viewModel)
        
        return vc
    }
    
    func start() {}
}
