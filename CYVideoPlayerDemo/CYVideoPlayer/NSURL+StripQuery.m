//
//  NSURL+StripQuery.m
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/7.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import "NSURL+StripQuery.h"

@implementation NSURL (StripQuery)
//获取一个除掉？的url
- (NSString *)absoluteStringByStrippingQuery{
    NSString *absoluteString = [self absoluteString];
    NSUInteger queryLength = [[self query] length];
    NSString* strippedString = (queryLength ? [absoluteString substringToIndex:[absoluteString length] - (queryLength + 1)] : absoluteString);
    
    if ([strippedString hasSuffix:@"?"]) {
        strippedString = [strippedString substringToIndex:absoluteString.length-1];
    }
    return strippedString;
}
@end
