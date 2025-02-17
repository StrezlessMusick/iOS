extension Sequence where Element: MEGANode {
    func containsNewNode() -> Bool {
        contains { $0.hasChangedType(.new) }
    }
    
    func hasModifiedAttributes() -> Bool {
        contains { $0.hasChangedType(.attributes)}
    }
    
    func hasModifiedParent() -> Bool {
        contains { $0.hasChangedType(.parent) }
    }
    
    func modifiedFavourites() -> [MEGANode] {
        filter({ $0.hasChangedType(.favourite) })
    }
    
    func removedChangeTypeNodes() -> [MEGANode] {
        nodes(for: [.removed, .parent])
    }
    
    func hasPublicLink() -> Bool {
        contains {
            $0.hasChangedType(.publicLink) &&
            $0.publicLink != nil
        }
    }
    
    func isPublicLinkRemoved() -> Bool {
        contains {
            $0.hasChangedType(.publicLink) &&
            $0.publicLink == nil
        }
    }
    
    func publicLinkedNodes() -> [MEGANode] {
        filter({ $0.isExported() })
    }
    
    func nodes(for changedTypes: [MEGANodeChangeType]) -> [MEGANode] {
        filter {
            for type in changedTypes where $0.hasChangedType(type) {
                return true
            }
            
            return false
        }
    }
}
