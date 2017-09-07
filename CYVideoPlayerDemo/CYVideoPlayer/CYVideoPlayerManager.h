//
//  CYVideoPlayerManager.h
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/6.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CYVideoPlayerOperation.h"
#import "CYVideoPlayerCache.h"
#import "CYVideoPlayerDownloader.h"

typedef NS_OPTIONS(NSInteger, CYVideoPlayerOptions) {
    /**
     * 静音播放
     */
    CYVideoPlayerMutedPlay = 1 << 0,
    /**
     * 视频填充拉伸
     */
    CYVideoPlayerLayerVideoGravityResize = 1 << 1,
    /**
     * 视频按比例适配
     */
    CYVideoPlayerLayerVideoGravityResizeAspect = 1 << 2,
    /**
     * 视频按比例填充
     */
    CYVideoPlayerLayerVideoGravityResizeAspectFill = 1 << 3,
    /**
     * 视频重试失败
     */
    CYVideoPlayerRetryFailed = 1 << 4,
    CYVideoPlayerContinueInBackground = 1 << 5,
    /**
     * Handles cookies stored in NSHTTPCookieStore by setting
     * NSMutableURLRequest.HTTPShouldHandleCookies = YES;
     */
    CYVideoPlayerHandleCookies = 1 << 6,
    
    /**
     * Enable to allow untrusted SSL certificates.
     * Useful for testing purposes. Use with caution in production.
     */
    CYVideoPlayerAllowInvalidSSLCertificates = 1 << 7,
    
};
//播放状态的枚举
typedef NS_ENUM(NSInteger, CYVideoPlayerPlayingStatus) {
    CYVideoPlayerPlayingStatusUnkown,//未知
    CYVideoPlayerPlayingStatusBuffering,//正在缓存中
    CYVideoPlayerPlayingStatusPlaying,//正在播放中
    CYVideoPlayerPlayingStatusPause,//暂停
    CYVideoPlayerPlayingStatusFailed,//失败
    CYVideoPlayerPlayingStatusStop//停止
};

/**
 播放进度block
 
 @param progress 返回当前的播放进度
 */
typedef void(^CYVideoPlayerPlayToolPlayingProgressBlock)(CGFloat progress);

//视频缓存完成
typedef void(^CYVideoPlayerCompletionBlock)(NSString * _Nullable fullVideoCachePath, NSError * _Nullable error, CYVideoPlayerCacheType cacheType, NSURL * _Nullable videoURL);

//------------------------视频管理协议--------------
@class CYVideoPlayerManager;

@protocol CYVideoPlayerManagerDelegate <NSObject>

@optional

/**
 *是否需要缓存视频
 */
- (BOOL)videoPlayerManager:(nonnull CYVideoPlayerManager *)videoPlayerManager shouldDownloadVideoForURL:(nullable NSURL *)videoURL;

/**
 * 是否需要自动播放
 */
- (BOOL)videoPlayerManager:(nonnull CYVideoPlayerManager *)videoPlayerManager shouldAutoReplayForURL:(nullable NSURL *)videoURL;

/**
 * 播放状态改变
 */
- (void)videoPlayerManager:(nonnull CYVideoPlayerManager *)videoPlayerManager playingStatusDidChanged:(CYVideoPlayerPlayingStatus)playingStatus;
//是否显示下载进度或者播放进度
/**
 * 下载进度
 */
- (BOOL)videoPlayerManager:(nonnull CYVideoPlayerManager *)videoPlayerManager downloadingProgressDidChanged:(CGFloat)downloadingProgress;

/**
 * 播放进度
 */
- (BOOL)videoPlayerManager:(nonnull CYVideoPlayerManager *)videoPlayerManager playingProgressDidChanged:(CGFloat)playingProgress;

@end


@interface CYVideoPlayerManager : NSObject
@property (weak, nonatomic, nullable) id <CYVideoPlayerManagerDelegate> delegate;

@property (strong, nonatomic, readonly, nullable) CYVideoPlayerCache *videoCache;

@property (strong, nonatomic, readonly, nullable) CYVideoPlayerDownloader *videoDownloader;
/**
 创建播放器管理者单例对象
 */
+(nonnull instancetype)sharedManager;
- (nullable id <CYVideoPlayerOperation>)cy_loadVideoWithURL:(nullable NSURL *)url
                                                 showOnView:(nullable UIView *)showView
                                                    options:(CYVideoPlayerOptions)options
                                            playingProgress:(CYVideoPlayerPlayToolPlayingProgressBlock _Nullable ) playProgress
                                           downloadProgress:(nullable CYVideoPlayerDownloaderProgressBlock)progressBlock
                                                  completed:(nullable CYVideoPlayerCompletionBlock)completedBlock;
/**
 获取缓存视频的key

 @param url 缓存视频地址
 @return 返回对应的key
 */
- (nullable NSString *)cacheKeyForURL:(nullable NSURL *)url;
@end
