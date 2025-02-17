
import MEGADomain

extension SharedItemsViewController: ContatctsViewControllerDelegate {
    @objc func shareFolder() {
        if MEGAReachabilityManager.isReachableHUDIfNot() {
            guard let nodes = selectedNodesMutableArray as? [MEGANode] else { return }
            BackupNodesValidator(presenter: self, inboxUseCase: InboxUseCase(inboxRepository: InboxRepository.newRepo, nodeRepository: NodeRepository.newRepo), nodes: nodes.toNodeEntities()).showWarningAlertIfNeeded() { [weak self] in
                guard let `self` = self,
                        let navigationController = UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "ContactsNavigationControllerID") as? MEGANavigationController,
                        let contactsVC = navigationController.viewControllers.first as? ContactsViewController else {
                    return
                }
                
                contactsVC.contatctsViewControllerDelegate = self
                contactsVC.nodesArray = nodes
                contactsVC.contactsMode = .shareFoldersWith
                
                self.present(navigationController, animated: true)
            }
        }
    }
}
