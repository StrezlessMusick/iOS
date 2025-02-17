import MEGADomain

extension CloudDriveViewController {
    
    private func updatedParentNodeIfBelongs(_ nodeList: MEGANodeList) -> MEGANode? {
        nodeList
            .toNodeArray()
            .compactMap {
                if $0.handle == parentNode?.handle { return $0 }
                return nil
            }.first
    }
    
    @IBAction func actionsTouchUpInside(_ sender: UIBarButtonItem) {
        guard let nodes = selectedNodesArray as? [MEGANode] else {
            return
        }
        
        let inboxUseCase = InboxUseCase(inboxRepository: InboxRepository.newRepo, nodeRepository: NodeRepository.newRepo)
        let nodeActionsViewController = NodeActionViewController(nodes: nodes, delegate: self, displayMode: displayMode, isIncoming: isIncomingShareChildView, containsAnyInboxNode: inboxUseCase.containsAnyInboxNode(nodes.toNodeEntities()), sender: sender)
        present(nodeActionsViewController, animated: true, completion: nil)
    }
    
    @objc func showBrowserNavigation(for nodes: [MEGANode], action: BrowserAction) {
        guard let navigationController = storyboard?.instantiateViewController(withIdentifier: "BrowserNavigationControllerID") as? MEGANavigationController, let browserVC = navigationController.viewControllers.first as? BrowserViewController else {
            return
        }
        
        browserVC.browserViewControllerDelegate = self
        browserVC.selectedNodesArray = nodes
        browserVC.browserAction = action
        
        present(navigationController, animated: true)
    }
    
    @objc func showShareFolderForNodes(_ nodes: [MEGANode]) {
        guard let navigationController =
                UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "ContactsNavigationControllerID") as? MEGANavigationController, let contactsVC = navigationController.viewControllers.first as? ContactsViewController else {
            return
        }
        
        contactsVC.contatctsViewControllerDelegate = self
        contactsVC.nodesArray = nodes
        contactsVC.contactsMode = .shareFoldersWith
        
        present(navigationController, animated: true)
    }
    
    @objc func showSendToChat(_ nodes: [MEGANode]) {
        guard let navigationController =
                UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "SendToNavigationControllerID") as? MEGANavigationController, let sendToViewController = navigationController.viewControllers.first as? SendToViewController else {
            return
        }
        
        sendToViewController.nodes = nodes
        sendToViewController.sendMode = .cloud
        
        present(navigationController, animated: true)
    }
    
    @objc func prepareToMoveNodes(_ nodes: [MEGANode]) {
        showBrowserNavigation(for: nodes, action: .move)
    }
    
    @objc func toolbarActions(nodeArray: [MEGANode]?) {
        guard let nodeArray = nodeArray, !nodeArray.isEmpty else {
            return
        }
        
        shareType = .accessOwner
        
        let nodeInboxUC = InboxUseCase(inboxRepository: InboxRepository.newRepo, nodeRepository: NodeRepository.newRepo)

        if let parentNode = parentNode, nodeInboxUC.isInboxNode(parentNode.toNodeEntity()) {
            shareType = .accessRead
        } else {
            var currentNodeShareType: MEGAShareType = .accessUnknown
            
            nodeArray.forEach { node in
                currentNodeShareType = MEGASdkManager.sharedMEGASdk().accessLevel(for: node)
                
                if currentNodeShareType == .accessRead && currentNodeShareType.rawValue < shareType.rawValue {
                    shareType = currentNodeShareType
                    return
                }
                
                if (currentNodeShareType == .accessReadWrite && currentNodeShareType.rawValue < shareType.rawValue) ||
                    (currentNodeShareType == .accessFull && currentNodeShareType.rawValue < shareType.rawValue) {
                    shareType = currentNodeShareType
                }
            }
        }
        
        toolbarActions(for: shareType)
    }
    
    @objc func removeLinksForNodes(_ nodes: [MEGANode]) {
        nodes.publicLinkedNodes().mnz_removeLinks()
    }

    @objc func updateParentNodeIfNeeded(_ updatedNodeList: MEGANodeList) {
        guard let updatedParentNode = updatedParentNodeIfBelongs(updatedNodeList) else { return }
        
        self.parentNode = updatedParentNode
        setNavigationBarButtons()
    }
    
    @objc func sortNodes(_ nodes: [MEGANode], sortBy order: MEGASortOrderType) -> [MEGANode] {
        let sortOrder = SortOrderType(megaSortOrderType: order)
        let folderNodes = nodes.filter { $0.isFolder() }.sort(by: sortOrder)
        let fileNodes = nodes.filter { $0.isFile() }.sort(by: sortOrder)
        return folderNodes + fileNodes
    }
    
    @objc func newFolderNameAlertTitle(invalidChars containsInvalidChars: Bool) -> String {
        guard containsInvalidChars else {
            return Strings.Localizable.newFolder
        }
        return Strings.Localizable.General.Error.charactersNotAllowed(String.Constants.invalidFileFolderNameCharacters)
    }
}
