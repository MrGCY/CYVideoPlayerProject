//
//  CYDownLoadProgressView.h
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/8.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CYProgressView : UIView
/**
* 下载进度值
*/
@property(nonatomic, assign, readonly)CGFloat downloadProgressValue;

/**
 * 播放进度值
 */
@property(nonatomic, assign, readonly)CGFloat playingProgressValue;

/**
 * 设置下载进度值
 */
- (void)setDownloadProgress:(CGFloat)downloadProgress;

/**
 *设置播放进度值
 */
- (void)setPlayingProgress:(CGFloat)playingProgress;

/**
 * 下载进度条颜色
 */
- (void)perfersDownloadProgressViewColor:(UIColor * _Nonnull)color;

/**
 * 播放进度条颜色
 */
- (void)perfersPlayingProgressViewColor:(UIColor * _Nonnull)color;

/**
 * 刷新进度条视图布局
 */
- (void)refreshProgressViewForScreenEvents;
@end
