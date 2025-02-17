import MEGADomain
import Foundation

public struct MockMyBackupsRepository: MyBackupsRepositoryProtocol {
    public static let newRepo = MockInboxRepository()
    private let currentBackupNode: NodeEntity
    private let isBackupRootNodeEmpty: Bool
    
    public init(currentBackupNode: NodeEntity, isBackupRootNodeEmpty: Bool = false) {
        self.currentBackupNode = currentBackupNode
        self.isBackupRootNodeEmpty = isBackupRootNodeEmpty
    }
    
    public func isBackupRootNodeEmpty() async -> Bool {
        isBackupRootNodeEmpty
    }
    
    public func isBackupDeviceFolder(_ node: NodeEntity) -> Bool {
        guard node.deviceId != nil else { return false }
        return currentBackupNode.handle == node.parentHandle
    }
    
    public func backupRootNodeSize() async throws -> UInt64 {
        UInt64(currentBackupNode.size)
    }
    
    public func myBackupRootNode() async throws -> NodeEntity {
        currentBackupNode
    }
}
