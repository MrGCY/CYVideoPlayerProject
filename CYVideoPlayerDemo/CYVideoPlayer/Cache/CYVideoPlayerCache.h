//
//  CYVideoPlayerCache.h
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/7.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import <Foundation/Foundation.h>
/**
 缓存类型
 */
typedef NS_ENUM(NSInteger, CYVideoPlayerCacheType) {
    
    /**
     * 不进行缓存
     */
    CYVideoPlayerCacheTypeNone,
    
    /**
     * 缓存到硬盘 沙盒/Library/Caches
     */
    CYVideoPlayerCacheTypeDisk,
    
    /**
     * 缓存到本地沙盒文件
     */
    CYVideoPlayerCacheTypeLocation
};


@interface CYVideoPlayerCacheToken : NSObject

@end






@class CYVideoPlayerCacheConfig;
//缓存队列完成回掉
typedef void(^CYVideoPlayerCacheQueryCompletedBlock)(NSString * _Nullable videoPath, CYVideoPlayerCacheType cacheType);
//没有参数回调
typedef void(^CYVideoPlayerNoParamsBlock)();
//检测缓存存在
typedef void(^CYVideoPlayerCheckCacheCompletionBlock)(BOOL isInDiskCache);
//计算缓存大小
typedef void(^CYVideoPlayerCalculateSizeBlock)(NSUInteger fileCount, NSUInteger totalSize);
//存储数据完成
typedef void(^CYVideoPlayerStoreDataFinishedBlock)(NSUInteger storedSize, NSError * _Nullable error, NSString * _Nullable fullVideoCachePath);
@interface CYVideoPlayerCache : NSObject
+(nonnull instancetype)sharedCache;
//视频缓存配置
@property (nonatomic, nonnull, readonly)CYVideoPlayerCacheConfig *config;

/**
 * 往指定的key存储数据
 */
- (nullable CYVideoPlayerCacheToken *)storeVideoData:(nullable NSData *)videoData expectedSize:(NSUInteger)expectedSize forKey:(nullable NSString *)key completion:(nullable CYVideoPlayerStoreDataFinishedBlock)completionBlock;

/**
 * 取消缓存任务
 */
- (void)cancel:(nullable CYVideoPlayerCacheToken *)token;

/**
 * This method is be used to cancel current completion block when cache a peice of video data finished.
 */
- (void)cancelCurrentComletionBlock;


# pragma - Query and Retrieve Options
/**
 * 磁盘中存在对应key的文件并进行缓存操作
 */
- (void)diskVideoExistsWithKey:(nullable NSString *)key completion:(nullable CYVideoPlayerCheckCacheCompletionBlock)completionBlock;

/**
 * Operation that queries the cache asynchronously and call the completion when done.
 *
 * @param key       The unique key used to store the wanted video.
 * @param doneBlock The completion block. Will not get called if the operation is cancelled.
 *
 * @return a NSOperation instance containing the cache options.
 */
- (nullable NSOperation *)queryCacheOperationForKey:(nullable NSString *)key done:(nullable CYVideoPlayerCacheQueryCompletedBlock)doneBlock;

/**
 * 磁盘中是都存在该路径的文件
 */
- (BOOL)diskVideoExistsWithPath:(NSString * _Nullable)fullVideoCachePath;


# pragma - Clear Cache Events

/**
 * 删除给定key的缓存文件
 */
- (void)removeFullCacheForKey:(nullable NSString *)key withCompletion:(nullable CYVideoPlayerNoParamsBlock)completion;

/**
 * 删除给定key的临时文件
 */
- (void)removeTempCacheForKey:(NSString * _Nonnull)key withCompletion:(nullable CYVideoPlayerNoParamsBlock)completion;

/**
 * 删除一些旧文件
 */
- (void)deleteOldFilesWithCompletionBlock:(nullable CYVideoPlayerNoParamsBlock)completionBlock;

/**
 * 删除所有临时文件
 */
- (void)deleteAllTempCacheOnCompletion:(nullable CYVideoPlayerNoParamsBlock)completion;

/**
 * 清空磁盘
 */
- (void)clearDiskOnCompletion:(nullable CYVideoPlayerNoParamsBlock)completion;


# pragma mark - Cache Info
//判断文件大小能否存下
- (BOOL)haveFreeSizeToCacheFileWithSize:(NSUInteger)fileSize;
/**
 * 获取磁盘剩余空间
 */
- (unsigned long long)getDiskFreeSize;

/**
 * 获取缓存的大小
 */
- (unsigned long long)getSize;

/**
 * 获取磁盘文件的数量
 */
- (NSUInteger)getDiskCount;

/**
 * Calculate the disk cache's size, asynchronously .
 */
- (void)calculateSizeWithCompletionBlock:(nullable CYVideoPlayerCalculateSizeBlock)completionBlock;

/**
 通过key获取缓存文件名

 @param key key
 @return 文件名
 */
- (nullable NSString *)cacheFileNameForKey:(nullable NSString *)key;


@end
