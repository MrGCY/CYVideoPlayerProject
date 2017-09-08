//
//  CYVideoPlayerResourceLoader.m
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/6.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import "CYVideoPlayerResourceLoader.h"
#import <MobileCoreServices/MobileCoreServices.h>

static NSString * CYVideoPlayerMimeType = @"video/mp4";
@interface CYVideoPlayerResourceLoader()
/**
 * 保存等待处理的视频地址
 */
@property (nonatomic, strong, nullable)NSMutableArray *pendingRequests;

/**
 * 视频总大小
 */
@property(nonatomic, assign)NSUInteger expectedSize;

/**
 * 视频在磁盘中的大小
 */
@property(nonatomic, assign)NSUInteger receivedSize;

/**
 * 视频缓存磁盘路径
 */
@property(nonatomic, strong, nullable)NSString *tempCacheVideoPath;
@end
@implementation CYVideoPlayerResourceLoader
#pragma mark- 初始化方法
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.pendingRequests = [NSMutableArray arrayWithCapacity:0];
    }
    return self;
}
#pragma mark - Public 获取缓存信息的方法
//视频缓存一半的处理
- (void)didReceivedDataCacheInDiskByTempPath:(NSString * _Nonnull)tempCacheVideoPath videoFileExceptSize:(NSUInteger)expectedSize videoFileReceivedSize:(NSUInteger)receivedSize{
    self.tempCacheVideoPath = tempCacheVideoPath;
    self.expectedSize = expectedSize;
    self.receivedSize = receivedSize;
    
    [self cy_internalPendingRequests];
}
//视频缓存完成的处理
- (void)didCachedVideoDataFinishedFromWebFullVideoCachePath:(NSString * _Nullable)fullVideoCachePath{
    self.tempCacheVideoPath = fullVideoCachePath;
    self.receivedSize = self.expectedSize;
    [self cy_internalPendingRequests];
}
#pragma mark - AVAssetResourceLoaderDelegate 代理方法
//AVAssetResourceLoader通过你提供的委托对象去调节AVURLAsset所需要的加载资源。而很重要的一点是，AVAssetResourceLoader仅在AVURLAsset不知道如何去加载这个URL资源时才会被调用，就是说你提供的委托对象在AVURLAsset不知道如何加载资源时才会得到调用。所以我们又要通过一些方法来曲线解决这个问题，把我们目标视频URL地址的scheme替换为系统不能识别的scheme。这样才会调用代理方法

//要求加载资源的代理方法，这时我们需要保存loadingRequest并对其所指定的数据进行读取或下载操作，当数据读取或下载完成，我们可以对loadingRequest进行完成操作。
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest{
    if (resourceLoader && loadingRequest){
//        loadingRequest传给我们。拿到请求以后，首先把请求用一个数组保存起来
        [self.pendingRequests addObject:loadingRequest];
        [self cy_internalPendingRequests];
    }
    return YES;
}
//取消加载资源的代理方法，这时我们需要取消loadingRequest所指定的数据的读取或下载操作。
- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest{
    [self.pendingRequests removeObject:loadingRequest];
}
#pragma mark - Private
//处理等待处理得请求    数据响应的处理
- (void)cy_internalPendingRequests{
    NSError *error;
    NSData *tempVideoData = [NSData dataWithContentsOfFile:_tempCacheVideoPath options:NSDataReadingMappedIfSafe error:&error];
    if (!error) {
        NSMutableArray *requestsCompleted = [NSMutableArray array];
        @autoreleasepool {
            for (AVAssetResourceLoadingRequest *loadingRequest in self.pendingRequests) {
                [self fillInContentInformation:loadingRequest.contentInformationRequest];
                
                BOOL didRespondFinished = [self respondWithDataForRequest:loadingRequest andTempVideoData:tempVideoData];
                if (didRespondFinished) {
                    [requestsCompleted addObject:loadingRequest];
                    [loadingRequest finishLoading];
                }
            }
        }
        if (requestsCompleted.count) {
            [self.pendingRequests removeObjectsInArray:[requestsCompleted copy]];
        }
    }
}
// 判断此次请求的数据是否处理完全, 和填充数据
- (BOOL)respondWithDataForRequest:(AVAssetResourceLoadingRequest *)loadingRequest andTempVideoData:(NSData * _Nullable)tempVideoData{
    
    AVAssetResourceLoadingDataRequest *dataRequest = loadingRequest.dataRequest;
    // 请求起始点
    NSUInteger startOffset = (NSUInteger)dataRequest.requestedOffset;
    if (dataRequest.currentOffset!=0) {
    //当前请求点
        startOffset = (NSUInteger)dataRequest.currentOffset;
    }
    startOffset = MAX(0, startOffset);
    
    // 没有需要请求的数据
    if (self.receivedSize<startOffset) {
        return NO;
    }
    //获取没有缓存完的数据
    NSUInteger unreadBytes = self.receivedSize - startOffset;
    unreadBytes = MAX(0, unreadBytes);
    NSUInteger numberOfBytesToRespondWith = MIN((NSUInteger)dataRequest.requestedLength, unreadBytes);
    NSRange respondRange = NSMakeRange(startOffset, numberOfBytesToRespondWith);
    //判断缓存好的长度是否大于等于下载的长度
    if (tempVideoData.length>=numberOfBytesToRespondWith) {
        //大于 说明已经下载完成 并把下载好的数据填充到下载请求上
        //读取数据并填充到loadingRequest
        [dataRequest respondWithData:[tempVideoData subdataWithRange:respondRange]];
    }
    
    long long endOffset = startOffset + dataRequest.requestedLength;
    
    if (_receivedSize >= endOffset) {
        return YES;
    }
    return NO;
}
//填充响应数据的过程如下：
//填写 contentInformationRequest的信息，注意contentLength需要填写下载的文件的总长度，contentType需要转换
- (void)fillInContentInformation:(AVAssetResourceLoadingContentInformationRequest * _Nonnull)contentInformationRequest{
    if (contentInformationRequest) {
        NSString * mimetype = CYVideoPlayerMimeType;
        CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef _Nonnull)(mimetype), NULL);
        contentInformationRequest.byteRangeAccessSupported = YES;
        contentInformationRequest.contentType = CFBridgingRelease(contentType);
        contentInformationRequest.contentLength = self.expectedSize;
    }
}

@end
