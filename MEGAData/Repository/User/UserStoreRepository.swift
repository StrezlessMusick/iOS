

struct UserStoreRepository: UserStoreRepositoryProtocol {
    private let store: MEGAStore
    
    init(store: MEGAStore) {
        self.store = store
    }
    
    func getDisplayName(forUserHandle handle: UInt64) -> String? {
        fetchUser(withHandle: handle)?.displayName
    }
    
    func displayName(forUserHandle handle: UInt64) async -> String? {
        await withCheckedContinuation { continuation in
            guard let context = store.stack.newBackgroundContext() else {
                continuation.resume(returning: nil)
                return
            }
            context.perform {
                let displayName = store.fetchUser(withUserHandle: handle, context: context)?.displayName
                continuation.resume(returning: displayName)
            }
        }
    }
    
    private func fetchUser(withHandle handle: UInt64) -> MOUser? {
        store.fetchUser(withUserHandle: handle)
    }
}
