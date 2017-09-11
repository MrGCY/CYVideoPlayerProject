//
//  UITableView+PlayVideo.h
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/11.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CYShortVideoCell;
UIKIT_EXTERN CGFloat const CYVideoPlayerNavAndStatusTotalHei; // 导航栏和状态栏高度总和.
UIKIT_EXTERN CGFloat const CYVideoPlayerTabbarHei; // tabbar 高度.
#define JPVideoPlayerDemoRowHei (self.bounds.size.height)

/*
 * The scroll derection of tableview.
 * 滚动类型
 */
typedef NS_ENUM(NSUInteger, CYVideoPlayerScrollDerection) {
    CYVideoPlayerScrollDerectionNone = 0,
    CYVideoPlayerScrollDerectionUp = 1, // 向上滚动
    CYVideoPlayerScrollDerectionDown = 2 // 向下滚动
};

@interface UITableView (PlayVideo)
/**
 * The cell of playing video.
 * 正在播放视频的cell.
 */
@property(nonatomic, nullable)CYShortVideoCell * playingCell;

/**
 * The number of cells cannot stop in screen center.
 * 滑动不可及cell个数.
 */
@property(nonatomic)NSUInteger maxNumCannotPlayVideoCells;

/**
 * The scroll derection of tableview now.
 * 当前滚动方向类型.
 */
@property(nonatomic)CYVideoPlayerScrollDerection currentDerection;

/**
 * The dictionary of record the number of cells that cannot stop in screen center.
 * 滑动不可及cell字典.
 */
@property(nonatomic, nonnull)NSDictionary *dictOfVisiableAndNotPlayCells;

- (void)playVideoInVisiableCells;

- (void)handleScrollStop;

- (void)handleQuickScroll;

- (void)stopPlay;

@end
