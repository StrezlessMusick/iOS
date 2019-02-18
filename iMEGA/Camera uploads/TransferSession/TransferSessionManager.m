
#import "TransferSessionManager.h"
#import "TransferSessionDelegate.h"
#import "TransferSessionTaskDelegate.h"
#import "CameraUploadManager+Settings.h"
#import "CameraUploadCompletionManager.h"

static NSString * const PhotoCellularAllowedUploadSessionId = @"nz.mega.photoTransfer.cellularAllowed";
static NSString * const PhotoCellularDisallowedUploadSessionId = @"nz.mega.photoTransfer.cellularDisallowed";
static NSString * const VideoCellularAllowedUploadSessionId = @"nz.mega.videoTransfer.cellularAllowed";
static NSString * const VideoCellularDisallowedUploadSessionId = @"nz.mega.videoTransfer.cellularDisallowed";

@interface TransferSessionManager () <NSURLSessionDataDelegate>

@property (strong, nonatomic) NSURLSession *photoCellularAllowedUploadSession;
@property (strong, nonatomic) NSURLSession *photoCellularDisallowedUploadSession;
@property (strong, nonatomic) NSURLSession *videoCellularAllowedUploadSession;
@property (strong, nonatomic) NSURLSession *videoCellularDisallowedUploadSession;

@property (strong, nonatomic) dispatch_queue_t serialQueue;

@property (copy, nonatomic) void (^photoCellularAllowedUploadSessionCompletion)(void);
@property (copy, nonatomic) void (^photoCellularDisallowedUploadSessionCompletion)(void);
@property (copy, nonatomic) void (^videoCellularAllowedUploadSessionCompletion)(void);
@property (copy, nonatomic) void (^videoCellularDisallowedUploadSessionCompletion)(void);

@end

@implementation TransferSessionManager

