//
//  SEEDownloadManager.m
//  SEEPlayer
//
//  Created by 三只鸟 on 2017/10/27.
//  Copyright © 2017年 景彦铭. All rights reserved.
//

#import "SEEDownloadManager.h"
#import "SEEDataManager.h"
#import "SEEPlayer_Header.h"
@interface SEEDownloadManager () <NSURLSessionDelegate>

//当前下载的起始偏移量
@property (nonatomic,assign)long long startOffset;
//当前下载到的偏移量
@property (nonatomic,assign)long long  currentOffset;

@property (nonatomic,strong)NSURLSessionDataTask * task;

@property (nonatomic,assign)long long  offset;

//文件名
@property (nonatomic,copy)NSString * fileName;

@property (nonatomic,strong)NSURLSession * session;

@end

@implementation SEEDownloadManager {
    struct {
        int didReceiveData;
        int hadDownLoadAllData;
        int didReceiveResponse;
    }_responder;
}

- (instancetype)init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(see_pause) name:SEEPlayerWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(see_resume) name:SEEPlayerDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(see_cancel) name:SEEPlayerClearNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    SEEPlayerLog(@"downloadManager销毁");
}

#pragma mark - public method
- (void)downLoadWithOffset:(long long)offset url:(NSURL *)url; {
    if (self.task) {
        [self.task suspend];
        [self.task cancel];
        self.task = nil;
    }
    self.offset = offset;
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:[NSString stringWithFormat:@"bytes=%lld-",offset] forHTTPHeaderField:@"Range"];
#ifdef DEBUG
    //SEEPlayerLog(@"创建request请求 %@",[request valueForHTTPHeaderField:@"Range"]);
#endif
    NSURLSessionConfiguration * configure = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.session = [NSURLSession sessionWithConfiguration:configure delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    self.task = [self.session dataTaskWithRequest:request];
    [self.task resume];
}

#pragma mark - private method
- (void)see_pause {
    if (self.task) {
        [self.task suspend];
    }
}

- (void)see_resume {
    if (self.task) {
        [self.task resume];
    }
}

- (void)see_cancel {
    [self.session invalidateAndCancel];
    self.task = nil;
}

#pragma mark - NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    self.fileName = response.suggestedFilename;
    [[NSNotificationCenter defaultCenter]postNotificationName:SEEDownloadManagerDidReceiveFileNameNotification object:nil userInfo:@{@"fileName": self.fileName.length ? self.fileName : @""}];
    //询问代理是否开始下载
    if (_responder.didReceiveResponse) {
        [self.delegate managerDidReceiveResponse:response completionHandler:completionHandler];
    }
    self.startOffset = self.offset;
    self.currentOffset = self.offset;
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
//    SEEPlayerLog(@"接收到数据 %zd",data.length);
    if (self.task != nil) {
        self.currentOffset = self.currentOffset + data.length;
        if (_responder.didReceiveData) {
            [self.delegate managerDidReceiveData:data];
        }
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (_responder.hadDownLoadAllData) {
        [self.delegate managerHadDownLoadAllDataWithError:error];
    }
}

#pragma mark - getter & setter
- (void)setDelegate:(id<SEEDownloadManagerDelegate>)delegate {
    _delegate = delegate;
    _responder.didReceiveData = [delegate respondsToSelector:@selector(managerDidReceiveData:)];
    _responder.hadDownLoadAllData = [delegate respondsToSelector:@selector(managerHadDownLoadAllDataWithError:)];
    _responder.didReceiveResponse = [delegate respondsToSelector:@selector(managerDidReceiveResponse:completionHandler:)];
}

@end
