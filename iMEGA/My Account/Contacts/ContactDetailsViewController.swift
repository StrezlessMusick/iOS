import MEGADomain

extension ContactDetailsViewController {
    @objc func joinMeeting(withChatRoom chatRoom: MEGAChatRoom) {
        guard let call = MEGASdkManager.sharedMEGAChatSdk().chatCall(forChatId: chatRoom.chatId) else { return }
        let isSpeakerEnabled = AVAudioSession.sharedInstance().mnz_isOutputEqual(toPortType: .builtInSpeaker)
        MeetingContainerRouter(presenter: self,
                               chatRoom: chatRoom.toChatRoomEntity(),
                               call: call.toCallEntity(),
                               isSpeakerEnabled: isSpeakerEnabled).start()
    }
    
    @objc func openChatRoom(chatId: HandleEntity, delegate: MEGAChatRoomDelegate) {
        if ChatRoomRepository.sharedRepo.isChatRoomOpen(chatId: chatId) {
            ChatRoomRepository.sharedRepo.closeChatRoom(chatId: chatId, delegate: delegate)
        }
        try? ChatRoomRepository.sharedRepo.openChatRoom(chatId: chatId, delegate: delegate)
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.sizeHeaderToFit()
    }
}

extension ContactDetailsViewController: PushNotificationControlProtocol {
    func presentAlertController(_ alert: UIAlertController) {
        present(alert, animated: true)
    }
    
    func reloadDataIfNeeded() {
        tableView?.reloadData()
    }
    
    func pushNotificationSettingsLoaded() {
        
        guard let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? ContactTableViewCell else {
            return
        }
        if cell.controlSwitch != nil {
            cell.controlSwitch.isEnabled = true
        }
    }
}

