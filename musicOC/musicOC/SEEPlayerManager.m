//
//  SEEPlayerManager.m
//  musicOC
//
//  Created by 三只鸟 on 2017/9/19.
//  Copyright © 2017年 三只鸟. All rights reserved.
//

#import "SEEPlayerManager.h"
#import "SEEResourceLoader.h"
@interface SEEPlayerManager ()
/**
 player
 */
@property (nonatomic,strong)AVPlayer * player;

/**
 播放url
 */
@property (nonatomic,strong)NSURL * targetURL;

/**
 asset
 */
@property (nonatomic,strong)AVURLAsset * videoAsset;

/**
 下载器
 */
@property (nonatomic,strong)SEEResourceLoader * loader;

@end

@implementation SEEPlayerManager

- (void)playWithURL:(NSURL *)url {
    self.targetURL = url;
    /* 重要 将scheme替换为系统无法识别的才能调用代理*/
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
    components.scheme = @"streaming";
    url = [components URL];
    //创建下载器
    self.loader = [[SEEResourceLoader alloc]init];
    //创建assets
    self.videoAsset = [[AVURLAsset alloc]initWithURL:url options:nil];
    //设置代理
    [self.videoAsset.resourceLoader setDelegate:self.loader queue:dispatch_get_main_queue()];
    //创建playerItem
    AVPlayerItem * item = [[AVPlayerItem alloc]initWithAsset:self.videoAsset automaticallyLoadedAssetKeys:nil];
    //监听状态
    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //监听加载时间
    [item addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    //缓冲池是否为空
    [item addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    self.player = [[AVPlayer alloc]initWithPlayerItem:item];
    self.player.automaticallyWaitsToMinimizeStalling = NO;
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus status = AVPlayerItemStatusUnknown;
        // Get the status change from the change dictionary
        NSNumber *statusNumber = change[NSKeyValueChangeNewKey];
        if ([statusNumber isKindOfClass:[NSNumber class]]) {
            status = statusNumber.integerValue;
        }
        // Switch over the status
        switch (status) {
            case AVPlayerItemStatusReadyToPlay:
                [self.player play];
                break;
            case AVPlayerItemStatusFailed:
            case AVPlayerItemStatusUnknown:
                [self.player pause];
                break;
        }
    }
    if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        
    }
    
    if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        if (!self.player.currentItem.isPlaybackBufferEmpty) {
            [self waitSomeSecond];
        }
    }
}

#pragma mark - private method
- (void)waitSomeSecond {
    [self.player pause];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.player play];
        if (!self.player.currentItem.isPlaybackLikelyToKeepUp) {
            [self waitSomeSecond];
        }
    });
}

@end
