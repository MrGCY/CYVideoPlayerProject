//
//  CYVideoPlayerMacros.h
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/7.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#ifndef dispatch_main_async_safe
#define dispatch_main_async_safe(block)\
if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(dispatch_get_main_queue())) == 0) {\
block();\
} else {\
dispatch_async(dispatch_get_main_queue(), block);\
}
#endif


#ifdef DEBUG
#define CYLog(FORMAT, ...); fprintf(stderr,"%s\n",[[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
#define CYLog(...);
#endif
