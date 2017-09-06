//
//  CYVideoPlayerTool.m
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/6.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import "CYVideoPlayerTool.h"
#import "CYVideoPlayerManager.h"
#import "CYVideoPlayerResourceLoader.h"
@interface CYVideoPlayerToolItem()
/**
 * 视频播放的 URL
 */
@property(nonatomic, strong, nullable)NSURL *url;

/**
 * 播放视频的播放器.
 */
@property(nonatomic, strong, nullable)AVPlayer *player;

/**
 * 当前播放视频的 layer.
 */
@property(nonatomic, strong, nullable)AVPlayerLayer *currentPlayerLayer;

/**
 * 当前播放视频的 item资源
 */
@property(nonatomic, strong, nullable)AVPlayerItem *currentPlayerItem;

/**
 * 播放视频的 urlAsset.
 */
@property(nonatomic, strong, nullable)AVURLAsset *videoURLAsset;

/**
 * 视频展示的视图.
 */
@property(nonatomic, strong, nullable)UIView * unownShowView;

/**
 * 是否取消播放的标志位
 */
@property(nonatomic, assign, getter=isCancelled)BOOL cancelled;

/**
 * Error message.
 */
@property(nonatomic, copy, nullable)CYVideoPlayerPlayToolErrorBlock error;

/**
 * 视频资源缓存处理对象
 */
@property(nonatomic, strong, nullable)CYVideoPlayerResourceLoader * resourceLoader;

/**
 * 选择模式
 */
@property(nonatomic, assign)CYVideoPlayerOptions playerOptions;

/**
 * 当前正在播放视频地址的key
 */
@property(nonatomic, strong, nonnull)NSString *playingKey;

/**
 * The last play time for player.
 */
@property(nonatomic, assign)NSTimeInterval lastTime;

/**
 * The play progress observer.
 */
@property(nonatomic, strong)id timeObserver;
@end

@implementation CYVideoPlayerToolItem


@end


@implementation CYVideoPlayerTool
+(nonnull instancetype)shareTool{
    static dispatch_once_t onceToken;
    static id instance;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}
-(instancetype)init{
    if (self = [super init]) {
        
    }
    return self;
}

@end
