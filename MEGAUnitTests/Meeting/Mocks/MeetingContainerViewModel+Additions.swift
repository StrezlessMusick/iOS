@testable import MEGA
import MEGADomain

extension MeetingContainerViewModel {
    
    convenience init(
        router: MeetingContainerRouting = MockMeetingContainerRouter(),
        chatRoom: ChatRoomEntity = ChatRoomEntity(),
        callUseCase: CallUseCaseProtocol = MockCallUseCase(call: CallEntity()),
        chatRoomUseCase: ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        callCoordinatorUseCase: CallCoordinatorUseCaseProtocol = MockCallCoordinatorUseCase(),
        userUseCase: UserUseCaseProtocol = MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false),
        authUseCase: AuthUseCaseProtocol = MockAuthUseCase(isUserLoggedIn: true),
        noUserJoinedUseCase: MeetingNoUserJoinedUseCaseProtocol = MockMeetingNoUserJoinedUseCase(),
        statsUseCase: MeetingStatsUseCaseProtocol =  MockMeetingStatsUseCase(),
        isTesting: Bool = true
    ) {
        self.init(
            router: router,
            chatRoom: chatRoom,
            callUseCase: callUseCase,
            chatRoomUseCase: chatRoomUseCase,
            callCoordinatorUseCase: callCoordinatorUseCase,
            userUseCase: userUseCase,
            authUseCase: authUseCase,
            noUserJoinedUseCase: noUserJoinedUseCase,
            statsUseCase: statsUseCase
        )
    }
}
