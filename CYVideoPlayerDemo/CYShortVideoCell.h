//
//  CYShortVideoCell.h
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/11.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import <UIKit/UIKit.h>
/**
 * The style of cell cannot stop in screen center.
 * 播放滑动不可及cell的类型
 */
typedef NS_OPTIONS(NSInteger, CYPlayUnreachCellStyle) {
    CYPlayUnreachCellStyleNone = 1 << 0,  // normal 播放滑动可及cell
    CYPlayUnreachCellStyleUp = 1 << 1,    // top 顶部不可及
    CYPlayUnreachCellStyleDown = 1<< 2    // bottom 底部不可及
};
@interface CYShortVideoCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *coverImg;

/** videoPath */
@property(nonatomic, strong)NSString *videoPath;

/** indexPath */
@property(nonatomic, strong)NSIndexPath *indexPath;

/** cell类型 */
@property(nonatomic, assign)CYPlayUnreachCellStyle cellStyle;

@end