+ (instancetype)shared {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _serialQueue = dispatch_queue_create("nz.mega.sessionManager.cameraUploadSessionSerialQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark - session creation

- (NSURLSession *)photoCellularAllowedUploadSession {
    if (_photoCellularAllowedUploadSession) {
        return _photoCellularAllowedUploadSession;
    }
    
    dispatch_sync(self.serialQueue, ^{
        if (self->_photoCellularAllowedUploadSession == nil) {
            self->_photoCellularAllowedUploadSession = [self createBackgroundSessionWithIdentifier:PhotoCellularAllowedUploadSessionId];
        }
    });
    
    return _photoCellularAllowedUploadSession;
}

- (NSURLSession *)photoCellularDisallowedUploadSession {
    if (_photoCellularDisallowedUploadSession) {
        return _photoCellularDisallowedUploadSession;
    }
    
    dispatch_sync(self.serialQueue, ^{
        if (self->_photoCellularDisallowedUploadSession == nil) {
            self->_photoCellularDisallowedUploadSession = [self createBackgroundSessionWithIdentifier:PhotoCellularDisallowedUploadSessionId];
        }
    });
    
    return _photoCellularDisallowedUploadSession;
}

- (NSURLSession *)videoCellularAllowedUploadSession {
    if (_videoCellularAllowedUploadSession) {
        return _videoCellularAllowedUploadSession;
    }
    
    dispatch_sync(self.serialQueue, ^{
        if (self->_videoCellularAllowedUploadSession == nil) {
            self->_videoCellularAllowedUploadSession = [self createBackgroundSessionWithIdentifier:VideoCellularAllowedUploadSessionId];
        }
    });
    
    return _videoCellularAllowedUploadSession;
}

- (NSURLSession *)videoCellularDisallowedUploadSession {
    if (_videoCellularDisallowedUploadSession) {
        return _videoCellularDisallowedUploadSession;
    }
    
    dispatch_sync(self.serialQueue, ^{
        if (self->_videoCellularDisallowedUploadSession == nil) {
            self->_videoCellularDisallowedUploadSession = [self createBackgroundSessionWithIdentifier:VideoCellularDisallowedUploadSessionId];
        }
    });
    
    return _videoCellularDisallowedUploadSession;
}

- (NSURLSession *)createBackgroundSessionWithIdentifier:(NSString *)identifier {
    MEGALogDebug(@"[Camera Upload] create new background session with identifier %@", identifier);
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
    configuration.discretionary = NO;
    configuration.sessionSendsLaunchEvents = YES;
    configuration.allowsCellularAccess = [identifier isEqualToString:PhotoCellularAllowedUploadSessionId] || [identifier isEqualToString:VideoCellularAllowedUploadSessionId];
    TransferSessionDelegate *delegate = [[TransferSessionDelegate alloc] initWithSessionManager:self];
    return [NSURLSession sessionWithConfiguration:configuration delegate:delegate delegateQueue:nil];;
}

#pragma mark - invalidate sessions

- (void)invalidateAndCancelVideoSessions {
    [_videoCellularAllowedUploadSession invalidateAndCancel];
    _videoCellularAllowedUploadSession = nil;
    
    [_videoCellularDisallowedUploadSession invalidateAndCancel];
    _videoCellularDisallowedUploadSession = nil;
}

- (void)invalidateAndCancelPhotoSessions {
    [_photoCellularAllowedUploadSession invalidateAndCancel];
    _photoCellularAllowedUploadSession = nil;
    
    [_photoCellularDisallowedUploadSession invalidateAndCancel];
    _photoCellularDisallowedUploadSession = nil;
}

#pragma mark - session restoration

- (void)restoreAllSessions {
    NSArray<NSString *> *allSessionIdentifiers = @[PhotoCellularAllowedUploadSessionId, PhotoCellularDisallowedUploadSessionId, VideoCellularAllowedUploadSessionId, VideoCellularDisallowedUploadSessionId];
    for (NSString *identifier in allSessionIdentifiers) {
        [self restoreSessionIfNeededByIdentifier:identifier];
    }
}

- (void)restoreSessionIfNeededByIdentifier:(NSString *)identifier {
    NSURLSession *restoredSession;
    if ([identifier isEqualToString:PhotoCellularAllowedUploadSessionId]) {
        if (_photoCellularAllowedUploadSession == nil) {
            _photoCellularAllowedUploadSession = [self createBackgroundSessionWithIdentifier:identifier];
            restoredSession = _photoCellularAllowedUploadSession;
        }
    } else if ([identifier isEqualToString:PhotoCellularDisallowedUploadSessionId]) {
        if (_photoCellularDisallowedUploadSession == nil) {
            _photoCellularDisallowedUploadSession = [self createBackgroundSessionWithIdentifier:identifier];
            restoredSession = _photoCellularDisallowedUploadSession;
        }
    } else if ([identifier isEqualToString:VideoCellularAllowedUploadSessionId]) {
        if (_videoCellularAllowedUploadSession == nil) {
            _videoCellularAllowedUploadSession = [self createBackgroundSessionWithIdentifier:identifier];
            restoredSession = _videoCellularAllowedUploadSession;
        }
    } else if ([identifier isEqualToString:VideoCellularDisallowedUploadSessionId]) {
        if (_videoCellularDisallowedUploadSession == nil) {
            _videoCellularDisallowedUploadSession = [self createBackgroundSessionWithIdentifier:identifier];
            restoredSession = _videoCellularDisallowedUploadSession;
        }
    }
    
    [self restoreTaskDelegatesForSession:restoredSession];
}

- (void)restoreTaskDelegatesForSession:(NSURLSession *)session {
    [session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
        for (NSURLSessionUploadTask *task in uploadTasks) {
            [self addDelegateForTask:task inSession:session completion:nil];
        }
    }];
}

- (NSArray<NSURLSessionUploadTask *> *)allRunningUploadTasks {
    NSMutableArray<NSURLSessionUploadTask *> *tasks = [NSMutableArray array];
    NSArray<NSURLSession *> *sessions = @[self.photoCellularAllowedUploadSession, self.photoCellularDisallowedUploadSession, self.videoCellularAllowedUploadSession, self.videoCellularDisallowedUploadSession];
    for (NSURLSession *session in sessions) {
        [session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
            [tasks addObjectsFromArray:uploadTasks];
        }];
    }
    
    return [tasks copy];
}

