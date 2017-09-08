//
//  CYVideoPlayerManager.m
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/6.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import "CYVideoPlayerManager.h"
#import "CYVideoPlayerResourceLoader.h"
#import "CYVideoPlayerMacros.h"
#import "CYVideoPlayerTool.h"
#import "UIView+WebVideoCacheOperation.h"
#import "UIView+showVideoAndIndicator.h"
//-------------------------联系下载缓存操作的类
@interface CYVideoPlayerCombinedOperation : NSObject<CYVideoPlayerOperationProtocol>
@property (assign, nonatomic, getter = isCancelled) BOOL cancelled;

@property (copy, nonatomic, nullable) CYVideoPlayerNoParamsBlock cancelBlock;

@property (strong, nonatomic, nullable) NSOperation *cacheOperation;
@end
@implementation CYVideoPlayerCombinedOperation
- (void)setCancelBlock:(nullable CYVideoPlayerNoParamsBlock)cancelBlock {
    // check if the operation is already cancelled, then we just call the cancelBlock
    if (self.isCancelled) {
        if (cancelBlock) {
            cancelBlock();
        }
        _cancelBlock = nil; // don't forget to nil the cancelBlock, otherwise we will get crashes
    } else {
        _cancelBlock = [cancelBlock copy];
    }
}
//实现协议方法 CYVideoPlayerOperation
- (void)cancel {
    self.cancelled = YES;
    if (self.cacheOperation) {
        [self.cacheOperation cancel];
        self.cacheOperation = nil;
    }
    if (self.cancelBlock) {
        self.cancelBlock();
        _cancelBlock = nil;
    }
}

@end



//----------------------------视频管理者--------------------
@interface CYVideoPlayerManager()<CYVideoPlayerToolDelegate>
//视频缓存对象
@property (strong, nonatomic, readwrite, nullable) CYVideoPlayerCache *videoCache;
//视频下载对象
@property (strong, nonatomic, readwrite, nullable) CYVideoPlayerDownloader *videoDownloader;
//失败url的集合
@property (strong, nonatomic, nonnull) NSMutableSet<NSURL *> *failedURLs;
//缓存操作的数组
@property (strong, nonatomic, nonnull) NSMutableArray<CYVideoPlayerCombinedOperation *> *runningOperations;
//是否静音
@property(nonatomic, getter=isMuted) BOOL mute;
//展示视图的数组
@property (strong, nonatomic, nonnull) NSMutableArray<UIView *> *showViews;

@end
@implementation CYVideoPlayerManager
/**
 创建单例
 */
+(nonnull instancetype)sharedManager{
    static dispatch_once_t onceToken;
    static id instance;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}
#pragma mark- 初始化方法
- (nonnull instancetype)init {
    //创建缓存器
    CYVideoPlayerCache *cache = [CYVideoPlayerCache sharedCache];
    //创建下载器
    CYVideoPlayerDownloader *downloader = [CYVideoPlayerDownloader sharedDownloader];
    return [self initWithCache:cache downloader:downloader];
}

- (nonnull instancetype)initWithCache:(nonnull CYVideoPlayerCache *)cache downloader:(nonnull CYVideoPlayerDownloader *)downloader {
    if ((self = [super init])) {
        _videoCache = cache;
        _videoDownloader = downloader;
        _failedURLs = [NSMutableSet new];
        _runningOperations = [NSMutableArray array];
        _showViews = [NSMutableArray array];
    }
    return self;
}

