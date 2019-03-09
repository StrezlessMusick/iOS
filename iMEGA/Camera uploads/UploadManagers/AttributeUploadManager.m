
#import "AttributeUploadManager.h"
#import "NSFileManager+MNZCategory.h"
#import "NSURL+CameraUpload.h"
#import "ThumbnailUploadOperation.h"
#import "PreviewUploadOperation.h"
#import "CoordinatesUploadOperation.h"
#import "CameraUploadManager.h"
#import "NSString+MNZCategory.h"
#import "NSError+CameraUpload.h"
@import CoreLocation;

static const NSInteger CoordinatesConcurrentUploadCount = 3;
static const NSInteger ThumbnailConcurrentUploadCount = 20;

typedef NS_ENUM(NSInteger, PreviewConcurrentUploadCount) {
    PreviewConcurrentUploadCountWhenThumbnailsAreDone = 3,
    PreviewConcurrentUploadCountWhenThumbnailsAreUploading = 1
};

@interface AttributeUploadManager ()

@property (strong, nonatomic) NSOperationQueue *thumbnailUploadOperationQueue;
@property (strong, nonatomic) NSOperationQueue *previewUploadOperationQueue;
@property (strong, nonatomic) NSOperationQueue *coordinatesUploadOperationQueue;
@property (strong, nonatomic) NSOperationQueue *attributeScanQueue;

@end

@implementation AttributeUploadManager

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
        _thumbnailUploadOperationQueue = [[NSOperationQueue alloc] init];
        _thumbnailUploadOperationQueue.qualityOfService = NSQualityOfServiceUserInteractive;
        _thumbnailUploadOperationQueue.maxConcurrentOperationCount = ThumbnailConcurrentUploadCount;
        [_thumbnailUploadOperationQueue addObserver:self forKeyPath:NSStringFromSelector(@selector(operationCount)) options:0 context:NULL];
        
        _previewUploadOperationQueue = [[NSOperationQueue alloc] init];
        _previewUploadOperationQueue.qualityOfService = NSQualityOfServiceBackground;
        
        _coordinatesUploadOperationQueue = [[NSOperationQueue alloc] init];
        _coordinatesUploadOperationQueue.qualityOfService = NSQualityOfServiceUtility;
        _coordinatesUploadOperationQueue.maxConcurrentOperationCount = CoordinatesConcurrentUploadCount;

        _attributeScanQueue = [[NSOperationQueue alloc] init];
        _attributeScanQueue.qualityOfService = NSQualityOfServiceUtility;
        _attributeScanQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}

#pragma mark - thumbnail operation count KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(operationCount))] && object == self.thumbnailUploadOperationQueue) {
        NSInteger previewConcurrentCount;
        NSUInteger thumbnailsCount = self.thumbnailUploadOperationQueue.operationCount;
        if (thumbnailsCount == 0) {
            previewConcurrentCount = PreviewConcurrentUploadCountWhenThumbnailsAreDone;
        } else {
            previewConcurrentCount = PreviewConcurrentUploadCountWhenThumbnailsAreUploading;
        }
        
        if (self.previewUploadOperationQueue.maxConcurrentOperationCount != previewConcurrentCount) {
            self.previewUploadOperationQueue.maxConcurrentOperationCount = previewConcurrentCount;
        }
        
        MEGALogDebug(@"[Camera Upload] thumbnail count %lu, preview count %lu, preview concurrent count %li, coordinates count %lu", (unsigned long)thumbnailsCount, (unsigned long)self.previewUploadOperationQueue.operationCount, previewConcurrentCount, (unsigned long)self.coordinatesUploadOperationQueue.operationCount);
    }
}

#pragma mark - wait until done

- (void)waitUntilAllThumbnailUploadsAreFinished {
    [self.thumbnailUploadOperationQueue waitUntilAllOperationsAreFinished];
}

- (void)waitUntilAllAttributeUploadsAreFinished {
    [self waitUntilAllThumbnailUploadsAreFinished];
    [self.previewUploadOperationQueue waitUntilAllOperationsAreFinished];
    [self.coordinatesUploadOperationQueue waitUntilAllOperationsAreFinished];
}

#pragma mark - upload preview and thumbnail files

