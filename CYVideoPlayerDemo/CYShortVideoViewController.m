//
//  CYShortVideoViewController.m
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/11.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import "CYShortVideoViewController.h"
#import "UIView+VideoCache.h"
#import "CYShortVideoCell.h"
#import "UITableView+PlayVideo.h"

#define identifCYShortVideoCell @"CYShortVideoCell"

@interface CYShortVideoViewController ()<UITableViewDelegate,UITableViewDataSource>
/**
 * Arrary of video paths.
 * 播放路径数组集合.
 */
@property(nonatomic, strong, nonnull)NSArray *pathStrings;

/**
 * For calculate the scroll derection of tableview, we need record the offset-Y of tableview when begain drag.
 * 刚开始拖拽时scrollView的偏移量Y值, 用来判断滚动方向.
 */
@property(nonatomic, assign)CGFloat offsetY_last;

@property (nonatomic,strong) UITableView * tableView;
@end

@implementation CYShortVideoViewController
#pragma mark- 生命周期
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupSubViews];
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    // 用来防止选中 cell push 到下个控制器时, tableView 再次调用 scrollViewDidScroll 方法, 造成 playingCell 被置空.
    self.tableView.delegate = self;
    if (!self.tableView.playingCell) {
        // Find the first cell need to play video in visiable cells.
        // 在可见cell中找第一个有视频的进行播放.
        [self.tableView playVideoInVisiableCells];
    }else{
        NSURL *url = [NSURL URLWithString:self.tableView.playingCell.videoPath];
        [self.tableView.playingCell.coverImg cy_playVideoWithURL:url];
    }
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    // 用来防止选中 cell push 到下个控制器时, tableView 再次调用 scrollViewDidScroll 方法, 造成 playingCell 被置空.
    self.tableView.delegate = nil;
    if (self.tableView.playingCell) {
        [self.tableView.playingCell.coverImg cy_stopPlay];
    }
}

