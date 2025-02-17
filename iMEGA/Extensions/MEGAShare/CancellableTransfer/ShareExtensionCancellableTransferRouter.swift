import UIKit
import MEGADomain

final class ShareExtensionCancellableTransferRouter: NSObject, CancellableTransferRouting {
    
    private weak var presenter: UIViewController?
    
    private let transfers: [CancellableTransfer]
    private var wrapper: CancellableTransferControllerWrapper<ShareExtensionCancellableTransferViewModel>?

    init(presenter: UIViewController, transfers: [CancellableTransfer]) {
        self.presenter = presenter
        self.transfers = transfers
    }
    
    func build() -> UIViewController {
        let sdk = MEGASdkManager.sharedMEGASdk()
        let nodeRepository = NodeRepository.newRepo
        let fileSystemRepository = FileSystemRepository(fileManager: FileManager.default)
        
        let viewModel =  ShareExtensionCancellableTransferViewModel(router: self, uploadFileUseCase: UploadFileUseCase(uploadFileRepository: UploadFileRepository(sdk: sdk), fileSystemRepository: fileSystemRepository, nodeRepository: nodeRepository, fileCacheRepository: FileCacheRepository.newRepo), transfers: transfers)
        
        let wrapper = CancellableTransferControllerWrapper(viewModel: viewModel)
        self.wrapper = wrapper
        return wrapper.createViewController()
    }
    
    @objc func start() {
        guard let presenter = presenter else { return }
        presenter.present(build(), animated: true) { [weak self] in
            self?.wrapper?.viewIsReady()
        }
    }
    
    func showTransfersAlert() {
        guard let presenter = presenter else { return }
        presenter.present(build(), animated: true)
    }
    
    func transferSuccess(with message: String) {
        presenter?.dismiss(animated: true, completion: {
            SVProgressHUD.showSuccess(withStatus: message)
            self.finishShareExtensionIfNeeded()
        })
    }
    
    func transferCancelled(with message: String) {
        presenter?.dismiss(animated: true, completion: {
            SVProgressHUD.showInfo(withStatus: message)
            self.finishShareExtensionIfNeeded()
        })
    }
    
    func transferFailed(error: String) {
        presenter?.dismiss(animated: true, completion: {
            SVProgressHUD.showError(withStatus: error)
            self.finishShareExtensionIfNeeded()
        })
    }
    
    func transferCompletedWithError(error: String) {
        presenter?.dismiss(animated: true, completion: {
            SVProgressHUD.show(Asset.Images.Hud.hudDownload.image, status: error)
            self.finishShareExtensionIfNeeded()
        })
    }
    
    private func finishShareExtensionIfNeeded() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.presenter?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }
}
