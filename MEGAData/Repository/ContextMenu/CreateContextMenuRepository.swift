import MEGADomain

struct CreateContextMenuRepository: CreateContextMenuRepositoryProtocol {
    static var newRepo: CreateContextMenuRepository {
        CreateContextMenuRepository()
    }
    
    func createContextMenu(config: CMConfigEntity) -> CMEntity? {
        ContextMenuBuilder()
                        .setType(config.menuType)
                        .setViewMode(config.viewMode)
                        .setAccessLevel(config.accessLevel)
                        .setSortType(config.sortType)
                        .setIsAFolder(config.isAFolder)
                        .setIsRubbishBinFolder(config.isRubbishBinFolder)
                        .setIsOfflineFolder(config.isOfflineFolder)
                        .setIsRestorable(config.isRestorable)
                        .setIsInVersionsView(config.isInVersionsView)
                        .setVersionsCount(config.versionsCount)
                        .setIsSharedItems(config.isSharedItems)
                        .setIsIncomingShareChild(config.isIncomingShareChild)
                        .setIsFavouritesExplorer(config.isFavouritesExplorer)
                        .setIsDocumentExplorer(config.isDocumentExplorer)
                        .setIsAudiosExplorer(config.isAudiosExplorer)
                        .setIsVideosExplorer(config.isVideosExplorer)
                        .setIsCameraUploadExplorer(config.isCameraUploadExplorer)
                        .setIsFilterEnabled(config.isFilterEnabled)
                        .setIsHome(config.isHome)
                        .setShowMediaDiscovery(config.showMediaDiscovery)
                        .setChatStatus(config.chatStatus)
                        .setIsDoNotDisturbEnabled(config.isDoNotDisturbEnabled)
                        .setTimeRemainingToDeactiveDND(config.timeRemainingToDeactiveDND)
                        .setIsShareAvailable(config.isShareAvailable)
                        .setIsInboxNode(config.isInboxNode)
                        .setIsInboxChild(config.isInboxChild)
                        .setIsSharedItemsChild(config.isSharedItemsChild)
                        .setIsOutShare(config.isOutShare)
                        .setIsExported(config.isExported)
                        .setIsEmptyState(config.isEmptyState)
                        .setShouldStartMeeting(config.shouldStartMeeting)
                        .setShouldJoinMeeting(config.shouldJoiningMeeting)
                        .setShouldScheduleMeeting(config.shouldScheduleMeeting)
                        .build()
    }
}
