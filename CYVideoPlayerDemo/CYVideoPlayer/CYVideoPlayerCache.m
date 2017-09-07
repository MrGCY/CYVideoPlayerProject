//
//  CYVideoPlayerCache.m
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/7.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import "CYVideoPlayerCache.h"
#import "NSURL+StripQuery.h"
#import "CYVideoPlayerCacheConfig.h"
#import "CYVideoPlayerCachePathManager.h"
#import "CYVideoPlayerDownloaderOperation.h"
#import "CYVideoPlayerMacros.h"
#import "CYVideoPlayerManager.h"

#include <sys/param.h>
#include <sys/mount.h>
#import <CommonCrypto/CommonDigest.h>


@interface CYVideoPlayerCacheToken()

/**
 * 输出的流
 */
@property(nonnull, nonatomic, strong)NSOutputStream *outputStream;

/**
 * 缓存的视频大小
 */
@property(nonatomic, assign)NSUInteger receivedVideoSize;

/**
 * 缓存的key
 */
@property(nonnull, nonatomic, strong)NSString *key;

@end

@implementation CYVideoPlayerCacheToken

@end





@interface CYVideoPlayerCache()
{
    NSFileManager *_fileManager;
}
//创建队列
@property (nonatomic, strong, nonnull) dispatch_queue_t ioQueue;
/**
* 输出流的数组.
*/
@property(nonatomic, strong, nonnull)NSMutableArray<CYVideoPlayerCacheToken *> *outputStreams;

/**
 * 是否完成
 */
@property(nonatomic, assign, getter=isCompletionBlockEnable)BOOL completionBlockEnable;
@end
@implementation CYVideoPlayerCache
+(nonnull instancetype)sharedCache{
    static dispatch_once_t onceToken;
    static id instance;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}
-(instancetype)init{
    if (self = [super init]) {
        // Create IO serial queue
        _ioQueue = dispatch_queue_create("com.NewPan.JPVideoPlayerCache", DISPATCH_QUEUE_SERIAL);
        
        _config = [[CYVideoPlayerCacheConfig alloc] init];
        _fileManager = [NSFileManager defaultManager];
        _outputStreams = [NSMutableArray array];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadVideoDidStart:) name:CYVideoPlayerDownloadStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(deleteOldFiles)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(backgroundDeleteOldFiles)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];

    }
    return self;
}
#pragma mark - Store Video Options

