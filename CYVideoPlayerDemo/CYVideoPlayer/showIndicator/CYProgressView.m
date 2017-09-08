//
//  CYDownLoadProgressView.m
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/8.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import "CYProgressView.h"
@interface CYProgressView()
/**
 * 下载 layer.
 */
@property(nonatomic, strong)CALayer *downloadLayer;

/**
 * 播放 layer.
 */
@property(nonatomic, strong)CALayer *playingLayer;

/**
 * 下载 value.
 */
@property(nonatomic, assign, readwrite)CGFloat downloadProgressValue;

/**
 * 播放 value.
 */
@property(nonatomic, assign, readwrite)CGFloat playingProgressValue;
@end
@implementation CYProgressView
- (instancetype)init{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:22.0/255.0 green:30.0/255.0 blue:37.0/255.0 alpha:0.8];
    }
    return self;
}
#pragma mark - Public

- (void)setDownloadProgress:(CGFloat)downloadProgress{
    if (downloadProgress<0 || downloadProgress > 1) {
        return;
    }
    _downloadProgressValue = downloadProgress;
    [self addIndicatorLayerOnce];
    [self refreshProgressWithProgressVaule:downloadProgress forLayer:self.downloadLayer];
}

- (void)setPlayingProgress:(CGFloat)playingProgress{
    if (playingProgress<0 || playingProgress > 1) {
        return;
    }
    _playingProgressValue = playingProgress;
    [self addIndicatorLayerOnce];
    [self refreshProgressWithProgressVaule:playingProgress forLayer:self.playingLayer];
}

- (void)perfersPlayingProgressViewColor:(UIColor *)color{
    if (color != nil) {
        self.playingLayer.backgroundColor = color.CGColor;
    }
}

- (void)perfersDownloadProgressViewColor:(UIColor *)color{
    if (color != nil) {
        self.downloadLayer.backgroundColor = color.CGColor;
    }
}

- (void)refreshProgressViewForScreenEvents{
    [self refreshProgressWithProgressVaule:_downloadProgressValue forLayer:_downloadLayer];
    [self refreshProgressWithProgressVaule:_playingProgressValue forLayer:_playingLayer];
}
#pragma mark - Private
//修改进度条的值
- (void)refreshProgressWithProgressVaule:(CGFloat)progressValue forLayer:(CALayer *)layer{
    CGRect frame = layer.frame;
    frame.size.width = self.bounds.size.width  * progressValue;
    layer.frame = frame;
}
//第一次添加
- (void)addIndicatorLayerOnce{
    if (!self.downloadLayer.superlayer) {
        self.downloadLayer.frame = CGRectMake(0, 0, 0, self.bounds.size.height);
        [self.layer addSublayer:self.downloadLayer];
    }
    
    if (!self.playingLayer.superlayer) {
        self.playingLayer.frame = CGRectMake(0, 0,  0, self.bounds.size.height);
        [self.layer addSublayer:self.playingLayer];
    }
}
- (CALayer *)downloadLayer{
    if (!_downloadLayer) {
        _downloadLayer = [CALayer new];
        _downloadLayer.backgroundColor = [UIColor colorWithRed:196.0/255.0 green:193.0/255.0 blue:195.0/255.0 alpha:0.8].CGColor;
    }
    return _downloadLayer;
}

- (CALayer *)playingLayer{
    if (!_playingLayer) {
        _playingLayer = [CALayer new];
        _playingLayer.backgroundColor = self.tintColor.CGColor;
    }
    return _playingLayer;
}
@end
