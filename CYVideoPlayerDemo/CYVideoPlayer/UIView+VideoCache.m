//
//  UIView+VideoCache.m
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/8.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import "UIView+VideoCache.h"
#import "CYVideoPlayerTool.h"
#import "UIView+showVideoAndIndicator.h"
#import "UIView+VideoCacheOperation.h"
#import "CYVideoPlayerMacros.h"
#import <objc/message.h>
static NSString * CYVideoPlayerErrorDomain = @"CYVideoPlayerErrorDomain";
@interface UIView()<CYVideoPlayerManagerDelegate>

/**
 *全屏前的展示视图
 */
@property(nonatomic)UIView *parentView_beforeFullScreen;

/**
 * 全屏前的位置
 */
@property(nonatomic)NSValue *frame_beforeFullScreen;

@end

@implementation UIView (VideoCache)
#pragma mark - Play Video Methods
//默认有进度和加载视图
- (void)cy_playVideoWithURL:(NSURL *)url{
    [self cy_playVideoWithURL:url options:CYVideoPlayerContinueInBackground | CYVideoPlayerLayerVideoGravityResizeAspect | CYVideoPlayerShowActivityIndicatorView | CYVideoPlayerShowProgressView progress:nil completed:nil];
}
//隐藏进度条视图
- (void)cy_playVideoHiddenStatusViewWithURL:(NSURL *)url{
    [self cy_playVideoWithURL:url options:CYVideoPlayerContinueInBackground | CYVideoPlayerShowActivityIndicatorView | CYVideoPlayerLayerVideoGravityResizeAspect progress:nil completed:nil];
}
//静音播放
- (void)cy_playVideoMutedDisplayStatusViewWithURL:(NSURL *)url{
    [self cy_playVideoWithURL:url options:CYVideoPlayerContinueInBackground | CYVideoPlayerShowProgressView | CYVideoPlayerShowActivityIndicatorView | CYVideoPlayerLayerVideoGravityResizeAspect | CYVideoPlayerMutedPlay progress:nil completed:nil];
}
//静音播放并切隐藏进度条
- (void)cy_playVideoMutedHiddenStatusViewWithURL:(NSURL *)url{
    [self cy_playVideoWithURL:url options:CYVideoPlayerContinueInBackground | CYVideoPlayerMutedPlay | CYVideoPlayerLayerVideoGravityResizeAspect | CYVideoPlayerShowActivityIndicatorView progress:nil completed:nil];
}

- (void)cy_playVideoWithURL:(NSURL *)url options:(CYVideoPlayerOptions)options progress:(CYVideoPlayerDownloaderProgressBlock)progressBlock completed:(CYVideoPlayerCompletionBlock)completedBlock{
    
    NSString *validOperationKey = NSStringFromClass([self class]);
    [self cy_cancelVideoLoadOperationWithKey:validOperationKey];
    [self cy_stopPlay];
    self.currentPlayingURL = url;
    self.viewStatus = CYVideoPlayerVideoViewPlaceStatusPortrait;
    
    if (url) {
        __weak typeof(self) wself = self;
        
        [CYVideoPlayerManager sharedManager].delegate = self;
        
        // 初始化播放器和加载视图
        [self cy_setupVideoLayerViewAndIndicatorView];
        
        id <CYVideoPlayerOperationProtocol> operation = [[CYVideoPlayerManager sharedManager] cy_loadVideoWithURL:url showOnView:self options:options downloadProgress:progressBlock completed:^(NSString * _Nullable fullVideoCachePath, NSError * _Nullable error, CYVideoPlayerCacheType cacheType, NSURL * _Nullable videoURL) {
            __strong __typeof (wself) sself = wself;
            if (!sself) return;
            
            dispatch_main_async_safe(^{
                if (completedBlock) {
                    completedBlock(fullVideoCachePath, error, cacheType, url);
                }
            });
        }];
        
        [self cy_setVideoLoadOperation:operation forKey:validOperationKey];
    }
    else {
        dispatch_main_async_safe(^{
            if (completedBlock) {
                NSError *error = [NSError errorWithDomain:CYVideoPlayerErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey : @"Trying to load a nil url"}];
                completedBlock(nil, error, CYVideoPlayerCacheTypeNone, url);
            }
        });
    }
}


#pragma mark - Play Control

- (void)cy_stopPlay{
    [[CYVideoPlayerCache sharedCache] cancelCurrentComletionBlock];
    [[CYVideoPlayerDownloader sharedDownloader] cancelAllDownloads];
    [[CYVideoPlayerManager sharedManager] stopPlay];
}

- (void)cy_pause{
    [[CYVideoPlayerManager sharedManager] pause];
}

- (void)cy_resume{
    [[CYVideoPlayerManager sharedManager] resume];
}

- (void)cy_setPlayerMute:(BOOL)mute{
    [[CYVideoPlayerManager sharedManager] setPlayerMute:mute];
}