- (void)downloadVideoDidStart:(NSNotification *)notification{
    //开始下载任务 前 移除改缓存中的所有东西
    CYVideoPlayerDownloaderOperation *operation = notification.object;
    NSURL *url = operation.request.URL;
    NSString *key = [[CYVideoPlayerManager sharedManager] cacheKeyForURL:url];
    [self removeTempCacheForKey:key withCompletion:nil];
    
    @autoreleasepool {
        [self.outputStreams removeAllObjects];
    }
}
//存储视频数据
- (nullable CYVideoPlayerCacheToken *)storeVideoData:(nullable NSData *)videoData expectedSize:(NSUInteger)expectedSize forKey:(nullable NSString *)key completion:(nullable CYVideoPlayerStoreDataFinishedBlock)completionBlock{
    
    if (videoData.length==0) return nil;
    
    if (key.length==0) {
        if (completionBlock)
            completionBlock(0, [NSError errorWithDomain:@"Need a key for storing video data" code:0 userInfo:nil], nil);
        return nil;
    }
    
    // Check the free size of the device.
    if (![self haveFreeSizeToCacheFileWithSize:expectedSize]) {
        if (completionBlock)
            completionBlock(0, [NSError errorWithDomain:@"No enough size of device to cache the video data" code:0 userInfo:nil], nil);
        return nil;
    }
    
    @synchronized (self) {
        self.completionBlockEnable = YES;
        CYVideoPlayerCacheToken *targetToken = nil;
        for (CYVideoPlayerCacheToken *token in self.outputStreams) {
            if ([token.key isEqualToString:key]) {
                //获取当前缓存的任务
                targetToken = token;
                break;
            }
        }
        if (!targetToken) {
            //缓存任务不存在 进行创建
            NSString *path = [CYVideoPlayerCachePathManager videoCacheTemporaryPathForKey:key];
            NSOutputStream *stream = [[NSOutputStream alloc]initToFileAtPath:path append:YES];
            [stream open];
            CYVideoPlayerCacheToken *token = [CYVideoPlayerCacheToken new];
            token.key = key;
            token.outputStream = stream;
            [self.outputStreams addObject:token];
            targetToken = token;
        }
        
        if (videoData.length>0) {
            dispatch_async(self.ioQueue, ^{
                [targetToken.outputStream write:videoData.bytes maxLength:videoData.length];
                targetToken.receivedVideoSize += videoData.length;
                
                NSString *tempVideoCachePath = [CYVideoPlayerCachePathManager videoCacheTemporaryPathForKey:key];
                
                // transform to NSUrl
                NSURL *fileURL = [NSURL fileURLWithPath:tempVideoCachePath];
                
                // disable iCloud backup
                if (self.config.shouldDisableiCloud) {
                    [fileURL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
                }
                
                if (completionBlock) {
                    NSString *fullVideoCachePath = nil;
                    NSError *error = nil;
                    if (targetToken.receivedVideoSize==expectedSize) {
                        //缓存数据完成 接受大小和总大小一样 移动临时文件到缓存文件中去
                        fullVideoCachePath = [CYVideoPlayerCachePathManager videoCacheFullPathForKey:key];
                        //移除临时文件到缓存文件中
                        [_fileManager moveItemAtPath:tempVideoCachePath toPath:fullVideoCachePath error:&error];
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (self.completionBlockEnable) {
                            completionBlock(targetToken.receivedVideoSize, error, fullVideoCachePath);
                        }
                    });
                }
                
                // cache temporary video data finished.
                // close the stream.
                // remove the cache operation.
                if (targetToken.receivedVideoSize==expectedSize) {
                    //视频缓存完成 移除改目标任务
                    [targetToken.outputStream close];
                    [self.outputStreams removeObject:targetToken];
                    self.completionBlockEnable = NO;
                }
            });
        }
        return targetToken;
    }
}

- (void)cancel:(nullable CYVideoPlayerCacheToken *)token{
    if (token) {
        [self.outputStreams removeObject:token];
        [self cancelCurrentComletionBlock];
    }
}

- (void)cancelCurrentComletionBlock{
    self.completionBlockEnable = NO;
}
//------------------通过key去查找对应的下载任务operation
- (nullable NSOperation *)queryCacheOperationForKey:(nullable NSString *)key done:(nullable CYVideoPlayerCacheQueryCompletedBlock)doneBlock {
    if (!key) {
        if (doneBlock) {
            doneBlock(nil, CYVideoPlayerCacheTypeNone);
        }
        return nil;
    }
    
    NSOperation *operation = [NSOperation new];
    dispatch_async(self.ioQueue, ^{
        if (operation.isCancelled) {
            // do not call the completion if cancelled
            return;
        }
        
        @autoreleasepool {
            BOOL exists = [_fileManager fileExistsAtPath:[CYVideoPlayerCachePathManager videoCacheFullPathForKey:key]];
            
            if (!exists) {
                exists = [_fileManager fileExistsAtPath:[CYVideoPlayerCachePathManager videoCacheFullPathForKey:key].stringByDeletingPathExtension];
            }
            
            if (exists) {
                if (doneBlock) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        doneBlock([CYVideoPlayerCachePathManager videoCacheFullPathForKey:key], CYVideoPlayerCacheTypeDisk);
                    });
                }
            }
            else{
                if (doneBlock) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        doneBlock(nil, CYVideoPlayerCacheTypeNone);
                    });
                }
            }
        }
    });
    
    return operation;
}
- (void)diskVideoExistsWithKey:(NSString *)key completion:(CYVideoPlayerCheckCacheCompletionBlock)completionBlock{
    dispatch_async(_ioQueue, ^{
        BOOL exists = [_fileManager fileExistsAtPath:[CYVideoPlayerCachePathManager videoCacheFullPathForKey:key]];
        
        if (!exists) {
            exists = [_fileManager fileExistsAtPath:[CYVideoPlayerCachePathManager videoCacheFullPathForKey:key].stringByDeletingPathExtension];
        }
        
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(exists);
            });
        }
    });
}

