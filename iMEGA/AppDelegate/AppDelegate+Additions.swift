import Foundation
import SafariServices
import MEGADomain

extension AppDelegate {
    @objc func showAddPhoneNumberIfNeeded() {
        let visibleViewController = UIApplication.mnz_visibleViewController()
        if  visibleViewController is AddPhoneNumberViewController ||
            visibleViewController is InitialLaunchViewController ||
            visibleViewController is LaunchViewController ||
            visibleViewController is SMSVerificationViewController ||
            visibleViewController is VerificationCodeViewController ||
            visibleViewController is CreateAccountViewController ||
            visibleViewController is UpgradeTableViewController ||
            visibleViewController is OnboardingViewController ||
            visibleViewController is UIAlertController ||
            visibleViewController is VerifyEmailViewController ||
            visibleViewController is LoginViewController ||
            visibleViewController is SFSafariViewController { return }

        if MEGASdkManager.sharedMEGASdk().isBusinessAccount && MEGASdkManager.sharedMEGASdk().businessStatus != .active {
            return
        }
        
        if MEGASdkManager.sharedMEGASdk().smsAllowedState() != .optInAndUnblock { return }

        if MEGASdkManager.sharedMEGASdk().isGuestAccount { return }

        if MEGASdkManager.sharedMEGASdk().smsVerifiedPhoneNumber() != nil { return }

        if UserDefaults.standard.bool(forKey: "dontShowAgainAddPhoneNumber") {
            return
        }
        
        if let lastDateAddPhoneNumberShowed = UserDefaults.standard.value(forKey: "lastDateAddPhoneNumberShowed") {
            guard let days = Calendar.current.dateComponents([.day], from: lastDateAddPhoneNumberShowed as! Date, to: Date()).day else { return }
            if days < 7 { return }
        }

        UserDefaults.standard.set(Date(), forKey: "lastDateAddPhoneNumberShowed")
        var hideDontShowAgain = true
        let timesAddPhoneNumberShowed = UserDefaults.standard.integer(forKey: "timesAddPhoneNumberShowed")
        if timesAddPhoneNumberShowed >= MEGAOptOutOfAddYourPhoneNumberMinCount {
            hideDontShowAgain = false
        }
        UserDefaults.standard.set(timesAddPhoneNumberShowed + 1, forKey: "timesAddPhoneNumberShowed")
        AddPhoneNumberRouter(hideDontShowAgain: hideDontShowAgain, presenter: UIApplication.mnz_presentingViewController()).start()
    }

    @objc func showEnableTwoFactorAuthenticationIfNeeded() {
        if UserDefaults.standard.bool(forKey: "twoFactorAuthenticationAlreadySuggested") {
            return
        }

        MEGASdkManager.sharedMEGASdk().multiFactorAuthCheck(withEmail: MEGASdkManager.sharedMEGASdk().myEmail ?? "", delegate: MEGAGenericRequestDelegate.init(completion: { (request, _) in
            if request.flag {
                return //Two Factor Authentication Enabled
            }

            if UIApplication.mnz_visibleViewController() is AddPhoneNumberViewController || UIApplication.mnz_visibleViewController() is CustomModalAlertViewController || UIApplication.mnz_visibleViewController() is BusinessExpiredViewController || (MEGASdkManager.sharedMEGASdk().isBusinessAccount && MEGASdkManager.sharedMEGASdk().businessStatus != .active) {
                return
            }
            
            if LTHPasscodeViewController.doesPasscodeExist() && LTHPasscodeViewController.sharedUser().isLockscreenPresent() {
                return
            }
            
            let enable2FACustomModalAlert = CustomModalAlertViewController()
            enable2FACustomModalAlert.configureForTwoFactorAuthentication(requestedByUser: false)

            UIApplication.mnz_presentingViewController().present(enable2FACustomModalAlert, animated: true, completion: nil)
            
            UserDefaults.standard.set(true, forKey: "twoFactorAuthenticationAlreadySuggested")
        }))
    }
    
