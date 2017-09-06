//
//  CYVideoPlayerResourceLoader.h
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/6.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
//视频播放器的数据代理，负责将网络视频数据填充给播放器
//这个AVAssetResourceLoader是负责数据加载的，最最重要的是我们只要遵守了AVAssetResourceLoaderDelegate，就可以成为它的代理，成为它的代理以后，数据加载可能会通过代理方法询问我们。
@interface CYVideoPlayerResourceLoader : NSObject<AVAssetResourceLoaderDelegate>
/**
 *视频缓存一半的处理
 * @param tempCacheVideoPath 视频缓存在磁盘中的地址
 * @param expectedSize       视频数据的总长度
 * @param receivedSize       视频缓存磁盘中的长度
 */
- (void)didReceivedDataCacheInDiskByTempPath:(NSString * _Nonnull)tempCacheVideoPath videoFileExceptSize:(NSUInteger)expectedSize videoFileReceivedSize:(NSUInteger)receivedSize;

/**
 * 视频缓存完成的处理
 * @param fullVideoCachePath 视频缓存在磁盘中的地址
 */
- (void)didCachedVideoDataFinishedFromWebFullVideoCachePath:(NSString * _Nullable)fullVideoCachePath;
@end
