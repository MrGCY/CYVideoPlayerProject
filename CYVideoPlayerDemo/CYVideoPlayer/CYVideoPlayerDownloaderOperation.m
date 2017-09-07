//
//  CYVideoPlayerDownloaderOperation.m
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/7.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import "CYVideoPlayerDownloaderOperation.h"
#import "CYVideoPlayerMacros.h"
#import "CYVideoPlayerManager.h"
#import "CYVideoPlayerCachePathManager.h"


NSString *const CYVideoPlayerDownloadStartNotification = @"www.cyvideplayer.download.start.notification";
NSString *const CYVideoPlayerDownloadReceiveResponseNotification = @"www.cyvideoplayer.download.received.response.notification";
NSString *const CYVideoPlayerDownloadStopNotification = @"www.cyvideplayer.download.stop.notification";
NSString *const CYVideoPlayerDownloadFinishNotification = @"www.cyvideplayer.download.finished.notification";

static NSString *const kProgressCallbackKey = @"www.cyvideplayer.progress.callback";
static NSString *const kErrorCallbackKey = @"www.cyvideplayer.error.callback";

typedef NSMutableDictionary<NSString *, id> CYCallbacksDictionary;

@interface CYVideoPlayerDownloaderOperation()

@property (strong, nonatomic, nonnull)NSMutableArray<CYCallbacksDictionary *> *callbackBlocks;
//是否正在执行
@property (assign, nonatomic, getter = isExecuting)BOOL executing;
//是否完成
@property (assign, nonatomic, getter = isFinished)BOOL finished;

// This is weak because it is injected by whoever manages this session. If this gets nil-ed out, we won't be able to run.
// 未知的网络会话 the task associated with this operation.
@property (weak, nonatomic, nullable) NSURLSession *unownedSession;

// 自己的网络会话 This is set if we're using not using an injected NSURLSession. We're responsible of invalidating this one.
@property (strong, nonatomic, nullable) NSURLSession *ownedSession;
//数据任务
@property (strong, nonatomic, readwrite, nullable) NSURLSessionTask *dataTask;
//等待队列
@property (strong, nonatomic, nullable) dispatch_queue_t barrierQueue;
//后台任务标识
@property (assign, nonatomic) UIBackgroundTaskIdentifier backgroundTaskId;

// 下载的数据
@property(nonatomic, assign)NSUInteger receiveredSize;

@end

@implementation CYVideoPlayerDownloaderOperation{
    BOOL responseFromCached;
}
@synthesize executing = _executing;
@synthesize finished = _finished;

- (nonnull instancetype)init{
    return [self initWithRequest:nil inSession:nil options:0];
}