    @objc func showTurnOnNotificationsIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { permission in
            if permission.authorizationStatus == .denied {
                asyncOnMain {
                    let visibleViewController = UIApplication.mnz_visibleViewController()
                    if visibleViewController is CustomModalAlertViewController ||
                        visibleViewController is BusinessExpiredViewController
                    { return }
                    
                    TurnOnNotificationsViewRouter(presenter: UIApplication.mnz_presentingViewController()).start()
                }
            }
        }
    }
    
    @objc func showCookieDialogIfNeeded() {
        let cookieSettingsUseCase = CookieSettingsUseCase(repository: CookieSettingsRepository(sdk: MEGASdkManager.sharedMEGASdk()))
        
        if cookieSettingsUseCase.cookieBannerEnabled() {
            cookieSettingsUseCase.cookieSettings { [weak self] in
                switch $0 {
                case .success(_): break //Cookie settings already set
                    
                case .failure(let error):
                    switch error {
                    case .generic, .invalidBitmap: break
                        
                    case .bitmapNotSet:
                        self?.showCookieDialog()
                    }
                }
            }
        }
    }
    
    @objc func performCall(presenter: UIViewController, chatRoom: MEGAChatRoom, isSpeakerEnabled: Bool) {
        guard let call = MEGASdkManager.sharedMEGAChatSdk().chatCall(forChatId: chatRoom.chatId) else { return }
        MeetingContainerRouter(presenter: presenter,
                               chatRoom: chatRoom.toChatRoomEntity(),
                               call: call.toCallEntity(),
                               isSpeakerEnabled: isSpeakerEnabled).start()
    }
        
    private func showCookieDialog() {
        let visibleViewController = UIApplication.mnz_visibleViewController()
        if visibleViewController is CustomModalAlertViewController ||
           visibleViewController is BusinessExpiredViewController {
            return
        }
        
        let cookieDialogCustomModalAlert = CustomModalAlertViewController()
        cookieDialogCustomModalAlert.configureForCookieDialog()

        UIApplication.mnz_presentingViewController().present(cookieDialogCustomModalAlert, animated: true, completion: nil)
    }

    @objc func showLaunchTabDialogIfNeeded() {
        
        if TabManager.isLaunchTabSelected() || TabManager.isLaunchTabDialogAlreadySuggested() {
            return
        }
        
        if let firstLoginDate = UserDefaults.standard.value(forKey: MEGAFirstLoginDate) {
            guard let days = Calendar.current.dateComponents([.day], from: firstLoginDate as! Date, to: Date()).day else { return }
            if days < 7 { return }
        }
        
        showLaunchTabDialog()
    }
    
    private func showLaunchTabDialog() {
        let visibleViewController = UIApplication.mnz_visibleViewController()
        if visibleViewController is CustomModalAlertViewController ||
           visibleViewController is BusinessExpiredViewController {
            return
        }
        
        let launchTabDialogCustomModalAlert = CustomModalAlertViewController()
        launchTabDialogCustomModalAlert.configureForChangeLaunchTab()

        UIApplication.mnz_presentingViewController().present(launchTabDialogCustomModalAlert, animated: true) {
            TabManager.setLaunchTabDialogAlreadyAsSuggested()
        }
    }
    
    @objc func updateContactsNickname() {
        MEGASdkManager.sharedMEGASdk().getUserAttributeType(.alias, delegate: RequestDelegate { (result) in
            if case let .success(request) = result {
                guard let stringDictionary = request.megaStringDictionary else { return }
                
                let names = stringDictionary.compactMap { (key, value) -> (HandleEntity, String)? in
                    guard let nickname = value.base64URLDecoded else { return nil }
                    return (MEGASdk.handle(forBase64UserHandle: key), nickname)
                }
                
                MEGAStore.shareInstance().updateUserNicknames(by: names)
                
                OperationQueue.main.addOperation {
                    NotificationCenter.default.post(name: Notification.Name(MEGAAllUsersNicknameLoaded), object: nil)
                }
            }
        })
    }

    @objc func handleAccountBlockedEvent(_ event: MEGAEvent) {
        guard let suspensionType = AccountSuspensionType(rawValue: event.number) else { return }

        if suspensionType == .smsVerification && MEGASdkManager.sharedMEGASdk().smsAllowedState() != .notAllowed {
            if UIApplication.mnz_presentingViewController() is SMSNavigationViewController {
                return
            }

            SMSVerificationViewRouter(verificationType: .unblockAccount, presenter: UIApplication.mnz_presentingViewController()).start()
        } else if suspensionType == .emailVerification {
            if UIApplication.mnz_visibleViewController() is VerifyEmailViewController || UIApplication.mnz_visibleViewController() is SFSafariViewController {
                return
            }

            let verifyEmailVC = UIStoryboard(name: "VerifyEmail", bundle: nil).instantiateViewController(withIdentifier: "VerifyEmailViewControllerID")
            UIApplication.mnz_presentingViewController().present(verifyEmailVC, animated: true, completion: nil)
        } else {
            var message: String
            
            switch suspensionType {
            case .businessDisabled:
                message = Strings.Localizable.YourAccountHasBeenDisabledByYourAdministrator.pleaseContactYourBusinessAccountAdministratorForFurtherDetails
            case .businessRemoved:
                message = Strings.Localizable.YourAccountHasBeenRemovedByYourAdministrator.pleaseContactYourBusinessAccountAdministratorForFurtherDetails
            case .copyright:
                message = Strings.Localizable.Account.Suspension.Message.copyright
            case .nonCopyright:
                message = Strings.Localizable.Account.Suspension.Message.nonCopyright
            default:
                return
            }
            
            let alert = UIAlertController(title: Strings.Localizable.error, message:message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Strings.Localizable.ok, style: .cancel) { _ in
                MEGASdkManager.sharedMEGASdk().logout()
            })
            UIApplication.mnz_presentingViewController().present(alert, animated: true, completion: nil)
        }
    }
}

