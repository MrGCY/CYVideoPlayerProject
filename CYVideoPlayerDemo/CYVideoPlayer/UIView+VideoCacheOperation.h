//
//  UIView+VideoCacheOperation.h
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/8.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (VideoCacheOperation)
/**
 * 获取当前播放的Url
 */
@property(nonatomic, nullable)NSURL *currentPlayingURL;

/**
 * 设置对应视频下载操作
 */
- (void)cy_setVideoLoadOperation:(nullable id)operation forKey:(nullable NSString *)key;

/**
 *  对应视频下载操作
 */
- (void)cy_cancelVideoLoadOperationWithKey:(nullable NSString *)key;

/**
 *移除对应视频下载操作
 */
- (void)cy_removeVideoLoadOperationWithKey:(nullable NSString *)key;

@end