- (BOOL)cy_playerIsMute{
    return [CYVideoPlayerManager sharedManager].playerIsMute;
}


#pragma mark - Landscape Or Portrait Control

- (void)cy_gotoLandscape {
    [self cy_gotoLandscapeAnimated:YES completion:nil];
}

- (void)cy_gotoLandscapeAnimated:(BOOL)animated completion:(CYVideoPlayerScreenAnimationCompletion)completion {
    if (self.viewStatus != CYVideoPlayerVideoViewPlaceStatusPortrait) {
        return;
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    // hide status bar.
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
#pragma clang diagnostic pop
    
    self.viewStatus = CYVideoPlayerVideoViewPlaceStatusAnimating;
    
    self.parentView_beforeFullScreen = self.superview;
    self.frame_beforeFullScreen = [NSValue valueWithCGRect:self.frame];
    
    CGRect rectInWindow = [self.superview convertRect:self.frame toView:nil];
    [self removeFromSuperview];
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    self.frame = rectInWindow;
    //    self.jp_indicatorView.alpha = 0;
    
    if (animated) {
        [UIView animateWithDuration:0.35 animations:^{
            
            [self executeLandscape];
            
        } completion:^(BOOL finished) {
            
            self.viewStatus = CYVideoPlayerVideoViewPlaceStatusLandscape;
            if (completion) {
                completion();
            }
            [UIView animateWithDuration:0.5 animations:^{
//                self.cy_indicatorView.alpha = 1;
            }];
            
        }];
    }
    else{
        [self executeLandscape];
        self.viewStatus = CYVideoPlayerVideoViewPlaceStatusLandscape;
        if (completion) {
            completion();
        }
        [UIView animateWithDuration:0.5 animations:^{
//            self.cy_indicatorView.alpha = 1;
        }];
    }
    
    [self refreshStatusBarOrientation:UIInterfaceOrientationLandscapeRight];
}

- (void)cy_gotoPortrait {
    [self cy_gotoPortraitAnimated:YES completion:nil];
}

- (void)cy_gotoPortraitAnimated:(BOOL)animated completion:(CYVideoPlayerScreenAnimationCompletion)completion{
    if (self.viewStatus != CYVideoPlayerVideoViewPlaceStatusLandscape) {
        return;
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    // display status bar.
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
#pragma clang diagnostic pop
    
    self.viewStatus = CYVideoPlayerVideoViewPlaceStatusAnimating;
    
//    self.cy_indicatorView.alpha = 0;
    
    if (animated) {
        [UIView animateWithDuration:0.35 animations:^{
            
            [self executePortrait];
            
        } completion:^(BOOL finished) {
            
            [self finishPortrait];
            if (completion) {
                completion();
            }
            
        }];
    }
    else{
        [self executePortrait];
        [self finishPortrait];
        if (completion) {
            completion();
        }
    }
    
    [self refreshStatusBarOrientation:UIInterfaceOrientationPortrait];
}


#pragma mark - Private

- (void)finishPortrait{
    [self removeFromSuperview];
    [self.parentView_beforeFullScreen addSubview:self];
    self.frame = [self.frame_beforeFullScreen CGRectValue];
    
    self.cy_backgroundLayer.frame = self.bounds;
    [CYVideoPlayerTool sharedTool].currentPlayVideoItem.currentPlayerLayer.frame = self.bounds;
    self.cy_videoLayerView.frame = self.bounds;
    self.cy_indicatorView.frame = self.bounds;
    
    self.viewStatus = CYVideoPlayerVideoViewPlaceStatusPortrait;
    
    [UIView animateWithDuration:0.5 animations:^{
        
//            self.cy_indicatorView.alpha = 1;
    }];
}

- (void)executePortrait{
    CGRect frame = [self.parentView_beforeFullScreen convertRect:[self.frame_beforeFullScreen CGRectValue] toView:nil];
    self.transform = CGAffineTransformIdentity;
    self.frame = frame;
    
    self.cy_backgroundLayer.frame = self.bounds;
    [CYVideoPlayerTool sharedTool].currentPlayVideoItem.currentPlayerLayer.frame = self.bounds;
    self.cy_videoLayerView.frame = self.bounds;
    self.cy_indicatorView.frame = self.bounds;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self performSelector:NSSelectorFromString(@"refreshIndicatorViewForPortrait")];
#pragma clang diagnostic pop
}

- (void)executeLandscape{
    self.transform = CGAffineTransformMakeRotation(M_PI_2);
    CGRect bounds = CGRectMake(0, 0, CGRectGetHeight(self.superview.bounds), CGRectGetWidth(self.superview.bounds));
    CGPoint center = CGPointMake(CGRectGetMidX(self.superview.bounds), CGRectGetMidY(self.superview.bounds));
    self.bounds = bounds;
    self.center = center;
    
    self.cy_backgroundLayer.frame = bounds;
    [CYVideoPlayerTool sharedTool].currentPlayVideoItem.currentPlayerLayer.frame = bounds;
    self.cy_videoLayerView.frame = bounds;
    self.cy_indicatorView.frame = bounds;
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self performSelector:NSSelectorFromString(@"refreshIndicatorViewForLandscape")];
    #pragma clang diagnostic pop
}

