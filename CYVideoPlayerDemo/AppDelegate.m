//
//  AppDelegate.m
//  CYVideoPlayerDemo
//
//  Created by Mr.GCY on 2017/9/6.
//  Copyright © 2017年 Mr.GCY. All rights reserved.
//

#import "AppDelegate.h"
#import "CYShortVideoViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    
//    UINavigationController *nav_home = [[UINavigationController alloc]initWithRootViewController:[JPVideoPlayerDemoVC_home new]];
//    nav_home.tabBarItem.image = [[UIImage imageNamed:@"player"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
//    nav_home.tabBarItem.selectedImage = [[UIImage imageNamed:@"player_select"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
//    nav_home.title = @"Player";
//    
//    UINavigationController *nav_setting = [[UINavigationController alloc]initWithRootViewController:[JPVideoPlayerDemoVC_Setting new]];
//    nav_setting.tabBarItem.image = [[UIImage imageNamed:@"setting"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
//    nav_setting.tabBarItem.selectedImage = [[UIImage imageNamed:@"setting_select"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
//    nav_setting.title = @"Setting";
//    
//    UITabBarController *tabVC = [[UITabBarController alloc]init];
//    tabVC.viewControllers = @[nav_home, nav_setting];
//    tabVC.tabBar.tintColor = [UIColor colorWithRed:64.0/255.0 green:146.0/255.0 blue:75.0/255.0 alpha:1];
    self.window.rootViewController = [CYShortVideoViewController new];
    [self.window makeKeyAndVisible];
//    [[UIApplication sharedApplication]setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
