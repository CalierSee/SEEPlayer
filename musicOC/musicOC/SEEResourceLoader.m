//
//  SEEResourceLoader.m
//  musicOC
//
//  Created by 三只鸟 on 2017/9/19.
//  Copyright © 2017年 三只鸟. All rights reserved.
//

#import "SEEResourceLoader.h"
#import "SEETask.h"
#import "SEECacheManager.h"
@interface SEEResourceLoader () <SEETaskDelegate>

/**
 所有的数据请求
 */
@property (nonatomic,strong)NSMutableArray <AVAssetResourceLoadingRequest *> * loadingRequests;

/**
 数据下载对象
 */
@property (nonatomic,strong)SEETask * task;

@property (nonatomic,assign)BOOL isFirst;

@end

@implementation SEEResourceLoader

#pragma mark - life circle



#pragma mark - private method
//处理请求  拼接请求range 发起下载请求
- (void)dealLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    /* 重要 需要将scheme替换为原来的http*/
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:loadingRequest.request.URL resolvingAgainstBaseURL:NO];
    components.scheme = @"http";
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[components URL]];
    if (_isFirst) {
      [request setValue:[NSString stringWithFormat:@"bytes=%lld-%lu",loadingRequest.dataRequest.currentOffset,NSUIntegerMax] forHTTPHeaderField:@"Range"];
    }
    else {
        [request setValue:[NSString stringWithFormat:@"bytes=%lld-%lu",loadingRequest.dataRequest.currentOffset,loadingRequest.dataRequest.requestedLength] forHTTPHeaderField:@"Range"];
    }
    self.isFirst = NO;
    [self.task downloadRequest:request startOffset:(NSUInteger)loadingRequest.dataRequest.currentOffset];
}

//处理请求 填充请求数据  并且返回当前请求是否结束
- (BOOL)isComplete:(AVAssetResourceLoadingRequest *)loadingRequest {
    //获取缓存文件
    NSData * data = [NSData dataWithContentsOfURL:[SEECacheManager share].tempPath];
    NSLog(@"%ld",loadingRequest.dataRequest.requestedLength);
    //获取可以返回的数据长度 = 下载开始偏移+下载量-当前偏移量
    NSUInteger redyLength = self.task.startOffset + self.task.downloadTotalBytes - loadingRequest.dataRequest.currentOffset > loadingRequest.dataRequest.requestedLength - loadingRequest.dataRequest.currentOffset ? loadingRequest.dataRequest.requestedLength - loadingRequest.dataRequest.currentOffset : self.task.startOffset + self.task.downloadTotalBytes - loadingRequest.dataRequest.currentOffset;
    //创建数据范围
    NSRange range = NSMakeRange(loadingRequest.dataRequest.currentOffset, redyLength);
    //截取已经准备好的数据
    NSData * redyData = [data subdataWithRange:range];
    NSLog(@"redy -- %ld",redyData.length);
    //填充数据  2788017
    [loadingRequest.dataRequest respondWithData:redyData];
    NSLog(@"current --- %ld",loadingRequest.dataRequest.currentOffset);

    return loadingRequest.dataRequest.requestedLength == loadingRequest.dataRequest.currentOffset;
}

#pragma mark - public mehtod

#pragma mark - AVAssetResourceLoaderDelegate



- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSLog(@"---waitingforloadingofrequestedresource: %ld",loadingRequest.dataRequest.requestedLength);
    //将数据请求放入数组
    [self.loadingRequests addObject:loadingRequest];
    //处理数据请求
    [self dealLoadingRequest:loadingRequest];
    
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest{
    
    //[self.loadingRequests removeObject:loadingRequest];
    
}


#pragma mark - SEETaskDelegate
- (void)task:(SEETask *)task didReceiveData:(NSData *)data {
    //更新请求信息，并且将完成的请求结束
    NSMutableArray * completeArray = [NSMutableArray array];
    [self.loadingRequests enumerateObjectsUsingBlock:^(AVAssetResourceLoadingRequest * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //更新请求信息
        obj.contentInformationRequest.byteRangeAccessSupported = YES;
        obj.contentInformationRequest.contentType = task.contentType;
        obj.contentInformationRequest.contentLength = task.totalBytes;
        
        //判断是否有请求完成 将未完成的请求取出  结束完成的请求
        if ([self isComplete:obj]) {
            [obj finishLoading];
            [completeArray addObject:obj];
        }
    }];
    NSLog(@"%p -- %zd",self.loadingRequests,self.loadingRequests.count);
    if (completeArray.count) {
        [self.loadingRequests removeObjectsInArray:completeArray];
    }
}

- (void)task:(SEETask *)task didCompleteWithError:(NSError *)error {
    
    
    
}

#pragma mark - getter & setter
- (NSMutableArray<AVAssetResourceLoadingRequest *> *)loadingRequests {
    if (_loadingRequests == nil) {
        _loadingRequests = [NSMutableArray array];
        self.isFirst = YES;
    }
    return _loadingRequests;
}

- (SEETask *)task {
    if (_task == nil) {
        _task = [[SEETask alloc]init];
        _task.delegate = self;
    }
    return _task;
}


@end
