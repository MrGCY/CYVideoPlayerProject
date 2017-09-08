//
//  CYVideoPlayerCachePathManager.h
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/7.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import <Foundation/Foundation.h>
extern NSString * _Nonnull const CYVideoPlayerCacheVideoPathForTemporaryFile;
extern NSString * _Nonnull const CYVideoPlayerCacheVideoPathForFullFile;

@interface CYVideoPlayerCachePathManager : NSObject
/**
获取所有临时文件总路径
 */
+(nonnull NSString *)videoCachePathForAllTemporaryFile;

/**
获取所有缓存文件总的全路径
 */
+(nonnull NSString *)videoCachePathForAllFullFile;

/**
通过key找到临时文件路径
 */
+(nonnull NSString *)videoCacheTemporaryPathForKey:( NSString * _Nonnull )key;

/**
通过key找到缓存文件全路径
 */
+(nonnull NSString *)videoCacheFullPathForKey:(NSString * _Nonnull)key;


@end
