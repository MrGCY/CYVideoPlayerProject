//
//  CYVideoPlayerTool.h
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/6.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CYVideoPlayerManager.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
//视频资源管理类
@interface CYVideoPlayerToolItem : NSObject
/**
 * 当前正在播放视频的的key
 */
@property(nonatomic, strong, readonly, nonnull)NSString *playingKey;

/**
 * 当前正在播放视频的layer
 */
@property(nonatomic, strong, readonly, nullable)AVPlayerLayer *currentPlayerLayer;

@end



@class CYVideoPlayerTool;
//协议代理
@protocol CYVideoPlayerToolDelegate <NSObject>

@optional

/**
 是否重复播放视频
 */
- (BOOL)playVideoTool:(nonnull CYVideoPlayerTool *)videoTool shouldAutoReplayVideoForURL:(nonnull NSURL *)videoURL;

/**
视频播放的状态
 */
- (void)playVideoTool:(nonnull CYVideoPlayerTool *)videoTool playingStatuDidChanged:(CYVideoPlayerPlayingStatus)playingStatus;

@end



/**
 错误的block

 @param error 返回错误信息
 */
typedef void(^CYVideoPlayerPlayToolErrorBlock)(NSError * _Nullable error);


//视频工具类
@interface CYVideoPlayerTool : NSObject

/**
 * 当前播放的资源
 */
@property(nonatomic, strong, readonly, nullable)CYVideoPlayerToolItem * currentPlayVideoItem;

/**
 代理对象
 */
@property(nullable, nonatomic, weak)id<CYVideoPlayerToolDelegate> delegate;

/**
 创建播放器工具的单例对象
 */
+(nonnull instancetype)sharedTool;

/**
 加载本地视频资源

 @param url 视频地址
 @param fullVideoCachePath 视频已缓存的路径
 @param options 视频的一些操作行为
 @param showView 视频显示的视图
 @param progress 视频播放的进度
 @param error 错误信息
 @return 当前视频的资源信息
 */
- (nullable CYVideoPlayerToolItem *)playExistedVideoWithURL:(NSURL * _Nullable)url
                                         fullVideoCachePath:(NSString * _Nullable)fullVideoCachePath
                                                    options:(CYVideoPlayerOptions)options showOnView:(UIView * _Nullable)showView
                                            playingProgress:(CYVideoPlayerPlayToolPlayingProgressBlock _Nullable ) progress
                                                      error:(nullable CYVideoPlayerPlayToolErrorBlock)error;

/**
 播放在线视频 流媒体之类的

 @param url 视频地址
 @param tempVideoCachePath 视频缓存的路径
 @param options 视频的一些操作行为
 @param exceptSize 视频总大小
 @param receivedSize 视频缓存的大小
 @param showView 视频显示的视图
 @param progress 视频播放的进度
 @param error 错误信息
 @return 当前视频的资源信息
 */
- (nullable CYVideoPlayerToolItem *)playOnlineVideoWithURL:(NSURL * _Nullable)url
                                        tempVideoCachePath:(NSString * _Nullable)tempVideoCachePath
                                                   options:(CYVideoPlayerOptions)options
                                       videoFileExceptSize:(NSUInteger)exceptSize
                                     videoFileReceivedSize:(NSUInteger)receivedSize
                                                showOnView:(UIView * _Nullable)showView
                                           playingProgress:(CYVideoPlayerPlayToolPlayingProgressBlock _Nullable )progress
                                                     error:(nullable CYVideoPlayerPlayToolErrorBlock)error;
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
- (void)stopPlay;
- (void)pause;
- (void)resume;
- (void)setMute:(BOOL)mute;
@end
