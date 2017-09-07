//
//  CYVideoPlayerTool.m
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/6.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import "CYVideoPlayerTool.h"
#import "CYVideoPlayerResourceLoader.h"
#import "UIView+VideoCacheOperation.h"

@interface CYVideoPlayerToolItem()
/**
 * 视频播放的 URL
 */
@property(nonatomic, strong, nullable)NSURL *url;

/**
 * 播放视频的播放器.
 */
@property(nonatomic, strong, nullable)AVPlayer *player;

/**
 * 当前播放视频的 layer.
 */
@property(nonatomic, strong, nullable)AVPlayerLayer *currentPlayerLayer;

/**
 * 当前播放视频的 item资源
 */
@property(nonatomic, strong, nullable)AVPlayerItem *currentPlayerItem;

/**
 * 播放视频的 urlAsset.
 */
@property(nonatomic, strong, nullable)AVURLAsset *videoURLAsset;

/**
 * 视频展示的视图.
 */
@property(nonatomic, strong, nullable)UIView * unownShowView;

/**
 * 是否取消播放的标志位
 */
@property(nonatomic, assign, getter=isCancelled)BOOL cancelled;

/**
 * Error message.
 */
@property(nonatomic, copy, nullable)CYVideoPlayerPlayToolErrorBlock error;

/**
 * 视频资源缓存处理对象
 */
@property(nonatomic, strong, nullable)CYVideoPlayerResourceLoader * resourceLoader;

/**
 * 选择模式
 */
@property(nonatomic, assign)CYVideoPlayerOptions playerOptions;

/**
 * 当前正在播放视频地址的key
 */
@property(nonatomic, strong, nonnull)NSString *playingKey;

/**
 * 上一次播放的时间
 */
@property(nonatomic, assign)NSTimeInterval lastTime;

/**
 * 事件监听者
 */
@property(nonatomic, strong)id timeObserver;
@end

@implementation CYVideoPlayerToolItem
/**
 停止播放
 */
- (void)stopPlayVideo{
    self.cancelled = YES;
    [self reset];
}
/**
 暂停播放
 */
- (void)pausePlayVideo{
    if (!self.player) {
        return;
    }
    [self.player pause];
}
/**
 重新播放
 */
- (void)resumePlayVideo{
    if (!self.player) {
        return;
    }
    [self.player play];
}
/**
 重置播放器
 */
- (void)reset{
    // remove video layer from superlayer.
    if (self.unownShowView.cy_backgroundLayer.superlayer) {
        [self.currentPlayerLayer removeFromSuperlayer];
        [self.unownShowView.cy_backgroundLayer removeFromSuperlayer];
    }
    
    // 移除监听 observer.
    CYVideoPlayerTool * tool = [CYVideoPlayerTool sharedTool];
    [_currentPlayerItem removeObserver:tool forKeyPath:@"status"];
    [_currentPlayerItem removeObserver:tool forKeyPath:@"loadedTimeRanges"];
    [self.player removeTimeObserver:self.timeObserver];
    
    // 移除 player
    [self.player pause];
    [self.player cancelPendingPrerolls];
    self.player = nil;
    [self.videoURLAsset.resourceLoader setDelegate:nil queue:dispatch_get_main_queue()];
    self.currentPlayerItem = nil;
    self.currentPlayerLayer = nil;
    self.videoURLAsset = nil;
    self.resourceLoader = nil;
}
@end

static NSString *CYVideoPlayerURLScheme = @"SystemCannotRecognition";
static NSString *CYVideoPlayerURL = @"www.Mr-GCY.com";
@interface CYVideoPlayerTool()
/**
 * 视频进入后台前的播放状态
 */
@property(nonatomic, assign)CYVideoPlayerPlayingStatus playingStatus_beforeEnterBackground;
//保存所有的播放资源
@property(nonatomic, strong, nonnull)NSMutableArray<CYVideoPlayerToolItem *> *playVideoItems;
@property(nonatomic, strong, readwrite, nullable)CYVideoPlayerToolItem * currentPlayVideoItem;
@end
@implementation CYVideoPlayerTool

+(nonnull instancetype)sharedTool{
    static dispatch_once_t onceToken;
    static id instance;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}
