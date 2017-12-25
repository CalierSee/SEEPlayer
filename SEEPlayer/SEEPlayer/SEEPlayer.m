//
//  SEEPlayer.m
//  SEEPlayer
//
//  Created by 三只鸟 on 2017/10/26.
//  Copyright © 2017年 景彦铭. All rights reserved.
//

#import "SEEPlayer.h"
#import "SEEResourceLoader.h"
#import "SEEPlayer_Header.h"

typedef NS_ENUM(NSInteger,SEEPlayerScreenMode) {
    SEEPlayerScreenModeNormal,
    SEEPlayerScreenModeSmall,
    SEEPlayerScreenModeFull,
};


@interface SEEPlayer ()

/**
 播放状态
 */
@property (nonatomic,assign)SEEPlayerStatus status;

/**
 播放暂停按钮
 */
@property (nonatomic,strong)UIButton * playOrPauseButton;

/**
 顶部工具条
 */
@property (nonatomic,strong)UIView * topToolBar;
//标题label
@property (nonatomic,strong)UILabel * titleLabel;
//关闭按钮
@property (nonatomic,strong)UIButton * closeButton;

/**
 底部工具条
 */
@property (nonatomic,strong)UIView * bottomToolBar;
//进度条
@property (nonatomic,strong)UISlider * slider;
//时间label
@property (nonatomic,strong)UILabel * durationLabel;
@property (nonatomic,strong)UILabel * currentTimeLabel;
//全屏按钮
@property (nonatomic,strong)UIButton * fullScreenButton;

//当前是否为全屏状态
@property (nonatomic,assign)BOOL isFullScreen;

@property (nonatomic,assign)SEEPlayerScreenMode screenMode;

/**
 全屏小屏位置
 */
//原始父视图
@property (nonatomic,weak)UIView * originSuperView;
//原始大小
@property (nonatomic,assign)CGRect originFrame;
//全屏大小
@property (nonatomic,assign)CGRect windowFrame;

/**
 播放器
 */
@property (nonatomic,strong)AVPlayer * player;
//是否停止自动更新时间label
@property (nonatomic,assign)BOOL isStopUpdateCurrentTime;
//layer附着的view
//@property (nonatomic,strong)UIView * displayView;
//layer
@property (nonatomic,weak)AVPlayerLayer * displayLayer;
//时间变化监听回调对象
@property (nonatomic,strong)id observer;

@end

@implementation SEEPlayer {
    SEEResourceLoader * _resourceLoader;
    struct {
        int willBecomeFullScreen;
        int willResignFullScreen;
    }_responder;
}

- (instancetype)initWithURL:(NSString *)url {
    if (self = [super init]) {
        [self changeCurrentURL:url];
        
        //监听app状态
        //app即将睡眠
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(see_waitingActivate) name:UIApplicationWillResignActiveNotification object:nil];
        //app被激活
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(see_becomeActivate) name:UIApplicationDidBecomeActiveNotification object:nil];
        //获取到文件名通知
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(see_setTitle:) name:SEEDownloadManagerDidReceiveFileNameNotification object:nil];
        //监听屏幕旋转状态
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(see_orientationNotification:) name:UIDeviceOrientationDidChangeNotification object:nil];
        self.status = SEEPlayerStatusUnknow;
        //添加底部工具栏
        [self addSubview:self.bottomToolBar];
        //添加播放按钮
        [self addSubview:self.playOrPauseButton];
        //添加顶部工具栏
        [self addSubview:self.topToolBar];
    }
    return self;
}

- (void)dealloc {
    [self see_clearPlayer];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    SEEPlayerLog(@"播放器销毁");
}

#pragma mark - public method

- (void)invalidate {
    [self see_close:self.closeButton];
}