#pragma mark -加载视频资源  通过地址判断是本地资源还是流媒体资源
- (nullable id <CYVideoPlayerOperationProtocol>)cy_loadVideoWithURL:(nullable NSURL *)url
                                                 showOnView:(nullable UIView *)showView
                                                    options:(CYVideoPlayerOptions)options
                                           downloadProgress:(nullable CYVideoPlayerDownloaderProgressBlock)progressBlock
                                                  completed:(nullable CYVideoPlayerCompletionBlock)completedBlock{
    
    if ([url isKindOfClass:NSString.class]) {
        url = [NSURL URLWithString:(NSString *)url];
    }
    //判断url是不是NSURL的对象
    if (![url isKindOfClass:NSURL.class]) {
        url = nil;
    }
    //创建联和操作对象
    __block CYVideoPlayerCombinedOperation *operation = [CYVideoPlayerCombinedOperation new];
    __weak CYVideoPlayerCombinedOperation *weakOperation = operation;
    
    BOOL isFailedUrl = NO;
    if (url) {
        //判断url是不是失败的地址
        @synchronized (self.failedURLs) {
            isFailedUrl = [self.failedURLs containsObject:url];
        }
    }
    //判断视频地址是不是无效地址
    if (url.absoluteString.length == 0 || (!(options & CYVideoPlayerRetryFailed) && isFailedUrl)) {
        [self cy_completionBlockForOperation:operation completion:completedBlock videoPath:nil error:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorFileDoesNotExist userInfo:nil] cacheType:CYVideoPlayerCacheTypeNone url:url];
        return operation;
    }
    //添加操作
    @synchronized (self.runningOperations) {
        [self.runningOperations addObject:operation];
    }
    //添加显示视图
    @synchronized (self.showViews) {
        [self.showViews addObject:showView];
    }
    
    //获取缓存视频key
    NSString *key = [self cacheKeyForURL:url];
    BOOL isFileURL = [url isFileURL];
    
    // 显示加载器和下载视图
    [self showProgressViewAndActivityIndicatorViewForView:showView options:options];
    
    __weak typeof(showView) wShowView = showView;
    if (isFileURL) {
        // 隐藏指示器
        [self hideActivityViewWithURL:url options:options];
        //加载本地视频
        id  backOperation = [self cy_loadLocalVideoWithURL:url showOnView:showView options:options completed:completedBlock combinedOperation:operation];
        if (backOperation) {
            return backOperation;
        }
    }else{
        operation.cacheOperation = [self.videoCache queryCacheOperationForKey:key done:^(NSString * _Nullable videoPath, CYVideoPlayerCacheType cacheType) {
        //判断缓存操作是否取消
        if (operation.isCancelled) {
            //移除操作
            [self cy_safelyRemoveOperationFromRunning:operation];
            return;
        }
        //判断需不需要进行视频数据缓存
        if (!videoPath && (![self.delegate respondsToSelector:@selector(videoPlayerManager:shouldDownloadVideoForURL:)] || [self.delegate videoPlayerManager:self shouldDownloadVideoForURL:url])) {
            
            // cache token.
            __block  CYVideoPlayerCacheToken *cacheToken = nil;
            
            //需要下载视频到缓存中
            CYVideoPlayerDownloaderOptions downloaderOptions = 0;
            {
                if (options & CYVideoPlayerContinueInBackground)
                    downloaderOptions |= CYVideoPlayerDownloaderContinueInBackground;
                if (options & CYVideoPlayerHandleCookies)
                    downloaderOptions |= CYVideoPlayerDownloaderHandleCookies;
                if (options & CYVideoPlayerAllowInvalidSSLCertificates)
                    downloaderOptions |= CYVideoPlayerDownloaderAllowInvalidSSLCertificates;
                if (options & CYVideoPlayerShowProgressView)
                    downloaderOptions |= CYVideoPlayerDownloaderShowProgressView;
                if (options & CYVideoPlayerShowActivityIndicatorView)
                    downloaderOptions |= CYVideoPlayerDownloaderShowActivityIndicatorView;
            }
            // Save received data to disk. 保存视频到硬盘中 下载进度的回调
            CYVideoPlayerDownloaderProgressBlock handleProgressBlock = ^(NSData * _Nullable data, NSInteger receivedSize, NSInteger expectedSize, NSString *_Nullable tempVideoCachedPath, NSURL * _Nullable targetURL){
                //下载完成并进行存储
                cacheToken = [self.videoCache storeVideoData:data expectedSize:expectedSize forKey:key completion:^(NSUInteger storedSize, NSError * _Nullable error, NSString * _Nullable fullVideoCachePath) {
                    
                    //当前分段的缓存完成
                    __strong __typeof(weakOperation) strongOperation = weakOperation;
                    
                    if (!strongOperation || strongOperation.isCancelled) {
                    }
                    if (!error) {
                        if (!fullVideoCachePath) {
                            // 刷新下载视图
                            [self progressRefreshWithURL:targetURL options:options receiveSize:storedSize exceptSize:expectedSize];
                            //没有完全缓存完成  只缓存了一部分
                            if (progressBlock) {
                                progressBlock(data, storedSize, expectedSize, tempVideoCachedPath, targetURL);
                            }
                            { //开始播放缓存的视频
                                if (![CYVideoPlayerTool sharedTool].currentPlayVideoItem) {
                                    //当前资源为空
                                    __strong typeof(wShowView) sShowView = wShowView;
                                    if (!sShowView) return;
                                    //播放前显示黑色背景
                                    [showView displayBackLayer];
                                    //直接播放在线资源
                                    [[CYVideoPlayerTool sharedTool] playOnlineVideoWithURL:url tempVideoCachePath:tempVideoCachedPath options:options videoFileExceptSize:expectedSize videoFileReceivedSize:storedSize showOnView:sShowView playingProgress:^(CGFloat progress) {
                                        //播放进度
                                        BOOL needDisplayProgress = [self needDisplayPlayingProgressViewWithPlayingProgressValue:progress];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                                        if (needDisplayProgress) {
                                            [sShowView performSelector:NSSelectorFromString(@"cy_progressViewPlayingStatusChangedWithProgressValue:") withObject:@(progress)];
                                        }
#pragma clang diagnostic pop
                                    } error:^(NSError * _Nullable error) {
                                        if (error) {
                                            if (completedBlock) {
                                                [self cy_completionBlockForOperation:strongOperation completion:completedBlock videoPath:nil error:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorFileDoesNotExist userInfo:nil] cacheType:CYVideoPlayerCacheTypeNone url:targetURL];
                                                //移除操作
                                                [self cy_safelyRemoveOperationFromRunning:operation];
                                                //移除加载器视图
                                                [self hideAllIndicatorAndProgressViewsWithURL:url options:options];
                                            }
                                        }

                                    }];
                                    [CYVideoPlayerTool sharedTool].delegate = self;
                                }else{
                                    //资源不为空
                                    
                                    NSString *key = [[CYVideoPlayerManager sharedManager] cacheKeyForURL:targetURL];
                                    if ([CYVideoPlayerTool sharedTool].currentPlayVideoItem && [key isEqualToString:[CYVideoPlayerTool sharedTool].currentPlayVideoItem.playingKey]) {
                                        //将当前缓存好的视频填充到对应的loadRequestUrl中
                                        [[CYVideoPlayerTool sharedTool] didReceivedDataCacheInDiskByTempPath:tempVideoCachedPath videoFileExceptSize:expectedSize videoFileReceivedSize:receivedSize];
                                    }
                                }
                            }
                        }else{
                            //视频全部缓存完成
                            [[CYVideoPlayerTool sharedTool] didCachedVideoDataFinishedFromWebFullVideoCachePath:fullVideoCachePath];
                            [self cy_completionBlockForOperation:strongOperation completion:completedBlock videoPath:fullVideoCachePath error:nil cacheType:CYVideoPlayerCacheTypeNone url:url];
                            [self cy_safelyRemoveOperationFromRunning:strongOperation];
                            
                            if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayerManager:downloadingProgressDidChanged:)]) {
                                [self.delegate videoPlayerManager:self downloadingProgressDidChanged:1];
                            }
                        }
                    }else{
                        //存储出现的一些错误
                        [self cy_completionBlockForOperation:strongOperation completion:completedBlock videoPath:nil error:error cacheType:CYVideoPlayerCacheTypeNone url:url];
                        [self cy_safelyRemoveOperationFromRunning:strongOperation];
                        // 隐藏指示器视图
                        [self hideAllIndicatorAndProgressViewsWithURL:url options:options];
                    }
                }];
            };

            // 先删除所有的临时文件然后进行下载
            [self.videoCache deleteAllTempCacheOnCompletion:^{
                //开始进行视频下载
                CYVideoPlayerDownloadToken *subOperationToken = [self.videoDownloader downloadVideoWithURL:url options:downloaderOptions progress:handleProgressBlock completed:^(NSError * _Nullable error) {
                    __strong __typeof(weakOperation) strongOperation = weakOperation;
                    if (!strongOperation || strongOperation.isCancelled) {
                        // Do nothing if the operation was cancelled.
                        // if we would call the completedBlock, there could be a race condition between this block and another completedBlock for the same object, so if this one is called second, we will overwrite the new data.
                    }else if (error){
                        //有错误信息
                        [self cy_completionBlockForOperation:strongOperation completion:completedBlock videoPath:nil error:error cacheType:CYVideoPlayerCacheTypeNone url:url];
                        if (   error.code != NSURLErrorNotConnectedToInternet
                            && error.code != NSURLErrorCancelled
                            && error.code != NSURLErrorTimedOut
                            && error.code != NSURLErrorInternationalRoamingOff
                            && error.code != NSURLErrorDataNotAllowed
                            && error.code != NSURLErrorCannotFindHost
                            && error.code != NSURLErrorCannotConnectToHost) {
                            @synchronized (self.failedURLs) {
                                [self.failedURLs addObject:url];
                            }
                        }
                        [self cy_safelyRemoveOperationFromRunning:strongOperation];
                    }else{
                        //完成下载
                        if ((options & CYVideoPlayerRetryFailed)) {
                            @synchronized (self.failedURLs) {
                                if ([self.failedURLs containsObject:url]) {
                                    [self.failedURLs removeObject:url];
                                }
                            }
                        }
                    }
                }];
                //操作取消的回调
                operation.cancelBlock = ^{
                    [self.videoCache cancel:cacheToken];
                    [self.videoDownloader cancel:subOperationToken];
                    [[CYVideoPlayerManager sharedManager] stopPlay];
                    // hide indicator view.
                    [self hideAllIndicatorAndProgressViewsWithURL:url options:options];
                    
                    __strong __typeof(weakOperation) strongOperation = weakOperation;
                    [self cy_safelyRemoveOperationFromRunning:strongOperation];
                };
            }];
        }else if(videoPath){
                //缓存中有视频
                __strong __typeof(weakOperation) strongOperation = weakOperation;
                // hide activity view.
                [self hideActivityViewWithURL:url options:options];
                // play video from disk.
                if (cacheType==CYVideoPlayerCacheTypeDisk) {
                    BOOL needDisplayProgressView = [self needDisplayDownloadingProgressViewWithDownloadingProgressValue:1.0];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                    if (needDisplayProgressView) {
                        [showView performSelector:NSSelectorFromString(@"cy_progressViewDownloadingStatusChangedWithProgressValue:") withObject:@1];
                    }
#pragma clang diagnostic pop
                    //播放前显示黑色背景
                    [showView displayBackLayer];
                    
                    //视频是否在磁盘中
                    //播放本地视频
                    [[CYVideoPlayerTool sharedTool] playExistedVideoWithURL:url fullVideoCachePath:videoPath options:options showOnView:showView playingProgress:^(CGFloat progress) {
                        __strong typeof(wShowView) sShowView = wShowView;
                        if (!sShowView) return;
                        BOOL needDisplayProgressView = [self needDisplayPlayingProgressViewWithPlayingProgressValue:progress];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                        if (needDisplayProgressView) {
                            [showView performSelector:NSSelectorFromString(@"cy_progressViewPlayingStatusChangedWithProgressValue:") withObject:@(progress)];
                        }
#pragma clang diagnostic pop
                    } error:^(NSError * _Nullable error) {
                        if (completedBlock) {
                            completedBlock(nil, error, CYVideoPlayerCacheTypeLocation, url);
                        }
                    }];
                    [CYVideoPlayerTool sharedTool].delegate = self;
                }
                
                [self cy_completionBlockForOperation:strongOperation completion:completedBlock videoPath:videoPath error:nil cacheType:CYVideoPlayerCacheTypeDisk url:url];
                [self cy_safelyRemoveOperationFromRunning:operation];
        }else {
                // hide activity and progress view.
                [self hideAllIndicatorAndProgressViewsWithURL:url options:options];
                __strong __typeof(weakOperation) strongOperation = weakOperation;
                [self cy_completionBlockForOperation:strongOperation completion:completedBlock videoPath:nil error:nil cacheType:CYVideoPlayerCacheTypeNone url:url];
                [self cy_safelyRemoveOperationFromRunning:operation];
                // hide activity and progress view.
                [self hideAllIndicatorAndProgressViewsWithURL:url options:options];
            }
        }];
    }
    
    return operation;
}

