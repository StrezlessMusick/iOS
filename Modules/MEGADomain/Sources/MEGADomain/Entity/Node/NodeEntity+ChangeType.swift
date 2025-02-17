import Foundation
import MEGASwift

public extension Sequence where Element == NodeEntity {
    func removedChangeTypeNodes() -> [NodeEntity] {
        nodes(for: [.removed, .parent])
    }
    
    func nodes(for changedTypes: ChangeTypeEntity) -> [NodeEntity] {
        filter { $0.changeTypes.intersection(changedTypes).isNotEmpty }
    }
}
