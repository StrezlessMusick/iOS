import MEGADomain

protocol MeetingParticipantsLayoutRouting: Routing {
    func showRenameChatAlert()
    func startCallEndCountDownTimer()
    func endCallEndCountDownTimer()
}

final class MeetingParticipantsLayoutRouter: NSObject, MeetingParticipantsLayoutRouting {
    private weak var baseViewController: UIViewController?
    private weak var presenter: UINavigationController?
    private weak var navigationController: UINavigationController?
    private weak var containerViewModel: MeetingContainerViewModel?
    private(set) weak var viewModel: MeetingParticipantsLayoutViewModel?
    
    private let chatRoom: ChatRoomEntity
    private let call: CallEntity

    init(presenter: UINavigationController, containerViewModel: MeetingContainerViewModel, chatRoom: ChatRoomEntity, call: CallEntity) {
        self.presenter = presenter
        self.containerViewModel = containerViewModel
        self.chatRoom = chatRoom
        self.call = call
        super.init()
    }
    
    func build() -> UIViewController {
        guard let containerViewModel = containerViewModel else { return UIViewController() }
        
        let userImageUseCase = UserImageUseCase(
            userImageRepo: UserImageRepository(sdk: MEGASdkManager.sharedMEGASdk()),
            userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()),
            thumbnailRepo: ThumbnailRepository.newRepo,
            fileSystemRepo: FileSystemRepository.newRepo
        )
        let statsUseCase = MeetingStatsUseCase(repository: StatsRepository(sdk: MEGASdkManager.sharedMEGASdk()))

        let vm = MeetingParticipantsLayoutViewModel(
            router: self,
            containerViewModel: containerViewModel,
            callUseCase: CallUseCase(repository: CallRepository(chatSdk: MEGASdkManager.sharedMEGAChatSdk(), callActionManager: CallActionManager.shared)),
            captureDeviceUseCase: CaptureDeviceUseCase(repo: CaptureDeviceRepository()),
            localVideoUseCase: CallLocalVideoUseCase(repository: CallLocalVideoRepository(chatSdk: MEGASdkManager.sharedMEGAChatSdk())),
            remoteVideoUseCase: CallRemoteVideoUseCase(repository: CallRemoteVideoRepository(chatSdk: MEGASdkManager.sharedMEGAChatSdk())),
            chatRoomUseCase: ChatRoomUseCase(
                chatRoomRepo: ChatRoomRepository.sharedRepo,
                userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance())),
            userUseCase: UserUseCase(repo: .live),
            userImageUseCase: userImageUseCase,
            statsUseCase: statsUseCase,
            chatRoom: chatRoom,
            call: call
        )
        
        let vc = MeetingParticipantsLayoutViewController(viewModel: vm)
        baseViewController = vc
        viewModel = vm
        return vc
    }
    
    @objc func start() {
        guard let presenter = presenter else { return }
        presenter.setViewControllers([build()], animated: true)
    }
    
    func showRenameChatAlert() {
        viewModel?.dispatch(.showRenameChatAlert)
    }
    
    func startCallEndCountDownTimer() {
        viewModel?.dispatch(.startCallEndCountDownTimer)
    }
    
    func endCallEndCountDownTimer() {
        viewModel?.dispatch(.endCallEndCountDownTimer)
    }
    
    func pinParticipantAsSpeaker(_ participant: CallParticipantEntity) {
        viewModel?.dispatch(.pinParticipantAsSpeaker(participant))
    }
}
