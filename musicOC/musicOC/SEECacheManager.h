//
//  SEECacheManager.h
//  musicOC
//
//  Created by 三只鸟 on 2017/9/20.
//  Copyright © 2017年 三只鸟. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SEECacheManager : NSObject

+ (instancetype)share;

- (void)writeData:(NSData *)data withFileName:(NSString *)fileName;

- (void)finishWrite:(BOOL)success;

- (NSURL *)cachePathWithCurrentRequest;

- (NSURL *)tempPath;

- (NSURL *)cachePath;

@end