#pragma mark - session completion handler

- (void)saveSessionCompletion:(void (^)(void))completion forIdentifier:(NSString *)identifier {
    if ([identifier isEqualToString:PhotoCellularAllowedUploadSessionId]) {
        self.photoCellularAllowedUploadSessionCompletion = completion;
    } else if ([identifier isEqualToString:PhotoCellularDisallowedUploadSessionId]) {
        self.photoCellularDisallowedUploadSessionCompletion = completion;
    } else if ([identifier isEqualToString:VideoCellularAllowedUploadSessionId]) {
        self.videoCellularAllowedUploadSessionCompletion = completion;
    } else if ([identifier isEqualToString:VideoCellularDisallowedUploadSessionId]) {
        self.videoCellularDisallowedUploadSessionCompletion = completion;
    }
}

- (void (^)(void))completionHandlerForIdentifier:(NSString *)identifier {
    if ([identifier isEqualToString:PhotoCellularAllowedUploadSessionId]) {
        return self.photoCellularAllowedUploadSessionCompletion;
    } else if ([identifier isEqualToString:PhotoCellularDisallowedUploadSessionId]) {
        return self.photoCellularDisallowedUploadSessionCompletion;
    } else if ([identifier isEqualToString:VideoCellularAllowedUploadSessionId]) {
        return self.videoCellularAllowedUploadSessionCompletion;
    } else if ([identifier isEqualToString:VideoCellularDisallowedUploadSessionId]) {
        return self.videoCellularDisallowedUploadSessionCompletion;
    } else {
        return nil;
    }
}

#pragma mark - task creation

- (NSURLSessionUploadTask *)photoUploadTaskWithURL:(NSURL *)requestURL fromFile:(NSURL *)fileURL completion:(UploadCompletionHandler)completion {
    NSURLSession *photoSession = CameraUploadManager.isCellularUploadAllowed ? self.photoCellularAllowedUploadSession : self.photoCellularDisallowedUploadSession;
    return [self backgroundUploadTaskInSession:photoSession withURL:requestURL fromFile:fileURL completion:completion];
}

- (NSURLSessionUploadTask *)videoUploadTaskWithURL:(NSURL *)requestURL fromFile:(NSURL *)fileURL completion:(UploadCompletionHandler)completion {
    NSURLSession *videoSession = CameraUploadManager.isCellularUploadAllowed ? self.videoCellularAllowedUploadSession : self.videoCellularDisallowedUploadSession;
    return [self backgroundUploadTaskInSession:videoSession withURL:requestURL fromFile:fileURL completion:completion];
}

- (NSURLSessionUploadTask *)backgroundUploadTaskInSession:(NSURLSession *)session withURL:(NSURL *)requestURL fromFile:(NSURL *)fileURL completion:(UploadCompletionHandler)completion {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
    request.HTTPMethod = @"POST";
    NSURLSessionUploadTask *task = [session uploadTaskWithRequest:request fromFile:fileURL];
    
    [self addDelegateForTask:task inSession:session completion:completion];
    
    return task;
}

- (void)addDelegateForTask:(NSURLSessionTask *)task inSession:(NSURLSession *)session completion:(UploadCompletionHandler)completion {
    TransferSessionTaskDelegate *delegate = [[TransferSessionTaskDelegate alloc] initWithCompletionHandler:completion];
    [(TransferSessionDelegate *)session.delegate addDelegate:delegate forTask:task];
}

#pragma mark - session finishes

- (void)didFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    [CameraUploadCompletionManager.shared waitUnitlAllUploadsAreFinished];
    void (^sessionCompletion)(void) = [self completionHandlerForIdentifier:session.configuration.identifier];
    [NSOperationQueue.mainQueue addOperationWithBlock:^{
        if (sessionCompletion) {
            sessionCompletion();
        }
    }];
}

@end
