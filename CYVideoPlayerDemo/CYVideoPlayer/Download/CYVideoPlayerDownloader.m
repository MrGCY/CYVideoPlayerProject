//
//  CYVideoPlayerDownloader.m
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/7.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import "CYVideoPlayerDownloader.h"
#import "CYVideoPlayerDownloaderOperation.h"

@implementation CYVideoPlayerDownloadToken

@end
@interface CYVideoPlayerDownloader()<NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (strong, nonatomic, nonnull) NSOperationQueue *downloadQueue;

@property (assign, nonatomic, nullable) Class operationClass;
//存放线程下载任务的数组
@property (strong, nonatomic, nonnull) NSMutableDictionary<NSURL *, CYVideoPlayerDownloaderOperation *> *URLOperations;

@property (strong, nonatomic, nullable) CYHTTPHeadersMutableDictionary *HTTPHeaders;

// This queue is used to serialize the handling of the network responses of all the download operation in a single queue
@property (nonatomic, nullable) dispatch_queue_t barrierQueue;

// The session in which data tasks will run
@property (strong, nonatomic) NSURLSession *session;

@end

@implementation CYVideoPlayerDownloader
+(nonnull instancetype)sharedDownloader{
    static dispatch_once_t onceToken;
    static id instance;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}
- (nonnull instancetype)init {
    return [self initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
}

- (nonnull instancetype)initWithSessionConfiguration:(nullable NSURLSessionConfiguration *)sessionConfiguration {
    if ((self = [super init])) {
        _operationClass = [CYVideoPlayerDownloaderOperation class];
        _downloadQueue = [NSOperationQueue new];
        _downloadQueue.maxConcurrentOperationCount = 3;
        _downloadQueue.name = @"com.Mr.GCY.CYVideoPlayerDownloader";
        _URLOperations = [NSMutableDictionary new];
        _HTTPHeaders = [@{@"Accept": @"video/mpeg"} mutableCopy];
        _barrierQueue = dispatch_queue_create("com.Mr.GCY.CYVideoPlayerDownloaderBarrierQueue", DISPATCH_QUEUE_CONCURRENT);
        _downloadTimeout = 15.0;
        sessionConfiguration.timeoutIntervalForRequest = _downloadTimeout;
        
        /**
         *  Create the session for this task
         *  We send nil as delegate queue so that the session creates a serial operation queue for performing all delegate
         *  method calls and completion handler calls.
         */
        // self.session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:nil];
    }
    return self;
}

- (void)dealloc {
    [self.session invalidateAndCancel];
    self.session = nil;
    
    [self.downloadQueue cancelAllOperations];
}


#pragma mark - Public
//设置请求头
- (void)setValue:(nullable NSString *)value forHTTPHeaderField:(nullable NSString *)field {
    if (value) {
        self.HTTPHeaders[field] = value;
    }
    else {
        [self.HTTPHeaders removeObjectForKey:field];
    }
}

- (nullable NSString *)valueForHTTPHeaderField:(nullable NSString *)field {
    return self.HTTPHeaders[field];
}
//下载视频操作
- (nullable CYVideoPlayerDownloadToken *)downloadVideoWithURL:(NSURL *)url
                                                      options:(CYVideoPlayerDownloaderOptions)options
                                                     progress:(CYVideoPlayerDownloaderProgressBlock)progressBlock
                                                    completed:(CYVideoPlayerDownloaderErrorBlock)errorBlock{
    
    __weak typeof(self) weakSelf = self;
    
    return [self addProgressCallback:progressBlock completedBlock:errorBlock forURL:url createCallback:^CYVideoPlayerDownloaderOperation *{
        
        __strong __typeof (weakSelf) sself = weakSelf ;
        NSTimeInterval timeoutInterval = sself.downloadTimeout;
        if (timeoutInterval == 0.0) {
            timeoutInterval = 15.0;
        }
        
        // In order to prevent from potential duplicate caching (NSURLCache + JPVideoPlayerCache) we disable the cache for image requests if told otherwise.
        NSURLComponents *actualURLComponents = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
        actualURLComponents.scheme = url.scheme;
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[actualURLComponents URL] cachePolicy:(NSURLRequestReloadIgnoringLocalCacheData) timeoutInterval:timeoutInterval];
        
        request.HTTPShouldHandleCookies = (options & CYVideoPlayerDownloaderHandleCookies);
        request.HTTPShouldUsePipelining = YES;
        if (sself.headersFilter) {
            request.allHTTPHeaderFields = sself.headersFilter(url, [sself.HTTPHeaders copy]);
        }
        //创建下载任务对列
        CYVideoPlayerDownloaderOperation *operation = [[sself.operationClass alloc] initWithRequest:request inSession:sself.session options:options];
        
        if (sself.urlCredential) {
            operation.credential = sself.urlCredential;
        }
        else if (sself.username && sself.password) {
            operation.credential = [NSURLCredential credentialWithUser:sself.username password:sself.password persistence:NSURLCredentialPersistenceForSession];
        }
        
        [sself.downloadQueue addOperation:operation];
        
        return operation;
    }];
}
//取消下载操作
- (void)cancel:(CYVideoPlayerDownloadToken *)token{
    dispatch_barrier_async(self.barrierQueue, ^{
        CYVideoPlayerDownloaderOperation *operation = self.URLOperations[token.url];
        //取消对应的线程下载操作
        BOOL canceled = [operation cancel:token.downloadOperationCancelToken];
        if (canceled) {
            [self.URLOperations removeObjectForKey:token.url];
        }
    });
}
//取消所有下载操作
- (void)cancelAllDownloads {
    [self.downloadQueue cancelAllOperations];
}


#pragma mark - Private
//添加下载任务
- (nullable CYVideoPlayerDownloadToken *)addProgressCallback:(CYVideoPlayerDownloaderProgressBlock)progressBlock completedBlock:(CYVideoPlayerDownloaderErrorBlock)errorBlock forURL:(nullable NSURL *)url createCallback:(CYVideoPlayerDownloaderOperation *(^)())createCallback {
    
    // The URL will be used as the key to the callbacks dictionary so it cannot be nil. If it is nil immediately call the completed block with no video or data.
    if (url == nil) {
        if (errorBlock) {
            errorBlock([NSError errorWithDomain:@"Please check the URL, because it is nil" code:0 userInfo:nil]);
        }
        return nil;
    }
    
    __block CYVideoPlayerDownloadToken *token = nil;
    //一个一个下载
    dispatch_barrier_sync(self.barrierQueue, ^{
        CYVideoPlayerDownloaderOperation *operation = self.URLOperations[url];
        if (!operation) {
            //获取下载操作
            operation = createCallback();
            //保存下载操作
            self.URLOperations[url] = operation;
            
            __weak CYVideoPlayerDownloaderOperation *woperation = operation;
            operation.completionBlock = ^{
                CYVideoPlayerDownloaderOperation *soperation = woperation;
                if (!soperation) return;
                if (self.URLOperations.allKeys.count>0) {
                    if (self.URLOperations[url] == soperation) {
                        //下载完成移除操作
                        [self.URLOperations removeObjectForKey:url];
                    };
                }
            };
        }
        id downloadOperationCancelToken = [operation addHandlersForProgress:progressBlock error:errorBlock];
        token = [CYVideoPlayerDownloadToken new];
        token.url = url;
        token.downloadOperationCancelToken = downloadOperationCancelToken;
    });
    
    return token;
}
@end
