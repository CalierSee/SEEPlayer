//
//  SEETask.m
//  musicOC
//
//  Created by 三只鸟 on 2017/9/19.
//  Copyright © 2017年 三只鸟. All rights reserved.
//

#import "SEETask.h"
#import "SEECacheManager.h"
@interface SEETask () 

/**
 session
 */
@property (nonatomic,strong)NSURLSession * session;

/**
 task
 */
@property (nonatomic,strong)NSURLSessionDataTask * task;

/**
 是否缓不存数据
 */
@property (nonatomic,assign)BOOL notCache;

/**
 缓存单利
 */
@property (nonatomic,strong)SEECacheManager * cacheManager;

/**
 数据总量
 */
@property (nonatomic,assign)NSUInteger  totalBytes;

/**
 当前下载数据总量
 */
@property (nonatomic,assign)NSUInteger  downloadTotalBytes;

/**
 当前下载起始位置偏移量
 */
@property (nonatomic,assign)NSUInteger  startOffset;

/**
 文件名
 */
@property (nonatomic,copy)NSString * fileName;

/**
 请求类型
 */
@property (nonatomic,copy)NSString * contentType;

@end

@implementation SEETask {
    struct {
        int didReceiveData;
        int didComplete;
    }_responder;
}

- (void)downloadRequest:(NSURLRequest *)request startOffset:(NSUInteger)offset {
    if (self.task) {
        [self clear];
    }
    self.notCache = offset;
    self.startOffset = offset;
    NSURLSessionConfiguration * configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    self.task = [self.session dataTaskWithRequest:request];
    [self.task resume];
}

#pragma mark - private method
- (void)clear {
    [self.task cancel];
    _totalBytes = 0;
    _downloadTotalBytes = 0;
    [self.cacheManager finishWrite:NO];
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    self.mimeType = response.MIMEType;
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
        self.fileName = [httpResponse.allHeaderFields valueForKey:@"Content-Disposition"];
        self.totalBytes = ((NSNumber *)[httpResponse.allHeaderFields valueForKey:@"Content-Length"]).integerValue;
        self.contentType = [httpResponse.allHeaderFields valueForKey:@"Content-Type"];
    }
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    if (!data.length) {
        return;
    }
    self.downloadTotalBytes += data.length;
    if (self.downloadTotalBytes == self.totalBytes) {
        
    }
    [self.cacheManager writeData:data withFileName:self.fileName];
    if (_responder.didReceiveData) {
        [self.delegate task:self didReceiveData:data];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    [self.cacheManager finishWrite:error == nil];
    if (_responder.didComplete) {
        [self.delegate task:self didCompleteWithError:error];
    }
}


#pragma mark - getter & setter

- (SEECacheManager *)cacheManager {
    if (_cacheManager == nil) {
        _cacheManager =[SEECacheManager share];
    }
    return _cacheManager;
}

- (void)setDelegate:(id<SEETaskDelegate>)delegate {
    _delegate = delegate;
    _responder.didReceiveData = [delegate respondsToSelector:@selector(task:didReceiveData:)];
    _responder.didComplete = [delegate respondsToSelector:@selector(task:didCompleteWithError:)];
}

@end