- (AssetLocalAttribute *)saveAttributesForUploadInfo:(AssetUploadInfo *)uploadInfo error:(NSError **)error {
    NSURL *attributeDirectoryURL = [self nodeAttributesDirectoryURLByLocalIdentifier:uploadInfo.savedLocalIdentifier];
    [NSFileManager.defaultManager removeItemIfExistsAtURL:attributeDirectoryURL];
    [NSFileManager.defaultManager createDirectoryAtURL:attributeDirectoryURL withIntermediateDirectories:YES attributes:nil error:error];
    if (error != NULL && *error != nil) {
        return nil;
    }
    
    AssetLocalAttribute *attribute = [[AssetLocalAttribute alloc] initWithAttributeDirectoryURL:attributeDirectoryURL];
    [uploadInfo.fingerprint writeToURL:attribute.fingerprintURL atomically:YES encoding:NSUTF8StringEncoding error:error];
    if (error != NULL && *error != nil) {
        return nil;
    }
    
    if (uploadInfo.location) {
        if (![NSKeyedArchiver archiveRootObject:uploadInfo.location toFile:attribute.locationURL.path]) {
            if (error != NULL) {
                *error = [NSError mnz_cameraUploadCanNotArchiveLocationError];
            }
            return nil;
        }
    }

    [NSFileManager.defaultManager copyItemAtURL:uploadInfo.thumbnailURL toURL:attribute.thumbnailURL error:error];
    if (error != NULL && *error != nil) {
        return nil;
    }
    
    [NSFileManager.defaultManager copyItemAtURL:uploadInfo.previewURL toURL:attribute.previewURL error:error];
    if (error != NULL && *error != nil) {
        return nil;
    }
    
    return attribute;
}

- (void)uploadLocalAttribute:(AssetLocalAttribute *)attribute forNode:(MEGANode *)node {
    if (attribute.hasSavedThumbnail) {
        [self.thumbnailUploadOperationQueue addOperation:[[ThumbnailUploadOperation alloc] initWithAttributeURL:attribute.thumbnailURL node:node]];
    } else {
        MEGALogError(@"[Camera Upload] No thumbnail file found for node %@ in %@", node.name, attribute.thumbnailURL);
    }
    
    if (attribute.hasSavedPreview) {
        [self.previewUploadOperationQueue addOperation:[[PreviewUploadOperation alloc] initWithAttributeURL:attribute.previewURL node:node]];
    } else {
        MEGALogError(@"[Camera Upload] No preview file found for node %@ in %@", node.name, attribute.previewURL);
    }
    
    if (attribute.hasSavedLocation) {
        [self.coordinatesUploadOperationQueue addOperation:[[CoordinatesUploadOperation alloc] initWithAttributeURL:attribute.locationURL node:node]];
    }
}

#pragma mark - attributes scan and retry

