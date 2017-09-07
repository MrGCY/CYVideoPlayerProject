//
//  UIView+VideoCacheOperation.h
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/7.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (VideoCacheOperation)
/**
 * 视频显示的视图
 */
@property(nonatomic, readonly, nullable)UIView * cy_videoLayerView;

/**
 * 视频展示的layer
 */
@property(nonatomic, readonly, nullable)CALayer * cy_backgroundLayer;
@end