#pragma mark- 初始化视图
-(void)setupSubViews{
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];
}
#pragma mark- 懒加载数据
-(UITableView *)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.pagingEnabled = YES;
        [_tableView registerNib:[UINib nibWithNibName:identifCYShortVideoCell bundle:nil] forCellReuseIdentifier:identifCYShortVideoCell];
    }
    return _tableView;
}
-(NSArray *)pathStrings{
    if (!_pathStrings) {
        _pathStrings = @[
                             //                         // location video path.
                             //                         url.absoluteString,
                             
                             // This url will redirect.
                             @"http://v.polyv.net/uc/video/getMp4?vid=9c9f71f62d5f24a7f9c6273e469a71a0_9",
                             
                             @"http://lavaweb-10015286.video.myqcloud.com/%E5%B0%BD%E6%83%85LAVA.mp4",
                             @"http://lavaweb-10015286.video.myqcloud.com/lava-guitar-creation-2.mp4",
                             @"http://lavaweb-10015286.video.myqcloud.com/hong-song-mei-gui-mu-2.mp4",
                             @"http://lavaweb-10015286.video.myqcloud.com/ideal-pick-2.mp4",
                             
                             // This path is a https.
                             // "https://bb-bang.com:9002/Test/Vedio/20170110/f49601b6bfe547e0a7d069d9319388f4.mp4",
                             // "http://123.103.15.1JPVideoPlayerDemoNavAndStatusTotalHei:8880/myVirtualImages/14266942.mp4",
                             
                             // This video saved in amazon, maybe load sowly.
                             // "http://vshow.s3.amazonaws.com/file147801253818487d5f00e2ae6e0194ab085fe4a43066c.mp4",
                             @"http://120.25.226.186:32812/resources/videos/minion_01.mp4",
                             @"http://120.25.226.186:32812/resources/videos/minion_02.mp4",
                             @"http://120.25.226.186:32812/resources/videos/minion_03.mp4",
                             @"http://120.25.226.186:32812/resources/videos/minion_04.mp4",
                             @"http://120.25.226.186:32812/resources/videos/minion_05.mp4",
                             @"http://120.25.226.186:32812/resources/videos/minion_06.mp4",
                             @"http://120.25.226.186:32812/resources/videos/minion_07.mp4",
                             @"http://120.25.226.186:32812/resources/videos/minion_08.mp4",
                             
                             // To simulate the cell have no video to play.
                             // "",
                             @"http://120.25.226.186:32812/resources/videos/minion_10.mp4",
                             @"http://120.25.226.186:32812/resources/videos/minion_11.mp4",
                             @"http://lavaweb-10015286.video.myqcloud.com/%E5%B0%BD%E6%83%85LAVA.mp4",
                             @"http://lavaweb-10015286.video.myqcloud.com/lava-guitar-creation-2.mp4",
                             @"http://lavaweb-10015286.video.myqcloud.com/hong-song-mei-gui-mu-2.mp4",
                             @"http://lavaweb-10015286.video.myqcloud.com/ideal-pick-2.mp4",
                             
                             // The vertical video.
                             @"https://bb-bang.com:9002/Test/Vedio/20170425/74ba5b355c6742c084414d4ebd520696.mp4",
                             
                             @"http://static.smartisanos.cn/common/video/video-jgpro.mp4",
                             @"http://static.smartisanos.cn/common/video/smartisanT2.mp4",
                             @"http://static.smartisanos.cn/common/video/m1-white.mp4",
                             @"http://static.smartisanos.cn/common/video/t1-ui.mp4",
                             @"http://static.smartisanos.cn/common/video/smartisant1.mp4",
                             @"http://static.smartisanos.cn/common/video/ammounition-video.mp4",
                             @"http://static.smartisanos.cn/common/video/proud-driver.mp4",
                             @"http://static.smartisanos.cn/common/video/proud-farmer.mp4"
                             ];

    }
    return _pathStrings;
}
#pragma mark- UITableViewDelegate,UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.pathStrings.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    CYShortVideoCell *cell = [tableView dequeueReusableCellWithIdentifier:identifCYShortVideoCell forIndexPath:indexPath];
    cell.videoPath = self.pathStrings[indexPath.row];
    cell.indexPath = indexPath;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (self.tableView.maxNumCannotPlayVideoCells > 0) {
        if (indexPath.row <= self.tableView.maxNumCannotPlayVideoCells-1) {
            // 上不可及
            cell.cellStyle = CYPlayUnreachCellStyleUp;
        }
        else if (indexPath.row >= self.pathStrings.count-self.tableView.maxNumCannotPlayVideoCells){
            // 下不可及
            cell.cellStyle = CYPlayUnreachCellStyleDown;
        }
        else{
            cell.cellStyle = CYPlayUnreachCellStyleNone;
        }
    }
    else{
        cell.cellStyle = CYPlayUnreachCellStyleNone;
    }
    
    return cell;
}
#pragma mark - TableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return tableView.bounds.size.height;
}

/**
 * Called on finger up if the user dragged. decelerate is true if it will continue moving afterwards
 * 松手时已经静止, 只会调用scrollViewDidEndDragging
 */
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    
    if (decelerate == NO)
        // scrollView已经完全静止
        [self.tableView handleScrollStop];
}

/**
 * Called on tableView is static after finger up if the user dragged and tableView is scrolling.
 * 松手时还在运动, 先调用scrollViewDidEndDragging, 再调用scrollViewDidEndDecelerating
 */
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    
    // scrollView已经完全静止
    [self.tableView handleScrollStop];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    // 处理滚动方向
    [self handleScrollDerectionWithOffset:scrollView.contentOffset.y];
    
    // Handle cyclic utilization
    // 处理循环利用
    [self.tableView handleQuickScroll];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    self.offsetY_last = scrollView.contentOffset.y;
}

- (void)handleScrollDerectionWithOffset:(CGFloat)offsetY{
    self.tableView.currentDerection = (offsetY-self.offsetY_last>0) ? CYVideoPlayerScrollDerectionUp : CYVideoPlayerScrollDerectionDown;
    self.offsetY_last = offsetY;
}

@end
