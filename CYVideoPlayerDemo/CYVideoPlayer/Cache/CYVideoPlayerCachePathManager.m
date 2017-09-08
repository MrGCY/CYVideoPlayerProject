//
//  CYVideoPlayerCachePathManager.m
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/7.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import "CYVideoPlayerCachePathManager.h"
#import "CYVideoPlayerCache.h"

NSString * const CYVideoPlayerCacheVideoPathForTemporaryFile = @"/TemporaryFile";
NSString * const CYVideoPlayerCacheVideoPathForFullFile = @"/FullFile";
@implementation CYVideoPlayerCachePathManager
+(nonnull NSString *)videoCachePathForAllTemporaryFile{
    return [self getFilePathWithAppendingString:CYVideoPlayerCacheVideoPathForTemporaryFile];
}

+(nonnull NSString *)videoCachePathForAllFullFile{
    return [self getFilePathWithAppendingString:CYVideoPlayerCacheVideoPathForFullFile];
}

+(nonnull NSString *)videoCacheTemporaryPathForKey:(NSString * _Nonnull)key{
    NSString *path = [self videoCachePathForAllTemporaryFile];
    if (path.length!=0) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        path = [path stringByAppendingPathComponent:[[CYVideoPlayerCache sharedCache] cacheFileNameForKey:key]];
        if (![fileManager fileExistsAtPath:path]) {
            [fileManager createFileAtPath:path contents:nil attributes:nil];
        }
    }
    return path;
}
+(nonnull NSString *)videoCacheFullPathForKey:(NSString * _Nonnull)key{
    NSString *path = [self videoCachePathForAllFullFile];
    path = [path stringByAppendingPathComponent:[[CYVideoPlayerCache sharedCache] cacheFileNameForKey:key]];
    return path;
}
#pragma mark - Private
//创建路径
+(nonnull NSString *)getFilePathWithAppendingString:(nonnull NSString *)apdStr{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingString:apdStr];
    if (![fileManager fileExistsAtPath:path])
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    
    return path;
}
@end
