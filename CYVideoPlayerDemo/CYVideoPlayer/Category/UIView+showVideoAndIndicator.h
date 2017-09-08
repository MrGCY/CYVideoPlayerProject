//
//  UIView+showVideoAndIndicator.h
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/8.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (showVideoAndIndicator)
/**
 * 获取视频显示的layer
 */
@property(nonatomic, readonly, nullable)UIView *cy_videoLayerView;

/**
 * 获取底部layer
 */
@property(nonatomic, readonly, nullable)CALayer *cy_backgroundLayer;

/**
 *  获取指示视图
 */
@property(nonatomic, readonly, nullable)UIView *cy_indicatorView;

/**
 * 获取下载播放进度值
 */
@property(nonatomic, readonly)CGFloat cy_downloadProgressValue;

/**
 * 获取播放进度值
 */
@property(nonatomic, readonly)CGFloat cy_playingProgressValue;

/**
 * 修改下载进度颜色
 */
- (void)cy_perfersDownloadProgressViewColor:(UIColor * _Nonnull)color;

/**
 * 修改播放进度的颜色
 */
- (void)cy_perfersPlayingProgressViewColor:(UIColor * _Nonnull)color;
//播放前显示黑色的图层
- (void)displayBackLayer;
//刷新竖屏指示器位置
- (void)refreshIndicatorViewForPortrait;
//刷新横屏指示器位置
- (void)refreshIndicatorViewForLandscape;
//显示进度条视图
- (void)cy_showProgressView;
//隐藏进度条
- (void)cy_hideProgressView;
//设置下载进度条变化
- (void)cy_progressViewDownloadingStatusChangedWithProgressValue:(NSNumber *_Nonnull)progress;
//设置播放进度条变化
- (void)cy_progressViewPlayingStatusChangedWithProgressValue:(NSNumber *_Nonnull)progress;
//显示指示器视图
- (void)cy_showActivityIndicatorView;
//隐藏指示器视图
- (void)cy_hideActivityIndicatorView;
//初始化播放器视图和活动指示器视图
- (void)cy_setupVideoLayerViewAndIndicatorView;
//移除播放器视图和活动指示器视图
- (void)cy_removeVideoLayerViewAndIndicatorView;
@end
