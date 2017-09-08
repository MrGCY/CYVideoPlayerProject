//
//  CYVideoPlayerCacheConfig.m
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/7.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import "CYVideoPlayerCacheConfig.h"
static const NSInteger kDefaultCacheMaxCacheAge = 60*60*24*7; // 1 周
static const NSInteger kDefaultCacheMaxSize = 1000*1000*1000; // 1 GB
@implementation CYVideoPlayerCacheConfig
- (instancetype)init{
    self = [super init];
    if (self) {
        _maxCacheAge =  kDefaultCacheMaxCacheAge;
        _maxCacheSize = kDefaultCacheMaxSize;
    }
    return self;
}
@end