//加载本地视频资源
-(nullable id <CYVideoPlayerOperationProtocol>)cy_loadLocalVideoWithURL:(nullable NSURL *)url
                                                     showOnView:(nullable UIView *)showView
                                                        options:(CYVideoPlayerOptions)options
                                                      completed:(nullable CYVideoPlayerCompletionBlock)completedBlock
                                              combinedOperation:(nullable CYVideoPlayerCombinedOperation *)operation{
    //是本地视频
    __weak typeof(showView) wShowView = showView;
    NSString *path = [url.absoluteString stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    //判断文件路径是否存在
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        BOOL needDisplayProgressView = [self needDisplayDownloadingProgressViewWithDownloadingProgressValue:1.0];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        if (needDisplayProgressView) {
            [showView performSelector:NSSelectorFromString(@"cy_progressViewDownloadingStatusChangedWithProgressValue:") withObject:@1];
        }
#pragma clang diagnostic pop
        //播放前显示黑色背景
        [showView displayBackLayer];
        [[CYVideoPlayerTool sharedTool] playExistedVideoWithURL:url fullVideoCachePath:path options:options showOnView:showView playingProgress:^(CGFloat progress) {
            __strong typeof(wShowView) sShowView = wShowView;
            if (!sShowView) return;
            //显示下载进度
            BOOL needDisplayProgressView = [self needDisplayPlayingProgressViewWithPlayingProgressValue:progress];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            if (needDisplayProgressView) {
                [showView performSelector:NSSelectorFromString(@"cy_progressViewPlayingStatusChangedWithProgressValue:") withObject:@(progress)];
            }
#pragma clang diagnostic pop
        } error:^(NSError * _Nullable error) {
            if (completedBlock) {
                completedBlock(nil, error, CYVideoPlayerCacheTypeLocation, url);
            }
        }];
        //设置代理对象
        [CYVideoPlayerTool sharedTool].delegate = self;
    }
    else{
        //路径失效返回错误码
        [self cy_completionBlockForOperation:operation completion:completedBlock videoPath:nil error:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorFileDoesNotExist userInfo:nil] cacheType:CYVideoPlayerCacheTypeNone url:url];
        // hide progress view.
        [self hideProgressViewWithURL:url options:options];
        return operation;
    }
    return nil;
}


