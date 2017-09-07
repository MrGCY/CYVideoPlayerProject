//
//  CYVideoPlayerDownloader.h
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/7.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef NS_OPTIONS(NSUInteger, CYVideoPlayerDownloaderOptions) {
    
    /**
     * Call completion block with nil video/videoData if the image was read from NSURLCache
     * (to be combined with `JPVideoPlayerDownloaderUseNSURLCache`).
     */
    CYVideoPlayerDownloaderIgnoreCachedResponse = 1 << 0,
    
    /**
     * In iOS 4+, continue the download of the video if the app goes to background. This is achieved by asking the system for
     * extra time in background to let the request finish. If the background task expires the operation will be cancelled.
     */
    CYVideoPlayerDownloaderContinueInBackground = 1 << 1,
    
    /**
     * Handles cookies stored in NSHTTPCookieStore by setting
     * NSMutableURLRequest.HTTPShouldHandleCookies = YES;
     */
    CYVideoPlayerDownloaderHandleCookies = 1 << 2,
    
    /**
     * Enable to allow untrusted SSL certificates.
     * Useful for testing purposes. Use with caution in production.
     */
    CYVideoPlayerDownloaderAllowInvalidSSLCertificates = 1 << 3,
    
    /**
     * Use this flag to display progress view when play video from web.
     */
    CYVideoPlayerDownloaderShowProgressView = 1 << 4,
    
    /**
     * 是否显示指示视图
     */
    CYVideoPlayerDownloaderShowActivityIndicatorView = 1 << 5,
};
//下载进度
typedef void(^CYVideoPlayerDownloaderProgressBlock)(NSData * _Nullable data, NSInteger receivedSize, NSInteger expectedSize, NSString *_Nullable tempCachedVideoPath, NSURL * _Nullable targetURL);
//错误信息
typedef void(^CYVideoPlayerDownloaderErrorBlock)(NSError *_Nullable error);
//定义请求头内容类型
typedef NSDictionary<NSString *, NSString *> CYHTTPHeadersDictionary;
typedef NSMutableDictionary<NSString *, NSString *> CYHTTPHeadersMutableDictionary;
//下载请求头
typedef CYHTTPHeadersDictionary * _Nullable (^CYVideoPlayerDownloaderHeadersFilterBlock)(NSURL * _Nullable url, CYHTTPHeadersDictionary * _Nullable headers);


@interface CYVideoPlayerDownloadToken : NSObject

@property (nonatomic, strong, nullable) NSURL *url;

@property (nonatomic, strong, nullable) id downloadOperationCancelToken;

@end



@interface CYVideoPlayerDownloader : NSObject

/**
 *  Set the default URL credential to be set for request operations.
 */
@property (strong, nonatomic, nullable) NSURLCredential *urlCredential;

/**
 * Set username
 */
@property (strong, nonatomic, nullable) NSString *username;

/**
 * Set password
 */
@property (strong, nonatomic, nullable) NSString *password;


@property (nonatomic, copy, nullable) CYVideoPlayerDownloaderHeadersFilterBlock headersFilter;

+(nonnull instancetype)sharedDownloader;
//下载视频操作
- (nullable CYVideoPlayerDownloadToken *)downloadVideoWithURL:(nullable NSURL *)url
                                                      options:(CYVideoPlayerDownloaderOptions)options
                                                     progress:(nullable CYVideoPlayerDownloaderProgressBlock )progressBlock
                                                    completed:(nullable CYVideoPlayerDownloaderErrorBlock )errorBlock;
//设置请求头信息
- (void)setValue:(nullable NSString *)value forHTTPHeaderField:(nullable NSString *)field;
/**
返回头信息
 */
- (nullable NSString *)valueForHTTPHeaderField:(nullable NSString *)field;

/**
设置超时时间
 */
@property (assign, nonatomic) NSTimeInterval downloadTimeout;
//取消某个固定的下载操作
- (void)cancel:(nullable CYVideoPlayerDownloadToken *)token;
/**
 * 取消所有下载操作
 */
- (void)cancelAllDownloads;
@end
