//
//  UIView+VideoCacheOperation.m
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/8.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import "UIView+VideoCacheOperation.h"
#import <objc/message.h>
#import "CYVideoPlayerOperationProtocol.h"
static char loadOperationKey;
static char currentPlayingURLKey;

typedef NSMutableDictionary<NSString *, id> CYOperationsDictionary;
@implementation UIView (VideoCacheOperation)
- (void)setCurrentPlayingURL:(NSURL *)currentPlayingURL{
    objc_setAssociatedObject(self, &currentPlayingURLKey, currentPlayingURL, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSURL *)currentPlayingURL{
    return objc_getAssociatedObject(self, &currentPlayingURLKey);
}

- (void)cy_setVideoLoadOperation:(id)operation forKey:(NSString *)key{
    if (key) {
        [self cy_cancelVideoLoadOperationWithKey:key];
        if (operation) {
            CYOperationsDictionary *operationDictionary = [self operationDictionary];
            operationDictionary[key] = operation;
        }
    }
}

- (void)cy_cancelVideoLoadOperationWithKey:(NSString *)key{
    // Cancel in progress downloader from queue.
    CYOperationsDictionary *operationDictionary = [self operationDictionary];
    id operations = operationDictionary[key];
    if (operations) {
        if ([operations isKindOfClass:[NSArray class]]) {
            for (id <CYVideoPlayerOperationProtocol> operation in operations) {
                if (operation) {
                    [operation cancel];
                }
            }
        }
        else if ([operations conformsToProtocol:@protocol(CYVideoPlayerOperationProtocol)]){
            [(id<CYVideoPlayerOperationProtocol>) operations cancel];
        }
        [operationDictionary removeObjectForKey:key];
    }
}

- (void)cy_removeVideoLoadOperationWithKey:(NSString *)key{
    if (key) {
        CYOperationsDictionary *operationDictionary = [self operationDictionary];
        [operationDictionary removeObjectForKey:key];
    }
}


#pragma mark - Private

- (CYOperationsDictionary *)operationDictionary {
    CYOperationsDictionary *operations = objc_getAssociatedObject(self, &loadOperationKey);
    if (operations) {
        return operations;
    }
    operations = [NSMutableDictionary dictionary];
    objc_setAssociatedObject(self, &loadOperationKey, operations, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return operations;
}

@end
