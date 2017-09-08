//
//  UIView+showVideoAndIndicator.m
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/8.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import "UIView+showVideoAndIndicator.h"
#import "CYActivityindicatorView.h"
#import "CYProgressView.h"
#import "UIView+WebVideoCache.h"
#import "CYVideoPlayerTool.h"

#import <objc/message.h>

static char progressViewKey;
static char progressViewTintColorKey;
static char progressViewBackgroundColorKey;
static char activityIndicatorViewKey;
static char videoLayerViewKey;
static char indicatorViewKey;
static char downloadProgressValueKey;
static char playingProgressValueKey;
static char backgroundLayerKey;
@interface UIView ()

@property(nonatomic)CYProgressView *progressView;

@property(nonatomic)UIView * cy_videoLayerView;

@property(nonatomic)UIView * cy_indicatorView;

@property(nonatomic)UIColor * progressViewTintColor;

@property(nonatomic)UIColor * progressViewBackgroundColor;

@property(nonatomic)CYActivityindicatorView *activityIndicatorView;

/**
 * 获取下载播放进度值
 */
@property(nonatomic, readwrite)CGFloat cy_downloadProgressValue;

/**
 * 获取播放进度值
 */
@property(nonatomic, readwrite)CGFloat cy_playingProgressValue;
@end

@implementation UIView (showVideoAndIndicator)
#pragma mark - Public
/**
 * 修改播放进度的颜色
 */
- (void)cy_perfersPlayingProgressViewColor:(UIColor *)color{
    if (color) {
        [self.progressView perfersPlayingProgressViewColor:color];
        self.progressViewTintColor = color;
    }
}
/**
 * 修改下载进度颜色
 */
- (void)cy_perfersDownloadProgressViewColor:(UIColor *)color{
    if (color) {
        [self.progressView perfersDownloadProgressViewColor:color];
        self.progressViewBackgroundColor = color;
    }
}