//----------------安全移除缓存操作
- (void)cy_safelyRemoveOperationFromRunning:(nullable CYVideoPlayerCombinedOperation*)operation {
    @synchronized (self.runningOperations) {
        if (operation) {
            [self.runningOperations removeObject:operation];
        }
    }
}
//获取视频缓存的key  相当于将视频地址当做缓存的key
- (nullable NSString *)cacheKeyForURL:(nullable NSURL *)url {
    if (!url) {
        return @"";
    }
    //#pragma clang diagnostic push
    //#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    //    url = [[NSURL alloc] initWithScheme:url.scheme host:url.host path:url.path];
    //#pragma clang diagnostic pop
    return [url absoluteString];
}
//查看操作是否完成
- (void)cy_completionBlockForOperation:(nullable CYVideoPlayerCombinedOperation*)operation completion:(nullable CYVideoPlayerCompletionBlock)completionBlock videoPath:(nullable NSString *)videoPath error:(nullable NSError *)error cacheType:(CYVideoPlayerCacheType)cacheType url:(nullable NSURL *)url {
    dispatch_main_async_safe(^{
        if (operation && !operation.isCancelled && completionBlock) {
            completionBlock(videoPath, error, cacheType, url);
        }
    });
}
- (void)stopPlay{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    dispatch_main_async_safe(^{
        if (self.showViews.count) {
            for (UIView *view in self.showViews) {
                [view performSelector:NSSelectorFromString(@"cy_removeVideoLayerViewAndIndicatorView")];
                [view performSelector:NSSelectorFromString(@"cy_hideActivityIndicatorView")];
                [view performSelector:NSSelectorFromString(@"cy_hideProgressView")];
            }
            [self.showViews removeAllObjects];
        }
        [[CYVideoPlayerTool sharedTool] stopPlay];
    });
#pragma clang diagnostic pop
}

