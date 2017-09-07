//
//  UIView+VideoCacheOperation.m
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/7.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import "UIView+VideoCacheOperation.h"
#import <objc/message.h>
static char videoLayerViewKey;
static char backgroundLayerKey;

@implementation UIView (VideoCacheOperation)
- (CALayer *)cy_backgroundLayer{
    CALayer *backLayer = objc_getAssociatedObject(self, &backgroundLayerKey);
    if (!backLayer) {
        backLayer = [CALayer new];
        backLayer.backgroundColor = [UIColor blackColor].CGColor;
        objc_setAssociatedObject(self, &backgroundLayerKey, backLayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return backLayer;
}
- (UIView *)cy_videoLayerView{
    UIView *view = objc_getAssociatedObject(self, &videoLayerViewKey);
    if (!view) {
        view = [UIView new];
        view.frame = self.bounds;
        view.backgroundColor = [UIColor clearColor];
        view.userInteractionEnabled = NO;
        objc_setAssociatedObject(self, &videoLayerViewKey, view, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return view;
}
@end
