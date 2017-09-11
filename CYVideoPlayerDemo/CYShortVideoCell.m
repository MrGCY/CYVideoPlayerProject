//
//  CYShortVideoCell.m
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/11.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import "CYShortVideoCell.h"
#import "UIView+VideoCache.h"
@interface CYShortVideoCell()<CYVideoPlayerDelegate>

@end
@implementation CYShortVideoCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.coverImg.cy_videoPlayerDelegate = self;
}
- (void)setIndexPath:(NSIndexPath *)indexPath{
    _indexPath = indexPath;
    
    if (indexPath.row%2) {
        self.coverImg.image = [UIImage imageNamed:@"placeholder1"];
    }
    else{
        self.coverImg.image = [UIImage imageNamed:@"placeholder2"];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
#pragma mark- CYVideoPlayerDelegate
- (BOOL)videoPlayerManager:(CYVideoPlayerManager *)videoPlayerManager shouldAutoReplayForURL:(NSURL *)videoURL{
    // do something here.
    return YES;
}

- (BOOL)videoPlayerManager:(CYVideoPlayerManager *)videoPlayerManager shouldDownloadVideoForURL:(NSURL *)videoURL{
    // do something here.
    return YES;
}
@end
