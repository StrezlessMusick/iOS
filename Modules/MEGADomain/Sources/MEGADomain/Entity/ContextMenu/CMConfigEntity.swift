import Foundation

/// Configure the parameters needed to create a new CMEntity by the ContextMenuBuilder
///
///  - Parameters:
///     - menuType: The type of context menu used in each case
///     - viewMode: The current view mode (List, Thumbnail)
///     - accessLevel: The access level type for the current folder
///     - sortType: The selected sort type for this folder
///     - isRubbishBinFolder: Indicates whether or not it is the RubbishBin folder
///     - isRestorable: Indicates if the current node is restorable
///     - isOfflineFolder: Indicates whether or not it is the Offline folder
///     - isInVersionsView: Indicates whether or not it is versions view
///     - isSharedItems: Indicates whether or not it is the shared items screen
///     - isIncomingShareChild: Indicates whether or not it is an incoming shared child folder
///     - isHome: Indicates whether or not it is the home screen
///     - isDocumentExplorer: Indicates whether or not it is the home docs explorer
///     - isAudiosExplorer: Indicates whether or not it is the home audios explorer
///     - isVideosExplorer: Indicates whether or not it is the home videos explorer
///     - isCameraUploadExplorer: Indicates whether or not it is the camera upload explorer
///     - isFilterEnabled: Indicates whether or not if the filter is enabled
///     - isDoNotDisturbEnabled: Indicates wether or not the notifications are disabled
///     - isInboxNode: Indicates if the current node is the inbox root node
///     - isInboxChild: Indicates if the current node is an inbox node child
///     - isShareAvailable: Indicates if the share action is available
///     - isSharedItemsChild: Indicates if the current node is a shared items child
///     - isOutShare: Indicates if the current node is being shared with other users
///     - isExported: Indicates if the currrent node has been exported
///     - isEmptyState: Indicates whether an empty state is currently being displayed
///     - timeRemainingToDeactiveDND: Indicates the remaining time to active again the notifications
///     - versionsCount: The number of versions of the current node
///     - showMediaDiscovery:  Indicates whether or not it is avaiable to show Media Discovery
///     - chatStatus: Indicates the user chat status (online, away, busy, offline...)
///     - shouldStartMeeting: Indicates whether or not to start a meeting
///     - shouldJoiningMeeting: Indicated whether or not to join a meeting
///
public struct CMConfigEntity {
    public let menuType: CMElementTypeEntity
    public var viewMode: ViewModePreferenceEntity?
    public var accessLevel: ShareAccessLevelEntity?
    public var sortType: SortOrderEntity?
    public var isAFolder: Bool
    public var isRubbishBinFolder: Bool
    public var isRestorable: Bool
    public var isInVersionsView: Bool
    public var isOfflineFolder: Bool
    public var isSharedItems: Bool
    public var isIncomingShareChild: Bool
    public var isHome: Bool
    public var isFavouritesExplorer: Bool
    public var isDocumentExplorer: Bool
    public var isAudiosExplorer: Bool
    public var isVideosExplorer: Bool
    public var isCameraUploadExplorer: Bool
    public var isFilterEnabled: Bool
    public var isDoNotDisturbEnabled: Bool
    public var isInboxNode: Bool
    public var isInboxChild: Bool
    public var isShareAvailable: Bool
    public var isSharedItemsChild: Bool
    public var isOutShare: Bool
    public var isExported: Bool
    public var isEmptyState: Bool
    public var timeRemainingToDeactiveDND: String?
    public var versionsCount: Int
    public var showMediaDiscovery: Bool
    public var chatStatus: ChatStatusEntity
    public var shouldStartMeeting: Bool
    public var shouldJoiningMeeting: Bool
    public var shouldScheduleMeeting: Bool
    
    public init(menuType: CMElementTypeEntity, viewMode: ViewModePreferenceEntity? = nil, accessLevel: ShareAccessLevelEntity? = nil, sortType: SortOrderEntity? = nil, isAFolder: Bool = false, isRubbishBinFolder: Bool = false, isRestorable: Bool = false, isInVersionsView: Bool = false, isOfflineFolder: Bool = false, isSharedItems: Bool = false, isIncomingShareChild: Bool = false, isHome: Bool = false, isFavouritesExplorer: Bool = false, isDocumentExplorer: Bool = false, isAudiosExplorer: Bool = false, isVideosExplorer: Bool = false, isCameraUploadExplorer: Bool = false, isFilterEnabled: Bool = false, isDoNotDisturbEnabled: Bool = false, isInboxNode: Bool = false, isInboxChild: Bool = false, isShareAvailable: Bool = false, isSharedItemsChild: Bool = false, isOutShare: Bool = false, isExported: Bool = false, isEmptyState: Bool = false, timeRemainingToDeactiveDND: String? = nil, versionsCount: Int = 0, showMediaDiscovery: Bool = false, chatStatus: ChatStatusEntity = .invalid, shouldStartMeeting: Bool = false, shouldJoiningMeeting: Bool = false, shouldScheduleMeeting: Bool = false) {
        self.menuType = menuType
        self.viewMode = viewMode
        self.accessLevel = accessLevel
        self.sortType = sortType
        self.isAFolder = isAFolder
        self.isRubbishBinFolder = isRubbishBinFolder
        self.isRestorable = isRestorable
        self.isInVersionsView = isInVersionsView
        self.isOfflineFolder = isOfflineFolder
        self.isSharedItems = isSharedItems
        self.isIncomingShareChild = isIncomingShareChild
        self.isHome = isHome
        self.isFavouritesExplorer = isFavouritesExplorer
        self.isDocumentExplorer = isDocumentExplorer
        self.isAudiosExplorer = isAudiosExplorer
        self.isVideosExplorer = isVideosExplorer
        self.isCameraUploadExplorer = isCameraUploadExplorer
        self.isFilterEnabled = isFilterEnabled
        self.isDoNotDisturbEnabled = isDoNotDisturbEnabled
        self.isInboxNode = isInboxNode
        self.isInboxChild = isInboxChild
        self.isShareAvailable = isShareAvailable
        self.isSharedItemsChild = isSharedItemsChild
        self.isOutShare = isOutShare
        self.isExported = isExported
        self.isEmptyState = isEmptyState
        self.timeRemainingToDeactiveDND = timeRemainingToDeactiveDND
        self.versionsCount = versionsCount
        self.showMediaDiscovery = showMediaDiscovery
        self.chatStatus = chatStatus
        self.shouldStartMeeting = shouldStartMeeting
        self.shouldJoiningMeeting = shouldJoiningMeeting
        self.shouldScheduleMeeting = shouldScheduleMeeting
    }
}
