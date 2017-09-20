//
//  SEECacheManager.m
//  musicOC
//
//  Created by 三只鸟 on 2017/9/20.
//  Copyright © 2017年 三只鸟. All rights reserved.
//

#import "SEECacheManager.h"

@interface SEECacheManager ()

@property (nonatomic,strong)NSOutputStream * stream;

@property (nonatomic,copy)NSString * fileName;

@end

@implementation SEECacheManager

+ (instancetype)share {
    static SEECacheManager * manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[SEECacheManager alloc]init];
    });
    return manager;
}

- (void)writeData:(NSData *)data withFileName:(NSString *)fileName {
    if (_stream == nil) {
        self.fileName = fileName;
        if ([[NSFileManager defaultManager]fileExistsAtPath:[self tempPath].absoluteString]) {
            [[NSFileManager defaultManager]removeItemAtPath:[self tempPath].absoluteString error:nil];
        }
//        _stream = [NSOutputStream outputStreamWithURL:[NSURL URLWithString:[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:url.lastPathComponent]] append:YES];
        _stream = [NSOutputStream outputStreamWithURL:[self tempPath] append:YES];
        [_stream open];
    }
    [_stream write:data.bytes maxLength:data.length];
}

- (void)finishWrite:(BOOL)success {
    [_stream close];
    _stream = nil;
    if (success) {
        //成功保留文件
        [[NSFileManager defaultManager]copyItemAtURL:[self tempPath] toURL:[self cachePath] error:nil];
    }
}

- (NSURL *)cachePathWithCurrentRequest {
    return [self tempPath];
}

#pragma mark - private method

- (NSURL *)tempPath {
    return [NSURL fileURLWithPath:@"/Users/sanzhiniao/SEEPlayer/temp.mp4"];
    return [NSURL fileURLWithPath:[@"/Users/sanzhiniao/SEEPlayer/temp.mp4" stringByAppendingPathComponent:[self.fileName stringByReplacingOccurrencesOfString:@"\"" withString:@""]]];
}

- (NSURL *)cachePath {
    return [NSURL fileURLWithPath:@"/Users/sanzhiniao/SEEPlayer/complete.mp4"];
    return [NSURL fileURLWithPath:[@"/Users/sanzhiniao/SEEPlayer/cache" stringByAppendingPathComponent:[self.fileName stringByReplacingOccurrencesOfString:@"\"" withString:@""]]];
}

@end