-(instancetype)init{
    if (self = [super init]) {
        _playVideoItems = [NSMutableArray arrayWithCapacity:0];
    }
    return self;
}
//加载本地视频资源
- (nullable CYVideoPlayerToolItem *)playExistedVideoWithURL:(NSURL * _Nullable)url
                                         fullVideoCachePath:(NSString * _Nullable)fullVideoCachePath
                                                    options:(CYVideoPlayerOptions)options showOnView:(UIView * _Nullable)showView
                                            playingProgress:(CYVideoPlayerPlayToolPlayingProgressBlock _Nullable ) progress
                                                      error:(nullable CYVideoPlayerPlayToolErrorBlock)error{
    //判断已经缓存地址的全路径是否存在
    if (fullVideoCachePath.length==0) {
        if (error) error([NSError errorWithDomain:@"缓存路径不能使用" code:0 userInfo:nil]);
        return nil;
    }
    //判断视频展示的视图是否存在
    if (!showView) {
        if (error) error([NSError errorWithDomain:@"视频展示视图不能为空" code:0 userInfo:nil]);
        return nil;
    }
    //创建资源对象
    CYVideoPlayerToolItem *item = [CYVideoPlayerToolItem new];
    item.unownShowView = showView;
    NSURL *videoPathURL = [NSURL fileURLWithPath:fullVideoCachePath];
    //获取AVURLAsset 可以进行自己干预网络数据下载
    AVURLAsset *videoURLAsset = [AVURLAsset URLAssetWithURL:videoPathURL options:nil];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:videoURLAsset];
    {
        item.url = url;
        item.currentPlayerItem = playerItem;
        //添加播放状态的监听
        [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
        
        item.player = [AVPlayer playerWithPlayerItem:playerItem];
        item.currentPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:item.player];
        {
            NSString *videoGravity = nil;
            //设置视频布局模式  是填充 、比例适配 还是比例填充
            if (options & CYVideoPlayerLayerVideoGravityResizeAspect) {
                videoGravity = AVLayerVideoGravityResizeAspect;
            }
            else if (options & CYVideoPlayerLayerVideoGravityResize){
                videoGravity = AVLayerVideoGravityResize;
            }
            else if (options & CYVideoPlayerLayerVideoGravityResizeAspectFill){
                videoGravity = AVLayerVideoGravityResizeAspectFill;
            }
            //进行设置
            item.currentPlayerLayer.videoGravity = videoGravity;
        }
        //设置视频预览的大小
        item.unownShowView.cy_backgroundLayer.frame = CGRectMake(0, 0, showView.bounds.size.width, showView.bounds.size.height);
        item.currentPlayerLayer.frame = item.unownShowView.cy_backgroundLayer.bounds;
        item.error = error;
        //保存缓存的key
        item.playingKey = [[CYVideoPlayerManager sharedManager] cacheKeyForURL:url];
    }
    {
        // 添加视频播放的监听
        __weak typeof(item) wItem = item;
        [item.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 10.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time){
            __strong typeof(wItem) sItem = wItem;
            if (!sItem) return;
            
            float current = CMTimeGetSeconds(time);
            float total = CMTimeGetSeconds(sItem.currentPlayerItem.duration);
            if (current && progress) {
                progress(current / total);
            }
        }];
    }
    
    if (options & CYVideoPlayerMutedPlay) {
        //设置静音模式
        item.player.muted = YES;
    }
    @synchronized (self) {
        //添加播放资源
        [self.playVideoItems addObject:item];
    }
    self.currentPlayVideoItem = item;
    return item;
}
//播放在线视频 流媒体之类的
- (nullable CYVideoPlayerToolItem *)playOnlineVideoWithURL:(NSURL * _Nullable)url
                                        tempVideoCachePath:(NSString * _Nullable)tempVideoCachePath
                                                   options:(CYVideoPlayerOptions)options
                                       videoFileExceptSize:(NSUInteger)exceptSize
                                     videoFileReceivedSize:(NSUInteger)receivedSize
                                                showOnView:(UIView * _Nullable)showView
                                           playingProgress:(CYVideoPlayerPlayToolPlayingProgressBlock _Nullable )progress
                                                     error:(nullable CYVideoPlayerPlayToolErrorBlock)error{
    //判断需要缓存地址的全路径是否存在
    if (tempVideoCachePath.length==0) {
        if (error) error([NSError errorWithDomain:@"缓存路径不能使用" code:0 userInfo:nil]);
        return nil;
    }
    //判断视频展示的视图是否存在
    if (!showView) {
        if (error) error([NSError errorWithDomain:@"视频展示视图不能为空" code:0 userInfo:nil]);
        return nil;
    }
    // Re-create all all configuration agian.
    // Make the `resourceLoader` become the delegate of 'videoURLAsset', and provide data to the player.
    
    //创建资源对象
    CYVideoPlayerToolItem *item = [CYVideoPlayerToolItem new];
    item.unownShowView = showView;
    //创建视频网络资源加载对象
    CYVideoPlayerResourceLoader *resourceLoader = [CYVideoPlayerResourceLoader new];
    item.resourceLoader = resourceLoader;
    //AVAssetResourceLoader通过你提供的委托对象去调节AVURLAsset所需要的加载资源。而很重要的一点是，AVAssetResourceLoader仅在AVURLAsset不知道如何去加载这个URL资源时才会被调用，就是说你提供的委托对象在AVURLAsset不知道如何加载资源时才会得到调用。所以我们又要通过一些方法来曲线解决这个问题，把我们目标视频URL地址的scheme替换为系统不能识别的scheme。这样才会调用代理方法
    //处理一个不能加载的资源就会走 AVAssetResourceLoader的代理方法
    AVURLAsset *videoURLAsset = [AVURLAsset URLAssetWithURL:[self handleCannotRecognitionVideoURL] options:nil];
    [videoURLAsset.resourceLoader setDelegate:resourceLoader queue:dispatch_get_main_queue()];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:videoURLAsset];
    {
        item.url = url;
        item.currentPlayerItem = playerItem;
        [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
        
        item.player = [AVPlayer playerWithPlayerItem:playerItem];
        item.currentPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:item.player];
        {
            NSString *videoGravity = nil;
            if (options & CYVideoPlayerLayerVideoGravityResizeAspect) {
                videoGravity = AVLayerVideoGravityResizeAspect;
            }
            else if (options & CYVideoPlayerLayerVideoGravityResize){
                videoGravity = AVLayerVideoGravityResize;
            }
            else if (options & CYVideoPlayerLayerVideoGravityResizeAspectFill){
                videoGravity = AVLayerVideoGravityResizeAspectFill;
            }
            item.currentPlayerLayer.videoGravity = videoGravity;
        }
        {
            // add observer for video playing progress.
            __weak typeof(item) wItem = item;
            [item.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 10.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time){
                __strong typeof(wItem) sItem = wItem;
                if (!sItem) return;
                
                float current = CMTimeGetSeconds(time);
                float total = CMTimeGetSeconds(sItem.currentPlayerItem.duration);
                if (current && progress) {
                    progress(current / total);
                }
            }];
        }
        item.unownShowView.cy_backgroundLayer.frame = CGRectMake(0, 0, showView.bounds.size.width, showView.bounds.size.height);
        item.currentPlayerLayer.frame = item.unownShowView.cy_backgroundLayer.bounds;
        item.videoURLAsset = videoURLAsset;
        item.error = error;
        item.playerOptions = options;
        item.playingKey = [[CYVideoPlayerManager sharedManager] cacheKeyForURL:url];
    }
    self.currentPlayVideoItem = item;
    
    if (options & CYVideoPlayerMutedPlay) {
        item.player.muted = YES;
    }
    
    @synchronized (self) {
        [self.playVideoItems addObject:item];
    }
    self.currentPlayVideoItem = item;
    // play. 缓存视频资源
    [self.currentPlayVideoItem.resourceLoader didReceivedDataCacheInDiskByTempPath:tempVideoCachePath videoFileExceptSize:exceptSize videoFileReceivedSize:receivedSize];
    
    return item;
}
//得到一个不能识别的URL
- (NSURL *)handleCannotRecognitionVideoURL{
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[NSURL URLWithString:CYVideoPlayerURL] resolvingAgainstBaseURL:NO];
    components.scheme = CYVideoPlayerURLScheme;
    return [components URL];
}
@end