- (void)changeCurrentURL:(NSString *)url {
    [self see_clearPlayer];
    //创建资源下载器
    _resourceLoader = [[SEEResourceLoader alloc]initWithURL:[NSURL URLWithString:url]];
    
    //创建urlasset
    AVURLAsset * asset = [AVURLAsset URLAssetWithURL:_resourceLoader.url options:nil];
    //设置代理
    [asset.resourceLoader setDelegate:_resourceLoader queue:dispatch_get_main_queue()];
    //创建item
    AVPlayerItem * itme = [AVPlayerItem playerItemWithAsset:asset automaticallyLoadedAssetKeys:nil];
    //创建player
    if (_player.currentItem) {
        [self.player.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
        [self.player.currentItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [self.player.currentItem removeObserver:self forKeyPath:@"duration"];
        [_player replaceCurrentItemWithPlayerItem:nil];
    }
    _player = [[AVPlayer alloc]initWithPlayerItem:itme];
    _displayLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    [self.layer insertSublayer:_displayLayer atIndex:0];
    _displayLayer.backgroundColor = [UIColor blackColor].CGColor;
    //监听缓冲池数据是否可以顺利播放
    [itme addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    //监听缓冲池是否为空
    [itme addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    //监听播放总时长变化
    [itme addObserver:self forKeyPath:@"duration" options:NSKeyValueObservingOptionNew context:nil];
    if ([UIDevice currentDevice].systemVersion.doubleValue >= 10.0) {
        _player.automaticallyWaitsToMinimizeStalling = NO;
    }
    //监听播放器状态
    [_player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //监听播放进度改变
    __weak typeof(self) weakSelf = self;
    _observer = [_player addPeriodicTimeObserverForInterval:CMTimeMake(1000, 1000) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        if (weakSelf.isStopUpdateCurrentTime) return;
        weakSelf.slider.value = (time.value / time.timescale) / ((weakSelf.player.currentItem.duration.value / weakSelf.player.currentItem.duration.timescale) * 1.0);
        weakSelf.currentTimeLabel.text = [weakSelf see_timeStringWithTime:time];
        if (weakSelf.slider.value == 1) {
            //如果播放完成则暂停播放
            if (self.status & SEEPlayerStatusPlay) {
                [weakSelf see_playOrPauseButtonAction:weakSelf.playOrPauseButton];
            }
        }
    }];
}

#pragma mark - private method

//界面布局
- (void)layoutSubviews {
    [super layoutSubviews];
    self.displayLayer.position = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    self.displayLayer.bounds = self.bounds;
    //顶部工具条
    self.topToolBar.frame = CGRectMake(0, 0, self.bounds.size.width, 44);
    self.titleLabel.frame = CGRectMake(10, 0, self.topToolBar.bounds.size.width - 64, self.topToolBar.bounds.size.height);
    self.closeButton.frame = CGRectMake(self.topToolBar.bounds.size.width - 54, 0, 44, 44);
    //底部工具条
    self.bottomToolBar.frame = CGRectMake(0, self.bounds.size.height - 44, self.bounds.size.width, 44);
    self.currentTimeLabel.frame = CGRectMake(10, 0, 60, 44);
    self.slider.frame = CGRectMake(70, 0, self.bottomToolBar.frame.size.width - 184, 44);
    self.durationLabel.frame = CGRectMake(self.bottomToolBar.frame.size.width - 114, 0, 60, 44);
    self.fullScreenButton.frame = CGRectMake(self.bottomToolBar.frame.size.width - 54, 0, 44, 44);
    //播放按钮
    self.playOrPauseButton.frame = CGRectMake(0,44,self.bounds.size.width,self.bounds.size.height - 88);
}


//播放
- (void)see_play {
    SEEPlayerLog(@"开始播放");
    [_player play];
    //如果当前已经播放完成，则从头开始播放
    if (self.slider.value == 1) {
        self.slider.value = 0;
        [self seekToTime:self.slider];
    }
    self.status = (self.status & 0xf) | SEEPlayerStatusPlay;
}

//暂停
- (void)see_pause {
    SEEPlayerLog(@"暂停");
    [_player pause];
    self.status = (self.status & 0xf) | SEEPlayerStatusPause;
}

//进入缓冲状态
- (void)see_buffering {
    if (!(self.status & SEEPlayerStatusBuffering)) {
        SEEPlayerLog(@"开始缓冲");
        [_player pause];
        self.status = self.status | SEEPlayerStatusBuffering;
        [[NSNotificationCenter defaultCenter]postNotificationName:SEEPlayerBufferingNotification object:nil];
        [self see_bufferSomeSeconds];
    }
}
//缓冲
- (void)see_bufferSomeSeconds {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!self.player.currentItem.playbackLikelyToKeepUp) {
            [self see_bufferSomeSeconds];
            [[NSNotificationCenter defaultCenter]postNotificationName:SEEPlayerCheckTaskNotification object:nil];
        }
        else {
            if (self.status & SEEPlayerStatusPlay) {
                [_player play];
            }
            self.status = self.status & ~SEEPlayerStatusBuffering;
        }
    });
}

//等待app激活
- (void)see_waitingActivate {
    SEEPlayerLog(@"等待激活");
    [_player pause];
    self.status = self.status | SEEPlayerStatusWaitingActivate;
    [[NSNotificationCenter defaultCenter] postNotificationName:SEEPlayerWillResignActiveNotification object:nil];
}

//app激活
- (void)see_becomeActivate {
    if (self.status & SEEPlayerStatusWaitingActivate) {
        SEEPlayerLog(@"激活");
        if (self.status & SEEPlayerStatusPlay) {
            [_player play];
        }
        self.status = self.status & ~SEEPlayerStatusWaitingActivate;
        [[NSNotificationCenter defaultCenter] postNotificationName:SEEPlayerDidBecomeActiveNotification object:nil];
    }
}

//播放失败
- (void)see_failed {
    self.status = SEEPlayerStatusFailed;
    SEEPlayerLog(@"%@",self.player.error);
    [_player pause];
}

//返回时间字符串
- (NSString *)see_timeStringWithTime:(CMTime)time {
    if (!time.value && !time.timescale)return @"00:00";
    long long seconds = time.value / time.timescale;
    long long minutes = seconds / 60;
    seconds = seconds % 60;
    return [NSString stringWithFormat:@"%02lld:%02lld",minutes,seconds];
}

//清除播放器
- (void)see_clearPlayer {
    if (_player.currentItem) {
        //暂停视频
        [self see_pause];
        [self.player removeTimeObserver:_observer];
        [self.player.currentItem cancelPendingSeeks];
        [self.player.currentItem.asset cancelLoading];
        [self.player.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
        [self.player.currentItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [self.player.currentItem removeObserver:self forKeyPath:@"duration"];
        [self.player removeObserver:self forKeyPath:@"status"];
        _player = nil;
        _observer = nil;
        _resourceLoader = nil;
        [_displayLayer removeFromSuperlayer];
        [[NSNotificationCenter defaultCenter]postNotificationName:SEEPlayerClearNotification object:nil];
    }
}

#pragma mark - action mehtod
//设置标题
- (void)see_setTitle:(NSNotification *)noti {
    self.titleLabel.text = noti.userInfo[@"fileName"];
}

//关闭
- (void)see_close:(UIButton *)button {
    
    //如果是全屏状态则切换到小屏幕
    if (self.isFullScreen) {
        [self see_fullScreen:self.fullScreenButton];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //移除播放器
            [self removeFromSuperview];
            //清除播放器
            [self see_clearPlayer];

        });
    }
    else {
        [self removeFromSuperview];
        //清除播放器
        [self see_clearPlayer];
    }
    
}

//屏幕方向改变重新布局控件
- (void)see_orientationNotification:(NSNotification *)noti {
    if (self.superview == nil) return;
    
//    NSDictionary * userInfo = noti.userInfo;
    UIDeviceOrientation orient = [UIDevice currentDevice].orientation;
    
    if (self.isFullScreen) {
        self.frame = [UIScreen mainScreen].bounds;
    }
    //如果当前不是全屏播放状态，并且屏幕方向变为横屏 则默认进入全屏状态
    else if (orient == UIDeviceOrientationLandscapeLeft || orient == UIDeviceOrientationLandscapeRight) {
        [self see_fullScreen:self.fullScreenButton];
        self.frame = [UIScreen mainScreen].bounds;
    }
}

- (void)see_playOrPauseButtonAction:(UIButton *)sender {
    //播放器未准备好或者播放失败时禁用按钮
    if (self.status >= SEEPlayerStatusFailed) return;
    if (sender.selected) {
        [self see_pause];
    }
    else {
        [self see_play];
    }
    sender.selected = !sender.selected;
}

//全屏按钮点击
- (void)see_fullScreen:(UIButton *)sender {
    //暂停播放
    [_player pause];
    //将播放器从旧的父视图移除
    sender.selected = !sender.selected;
    if (sender.selected) {
        self.isFullScreen = YES;
        self.originSuperView = self.superview;
        self.originFrame = self.frame;
        [self removeFromSuperview];
        self.windowFrame = [self.originSuperView convertRect:self.originFrame toView:[UIApplication sharedApplication].keyWindow];
        self.frame = self.windowFrame;
        [[UIApplication sharedApplication].keyWindow addSubview:self];
        [UIView animateWithDuration:0.25 animations:^{
            self.frame = [UIScreen mainScreen].bounds;
        } completion:^(BOOL finished) {
            if (self.status & SEEPlayerStatusPlay) {
                [_player play];
            }
        }];
    }
    else {
        self.isFullScreen = NO;
        [UIView animateWithDuration:0.25 animations:^{
            self.frame = self.windowFrame;
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
            [self.originSuperView addSubview:self];
            self.frame = self.originFrame;
            if (self.status & SEEPlayerStatusPlay) {
                [_player play];
            }
        }];
    }
}

- (void)see_timeChanged:(UISlider *)sender {
    //播放器未准备好或者播放失败时禁用按钮
    if (self.status >= SEEPlayerStatusFailed) return;
    CMTime time = CMTimeMake(self.player.currentItem.duration.value * sender.value, self.player.currentItem.duration.timescale);
    self.currentTimeLabel.text = [self see_timeStringWithTime:time];
}

//时间进度条被点中时
- (void)see_stopUpdateCurrentTime {
    //播放器未准备好或者播放失败时禁用按钮
    if (self.status >= SEEPlayerStatusFailed) return;
    self.isStopUpdateCurrentTime = YES;
}

//拖动时间进度条
- (void)seekToTime:(UISlider *)sender {
    if (self.status >= SEEPlayerStatusFailed) {
        sender.value = 0;
        return ;
    }
    [_player pause];
    CMTime time = self.player.currentItem.duration;
    CGFloat scale = sender.value;
    time = CMTimeMake(time.value * scale, time.timescale);
    [_player seekToTime:time];
     self.isStopUpdateCurrentTime = NO;
    if (self.status & SEEPlayerStatusPlay) {
        [_player play];
    }
}

//取消时间进度条拖动操作
- (void)see_cancleSeek:(UISlider *)sender {
    if (self.status >= SEEPlayerStatusFailed) {
        sender.value = 0;
        return ;
    }
    CMTime time = self.player.currentItem.currentTime;
    self.slider.value = (time.value / time.timescale) / ((self.player.currentItem.duration.value / self.player.currentItem.duration.timescale) * 1.0);
    self.currentTimeLabel.text = [self see_timeStringWithTime:time];
    self.isStopUpdateCurrentTime = NO;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) { //播放状态
        //触发播放器播放或者失败
        if (_player.status == AVPlayerStatusReadyToPlay) {
            [self see_play];
        }
        else if (_player.status == AVPlayerStatusFailed) {
            [self see_failed];
        }
        else {
            self.status = SEEPlayerStatusUnknow;
        }
    }
    else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) { //指示该项目是否有可能在不拖延的情况下顺利完成。
        if (self.player.currentItem.playbackLikelyToKeepUp && self.status == SEEPlayerStatusPlay) {
            [self see_play];
        }
    }
    else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) { //监听缓冲池状态 如果缓冲池空则开始缓冲操作
        if (self.player.currentItem.playbackBufferEmpty) {
            [self see_buffering];
        }
    }
    else if ([keyPath isEqualToString:@"duration"]) { //监听播放时长变化
        self.durationLabel.text = [self see_timeStringWithTime:self.player.currentItem.duration];
    }
}

