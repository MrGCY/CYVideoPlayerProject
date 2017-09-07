//
//  ViewController.m
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/6.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import "ViewController.h"
#import "CYVideoPlayerManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[CYVideoPlayerManager sharedManager] cy_loadVideoWithURL:[NSURL URLWithString:@"http://120.25.226.186:32812/resources/videos/minion_01.mp4"] showOnView:self.view options:CYVideoPlayerContinueInBackground | CYVideoPlayerLayerVideoGravityResize playingProgress:nil downloadProgress:nil completed:^(NSString * _Nullable fullVideoCachePath, NSError * _Nullable error, CYVideoPlayerCacheType cacheType, NSURL * _Nullable videoURL) {
        
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
