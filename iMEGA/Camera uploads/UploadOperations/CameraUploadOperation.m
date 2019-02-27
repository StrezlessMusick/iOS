
#import "CameraUploadOperation.h"
#import "MEGASdkManager.h"
#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "TransferSessionManager.h"
#import "AssetUploadInfo.h"
#import "CameraUploadRecordManager.h"
#import "CameraUploadManager.h"
#import "CameraUploadRequestDelegate.h"
#import "FileEncrypter.h"
#import "NSURL+CameraUpload.h"
#import "MEGAConstants.h"
#import "PHAsset+CameraUpload.h"
#import "CameraUploadManager+Settings.h"
#import "NSError+CameraUpload.h"
#import "MEGAReachabilityManager.h"
#import "MEGAError+MNZCategory.h"
#import "CameraUploadOperation+Utils.h"
#import "NSDate+MNZCategory.h"
@import Photos;

@interface CameraUploadOperation ()

@property (strong, nonatomic, nullable) MEGASdk *sdk;
@property (strong, nonatomic) FileEncrypter *fileEncrypter;
@property (strong, nonatomic) dispatch_queue_t serialQueue;

@end

@implementation CameraUploadOperation

#pragma mark - initializers

- (instancetype)initWithUploadInfo:(AssetUploadInfo *)uploadInfo uploadRecord:(MOAssetUploadRecord *)uploadRecord {
    self = [super init];
    if (self) {
        _uploadInfo = uploadInfo;
        _uploadRecord = uploadRecord;
        _serialQueue = dispatch_queue_create("nz.mega.cameraUpload.uploadOperation", DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

#pragma mark - properties

- (MEGASdk *)sdk {
    if (_sdk == nil) {
        _sdk = [MEGASdkManager createMEGASdk];
    }
    
    return _sdk;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@ %@", NSStringFromClass(self.class), [self.uploadInfo.asset.creationDate mnz_formattedDefaultNameForMedia], self.uploadInfo.savedLocalIdentifier];
}

#pragma mark - start operation

- (void)start {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        return;
    }
    
    [self startExecuting];

    [self beginBackgroundTaskWithExpirationHandler:^{
        [self cancel];
    }];
    
    MEGALogDebug(@"[Camera Upload] %@ starts processing", self);
    [CameraUploadRecordManager.shared updateUploadRecord:self.uploadRecord withStatus:CameraAssetUploadStatusProcessing error:nil];
    
    self.uploadInfo.directoryURL = [self URLForAssetProcessing];
}

- (void)cancel {
    [super cancel];
    [self cancelPendingTasks];
}

- (void)cancelPendingTasks {
    [self.fileEncrypter cancelEncryption];
}

#pragma mark - data processing

- (NSURL *)URLForAssetProcessing {
    NSURL *directoryURL = [NSURL mnz_assetDirectoryURLForLocalIdentifier:self.uploadInfo.savedLocalIdentifier];
    [NSFileManager.defaultManager removeItemIfExistsAtURL:directoryURL];
    [[NSFileManager defaultManager] createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:nil];
    return directoryURL;
}

- (BOOL)createThumbnailAndPreviewFiles {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        return NO;
    }
    
    BOOL thumbnailCreated = [self.sdk createThumbnail:self.uploadInfo.fileURL.path destinatioPath:self.uploadInfo.thumbnailURL.path];
    if (!thumbnailCreated) {
        MEGALogError(@"[Camera Upload] %@ error when to create thumbnail", self);
    }
    
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        return NO;
    }
    BOOL previewCreated = [self.sdk createPreview:self.uploadInfo.fileURL.path destinatioPath:self.uploadInfo.previewURL.path];
    if (!previewCreated) {
        MEGALogError(@"[Camera Upload] %@ error when to create preview", self);
    }
    
    self.sdk = nil;
    return thumbnailCreated && previewCreated;
}

#pragma mark - upload task

