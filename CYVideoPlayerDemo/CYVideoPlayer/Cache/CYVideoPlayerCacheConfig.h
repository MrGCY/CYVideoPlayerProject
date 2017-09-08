//
//  CYVideoPlayerCacheConfig.h
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/7.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CYVideoPlayerCacheConfig : NSObject
/**
最长缓存时间   单位是秒
 */
@property (assign, nonatomic) NSInteger maxCacheAge;

/**
最大缓存大小  超过后缓存将自动清空
 */
@property (assign, nonatomic) NSUInteger maxCacheSize;

/**
 *  是否不使能iCloud 默认是YES
 */
@property (assign, nonatomic) BOOL shouldDisableiCloud;
@end
