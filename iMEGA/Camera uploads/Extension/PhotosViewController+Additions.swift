extension PhotosViewController {
    @IBAction func moreAction(_ sender: UIBarButtonItem) {
        let nodeActionsViewController = NodeActionViewController(nodes: selection.nodes, delegate: self, displayMode: .selectionToolBar, sender: sender)
        present(nodeActionsViewController, animated: true, completion: nil)
    }
    
    @objc func handleDownloadAction(for nodes: [MEGANode]) {
        let transfers = nodes.map {
            CancellableTransfer(handle: $0.handle, name: nil, appData: nil, priority: false, isFile: $0.isFile(), type: .download)
        }
        CancellableTransferRouter(presenter: self, transfers: transfers, transferType: .download).start()
        toggleEditing()
    }
    
    @objc func showBrowserNavigation(for nodes: [MEGANode], action: BrowserAction) {
        guard let navigationController = UIStoryboard(name: "Cloud", bundle: nil).instantiateViewController(withIdentifier: "BrowserNavigationControllerID") as? MEGANavigationController,
              let browserVC = navigationController.viewControllers.first as? BrowserViewController else {
            return
        }
        browserVC.browserViewControllerDelegate = self
        browserVC.selectedNodesArray = nodes
        browserVC.browserAction = action
        present(navigationController, animated: true)
    }
    
    @objc func handleShareLink(for nodes: [MEGANode]) {
        guard MEGAReachabilityManager.isReachableHUDIfNot() else { return }
        CopyrightWarningViewController.presentGetLinkViewController(for: nodes, in: UIApplication.mnz_presentingViewController())
        toggleEditing()
    }
    
    @objc func handleDeleteAction(for nodes: [MEGANode]) {
        guard let rubbish = MEGASdkManager.sharedMEGASdk().rubbishNode else { return }
        let delegate = MEGAMoveRequestDelegate(toMoveToTheRubbishBinWithFiles: nodes.contentCounts().fileCount,
                                               folders: nodes.contentCounts().folderCount) { [weak self] in
            self?.toggleEditing()
        }
        nodes.forEach { MEGASdkManager.sharedMEGASdk().move($0, newParent: rubbish, delegate: delegate) }
    }
    
    func handleRemoveLinks(for nodes: [MEGANode]) {
        nodes.publicLinkedNodes().mnz_removeLinks()
        toggleEditing()
    }
    
    private func handleExportFile(for nodes: [MEGANode], sender: Any) {
        let entityNodes = nodes.toNodeEntities()
        ExportFileRouter(presenter: self, sender: sender).export(nodes: entityNodes)
        toggleEditing()
    }
    
    private func handleSendToChat(for nodes: [MEGANode]) {
        guard let navigationController = UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "SendToNavigationControllerID") as? MEGANavigationController,
              let sendToViewController = navigationController.viewControllers.first as? SendToViewController else {
            return
        }
        
        sendToViewController.nodes = nodes
        sendToViewController.sendMode = .cloud
        present(navigationController, animated: true)
        toggleEditing()
    }
}

//MARK: - NodeActionViewControllerDelegate
extension PhotosViewController: NodeActionViewControllerDelegate {
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, forNodes nodes: [MEGANode], from sender: Any) {
        handleNodesAction(action: action, nodes: nodes, sender: sender)
    }
    
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) {
        handleNodesAction(action: action, nodes: [node], sender: sender)
    }

    private func handleNodesAction(action: MegaNodeActionType, nodes: [MEGANode], sender: Any) {
        switch action {
        case .download:
            handleDownloadAction(for: nodes)
        case .copy:
            showBrowserNavigation(for: nodes, action: .copy)
        case .move:
            showBrowserNavigation(for: nodes, action: .move)
        case .shareLink:
            handleShareLink(for: nodes)
        case .moveToRubbishBin:
            handleDeleteAction(for: nodes)
        case .exportFile:
            handleExportFile(for: nodes, sender: sender)
        case .sendToChat:
            handleSendToChat(for: nodes)
        case .removeLink:
            handleRemoveLinks(for: nodes)
        default:
            break
        }
    }
}

//MARK: - BrowserViewControllerDelegate and ContatctsViewControllerDelegate
extension PhotosViewController: BrowserViewControllerDelegate, ContatctsViewControllerDelegate {
    public func nodeEditCompleted(_ complete: Bool) {
        toggleEditing()
    }
}

extension PhotosViewController {
    @objc func configureStackViewHeight(view: UIView, perviousConstraint: NSLayoutConstraint?) -> NSLayoutConstraint? {

        var newConstraint: NSLayoutConstraint?
        let verticalPadding = 24.0

        let maxHeight = view.subviews.flatMap({ $0.subviews }).map({ $0.intrinsicContentSize.height }).max() ?? 0

        if perviousConstraint == nil {
            newConstraint = view.heightAnchor.constraint(equalToConstant: maxHeight > 0 ? maxHeight + verticalPadding : 0)
        } else {
            perviousConstraint?.isActive = false
            newConstraint = view.heightAnchor.constraint(equalToConstant: maxHeight + verticalPadding)
        }
        newConstraint?.isActive = true
        return newConstraint
    }
}