- (BOOL)diskVideoExistsWithPath:(NSString * _Nullable)fullVideoCachePath{
    return [_fileManager fileExistsAtPath:fullVideoCachePath];
}
#pragma mark - Clear Cache Events

- (void)removeFullCacheForKey:(nullable NSString *)key withCompletion:(nullable CYVideoPlayerNoParamsBlock)completion{
    dispatch_async(self.ioQueue, ^{
        if ([_fileManager fileExistsAtPath:[CYVideoPlayerCachePathManager videoCacheFullPathForKey:key]]) {
            [_fileManager removeItemAtPath:[CYVideoPlayerCachePathManager videoCacheFullPathForKey:key] error:nil];
            dispatch_main_async_safe(^{
                if (completion) {
                    completion();
                }
            });
        }
    });
}

- (void)removeTempCacheForKey:(NSString * _Nonnull)key withCompletion:(nullable CYVideoPlayerNoParamsBlock)completion{
    dispatch_async(self.ioQueue, ^{
        NSString *path = [CYVideoPlayerCachePathManager videoCachePathForAllTemporaryFile];
        path = [path stringByAppendingPathComponent:[[CYVideoPlayerCache sharedCache] cacheFileNameForKey:key]];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:path]) {
            [fileManager removeItemAtPath:path error:nil];
            dispatch_main_async_safe(^{
                if (completion) {
                    completion();
                }
            });
        }
    });
}

- (void)deleteOldFilesWithCompletionBlock:(nullable CYVideoPlayerNoParamsBlock)completionBlock{
    dispatch_async(self.ioQueue, ^{
        NSURL *diskCacheURL = [NSURL fileURLWithPath:[CYVideoPlayerCachePathManager videoCachePathForAllFullFile] isDirectory:YES];
        NSArray<NSString *> *resourceKeys = @[NSURLIsDirectoryKey, NSURLContentModificationDateKey, NSURLTotalFileAllocatedSizeKey];
        
        // This enumerator prefetches useful properties for our cache files.
        NSDirectoryEnumerator *fileEnumerator = [_fileManager enumeratorAtURL:diskCacheURL
                                                   includingPropertiesForKeys:resourceKeys
                                                                      options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                 errorHandler:NULL];
        
        NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:-self.config.maxCacheAge];
        NSMutableDictionary<NSURL *, NSDictionary<NSString *, id> *> *cacheFiles = [NSMutableDictionary dictionary];
        NSUInteger currentCacheSize = 0;
        
        // Enumerate all of the files in the cache directory.  This loop has two purposes:
        //
        //  1. Removing files that are older than the expiration date.
        //  2. Storing file attributes for the size-based cleanup pass.
        NSMutableArray<NSURL *> *urlsToDelete = [[NSMutableArray alloc] init];
        
        @autoreleasepool {
            for (NSURL *fileURL in fileEnumerator) {
                NSError *error;
                NSDictionary<NSString *, id> *resourceValues = [fileURL resourceValuesForKeys:resourceKeys error:&error];
                
                // Skip directories and errors.
                if (error || !resourceValues || [resourceValues[NSURLIsDirectoryKey] boolValue]) {
                    continue;
                }
                
                // Remove files that are older than the expiration date;
                NSDate *modificationDate = resourceValues[NSURLContentModificationDateKey];
                if ([[modificationDate laterDate:expirationDate] isEqualToDate:expirationDate]) {
                    [urlsToDelete addObject:fileURL];
                    continue;
                }
                
                // Store a reference to this file and account for its total size.
                NSNumber *totalAllocatedSize = resourceValues[NSURLTotalFileAllocatedSizeKey];
                currentCacheSize += totalAllocatedSize.unsignedIntegerValue;
                cacheFiles[fileURL] = resourceValues;
            }
        }
        
        for (NSURL *fileURL in urlsToDelete) {
            [_fileManager removeItemAtURL:fileURL error:nil];
        }
        
        // If our remaining disk cache exceeds a configured maximum size, perform a second
        // size-based cleanup pass.  We delete the oldest files first.
        if (self.config.maxCacheSize > 0 && currentCacheSize > self.config.maxCacheSize) {
            // Target half of our maximum cache size for this cleanup pass.
            const NSUInteger desiredCacheSize = self.config.maxCacheSize / 2;
            
            // Sort the remaining cache files by their last modification time (oldest first).
            NSArray<NSURL *> *sortedFiles = [cacheFiles keysSortedByValueWithOptions:NSSortConcurrent
                                                                     usingComparator:^NSComparisonResult(id obj1, id obj2) {
                                                                         return [obj1[NSURLContentModificationDateKey] compare:obj2[NSURLContentModificationDateKey]];
                                                                     }];
            
            // Delete files until we fall below our desired cache size.
            for (NSURL *fileURL in sortedFiles) {
                if ([_fileManager removeItemAtURL:fileURL error:nil]) {
                    NSDictionary<NSString *, id> *resourceValues = cacheFiles[fileURL];
                    NSNumber *totalAllocatedSize = resourceValues[NSURLTotalFileAllocatedSizeKey];
                    currentCacheSize -= totalAllocatedSize.unsignedIntegerValue;
                    
                    if (currentCacheSize < desiredCacheSize) {
                        break;
                    }
                }
            }
        }
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock();
            });
        }
    });
}

