//
//  SEEResourceLoader.m
//  SEEPlayer
//
//  Created by 三只鸟 on 2017/10/26.
//  Copyright © 2017年 景彦铭. All rights reserved.
//

#import "SEEResourceLoader.h"
#import "SEEDataManager.h"
#import "SEEPlayer_Header.h"
#import <MobileCoreServices/MobileCoreServices.h>
@interface SEEResourceLoader () <SEEDataManagerDelegate>

//经过处理后的url
@property (nonatomic,strong)NSURL * url;

//存放所有由播放器发出的loadingRequest
@property (nonatomic,strong)NSMutableArray <AVAssetResourceLoadingRequest *> * requests;

//当前是否从缓存中加载数据
@property (nonatomic,assign)BOOL isCache;

//数据提供者  该对象决定从网络或者缓存中拿出数据给resourceLoader
@property (nonatomic,strong)SEEDataManager * dataManager;

@end

@implementation SEEResourceLoader {
    //原始url
    NSURL * _originUrl;
}

- (instancetype)initWithURL:(NSURL *)url {
    if (self = [super init]) {
        _originUrl = url;
        //修改scheme 只有当player无法识别scheme时才会询问代理是否能够播放，如果可以识别则不会询问代理直接播放
        self.requests = [NSMutableArray array];
        NSURLComponents * components = [NSURLComponents componentsWithString:url.absoluteString];
        components.scheme = @"seeplayer";
        self.url = [components URL];
        //初始化数据提供者
        self.dataManager = [[SEEDataManager alloc]initWithURL:_originUrl];
        self.dataManager.delegate = self;
        
        
        //监听缓冲状态
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(buffering) name:SEEPlayerBufferingNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    SEEPlayerLog(@"resourceLoader销毁");
}

#pragma mark - public method
- (void)buffering {
    __block long long maxOffset = 0;
    [self.requests enumerateObjectsUsingBlock:^(AVAssetResourceLoadingRequest * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.dataRequest.currentOffset > maxOffset) maxOffset = obj.dataRequest.currentOffset;
    }];
    [self.dataManager downLoadDataWithRange:(SEEDataRange){maxOffset,2}];
}

#pragma mark - private method

//每次播放器发出新的resourceLoadingRequest时丢给数据管理者处理，由数据管理者决定是否取消之前的下载开始新的下载请求
- (void)see_downLoadResourceLoadingRequest:(AVAssetResourceLoadingRequest *)request {
//    SEEPlayerLog(@"请求起始位置 :%lld",request.dataRequest.requestedOffset);
    SEEDataRange dataRange = {request.dataRequest.requestedOffset, request.dataRequest.requestedLength};
    [self.dataManager downLoadDataWithRange:dataRange];
}

//接收到数据后像请求中填充数据
- (void)see_fillData {
    //记录已经完成的请求
    NSMutableArray * completeArray = [NSMutableArray array];
    //填充数据
    [self.requests enumerateObjectsUsingBlock:^(AVAssetResourceLoadingRequest * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.isCancelled) {
            [completeArray addObject:obj];
            return ;
        }
        //填充请求信息   不填充会导致播放失败
        [self see_fillInformation:obj.contentInformationRequest];
        //向dataManager请求数据
        SEEDataRange dataRange = {obj.dataRequest.currentOffset, obj.dataRequest.requestedLength + obj.dataRequest.requestedOffset - obj.dataRequest.currentOffset};
//        SEEPlayerLog(@"播放器请求数据范围 {offset: %lld length: %lld}",dataRange.offset,dataRange.length);
        NSData * data = [self.dataManager readData:dataRange];
//        //SEEPlayerLog(@"数据长度 %zd",data.length);
        if (data.length) {
            [obj.dataRequest respondWithData:data];
        }
        //判断是否完成请求
        if (obj.dataRequest.currentOffset == obj.dataRequest.requestedLength + obj.dataRequest.requestedOffset || obj.dataRequest.currentOffset < self.dataManager.downloadManager.startOffset) {
            //SEEPlayerLog(@"requestFinish");
            [obj finishLoading];
            [completeArray addObject:obj];
        }
    }];
    [self.requests removeObjectsInArray:completeArray];
}

- (void)see_fillInformation:(AVAssetResourceLoadingContentInformationRequest *)information {
    NSString *mimeType = self.dataManager.mimeType;
    CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(mimeType), NULL);
    information.byteRangeAccessSupported = YES;
    information.contentType = CFBridgingRelease(contentType);
    information.contentLength = self.dataManager.contentLength;
}

#pragma mark - AVAssetResourceLoaderDelegate

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
//    //SEEPlayerLog(@"接收到请求 --- offset: %zd length: %zd currentOffset:%zd",loadingRequest.dataRequest.requestedOffset,loadingRequest.dataRequest.requestedLength,loadingRequest.dataRequest.currentOffset);
    [self.requests addObject:loadingRequest];
    //下载
    [self see_downLoadResourceLoadingRequest:loadingRequest];
     return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    //SEEPlayerLog(@"取消请求 --- offset: %zd length: %zd currentOffset: %zd",loadingRequest.dataRequest.requestedOffset,loadingRequest.dataRequest.requestedLength,loadingRequest.dataRequest.currentOffset);
    [self.requests removeObject:loadingRequest];
}

#pragma mark - SEEDataManagerDelegate
- (void)dataManagerDidWriteData {
    [self see_fillData];
}

- (void)dataManagerDidCompleteWithError:(NSError *)error {
    if (error == nil) {
        [self see_fillData];
    }
    else {
        
    }
}

@end
