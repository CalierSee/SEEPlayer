//
//  SEEResourceLoader.h
//  SEEPlayer
//
//  Created by 三只鸟 on 2017/10/26.
//  Copyright © 2017年 景彦铭. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@interface SEEResourceLoader : NSObject <AVAssetResourceLoaderDelegate>

/**
 处理后的url
 */
@property (nonatomic,strong,readonly)NSURL * url;

- (instancetype)initWithURL:(NSURL *)url;

@end