#pragma mark - Public
- (nonnull instancetype)initWithRequest:(nullable NSURLRequest *)request
                              inSession:(nullable NSURLSession *)session
                                options:(CYVideoPlayerDownloaderOptions)options {
    if ((self = [super init])) {
        _request = [request copy];
        _options = options;
        _callbackBlocks = [NSMutableArray new];
        _executing = NO;
        _finished = NO;
        _expectedSize = 0;
        _unownedSession = session;
        responseFromCached = YES; // Initially wrong until `- URLSession:dataTask:willCacheResponse:completionHandler: is called or not called
        _barrierQueue = dispatch_queue_create("com.Mr.GCY.CYVideoPlayerDownloaderOperationBarrierQueue", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (nullable id)addHandlersForProgress:(nullable CYVideoPlayerDownloaderProgressBlock)progressBlock error:(nullable CYVideoPlayerDownloaderErrorBlock)errorBlock{
    
    CYCallbacksDictionary *callbacks = [NSMutableDictionary new];
    
    if (progressBlock) callbacks[kProgressCallbackKey] = [progressBlock copy];
    if (errorBlock) callbacks[kErrorCallbackKey] = [errorBlock copy];
    /*
     dispatch_barrier_sync和dispatch_barrier_async的共同点：
     1、都会等待在它前面插入队列的任务（1、2、3）先执行完
     2、都会等待他们自己的任务（0）执行完再执行后面的任务（4、5、6）
     
     dispatch_barrier_sync和dispatch_barrier_async的不共同点：
     在将任务插入到queue的时候，dispatch_barrier_sync需要等待自己的任务（0）结束之后才会继续程序，然后插入被写在它后面的任务（4、5、6），然后执行后面的任务
     而dispatch_barrier_async将自己的任务（0）插入到queue之后，不会等待自己的任务结束，它会继续把后面的任务（4、5、6）插入到queue
     
     所以，dispatch_barrier_async的不等待（异步）特性体现在将任务插入队列的过程，它的等待特性体现在任务真正执行的过程。
     */
    dispatch_barrier_async(self.barrierQueue, ^{
        [self.callbackBlocks addObject:callbacks];
    });
    
    return callbacks;
}
//取消线程对应的下载操作
- (BOOL)cancel:(nullable id)token {
    __block BOOL shouldCancel = NO;
    dispatch_barrier_sync(self.barrierQueue, ^{
        [self.callbackBlocks removeObjectIdenticalTo:token];
        if (self.callbackBlocks.count == 0) {
            shouldCancel = YES;
        }
    });
    if (shouldCancel) {
        [self cancel];
    }
    return shouldCancel;
}


#pragma mark - NSOperation Required
//重写start 方法
//开启任务
- (void)start {
    @synchronized (self) {
        if (self.isCancelled) {
            self.finished = YES;
            [self reset];
            return;
        }
        Class UIApplicationClass = NSClassFromString(@"UIApplication");
        BOOL hasApplication = UIApplicationClass && [UIApplicationClass respondsToSelector:@selector(sharedApplication)];
        if (hasApplication && [self shouldContinueWhenAppEntersBackground]) {
            __weak __typeof__ (self) wself = self;
            UIApplication * app = [UIApplicationClass performSelector:@selector(sharedApplication)];
            self.backgroundTaskId = [app beginBackgroundTaskWithExpirationHandler:^{
                __strong __typeof (wself) sself = wself;
                //当进入后台超出期望时间后后台需要取消该线程任务 并记录任务标记
                if (sself) {
                    [sself cancel];
                    [app endBackgroundTask:sself.backgroundTaskId];
                    sself.backgroundTaskId = UIBackgroundTaskInvalid;
                }
            }];
        }else{
            return;
        }
        
        NSURLSession *session = self.unownedSession;
        //判断从上一层是否有传入NSURLSession
        if (!self.unownedSession) {
            //没有就创建
            //创建会话配置
            NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
            sessionConfig.timeoutIntervalForRequest = 15;
            
            /**
             *  Create the session for this task
             *  We send nil as delegate queue so that the session creates a serial operation queue for performing all delegate
             *  method calls and completion handler calls.
             */
            //创建会话  并设置代理
            self.ownedSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
            session = self.ownedSession;
        }
        //创建会话任务对象
        self.dataTask = [session dataTaskWithRequest:self.request];
        self.executing = YES;
    }
    //开始下载
    [self.dataTask resume];
    
    if (self.dataTask) {
        
        dispatch_main_async_safe(^{
            //开始下载任务
            [[NSNotificationCenter defaultCenter] postNotificationName:CYVideoPlayerDownloadStartNotification object:self];
        });
        @autoreleasepool {
            for (CYVideoPlayerDownloaderProgressBlock progressBlock in [self callbacksForKey:kProgressCallbackKey]) {
                progressBlock(nil, 0, NSURLResponseUnknownLength, nil, self.request.URL);
            }
        }
    }
    else {
        [self callErrorBlocksWithError:[NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Connection can't be initialized"}]];
    }
    
    if (self.backgroundTaskId != UIBackgroundTaskInvalid) {
        UIApplication * app = [UIApplication performSelector:@selector(sharedApplication)];
        [app endBackgroundTask:self.backgroundTaskId];
        self.backgroundTaskId = UIBackgroundTaskInvalid;
    }
}
//取消任务
- (void)cancel {
    @synchronized (self) {
        [self cancelInternal];
    }
}


#pragma mark - NSURLSessionDataDelegate
// 1.接收到服务器响应的时候
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler{
    
    //'304 Not Modified' is an exceptional one.
    if (![response respondsToSelector:@selector(statusCode)] || (((NSHTTPURLResponse *)response).statusCode < 400 && ((NSHTTPURLResponse *)response).statusCode != 304)) {
        
        NSInteger expected = MAX((NSInteger)response.expectedContentLength, 0);
        self.expectedSize = expected;
        
        @autoreleasepool {
            for (CYVideoPlayerDownloaderProgressBlock progressBlock in [self callbacksForKey:kProgressCallbackKey]) {
                
                // May the free size of the device less than the expected size of the video data.
                //判断本地空间是否够用
                if (![[CYVideoPlayerCache sharedCache] haveFreeSizeToCacheFileWithSize:expected]) {
                    if (completionHandler) {
                        completionHandler(NSURLSessionResponseCancel);
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:CYVideoPlayerDownloadStopNotification object:self];
                    });
                    
                    [self callErrorBlocksWithError:[NSError errorWithDomain:@"No enough size of device to cache the video data" code:0 userInfo:nil]];
                    
                    [self done];
                    
                    return;
                }
                else{
                    NSString *key = [[CYVideoPlayerManager sharedManager] cacheKeyForURL:self.request.URL];
                    progressBlock(nil, 0, expected, [CYVideoPlayerCachePathManager videoCacheTemporaryPathForKey:key], response.URL);
                }
            }
        }
        
        if (completionHandler) {
            completionHandler(NSURLSessionResponseAllow);
        }
        self.response = response;
        dispatch_main_async_safe(^{
            [[NSNotificationCenter defaultCenter] postNotificationName:CYVideoPlayerDownloadReceiveResponseNotification object:self];
        });
    }
    else {
        NSUInteger code = ((NSHTTPURLResponse *)response).statusCode;
        
        // This is the case when server returns '304 Not Modified'. It means that remote video is not changed.
        // In case of 304 we need just cancel the operation and return cached video from the cache.
        if (code == 304) {
            [self cancelInternal];
        } else {
            [self.dataTask cancel];
        }
        
        dispatch_main_async_safe(^{
            [[NSNotificationCenter defaultCenter] postNotificationName:CYVideoPlayerDownloadStopNotification object:self];
        });
        
        [self callErrorBlocksWithError:[NSError errorWithDomain:NSURLErrorDomain code:((NSHTTPURLResponse *)response).statusCode userInfo:nil]];
        
        [self done];
    }
}
// 2.接收到服务器返回数据的时候调用,会调用多次
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    NSString *key = [[CYVideoPlayerManager sharedManager] cacheKeyForURL:self.request.URL];
    self.receiveredSize += data.length;
    
    @autoreleasepool {
        for (CYVideoPlayerDownloaderProgressBlock progressBlock in [self callbacksForKey:kProgressCallbackKey]) {
            progressBlock(data, self.receiveredSize, self.expectedSize, [CYVideoPlayerCachePathManager videoCacheTemporaryPathForKey:key], self.request.URL);
        }
    }
}
// 3.请求结束的时候调用(成功|失败),如果失败那么error有值
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    @synchronized(self) {
        self.dataTask = nil;
        dispatch_main_async_safe(^{
            //停止下载
            [[NSNotificationCenter defaultCenter] postNotificationName:CYVideoPlayerDownloadStopNotification object:self];
            if (!error) {
                //完成下载通知
                [[NSNotificationCenter defaultCenter] postNotificationName:CYVideoPlayerDownloadFinishNotification object:self];
            }
        });
    }
    
    if (!error) {
        if (self.completionBlock) {
            self.completionBlock();
        }
    }else{
        //错误信息
        dispatch_main_async_safe(^{
            [[NSNotificationCenter defaultCenter] postNotificationName:CYVideoPlayerDownloadStopNotification object:self];
        });
        [self callErrorBlocksWithError:error];
    }
    //完成操作
    [self done];
}


//证书授权相关
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    __block NSURLCredential *credential = nil;
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        if (!(self.options & CYVideoPlayerDownloaderAllowInvalidSSLCertificates)) {
            disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        } else {
            credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            disposition = NSURLSessionAuthChallengeUseCredential;
        }
    } else {
        if (challenge.previousFailureCount == 0) {
            if (self.credential) {
                credential = self.credential;
                disposition = NSURLSessionAuthChallengeUseCredential;
            } else {
                disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
            }
        } else {
            disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
        }
    }
    
    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler {
    
    // If this method is called, it means the response wasn't read from cache
    responseFromCached = NO;
    NSCachedURLResponse *cachedResponse = proposedResponse;
    
    if (self.request.cachePolicy == NSURLRequestReloadIgnoringLocalCacheData) {
        // Prevents caching of responses
        cachedResponse = nil;
    }
    if (completionHandler) {
        completionHandler(cachedResponse);
    }
}


