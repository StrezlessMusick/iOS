
import XCTest
@testable import MEGA
import MEGADomainMock

final class CancellableTransferViewModelTests: XCTestCase {

    func testAction_onViewReady() {
        let transfer = CancellableTransfer(handle: .invalid, messageId: .invalid, chatId: .invalid, localFileURL: URL(fileURLWithPath: "PathToFile"), name: nil, appData: nil, priority: false, isFile: true, type: .download)
        let router = MockCancellableTransferRouter()
        let viewModel = CancellableTransferViewModel(router: router, uploadFileUseCase: MockUploadFileUseCase(), downloadNodeUseCase: MockDownloadNodeUseCase(), transfers: [transfer], transferType: .download)
        
        test(viewModel: viewModel, action: .onViewReady, expectedCommands: [])
        XCTAssert(router.prepareTransfersWidget_calledTimes == 1)
    }
    
    func testAction_cancelTransfer() {
        let transfer = CancellableTransfer(handle: .invalid, messageId: .invalid, chatId: .invalid, localFileURL: URL(fileURLWithPath: "PathToFile"), name: nil, appData: nil, priority: false, isFile: true, type: .download)
        let router = MockCancellableTransferRouter()
        let viewModel = CancellableTransferViewModel(router: router, uploadFileUseCase: MockUploadFileUseCase(), downloadNodeUseCase: MockDownloadNodeUseCase(), transfers: [transfer], transferType: .download)
        
        test(viewModel: viewModel, action: .didTapCancelButton, expectedCommands: [.cancelling])
    }
}

final class MockCancellableTransferRouter: CancellableTransferRouting, TransferWidgetRouting {
    var showTransfersAlert_calledTimes = 0
    var transferSuccess_calledTimes = 0
    var transferCancelled_calledTimes = 0
    var transferFailed_calledTimes = 0
    var transferCompletedWithError_calledTimes = 0
    var prepareTransfersWidget_calledTimes = 0

    func showTransfersAlert() {
        showTransfersAlert_calledTimes += 1
    }
    
    func transferSuccess(with message: String) {
        transferSuccess_calledTimes += 1
    }
    
    func transferCancelled(with message: String) {
        transferCancelled_calledTimes += 1
    }
    
    func transferFailed(error: String) {
        transferFailed_calledTimes += 1
    }
    
    func transferCompletedWithError(error: String) {
        transferCompletedWithError_calledTimes += 1
    }
    
    func prepareTransfersWidget() {
        prepareTransfersWidget_calledTimes += 1
    }
}
