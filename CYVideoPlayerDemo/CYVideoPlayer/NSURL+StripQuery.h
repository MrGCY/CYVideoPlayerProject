//
//  NSURL+StripQuery.h
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/7.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (StripQuery)
//获取一个除掉？的url
- (NSString *)absoluteStringByStrippingQuery;
@end