// MARK: - Config Cookie Settings

extension AppDelegate {
    @objc func checkCookieSettingsUpdate(in userList: MEGAUserList) {
        guard let size = userList.size?.intValue else {
            return
        }
        
        for index in 0..<size {
            let user = userList.user(at: index)
            if (user?.changes != nil) {
                if user?.isOwnChange == 0 { //If the change is external
                    if user?.handle == MEGASdkManager.sharedMEGASdk().myUser?.handle {
                        if ((user?.hasChangedType(.cookieSetting)) != nil) {
                            configAppWithNewCookieSettings()
                        }
                    }
                }
            }
        }
    }
    
    @objc func configAppWithNewCookieSettings() {
        let cookieSettingsUseCase = CookieSettingsUseCase(repository: CookieSettingsRepository(sdk: MEGASdkManager.sharedMEGASdk()))
        cookieSettingsUseCase.cookieSettings {
            switch $0 {
            case .success(let bitmap):
                let isPerformanceAndAnalyticsEnabled = CookiesBitmap(rawValue: bitmap).contains(.analytics)
                cookieSettingsUseCase.setCrashlyticsEnabled(isPerformanceAndAnalyticsEnabled)

            case .failure(_): break
            }
        }
    }
}

// MARK: SQLite disk full
extension AppDelegate {
    @objc func didReceiveSQLiteDiskFullNotification() {
        DispatchQueue.main.async {
            guard self.blockingWindow == nil else { return }
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.windowLevel = .alert + 1
            DiskFullBlockingViewRouter(window: window).start()
            self.blockingWindow = window
        }
    }
}

// MARK: - MEGAChatSdk onDBError
extension AppDelegate {
    @objc func handleChatDBError(error: MEGAChatDBError, message: String) {
        switch error {
        case .full:
            NotificationCenter.default.post(name: NSNotification.Name.MEGASQLiteDiskFull, object: nil, userInfo: nil)
            
        default:
            CrashlyticsLogger.log("MEGAChatSDK onDBError occurred. Error \(error) with message \(message)")
            MEGASdkManager.deleteSharedSdks()
            exit(0)
        }
    }
}

// MARK: - Register for background refresh
extension AppDelegate {
    @objc func registerCameraUploadBackgroundRefresh() {
        CameraUploadBGRefreshManager.shared.register()
    }
}
