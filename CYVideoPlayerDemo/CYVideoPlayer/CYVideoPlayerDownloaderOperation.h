//
//  CYVideoPlayerDownloaderOperation.h
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/7.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CYVideoPlayerDownloader.h"
@interface CYVideoPlayerDownloaderOperation : NSOperation<NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

//开始下载
extern NSString * _Nonnull const CYVideoPlayerDownloadStartNotification;
//接受响应
extern NSString * _Nonnull const CYVideoPlayerDownloadReceiveResponseNotification;
//下载停止
extern NSString * _Nonnull const CYVideoPlayerDownloadStopNotification;
//下载完成
extern NSString * _Nonnull const CYVideoPlayerDownloadFinishNotification;


/**
 * 操作任务的请求
 */
@property (strong, nonatomic, readonly, nullable) NSURLRequest *request;

/**
 * 操作任务
 */
@property (strong, nonatomic, readonly, nullable) NSURLSessionTask *dataTask;

/**
请求认证
 */
@property (nonatomic, strong, nullable) NSURLCredential *credential;

/**
 * 下载操作
 */
@property (assign, nonatomic, readonly) CYVideoPlayerDownloaderOptions options;

/**
 * 数据总的大小
 */
@property (assign, nonatomic) NSUInteger expectedSize;

/**
 *操作的响应
 */
@property (strong, nonatomic, nullable) NSURLResponse *response;

/**
初始化下载请求操作
 */
- (nonnull instancetype)initWithRequest:(nullable NSURLRequest *)request inSession:(nullable NSURLSession *)session options:(CYVideoPlayerDownloaderOptions)options NS_DESIGNATED_INITIALIZER;

/**
添加下载操作
 */
- (nullable id)addHandlersForProgress:(nullable CYVideoPlayerDownloaderProgressBlock)progressBlock error:(nullable CYVideoPlayerDownloaderErrorBlock)errorBlock;

/**
取消操作
 */
- (BOOL)cancel:(nullable id)token;

@end