- (void)deleteAllTempCacheOnCompletion:(nullable CYVideoPlayerNoParamsBlock)completion{
    dispatch_async(self.ioQueue, ^{
        [_fileManager removeItemAtPath:[CYVideoPlayerCachePathManager videoCachePathForAllTemporaryFile] error:nil];
        dispatch_main_async_safe(^{
            if (completion) {
                completion();
            }
        });
    });
}

- (void)clearDiskOnCompletion:(nullable CYVideoPlayerNoParamsBlock)completion{
    dispatch_async(self.ioQueue, ^{
        [_fileManager removeItemAtPath:[CYVideoPlayerCachePathManager videoCachePathForAllFullFile] error:nil];
        [_fileManager removeItemAtPath:[CYVideoPlayerCachePathManager videoCachePathForAllTemporaryFile] error:nil];
        dispatch_main_async_safe(^{
            if (completion) {
                completion();
            }
        });
    });
}

#pragma mark - ----------------File Name
// 通过key获取缓存文件名
- (nullable NSString *)cacheFileNameForKey:(nullable NSString *)key{
    return [self cachedFileNameForKey:key];
}
//对key进行MD5加密
- (nullable NSString *)cachedFileNameForKey:(nullable NSString *)key {
    if ([key length]) {
        NSString *strippedQueryKey = [[NSURL URLWithString:key] absoluteStringByStrippingQuery];
        key = [strippedQueryKey length] ? strippedQueryKey : key;
    }
    
    const char *str = key.UTF8String;
    if (str == NULL) str = "";
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *pathExtension = key.pathExtension.length > 0 ? [NSString stringWithFormat:@".%@", key.pathExtension] : @".mp4";
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%@",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10],
                          r[11], r[12], r[13], r[14], r[15], pathExtension];
    return filename;
}
#pragma mark - Cache Info  缓存信息处理
//判断文件大小能否存下
- (BOOL)haveFreeSizeToCacheFileWithSize:(NSUInteger)fileSize{
    unsigned long long freeSizeOfDevice = [self getDiskFreeSize];
    if (fileSize > freeSizeOfDevice) {
        return NO;
    }
    return YES;
}

