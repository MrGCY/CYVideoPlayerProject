//
//  CYVideoPlayerManager.h
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/6.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import <Foundation/Foundation.h>
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
    CYVideoPlayerLayerVideoGravityResizeAspectFill = 1 << 9,
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
@interface CYVideoPlayerManager : NSObject
/**
 创建播放器管理者单例对象
 */
+(nonnull instancetype)sharedManager;
/**
 获取缓存视频的key

 @param url 缓存视频地址
 @return 返回对应的key
 */
- (nullable NSString *)cacheKeyForURL:(nullable NSURL *)url;
@end