#pragma mark- 懒加载
//创建进度条
- (CYProgressView *)progressView{
    CYProgressView *progressView = objc_getAssociatedObject(self, &progressViewKey);
    if (!progressView) {
        progressView = [CYProgressView new];
        progressView.hidden = YES;
        [self layoutProgressViewForPortrait:progressView];
        [progressView perfersDownloadProgressViewColor:self.progressViewBackgroundColor];
        [progressView perfersPlayingProgressViewColor:self.progressViewTintColor];
        progressView.backgroundColor = [UIColor clearColor];
        objc_setAssociatedObject(self, &progressViewKey, progressView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return progressView;
}
//创建活动指示器底部view
- (UIView *)cy_indicatorView{
    UIView *view = objc_getAssociatedObject(self, &indicatorViewKey);
    if (!view) {
        view = [UIView new];
        view.frame = self.bounds;
        view.backgroundColor = [UIColor clearColor];
        view.userInteractionEnabled = NO;
        objc_setAssociatedObject(self, &indicatorViewKey, view, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return view;
}
//创建活动指示器
- (CYActivityindicatorView *)activityIndicatorView{
    CYActivityindicatorView *acv = objc_getAssociatedObject(self, &activityIndicatorViewKey);
    if (!acv) {
        acv = [CYActivityindicatorView new];
        [self layoutActivityIndicatorViewForPortrait:acv];
        acv.hidden = YES;
        objc_setAssociatedObject(self, &activityIndicatorViewKey, acv, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return acv;
}
//视频图层显示底部视图
- (UIView *)cy_videoLayerView{
    UIView *view = objc_getAssociatedObject(self, &videoLayerViewKey);
    if (!view) {
        view = [UIView new];
        view.frame = self.bounds;
        view.backgroundColor = [UIColor clearColor];
        view.userInteractionEnabled = NO;
        objc_setAssociatedObject(self, &videoLayerViewKey, view, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return view;
}
- (CALayer *)cy_backgroundLayer{
    CALayer *backLayer = objc_getAssociatedObject(self, &backgroundLayerKey);
    if (!backLayer) {
        backLayer = [CALayer new];
        backLayer.backgroundColor = [UIColor blackColor].CGColor;
        objc_setAssociatedObject(self, &backgroundLayerKey, backLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return backLayer;
}


#pragma mark- 一些公共方法
//播放前显示黑色的图层
- (void)displayBackLayer{
    if (self.cy_backgroundLayer.superlayer) {
        return;
    }
    self.cy_backgroundLayer.frame = self.bounds;
    UIColor *backcolor = [UIColor clearColor];
    if (self.jp_videoPlayerDelegate && [self.jp_videoPlayerDelegate respondsToSelector:@selector(shouldDisplayBlackLayerBeforePlayStart)]) {
        if ([self.jp_videoPlayerDelegate shouldDisplayBlackLayerBeforePlayStart]) {
            backcolor = [UIColor blackColor];
        }
    }
    self.cy_backgroundLayer.backgroundColor = backcolor.CGColor;
    [self.cy_videoLayerView.layer addSublayer:self.cy_backgroundLayer];
}

//刷新竖屏指示器位置
- (void)refreshIndicatorViewForPortrait{
    [self layoutProgressViewForPortrait:self.progressView];
    [self layoutActivityIndicatorViewForPortrait:self.activityIndicatorView];
    [self.progressView refreshProgressViewForScreenEvents];
}
//刷新横屏指示器位置
- (void)refreshIndicatorViewForLandscape{
    [self layoutProgressViewForLandscape:self.progressView];
    [self layoutActivityIndicatorViewForLandscape:self.activityIndicatorView];
    [self.progressView refreshProgressViewForScreenEvents];
}
//显示进度条视图
- (void)cy_showProgressView{
    if (!self.progressView.superview) {
        [self.cy_indicatorView addSubview:self.progressView];
        [self.progressView setDownloadProgress:0];
        [self.progressView setPlayingProgress:0];
        self.progressView.hidden = NO;
    }
}
//隐藏进度条
- (void)cy_hideProgressView{
    if (self.progressView.superview) {
        self.progressView.hidden = YES;
        [self.progressView setDownloadProgress:0];
        [self.progressView setPlayingProgress:0];
        [self.progressView removeFromSuperview];
    }
}
//设置下载进度条变化
- (void)cy_progressViewDownloadingStatusChangedWithProgressValue:(NSNumber *)progress{
    CGFloat delta = [progress floatValue];
    delta = MAX(0, delta);
    delta = MIN(delta, 1);
    [self.progressView setDownloadProgress:delta];
    self.cy_downloadProgressValue = delta;
}
//设置播放进度条变化
- (void)cy_progressViewPlayingStatusChangedWithProgressValue:(NSNumber *)progress{
    CGFloat delta = [progress floatValue];
    delta = MAX(0, delta);
    delta = MIN(delta, 1);
    [self.progressView setPlayingProgress:delta];
    self.cy_playingProgressValue = delta;
}
//显示指示器视图
- (void)cy_showActivityIndicatorView{
    if (!self.activityIndicatorView.superview) {
        [self.cy_indicatorView addSubview:self.activityIndicatorView];
        [self.activityIndicatorView startAnimating];
    }
}
//隐藏指示器视图
- (void)cy_hideActivityIndicatorView{
    if (self.activityIndicatorView.superview) {
        [self.activityIndicatorView stopAnimating];
        [self.activityIndicatorView removeFromSuperview];
    }
}
//初始化播放器视图和活动指示器视图
- (void)cy_setupVideoLayerViewAndIndicatorView{
    if (!self.cy_videoLayerView.superview && !self.cy_indicatorView.superview) {
        [self addSubview:self.cy_videoLayerView];
        [self addSubview:self.cy_indicatorView];
    }
}
//移除播放器视图和活动指示器视图
- (void)cy_removeVideoLayerViewAndIndicatorView{
    if (self.cy_videoLayerView.superview && self.cy_indicatorView.superview) {
        [self.cy_videoLayerView removeFromSuperview];
        [self.cy_indicatorView removeFromSuperview];
    }
}


#pragma mark - Properties

- (void)setCy_playingProgressValue:(CGFloat)jp_playingProgressValue{
    objc_setAssociatedObject(self, &playingProgressValueKey, @(jp_playingProgressValue), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)cy_playingProgressValue{
    return [objc_getAssociatedObject(self, &playingProgressValueKey) floatValue];
}

- (void)setCy_downloadProgressValue:(CGFloat)jp_downloadProgressValue{
    objc_setAssociatedObject(self, &downloadProgressValueKey, @(jp_downloadProgressValue), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)cy_downloadProgressValue{
    return [objc_getAssociatedObject(self, &downloadProgressValueKey) floatValue];
}

- (void)setProgressViewTintColor:(UIColor *)progressViewTintColor{
    objc_setAssociatedObject(self, &progressViewTintColorKey, progressViewTintColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIColor *)progressViewTintColor{
    UIColor *color = objc_getAssociatedObject(self, &progressViewTintColorKey);
    if (!color) {
        color = [UIColor colorWithRed:0.0/255 green:118.0/255 blue:255.0/255 alpha:1];
    }
    return color;
}

- (void)setProgressViewBackgroundColor:(UIColor *)progressViewBackgroundColor{
    objc_setAssociatedObject(self, &progressViewBackgroundColorKey, progressViewBackgroundColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIColor *)progressViewBackgroundColor{
    UIColor *color = objc_getAssociatedObject(self, &progressViewTintColorKey);
    if (!color) {
        color = [UIColor colorWithRed:155.0/255 green:155.0/255 blue:155.0/255 alpha:1.0];
    }
    return color;
}


#pragma mark - Landscape Events 横竖屏活动指示器和进度条的位置

- (void)layoutProgressViewForPortrait:(UIView *)progressView{
    CGFloat progressViewY = self.frame.size.height - CYVideoPlayerLayerFrameY;
    if ([self.jp_videoPlayerDelegate respondsToSelector:@selector(shouldProgressViewOnTop)] && [self.jp_videoPlayerDelegate shouldProgressViewOnTop]) {
        progressViewY = 0;
    }
    progressView.frame = CGRectMake(0, progressViewY, self.frame.size.width, CYVideoPlayerLayerFrameY);
}

- (void)layoutProgressViewForLandscape:(UIView *)progressView{
    CGFloat width = CGRectGetHeight(self.superview.bounds);
    CGFloat hei = CGRectGetWidth(self.superview.bounds);
    CGFloat progressViewY = hei - CYVideoPlayerLayerFrameY;
    if ([self.jp_videoPlayerDelegate respondsToSelector:@selector(shouldProgressViewOnTop)] && [self.jp_videoPlayerDelegate shouldProgressViewOnTop]) {
        progressViewY = 0;
    }
    progressView.frame = CGRectMake(0, progressViewY, width, hei);
}

- (void)layoutActivityIndicatorViewForPortrait:(UIView *)acv{
    CGSize viewSize = self.frame.size;
    CGFloat selfX = (viewSize.width-CYVideoPlayerActivityIndicatorWH)*0.5;
    CGFloat selfY = (viewSize.height-CYVideoPlayerActivityIndicatorWH)*0.5;
    acv.frame = CGRectMake(selfX, selfY, CYVideoPlayerActivityIndicatorWH, CYVideoPlayerActivityIndicatorWH);
}

- (void)layoutActivityIndicatorViewForLandscape:(UIView *)acv{
    CGFloat width = CGRectGetHeight(self.superview.bounds);
    CGFloat hei = CGRectGetWidth(self.superview.bounds);
    CGFloat selfX = (width-CYVideoPlayerActivityIndicatorWH)*0.5;
    CGFloat selfY = (hei-CYVideoPlayerActivityIndicatorWH)*0.5;
    acv.frame = CGRectMake(selfX, selfY, CYVideoPlayerActivityIndicatorWH, CYVideoPlayerActivityIndicatorWH);
}

@end