- (void)scanLocalAttributeFilesAndRetryUploadIfNeeded {
    MEGALogDebug(@"[Camera Upload] scan local attribute files and retry upload");
    if (!(MEGASdkManager.sharedMEGASdk.isLoggedIn && CameraUploadManager.shared.isNodeTreeCurrent)) {
        return;
    }
    
    if (![NSFileManager.defaultManager fileExistsAtPath:[self attributeDirectoryURL].path]) {
        return;
    }
    
    [MEGASdkManager.sharedMEGASdk retryPendingConnections];
    
    [self.attributeScanQueue addOperationWithBlock:^{
        NSError *error;
        NSArray<NSURL *> *attributeDirectoryURLs = [NSFileManager.defaultManager contentsOfDirectoryAtURL:[self attributeDirectoryURL] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
        if (error) {
            MEGALogError(@"[Camera Upload] error when to scan local attributes %@", error);
            return;
        }
        
        for (NSURL *URL in attributeDirectoryURLs) {
            [self scanAttributeDirectoryURL:URL];
        }
    }];
}

- (void)scanAttributeDirectoryURL:(NSURL *)URL {
    AssetLocalAttribute *attribute = [[AssetLocalAttribute alloc] initWithAttributeDirectoryURL:URL];
    MEGANode *node = [MEGASdkManager.sharedMEGASdk nodeForFingerprint:attribute.savedFingerprint];
    if (node == nil) {
        MEGALogDebug(@"[Camera Upload] no node can be created from %@ for %@", attribute.savedFingerprint, URL.lastPathComponent);
        return;
    }
    
    [self retryUploadLocalAttribute:attribute forNode:node];
}

- (void)retryUploadLocalAttribute:(AssetLocalAttribute *)attribute forNode:(MEGANode *)node {
    if (attribute.hasSavedThumbnail) {
        if ([node hasThumbnail]) {
            [attribute.thumbnailURL mnz_cacheThumbnailForNode:node];
        } else if (![self hasPendingThumbnailOperationForNode:node]) {
            MEGALogDebug(@"[Camera Upload] retry thumbnail upload for %@ in %@", node.name, attribute.attributeDirectoryURL.lastPathComponent);
            [self.thumbnailUploadOperationQueue addOperation:[[ThumbnailUploadOperation alloc] initWithAttributeURL:attribute.thumbnailURL node:node]];
        }
    }
    
    if (attribute.hasSavedPreview) {
        if ([node hasPreview]) {
            [attribute.previewURL mnz_cachePreviewForNode:node];
        } else if (![self hasPendingPreviewOperationForNode:node]) {
            MEGALogDebug(@"[Camera Upload] retry preview upload for %@ in %@", node.name, attribute.attributeDirectoryURL.lastPathComponent);
            [self.previewUploadOperationQueue addOperation:[[PreviewUploadOperation alloc] initWithAttributeURL:attribute.previewURL node:node]];
        }
    }
    
    if (attribute.hasSavedLocation) {
        if (node.latitude && node.longitude) {
            [NSFileManager.defaultManager removeItemIfExistsAtURL:attribute.locationURL];
        } else if (![self hasPendingCoordinatesOperationForNode:node]) {
            MEGALogDebug(@"[Camera Upload] retry coordinates upload for %@ in %@", node.name, attribute.attributeDirectoryURL.lastPathComponent);
            [self.coordinatesUploadOperationQueue addOperation:[[CoordinatesUploadOperation alloc] initWithAttributeURL:attribute.locationURL node:node]];
        }
    }
}

#pragma mark - pending operations check

- (BOOL)hasPendingThumbnailOperationForNode:(MEGANode *)node {
    BOOL hasPendingOperation = NO;
    
    for (NSOperation *operation in self.thumbnailUploadOperationQueue.operations) {
        if ([operation isMemberOfClass:[ThumbnailUploadOperation class]]) {
            ThumbnailUploadOperation *thumbnailUploadOperation = (ThumbnailUploadOperation *)operation;
            if (thumbnailUploadOperation.node.handle == node.handle) {
                hasPendingOperation = YES;
                break;
            }
        }
    }
    
    return hasPendingOperation;
}

- (BOOL)hasPendingPreviewOperationForNode:(MEGANode *)node {
    BOOL hasPendingOperation = NO;
    
    for (NSOperation *operation in self.previewUploadOperationQueue.operations) {
        if ([operation isMemberOfClass:[PreviewUploadOperation class]]) {
            PreviewUploadOperation *previewUploadOperation = (PreviewUploadOperation *)operation;
            if (previewUploadOperation.node.handle == node.handle) {
                hasPendingOperation = YES;
                break;
            }
        }
    }
    
    return hasPendingOperation;
}

- (BOOL)hasPendingCoordinatesOperationForNode:(MEGANode *)node {
    BOOL hasPendingOperation = NO;
    
    for (NSOperation *operation in self.coordinatesUploadOperationQueue.operations) {
        if ([operation isMemberOfClass:[CoordinatesUploadOperation class]]) {
            CoordinatesUploadOperation *coordinatesUploadOperation = (CoordinatesUploadOperation *)operation;
            if (coordinatesUploadOperation.node.handle == node.handle) {
                hasPendingOperation = YES;
                break;
            }
        }
    }
    
    return hasPendingOperation;
}

#pragma mark - data collation

- (void)collateLocalAttributes {
    NSArray<NSURL *> *attributeDirectoryURLs = [NSFileManager.defaultManager contentsOfDirectoryAtURL:[self attributeDirectoryURL] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:nil];
    for (NSURL *URL in attributeDirectoryURLs) {
        AssetLocalAttribute *localAttribute = [[AssetLocalAttribute alloc] initWithAttributeDirectoryURL:URL];
        if (!localAttribute.hasSavedAttributes) {
            [NSFileManager.defaultManager removeItemIfExistsAtURL:URL];
        }
    }
}

#pragma mark - Utils

- (NSURL *)attributeDirectoryURL {
    return [NSURL.mnz_cameraUploadURL URLByAppendingPathComponent:@"Attributes" isDirectory:YES];
}

- (NSURL *)nodeAttributesDirectoryURLByLocalIdentifier:(NSString *)identifier {
    return [[self attributeDirectoryURL] URLByAppendingPathComponent:identifier.mnz_stringByRemovingInvalidFileCharacters];
}

@end
