//
//  CYVideoPlayerTool.h
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/6.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import <Foundation/Foundation.h>
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

/**
 错误的block

 @param error 返回错误信息
 */
typedef void(^CYVideoPlayerPlayToolErrorBlock)(NSError * _Nullable error);

/**
 播放进度block

 @param progress 返回当前的播放进度
 */
typedef void(^CYVideoPlayerPlayToolPlayingProgressBlock)(CGFloat progress);

//视频工具类
@interface CYVideoPlayerTool : NSObject
/**
 创建播放器工具的单例对象
 */
+(nonnull instancetype)shareTool;
@end