- (void)pause{
    [[CYVideoPlayerTool sharedTool] pause];
}

- (void)resume{
    [[CYVideoPlayerTool sharedTool] resume];
}

- (void)setPlayerMute:(BOOL)mute{
    if ([CYVideoPlayerTool sharedTool].currentPlayVideoItem) {
        [[CYVideoPlayerTool sharedTool] setMute:mute];
    }
    self.mute = mute;
}

- (BOOL)playerIsMute{
    return self.mute;
}
#pragma mark- CYVideoPlayerToolDelegate   视频播放的相关代理
-(void)playVideoTool:(CYVideoPlayerTool *)videoTool playingStatuDidChanged:(CYVideoPlayerPlayingStatus)playingStatus{
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayerManager:playingStatusDidChanged:)]) {
        [self.delegate videoPlayerManager:self playingStatusDidChanged:playingStatus];
    }
}
-(BOOL)playVideoTool:(CYVideoPlayerTool *)videoTool shouldAutoReplayVideoForURL:(NSURL *)videoURL{
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayerManager:shouldAutoReplayForURL:)]) {
        return [self.delegate videoPlayerManager:self shouldAutoReplayForURL:videoURL];
    }
    return YES;
}
#pragma mark - Private
//是否需要显示下载进度
- (BOOL)needDisplayDownloadingProgressViewWithDownloadingProgressValue:(CGFloat)downloadingProgress{
    BOOL respond = self.delegate && [self.delegate respondsToSelector:@selector(videoPlayerManager:downloadingProgressDidChanged:)];
    BOOL download = [self.delegate videoPlayerManager:self downloadingProgressDidChanged:downloadingProgress];
    return  respond && download;
}
//是否需要显示播放进度
- (BOOL)needDisplayPlayingProgressViewWithPlayingProgressValue:(CGFloat)playingProgress{
    BOOL respond = self.delegate && [self.delegate respondsToSelector:@selector(videoPlayerManager:playingProgressDidChanged:)];
    BOOL playing = [self.delegate videoPlayerManager:self playingProgressDidChanged:playingProgress];
    return  respond && playing;
}
//隐藏所有的活动指示器和进度条
- (void)hideAllIndicatorAndProgressViewsWithURL:(nullable NSURL *)url options:(CYVideoPlayerOptions)options{
    [self hideActivityViewWithURL:url options:options];
    [self hideProgressViewWithURL:url options:options];
}


