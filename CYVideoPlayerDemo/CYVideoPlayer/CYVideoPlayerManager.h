//
//  CYVideoPlayerManager.h
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/6.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef NS_OPTIONS(NSInteger, CYVideoPlayerOptions) {
    /**
     * 静音播放
     */
    CYVideoPlayerMutedPlay = 1 << 0,
    
    /**
     * 视频填充拉伸
     */
    CYVideoPlayerLayerVideoGravityResize = 1 << 1,
    
    /**
     * 视频按比例适配
     */
    CYVideoPlayerLayerVideoGravityResizeAspect = 1 << 2,
    
    /**
     * 视频按比例填充
     */
    CYVideoPlayerLayerVideoGravityResizeAspectFill = 1 << 9,

};
@interface CYVideoPlayerManager : NSObject

@end