- (unsigned long long)getSize{
    __block unsigned long long size = 0;
    dispatch_sync(self.ioQueue, ^{
        NSString *tempFilePath = [CYVideoPlayerCachePathManager videoCachePathForAllTemporaryFile];
        NSString *fullFilePath = [CYVideoPlayerCachePathManager videoCachePathForAllFullFile];
        
        NSDirectoryEnumerator *fileEnumerator_temp = [_fileManager enumeratorAtPath:tempFilePath];
        
        @autoreleasepool {
            for (NSString *fileName in fileEnumerator_temp) {
                NSString *filePath = [tempFilePath stringByAppendingPathComponent:fileName];
                NSDictionary<NSString *, id> *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
                size += [attrs fileSize];
            }
            
            NSDirectoryEnumerator *fileEnumerator_full = [_fileManager enumeratorAtPath:fullFilePath];
            for (NSString *fileName in fileEnumerator_full) {
                NSString *filePath = [fullFilePath stringByAppendingPathComponent:fileName];
                NSDictionary<NSString *, id> *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
                size += [attrs fileSize];
            }
        }
    });
    return size;
}

- (NSUInteger)getDiskCount{
    __block NSUInteger count = 0;
    dispatch_sync(self.ioQueue, ^{
        NSString *tempFilePath = [CYVideoPlayerCachePathManager videoCachePathForAllTemporaryFile];
        NSString *fullFilePath = [CYVideoPlayerCachePathManager videoCachePathForAllFullFile];
        
        NSDirectoryEnumerator *fileEnumerator_temp = [_fileManager enumeratorAtPath:tempFilePath];
        count += fileEnumerator_temp.allObjects.count;
        
        NSDirectoryEnumerator *fileEnumerator_full = [_fileManager enumeratorAtPath:fullFilePath];
        count += fileEnumerator_full.allObjects.count;
    });
    return count;
}

- (void)calculateSizeWithCompletionBlock:(CYVideoPlayerCalculateSizeBlock )completionBlock{
    
    NSString *tempFilePath = [CYVideoPlayerCachePathManager videoCachePathForAllTemporaryFile];
    NSString *fullFilePath = [CYVideoPlayerCachePathManager videoCachePathForAllFullFile];
    
    NSURL *diskCacheURL_temp = [NSURL fileURLWithPath:tempFilePath isDirectory:YES];
    NSURL *diskCacheURL_full = [NSURL fileURLWithPath:fullFilePath isDirectory:YES];
    
    dispatch_async(self.ioQueue, ^{
        NSUInteger fileCount = 0;
        NSUInteger totalSize = 0;
        
        NSDirectoryEnumerator *fileEnumerator_temp = [_fileManager enumeratorAtURL:diskCacheURL_temp includingPropertiesForKeys:@[NSFileSize] options:NSDirectoryEnumerationSkipsHiddenFiles errorHandler:NULL];
        for (NSURL *fileURL in fileEnumerator_temp) {
            NSNumber *fileSize;
            [fileURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:NULL];
            totalSize += fileSize.unsignedIntegerValue;
            fileCount += 1;
        }
        
        NSDirectoryEnumerator *fileEnumerator_full = [_fileManager enumeratorAtURL:diskCacheURL_full includingPropertiesForKeys:@[NSFileSize] options:NSDirectoryEnumerationSkipsHiddenFiles errorHandler:NULL];
        for (NSURL *fileURL in fileEnumerator_full) {
            NSNumber *fileSize;
            [fileURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:NULL];
            totalSize += fileSize.unsignedIntegerValue;
            fileCount += 1;
        }
        
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(fileCount, totalSize);
            });
        }
    });
}

- (unsigned long long)getDiskFreeSize{
    struct statfs buf;
    unsigned long long freespace = -1;
    if(statfs("/var", &buf) >= 0){
        freespace = (long long)(buf.f_bsize * buf.f_bfree);
    }
    return freespace;
}

#pragma mark - Private
//监听通知方法
- (void)deleteOldFiles {
    [self deleteOldFilesWithCompletionBlock:nil];
    [self deleteAllTempCacheOnCompletion:nil];
}

- (void)backgroundDeleteOldFiles {
    Class UIApplicationClass = NSClassFromString(@"UIApplication");
    if(!UIApplicationClass || ![UIApplicationClass respondsToSelector:@selector(sharedApplication)]) {
        return;
    }
    UIApplication *application = [UIApplication performSelector:@selector(sharedApplication)];
    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        // Clean up any unfinished task business by marking where you
        // stopped or ending the task outright.
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    
    // Start the long-running task and return immediately.
    [self deleteOldFilesWithCompletionBlock:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
}
@end