- (void)hideActivityViewWithURL:(nullable NSURL *)url options:(CYVideoPlayerOptions)options{
    if (options & CYVideoPlayerShowActivityIndicatorView){
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        dispatch_main_async_safe(^{
            UIView *view = nil;
            for (UIView *v in self.showViews) {
                if (v.currentPlayingURL && [v.currentPlayingURL.absoluteString isEqualToString:url.absoluteString]) {
                    view = v;
                    break;
                }
            }
            if (view) {
                [view performSelector:NSSelectorFromString(@"cy_hideActivityIndicatorView")];
            }
        });
#pragma clang diagnostic pop
    }
}

- (void)hideProgressViewWithURL:(nullable NSURL *)url options:(CYVideoPlayerOptions)options{
    if (![self needDisplayPlayingProgressViewWithPlayingProgressValue:0] || ![self needDisplayDownloadingProgressViewWithDownloadingProgressValue:0]) {
        return;
    }
    
    if (options & CYVideoPlayerShowProgressView){
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        dispatch_main_async_safe(^{
            UIView *view = nil;
            for (UIView *v in self.showViews) {
                if (v.currentPlayingURL && [v.currentPlayingURL.absoluteString isEqualToString:url.absoluteString]) {
                    view = v;
                    break;
                }
            }
            if (view) {
                [view performSelector:NSSelectorFromString(@"cy_hideProgressView")];
            }
        });
    }
#pragma clang diagnostic pop
}
//刷新进度
- (void)progressRefreshWithURL:(nullable NSURL *)url options:(CYVideoPlayerOptions)options receiveSize:(NSUInteger)receiveSize exceptSize:(NSUInteger)expectedSize{
    if (![self needDisplayDownloadingProgressViewWithDownloadingProgressValue:(CGFloat)receiveSize/expectedSize]) {
        return;
    }
    if (options & CYVideoPlayerShowProgressView){
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        dispatch_main_async_safe(^{
            UIView *view = nil;
            for (UIView *v in self.showViews) {
                if (v.currentPlayingURL && [v.currentPlayingURL.absoluteString isEqualToString:url.absoluteString]) {
                    view = v;
                    break;
                }
            }
            if (view) {
                [view performSelector:NSSelectorFromString(@"cy_progressViewDownloadingStatusChangedWithProgressValue:") withObject:@((CGFloat)receiveSize/expectedSize)];
            }
        });
#pragma clang diagnostic pop
    }
}
//显示进度条和指示视图
- (void)showProgressViewAndActivityIndicatorViewForView:(UIView *)view options:(CYVideoPlayerOptions)options{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    dispatch_main_async_safe(^{
        BOOL needDisplayProgress = [self needDisplayDownloadingProgressViewWithDownloadingProgressValue:0] || [self needDisplayPlayingProgressViewWithPlayingProgressValue:0];
        
        if ((options & CYVideoPlayerShowProgressView) && needDisplayProgress) {
            [view performSelector:NSSelectorFromString(@"cy_showProgressView")];
        }
        if ((options & CYVideoPlayerShowActivityIndicatorView)) {
            [view performSelector:NSSelectorFromString(@"cy_showActivityIndicatorView")];
        }
    });
#pragma clang diagnostic pop
}

@end