- (void)refreshStatusBarOrientation:(UIInterfaceOrientation)interfaceOrientation {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [[UIApplication sharedApplication] setStatusBarOrientation:interfaceOrientation animated:YES];
#pragma clang diagnostic pop
}

- (void)setParentView_beforeFullScreen:(UIView *)parentView_beforeFullScreen{
    objc_setAssociatedObject(self, @selector(parentView_beforeFullScreen), parentView_beforeFullScreen, OBJC_ASSOCIATION_ASSIGN);
}

- (void)setPlayingStatus:(CYVideoPlayerPlayingStatus)playingStatus{
    objc_setAssociatedObject(self, @selector(playingStatus), @(playingStatus), OBJC_ASSOCIATION_ASSIGN);
}

- (CYVideoPlayerPlayingStatus)playingStatus{
    return [objc_getAssociatedObject(self, _cmd) integerValue];
}

- (UIView *)parentView_beforeFullScreen{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setFrame_beforeFullScreen:(NSValue *)frame_beforeFullScreen{
    objc_setAssociatedObject(self, @selector(frame_beforeFullScreen), frame_beforeFullScreen, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSValue *)frame_beforeFullScreen{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setViewStatus:(CYVideoPlayerVideoViewPlaceStatus)viewStatus{
    objc_setAssociatedObject(self, @selector(viewStatus), @(viewStatus), OBJC_ASSOCIATION_ASSIGN);
}

- (CYVideoPlayerVideoViewPlaceStatus)viewStatus{
    return [objc_getAssociatedObject(self, _cmd) integerValue];
}

- (id<CYVideoPlayerDelegate>)cy_videoPlayerDelegate{
    id (^__weak_block)() = objc_getAssociatedObject(self, _cmd);
    if (!__weak_block) {
        return nil;
    }
    return __weak_block();
}
- (void)setCy_videoPlayerDelegate:(id<CYVideoPlayerDelegate>)cy_videoPlayerDelegate{
    id __weak __weak_object = cy_videoPlayerDelegate;
    id (^__weak_block)() = ^{
        return __weak_object;
    };
    objc_setAssociatedObject(self, @selector(cy_videoPlayerDelegate),   __weak_block, OBJC_ASSOCIATION_COPY);
}


#pragma mark - CYVideoPlayerManagerDelegate

- (BOOL)videoPlayerManager:(CYVideoPlayerManager *)videoPlayerManager shouldDownloadVideoForURL:(NSURL *)videoURL{
    if (self.cy_videoPlayerDelegate && [self.cy_videoPlayerDelegate respondsToSelector:@selector(shouldDownloadVideoForURL:)]) {
        return [self.cy_videoPlayerDelegate shouldDownloadVideoForURL:videoURL];
    }
    return YES;
}

- (BOOL)videoPlayerManager:(CYVideoPlayerManager *)videoPlayerManager shouldAutoReplayForURL:(NSURL *)videoURL{
    if (self.cy_videoPlayerDelegate && [self.cy_videoPlayerDelegate respondsToSelector:@selector(shouldAutoReplayAfterPlayCompleteForURL:)]) {
        return [self.cy_videoPlayerDelegate shouldAutoReplayAfterPlayCompleteForURL:videoURL];
    }
    return YES;
}

- (void)videoPlayerManager:(CYVideoPlayerManager *)videoPlayerManager playingStatusDidChanged:(CYVideoPlayerPlayingStatus)playingStatus{
    self.playingStatus = playingStatus;
    if (self.cy_videoPlayerDelegate && [self.cy_videoPlayerDelegate respondsToSelector:@selector(playingStatusDidChanged:)]) {
        [self.cy_videoPlayerDelegate playingStatusDidChanged:playingStatus];
    }
}

- (BOOL)videoPlayerManager:(CYVideoPlayerManager *)videoPlayerManager downloadingProgressDidChanged:(CGFloat)downloadingProgress{
    if (self.cy_videoPlayerDelegate && [self.cy_videoPlayerDelegate respondsToSelector:@selector(downloadingProgressDidChanged:)]) {
        [self.cy_videoPlayerDelegate downloadingProgressDidChanged:downloadingProgress];
        return NO;
    }
    return YES;
}

- (BOOL)videoPlayerManager:(CYVideoPlayerManager *)videoPlayerManager playingProgressDidChanged:(CGFloat)playingProgress{
    if (self.cy_videoPlayerDelegate && [self.cy_videoPlayerDelegate respondsToSelector:@selector(playingProgressDidChanged:)]) {
        [self.cy_videoPlayerDelegate playingProgressDidChanged:playingProgress];
        return NO;
    }
    return YES;
}

@end
