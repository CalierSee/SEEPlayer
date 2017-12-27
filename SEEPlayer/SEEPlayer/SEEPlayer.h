//
//  SEEPlayer.h
//  SEEPlayer
//
//  Created by 三只鸟 on 2017/10/26.
//  Copyright © 2017年 景彦铭. All rights reserved.
// 支持边下边播功能

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(int, SEEPlayerStatus) {
    SEEPlayerStatusUnknow = 1 << 8, //未知
    SEEPlayerStatusFailed = 1 << 7, //播放失败
    SEEPlayerStatusPlay = 1 << 6, //播放
    SEEPlayerStatusPause = 1 << 5, //暂停
    SEEPlayerStatusBuffering = 1 << 4, //正在缓冲
    SEEPlayerStatusWaitingActivate = 1 << 3, //等待激活
};

@class SEEPlayer;

@protocol SEEPlayerDelegate <NSObject>
@required




@optional

/**
 即将变为全屏
 @param player 播放器
 */
- (void)playerWillBecomeFullScreen:(SEEPlayer *)player;
/**
 注销全屏显示
 @param player 播放器
 */
- (void)playerWillResignFullScreen:(SEEPlayer *)player;

/**
 返回视屏控件在小屏幕模式下的frame

 @param player 播放器
 @return frame
 */
- (CGRect)frameForSmallScreen:(SEEPlayer *)player;

@end


@interface SEEPlayer : UIView

@property (nonatomic,assign,readonly)SEEPlayerStatus status;

/**
 初始化

 @param url url地址
 */
- (instancetype)initWithURL:(NSString *)url;

//代理
@property (nonatomic,weak)id <SEEPlayerDelegate> delegate;

/**
 切换当前播放的URL

 @param url url字符串
 */
- (void)changeCurrentURL:(NSString *)url;

/**
 销毁播放器
 */
- (void)invalidate;

@end
