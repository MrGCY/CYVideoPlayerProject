//
//  UIView+VideoCache.h
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/8.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CYVideoPlayerManager.h"

typedef NS_ENUM(NSInteger, CYVideoPlayerVideoViewPlaceStatus) {
    CYVideoPlayerVideoViewPlaceStatusPortrait,//竖屏
    CYVideoPlayerVideoViewPlaceStatusLandscape,//横屏
    CYVideoPlayerVideoViewPlaceStatusAnimating
};
//播放全屏动画完成
typedef void(^CYVideoPlayerScreenAnimationCompletion)(void);



@protocol CYVideoPlayerDelegate <NSObject>

@optional

/**
 * 在没有找到缓存是否下载视频
 */
- (BOOL)shouldDownloadVideoForURL:(nonnull NSURL *)videoURL;

/**
 * 是否自动播放
 */
- (BOOL)shouldAutoReplayAfterPlayCompleteForURL:(nonnull NSURL *)videoURL;

/**
 * 进度条是否显示在顶部
 */
- (BOOL)shouldProgressViewOnTop;

/**
 * 在播放前是否显示黑色背景
 */
- (BOOL)shouldDisplayBlackLayerBeforePlayStart;

/**
 * 播放状态
 */
- (void)playingStatusDidChanged:(CYVideoPlayerPlayingStatus)playingStatus;

/**
 * 下载进度改变
 */
- (void)downloadingProgressDidChanged:(CGFloat)downloadingProgress;

/**
 * 播放进度改变
 */
- (void)playingProgressDidChanged:(CGFloat)playingProgress;

@end



@interface UIView (VideoCache)

@property(nonatomic, nullable)id<CYVideoPlayerDelegate> cy_videoPlayerDelegate;

/**
 * View status.
 */
@property(nonatomic, readonly)CYVideoPlayerVideoViewPlaceStatus viewStatus;

/**
 * Playing status of video player.
 */
@property(nonatomic, readonly)CYVideoPlayerPlayingStatus playingStatus;

#pragma mark - Play Video Methods

/**
 *默认有进度和加载视图
 */
- (void)cy_playVideoWithURL:(nullable NSURL *)url;

/**
 *隐藏进度条视图
 */
- (void)cy_playVideoHiddenStatusViewWithURL:(nullable NSURL *)url;

/**
 *静音播放
 */
- (void)cy_playVideoMutedHiddenStatusViewWithURL:(nullable NSURL *)url;

/**
 *静音播放并切隐藏进度条
 */
- (void)cy_playVideoMutedDisplayStatusViewWithURL:(nullable NSURL *)url;

/**
 *自定义播放模式
 */
- (void)cy_playVideoWithURL:(nullable NSURL *)url
                    options:(CYVideoPlayerOptions)options
                   progress:(nullable CYVideoPlayerDownloaderProgressBlock)progressBlock
                  completed:(nullable CYVideoPlayerCompletionBlock)completedBlock;

#pragma mark - Play Control

/**
 * 停止播放
 */
- (void)cy_stopPlay;

/**
 * 暂停
 */
- (void)cy_pause;

/**
 * 重新
 */
- (void)cy_resume;

/**
 * 设置静音
 */
- (void)cy_setPlayerMute:(BOOL)mute;

/**
 * 获取是不是静音.
 */
- (BOOL)cy_playerIsMute;

#pragma mark - Landscape Or Portrait Control

/**
 *进入横屏
 */
- (void)cy_gotoLandscape;

/**
 * 进入横屏
 */
- (void)cy_gotoLandscapeAnimated:(BOOL)animated completion:(CYVideoPlayerScreenAnimationCompletion _Nullable)completion;

/**
 * 进入全屏
 */
- (void)cy_gotoPortrait;

/**
 * 进入全屏
 */
- (void)cy_gotoPortraitAnimated:(BOOL)animated completion:(CYVideoPlayerScreenAnimationCompletion _Nullable)completion;

@end