- (void)handleProcessedUploadFile {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        return;
    }
    
    self.uploadInfo.fingerprint = [MEGASdkManager.sharedMEGASdk fingerprintForFilePath:self.uploadInfo.fileURL.path modificationTime:self.uploadInfo.asset.creationDate];
    MEGANode *matchingNode = [MEGASdkManager.sharedMEGASdk nodeForFingerprint:self.uploadInfo.fingerprint parent:self.uploadInfo.parentNode];
    if (matchingNode) {
        MEGALogDebug(@"[Camera Upload] %@ found existing node by file fingerprint", self);
        [self finishUploadForFingerprintMatchedNode:matchingNode];
        return;
    }
    
    if (![self createThumbnailAndPreviewFiles]) {
        [self finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
        return;
    }
    
    self.uploadInfo.mediaUpload = [MEGASdkManager.sharedMEGASdk backgroundMediaUpload];
    [self.uploadInfo.mediaUpload analyseMediaInfoForFileAtPath:self.uploadInfo.fileURL.path];
    
    [self encryptFile];
}

- (void)encryptFile {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        return;
    }
    
    self.fileEncrypter = [[FileEncrypter alloc] initWithMediaUpload:self.uploadInfo.mediaUpload outputDirectoryURL:self.uploadInfo.encryptionDirectoryURL shouldTruncateInputFile:YES];
    [self.fileEncrypter encryptFileAtURL:self.uploadInfo.fileURL completion:^(BOOL success, unsigned long long fileSize, NSDictionary<NSString *,NSURL *> * _Nonnull chunkURLsKeyedByUploadSuffix, NSError * _Nonnull error) {
        if (self.isCancelled) {
            [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
            return;
        }

        if (success) {
            MEGALogDebug(@"[Camera Upload] %@ file %llu encrypted to %lu, %@", self, fileSize, (unsigned long)chunkURLsKeyedByUploadSuffix.count, chunkURLsKeyedByUploadSuffix);
            self.uploadInfo.fileSize = fileSize;
            self.uploadInfo.encryptedChunkURLsKeyedByUploadSuffix = chunkURLsKeyedByUploadSuffix;
            self.uploadInfo.encryptedChunksCount = chunkURLsKeyedByUploadSuffix.count;
            [self requestUploadURL];
        } else {
            MEGALogError(@"[Camera Upload] %@ error when to encrypt file %@", self, error);
            if ([error.domain isEqualToString:CameraUploadErrorDomain] && error.code == CameraUploadErrorNoEnoughDiskFreeSpace) {
                [self finishUploadWithNoEnoughDiskSpace];
            } else if ([error.domain isEqualToString:NSCocoaErrorDomain] && error.code == NSFileWriteOutOfSpaceError) {
                [self finishUploadWithNoEnoughDiskSpace];
            } else if ([error.domain isEqualToString:CameraUploadErrorDomain] && error.code == CameraUploadErrorEncryptionCancelled) {
                [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
            } else {
                [self finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
            }
            return;
        }
    }];
}

- (void)requestUploadURL {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        return;
    }
    
    __weak __typeof__(self) weakSelf = self;
    [MEGASdkManager.sharedMEGASdk requestBackgroundUploadURLWithFileSize:self.uploadInfo.fileSize mediaUpload:self.uploadInfo.mediaUpload delegate:[[CameraUploadRequestDelegate alloc] initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
        if (weakSelf.isCancelled) {
            [weakSelf finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
            return;
        }
        
        if (error.type) {
            MEGALogError(@"[Camera Upload] %@ error when to requests upload url %@", weakSelf, error.nativeError);
            if (error.type == MEGAErrorTypeApiEOverQuota || error.type == MEGAErrorTypeApiEgoingOverquota) {
                [NSNotificationCenter.defaultCenter postNotificationName:MEGAStorageOverQuotaNotificationName object:weakSelf];
                [weakSelf finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
            } else {
                [weakSelf finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
            }
        } else {
            weakSelf.uploadInfo.uploadURLString = [weakSelf.uploadInfo.mediaUpload uploadURLString];
            MEGALogDebug(@"[Camera Upload] %@ upload url %@ for file size %llu", weakSelf, weakSelf.uploadInfo.uploadURLString, weakSelf.uploadInfo.fileSize);
            if ([weakSelf archiveUploadInfoDataForBackgroundTransfer]) {
                [weakSelf uploadEncryptedChunksToServer];
            } else {
                [weakSelf finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
            }
        }
    }]];
}

- (void)uploadEncryptedChunksToServer {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        return;
    }
    
    NSError *error;
    NSArray<NSURLSessionUploadTask *> *uploadTasks = [self createUploadTasksWithError:&error];
    if (error) {
        MEGALogError(@"[Camera Upload] %@ error when to create upload task %@", self, error);
        [self finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
        for (NSURLSessionUploadTask *task in uploadTasks) {
            MEGALogDebug(@"[Camera Upload] %@ cancel upload task %@", self, task.taskDescription);
            [task cancel];
        }
        return;
    }
    
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        for (NSURLSessionUploadTask *task in uploadTasks) {
            MEGALogDebug(@"[Camera Upload] %@ cancel upload task %@", self, task.taskDescription);
            [task cancel];
        }
        return;
    }
    
    for (NSURLSessionUploadTask *task in uploadTasks) {
        [task resume];
    }
    
    [self finishOperationWithStatus:CameraAssetUploadStatusUploading shouldUploadNextAsset:YES];
}

- (NSArray<NSURLSessionUploadTask *> *)createUploadTasksWithError:(NSError **)error {
    NSMutableArray<NSURLSessionUploadTask *> *uploadTasks = [NSMutableArray array];
    
    for (NSString *uploadSuffix in self.uploadInfo.encryptedChunkURLsKeyedByUploadSuffix.allKeys) {
        NSURL *serverURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", self.uploadInfo.uploadURLString, uploadSuffix]];
        NSURL *chunkURL = self.uploadInfo.encryptedChunkURLsKeyedByUploadSuffix[uploadSuffix];
        if ([NSFileManager.defaultManager isReadableFileAtPath:chunkURL.path]) {
            NSURLSessionUploadTask *uploadTask;
            if (self.uploadInfo.asset.mediaType == PHAssetMediaTypeVideo) {
                uploadTask = [TransferSessionManager.shared videoUploadTaskWithURL:serverURL fromFile:chunkURL completion:nil];
            } else {
                uploadTask = [[TransferSessionManager shared] photoUploadTaskWithURL:serverURL fromFile:chunkURL completion:nil];
            }
            uploadTask.taskDescription = self.uploadInfo.savedLocalIdentifier;
            [uploadTasks addObject:uploadTask];
        } else {
            if (error != NULL) {
                *error = [NSError mnz_cameraUploadChunkMissingError];
            }
            break;
        }
    }
    
    return [uploadTasks copy];
}

#pragma mark - archive upload info

- (BOOL)archiveUploadInfoDataForBackgroundTransfer {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        return NO;
    }
    
    NSURL *archivedURL = [NSURL mnz_archivedURLForLocalIdentifier:self.uploadInfo.savedLocalIdentifier];
    return [NSKeyedArchiver archiveRootObject:self.uploadInfo toFile:archivedURL.path];
}

#pragma mark - finish operation

- (void)finishOperationWithStatus:(CameraAssetUploadStatus)status shouldUploadNextAsset:(BOOL)uploadNextAsset {
    dispatch_sync(self.serialQueue, ^{
        if (self.isFinished) {
            return;
        }
        
        [self finishOperation];
        
        if (!CameraUploadManager.isCameraUploadEnabled) {
            return;
        }
        
        MEGALogDebug(@"[Camera Upload] %@ finishes with status: %@", self, [AssetUploadStatus stringForStatus:status]);
        [CameraUploadRecordManager.shared updateUploadRecord:self.uploadRecord withStatus:status error:nil];
        
        if (status != CameraAssetUploadStatusUploading) {
            [NSFileManager.defaultManager removeItemIfExistsAtURL:self.uploadInfo.directoryURL];
        }
        
        if (status == CameraAssetUploadStatusDone) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [NSNotificationCenter.defaultCenter postNotificationName:MEGACameraUploadAssetUploadDoneNotificationName object:nil];
            });
        }
        
        if (uploadNextAsset) {
            [CameraUploadManager.shared uploadNextAssetForMediaType:self.uploadInfo.asset.mediaType];
        }
    });
}

@end