#pragma mark - Private

- (void)cancelInternal {
    if (self.isFinished) return;
    [super cancel];
    if (self.dataTask) {
        [self.dataTask cancel];
        dispatch_main_async_safe(^{
            //停止下载任务
            [[NSNotificationCenter defaultCenter] postNotificationName:CYVideoPlayerDownloadStopNotification object:self];
        });
        
        // As we cancelled the connection, its callback won't be called and thus won't
        // maintain the isFinished and isExecuting flags.
        if (self.isExecuting) self.executing = NO;
        if (!self.isFinished) self.finished = YES;
    }
    //重置
    [self reset];
}

- (void)done {
    self.finished = YES;
    self.executing = NO;
    [self reset];
}
//获取错误信息
- (void)callErrorBlocksWithError:(nullable NSError *)error {
    NSArray<id> *errorBlocks = [self callbacksForKey:kErrorCallbackKey];
    dispatch_main_async_safe(^{
        for (CYVideoPlayerDownloaderErrorBlock errorBlock in errorBlocks) {
            errorBlock(error);
        }
    });
}
//获取key对应的block对象
- (nullable NSArray<id> *)callbacksForKey:(NSString *)key {
    
    __block NSMutableArray<id> *callbacks = nil;
    
    dispatch_sync(self.barrierQueue, ^{
        callbacks = [[self.callbackBlocks valueForKey:key] mutableCopy];
        [callbacks removeObjectIdenticalTo:[NSNull null]];
    });
    return [callbacks copy];    // strip mutability here
}
//是否在后台继续下载
- (BOOL)shouldContinueWhenAppEntersBackground {
    return self.options & CYVideoPlayerDownloaderContinueInBackground;
}
//重置下载
- (void)reset {
    dispatch_barrier_async(self.barrierQueue, ^{
        [self.callbackBlocks removeAllObjects];
    });
    self.dataTask = nil;
    if (self.ownedSession) {
        [self.ownedSession invalidateAndCancel];
        self.ownedSession = nil;
    }
}
//在.m文件里面我们将重写finished executing两个属性。我们重写set方法，手动发送keyPath的KVO通知
//完成
- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}
//正在执行
- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)isConcurrent {
    return YES;
}

@end
