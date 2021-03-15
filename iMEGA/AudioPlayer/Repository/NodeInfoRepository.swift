import Foundation

protocol NodeInfoRepositoryProtocol {
    func path(fromHandle: MEGAHandle) -> URL?
    func info(fromNodes: [MEGANode]?) -> [AudioPlayerItem]?
    func authInfo(fromNodes: [MEGANode]?) -> [AudioPlayerItem]?
    func childrenInfo(fromParentHandle: MEGAHandle) -> [AudioPlayerItem]?
    func folderChildrenInfo(fromParentHandle: MEGAHandle) -> [AudioPlayerItem]?
    func node(fromHandle: MEGAHandle) -> MEGANode?
    func folderNode(fromHandle: MEGAHandle) -> MEGANode?
    func folderAuthNode(fromNode: MEGANode) -> MEGANode?
    func publicNode(fromFileLink: String, completion: @escaping ((MEGANode?) -> Void))
    func loginToFolder(link: String)
    func folderLinkLogout()
}

final class NodeInfoRepository: NodeInfoRepositoryProtocol {
    private let sdk: MEGASdk
    private let folderSDK: MEGASdk
    private var streamingInfoRepository = StreamingInfoRepository()
    private var offlineFileInfoRepository = OfflineInfoRepository()
    
    init(sdk: MEGASdk = MEGASdkManager.sharedMEGASdk(), folderSDK: MEGASdk = MEGASdkManager.sharedMEGASdkFolder()) {
        self.sdk = sdk
        self.folderSDK = folderSDK
    }
    
    //MARK: - Private functions
    private func playableChildren(of parent: MEGAHandle) -> [MEGANode]? {
        guard let parentNode = sdk.node(forHandle: parent) else { return nil }
        
        return sdk.children(forParent: parentNode).nodes
                                                    .filter{ $0.name.mnz_isMultimediaPathExtension &&
                                                                !$0.name.mnz_isVideoPathExtension &&
                                                                $0.mnz_isPlayable() }
    }
    
    private func folderPlayableChildren(of parent: MEGAHandle) -> [MEGANode]? {
        guard let parentNode = folderNode(fromHandle: parent) else { return nil }
        
        return folderSDK.children(forParent: parentNode).nodes
                                                            .filter{ $0.name.mnz_isMultimediaPathExtension &&
                                                                        !$0.name.mnz_isVideoPathExtension &&
                                                                        $0.mnz_isPlayable() }
    }
    
    //MARK: - Public functions
    func node(fromHandle: MEGAHandle) -> MEGANode? { sdk.node(forHandle: fromHandle) }
    func folderNode(fromHandle: MEGAHandle) -> MEGANode? { folderSDK.node(forHandle: fromHandle) }
    func folderAuthNode(fromNode: MEGANode) -> MEGANode? { folderSDK.authorizeNode(fromNode) }
    
    func path(fromHandle: MEGAHandle) -> URL? {
        guard let node = node(fromHandle: fromHandle) else { return nil }
        
        return offlineFileInfoRepository.localPath(fromNode: node) ?? streamingInfoRepository.path(fromNode: node)
    }
    
    func info(fromNodes: [MEGANode]?) -> [AudioPlayerItem]? {
        return fromNodes?.compactMap {
            guard let url = path(fromHandle: $0.handle) else { return nil }
            return AudioPlayerItem(name: $0.name, url: url, node: $0.handle, hasThumbnail: $0.hasThumbnail())
        }
    }
    
    func authInfo(fromNodes: [MEGANode]?) -> [AudioPlayerItem]? {
        return fromNodes?.compactMap {
            guard let node = folderAuthNode(fromNode: $0),
                let url = streamingInfoRepository.path(fromNode: node) else { return nil }
            return AudioPlayerItem(name: node.name, url: url, node: node.handle, hasThumbnail: $0.hasThumbnail())
        }
    }
    
    func childrenInfo(fromParentHandle: MEGAHandle) -> [AudioPlayerItem]? {
        playableChildren(of: fromParentHandle).flatMap(info)
    }
    
    func folderChildrenInfo(fromParentHandle parent: MEGAHandle) -> [AudioPlayerItem]? {
        folderPlayableChildren(of: parent).flatMap(authInfo)
    }
    
    func publicNode(fromFileLink: String, completion: @escaping ((MEGANode?) -> Void)) {
        sdk.publicNode(forMegaFileLink: fromFileLink, delegate: MEGAGetPublicNodeRequestDelegate(completion: { (request, error) in
            guard let error = error, error.type == .apiOk  else {
                completion(nil)
                return
            }
            completion(request?.publicNode)
        }))
    }
    
    func loginToFolder(link: String) {
        if (folderSDK.isLoggedIn() == 0) {
            folderSDK.login(toFolderLink: link)
        }
    }
     
    func folderLinkLogout() {
        folderSDK.logout()
    }
}
