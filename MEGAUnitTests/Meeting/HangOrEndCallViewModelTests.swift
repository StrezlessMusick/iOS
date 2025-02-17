import XCTest
@testable import MEGA

class HangOrEndCallViewModelTests: XCTestCase {

    func testAction_leaveCall() {
        let router = MockHangOrEndCallRouter()
        let viewModel = HangOrEndCallViewModel(router: router,
                                               statsUseCase: MockMeetingStatsUseCase())
        test(viewModel: viewModel, action: .leaveCall, expectedCommands: [])
        XCTAssert(router.leaveCall_calledTimes == 1)
    }
    
    func testAction_endCallForAll() {
        let router = MockHangOrEndCallRouter()
        let statsUseCase = MockMeetingStatsUseCase()
        let viewModel = HangOrEndCallViewModel(router: router, statsUseCase: statsUseCase)
        test(viewModel: viewModel, action: .endCallForAll, expectedCommands: [])
        XCTAssert(router.endCallForAllTimes == 1)
        XCTAssert(statsUseCase.sendEndCallForAllStats_calledTimes == 1)
    }

}

final class MockHangOrEndCallRouter: HangOrEndCallRouting {
    
    private(set) var leaveCall_calledTimes = 0
    private(set) var endCallForAllTimes = 0
    
    func leaveCall() {
        leaveCall_calledTimes += 1
    }
    
    func endCallForAll() {
        endCallForAllTimes += 1
    }
    
    func dismiss(animated flag: Bool, completion: (() -> Void)?) {}
}