#pragma mark - getter & setter

//设置播放状态
- (void)setStatus:(SEEPlayerStatus)status {
    _status = status;
    SEEPlayerLog(@"%zd",status);
}

//顶部工具栏
- (UIView *)topToolBar {
    if (_topToolBar == nil) {
        _topToolBar = [[UIView alloc]init];
        _topToolBar.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        [_topToolBar addSubview:self.titleLabel];
        [_topToolBar addSubview:self.closeButton];
    }
    return _topToolBar;
}

//底部工具栏全屏按钮
- (UIButton *)fullScreenButton {
    if (_fullScreenButton == nil) {
        _fullScreenButton = [[UIButton alloc]init];
        [_fullScreenButton setTitle:@"全屏" forState:UIControlStateNormal];
        [_fullScreenButton setTitle:@"取消" forState:UIControlStateSelected];
        [_fullScreenButton addTarget:self action:@selector(see_fullScreen:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _fullScreenButton;
}

//顶部工具栏title
- (UILabel *)titleLabel {
    if (_titleLabel == nil) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont systemFontOfSize:12];
    }
    return _titleLabel;
}

//顶部工具栏关闭按钮
- (UIButton *)closeButton {
    if (_closeButton == nil) {
        _closeButton = [[UIButton alloc]init];
        [_closeButton setTitle:@"关闭" forState:UIControlStateNormal];
        [_closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(see_close:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

//底部工具栏
- (UIView *)bottomToolBar {
    if (_bottomToolBar == nil) {
        _bottomToolBar = [[UIView alloc]init];
        _bottomToolBar.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        [_bottomToolBar addSubview:self.slider];
        [_bottomToolBar addSubview:self.currentTimeLabel];
        [_bottomToolBar addSubview:self.durationLabel];
        [_bottomToolBar addSubview:self.fullScreenButton];
    }
    return _bottomToolBar;
}

//底部工具栏时间滑块
- (UISlider *)slider {
    if (_slider == nil) {
        _slider = [[UISlider alloc]init];
        //跳到某一时间点播放
        [_slider addTarget:self action:@selector(seekToTime:) forControlEvents:UIControlEventTouchUpInside];
        //按下按钮停止时间label自动更新
        [_slider addTarget:self action:@selector(see_stopUpdateCurrentTime) forControlEvents:UIControlEventTouchDown];
        //拖动过程中修改时间label显示
        [_slider addTarget:self action:@selector(see_timeChanged:) forControlEvents:UIControlEventValueChanged];
        //如果抬手不再按钮范围内则取消
        [_slider addTarget:self action:@selector(see_cancleSeek:) forControlEvents:UIControlEventTouchUpOutside];
    }
    return _slider;
}

//底部工具栏时间label
- (UILabel *)durationLabel {
    if (_durationLabel == nil) {
        _durationLabel = [[UILabel alloc]init];
        _durationLabel.text = @"00:00";
        _durationLabel.textColor = [UIColor whiteColor];
        _durationLabel.font = [UIFont systemFontOfSize:14];
        _durationLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _durationLabel;
}

//底部工具栏当前播放时间label
- (UILabel *)currentTimeLabel {
    if (_currentTimeLabel == nil) {
        _currentTimeLabel = [[UILabel alloc]init];
        _currentTimeLabel.text = @"00:00";
        _currentTimeLabel.textColor = [UIColor whiteColor];
        _currentTimeLabel.font = [UIFont systemFontOfSize:14];
        _currentTimeLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _currentTimeLabel;
}

//播放暂停按钮
- (UIButton *)playOrPauseButton {
    if (_playOrPauseButton == nil) {
        _playOrPauseButton = [[UIButton alloc]init];
        [_playOrPauseButton setTitle:@"播放" forState:UIControlStateNormal];
        [_playOrPauseButton setTitle:@"暂停" forState:UIControlStateSelected];
        [_playOrPauseButton addTarget:self action:@selector(see_playOrPauseButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _playOrPauseButton.selected = YES;
    }
    return _playOrPauseButton;
}

//设置代理
- (void)setDelegate:(id<SEEPlayerDelegate>)delegate {
    _delegate = delegate;
    _responder.willResignFullScreen = [delegate respondsToSelector:@selector(playerWillResignFullScreen:)];
    _responder.willBecomeFullScreen = [delegate respondsToSelector:@selector(playerWillBecomeFullScreen:)];
}

@end
