//
//  SEEPlayerManager.h
//  musicOC
//
//  Created by 三只鸟 on 2017/9/19.
//  Copyright © 2017年 三只鸟. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface SEEPlayerManager : NSObject

@property (nonatomic,strong,readonly)AVPlayer * player;

@property (nonatomic,strong,readonly)NSURL * targetURL;

- (void)playWithURL:(NSURL *)url;

@end
