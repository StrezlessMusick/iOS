import MEGADomain

extension UsageViewController {
     
    @objc func storageColor(traitCollection: UITraitCollection, isStorageFull: Bool, currentPage: Int) -> UIColor {
        guard currentPage == 0, isStorageFull else {
            return UIColor.mnz_turquoise(for: traitCollection)
        }
        return UIColor.mnz_red(for: traitCollection)
    }
    
    @objc func updateAppearance() {
        view.backgroundColor = UIColor.mnz_background()
        
        pieChartView?.backgroundColor = UIColor.mnz_background()
        
        pieChartMainLabel?.textColor = storageColor(traitCollection: traitCollection,
                                                   isStorageFull: isStorageFull(),
                                                   currentPage: usagePageControl?.currentPage ?? 0)
        
        pieChartSecondaryLabel?.textColor = UIColor.mnz_primaryGray(for: traitCollection)
        pieChartTertiaryLabel?.textColor = UIColor.mnz_secondaryGray(for: traitCollection)
        
        pieChartView?.reloadData()
        
        usagePageControl?.currentPageIndicatorTintColor = UIColor.mnz_turquoise(for: traitCollection)
        usagePageControl?.pageIndicatorTintColor = UIColor.mnz_secondaryGray(for: traitCollection)
        usageBottomSeparatorView?.backgroundColor = UIColor.mnz_separator(for: traitCollection)
        
        cloudDriveSizeLabel?.textColor = UIColor.mnz_secondaryGray(for: traitCollection)
        backupsSizeLabel?.textColor = UIColor.mnz_secondaryGray(for: traitCollection)
        rubbishBinSizeLabel?.textColor = UIColor.mnz_secondaryGray(for: traitCollection)
        incomingSharesSizeLabel?.textColor = UIColor.mnz_secondaryGray(for: traitCollection)
        
        cloudDriveBottomSeparatorView?.backgroundColor = UIColor.mnz_separator(for: traitCollection)
        backupsBottomSeparatorView?.backgroundColor = UIColor.mnz_separator(for: traitCollection)
        rubbishBinBottomSeparatorView?.backgroundColor = UIColor.mnz_separator(for: traitCollection)
        incomingSharesBottomSeparatorView?.backgroundColor = UIColor.mnz_separator(for: traitCollection)
    }
    
    @objc func initializeStorageInfo() {
        guard let accountDetails = MEGASdkManager.sharedMEGASdk().mnz_accountDetails else { return }
        
        if let rootNode = MEGASdkManager.sharedMEGASdk().rootNode {
            cloudDriveSize = accountDetails.storageUsed(forHandle: rootNode.handle)
        }
        
        cloudDriveSizeLabel?.text = text(forSizeLabels: cloudDriveSize ?? NSNumber(value: 0))
        
        backupsActivityIndicator?.isHidden = false
        backupsActivityIndicator?.startAnimating()
        Task {
            do {
                let backupSize = try await InboxUseCase(inboxRepository: InboxRepository.newRepo, nodeRepository: NodeRepository.newRepo).backupRootNodeSize()
                backupsSizeLabel?.text = self.text(forSizeLabels: NSNumber(value: backupSize))
            } catch {
                backupsSizeLabel?.text = self.text(forSizeLabels: NSNumber(value: 0))
            }
            backupsActivityIndicator?.stopAnimating()
            backupsActivityIndicator?.isHidden = true
        }
        
        if let rubbishNode = MEGASdkManager.sharedMEGASdk().rubbishNode {
            rubbishBinSize = accountDetails.storageUsed(forHandle: rubbishNode.handle)
        }
        
        rubbishBinSizeLabel?.text = text(forSizeLabels: rubbishBinSize ?? NSNumber(value: 0))
        
        var incomingSharedSizeSum: Int64 = 0
        
        MEGASdkManager.sharedMEGASdk().inShares().toNodeArray().forEach { node in
            incomingSharedSizeSum += MEGASdkManager.sharedMEGASdk().size(for: node).int64Value
        }
        
        incomingSharesSize = NSNumber(value: incomingSharedSizeSum)
        
        incomingSharesSizeLabel?.text = text(forSizeLabels: incomingSharesSize ?? NSNumber(value: 0))
        
        usedStorage = accountDetails.storageUsed
        maxStorage = accountDetails.storageMax
        
        transferOwnUsed = accountDetails.transferOwnUsed
        transferMax = accountDetails.transferMax
    }
    
    @objc func configView() {
        numberFormatter = NumberFormatter()
        numberFormatter?.numberStyle = .none
        numberFormatter?.roundingMode = .floor
        numberFormatter?.locale = .current

        cloudDriveLabel?.text = Strings.Localizable.cloudDrive
        backupsLabel?.text = Strings.Localizable.Backups.title
        rubbishBinLabel?.text = Strings.Localizable.rubbishBinLabel
        incomingSharesLabel?.text = Strings.Localizable.incomingShares
    }
}
