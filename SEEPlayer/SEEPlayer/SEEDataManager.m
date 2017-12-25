




//
//  SEEFileManager.m
//  SEEPlayer
//
//  Created by 三只鸟 on 2017/10/28.
//  Copyright © 2017年 景彦铭. All rights reserved.
//

#import "SEEDataManager.h"
#import "SEEPlayer_Header.h"
@interface SEEDataManager () <SEEDownloadManagerDelegate>


@property (nonatomic,strong)NSFileManager * fileManager;

@property (nonatomic,strong)NSOutputStream * outputStream;

@property (nonatomic,strong)SEEDownloadManager * downloadManager;

//文件类型
@property (nonatomic,copy)NSString * mimeType;
//contentLength
@property (nonatomic,assign)long long contentLength;

@property (nonatomic,strong)NSURL * url;
//是否已经缓存过文件
@property (nonatomic,assign)BOOL isCache;
//临时文件是否下载完成
@property (nonatomic,assign)BOOL isTemp;

@end


@implementation SEEDataManager {
    struct {
        int didDidWriteData;
        int didComplete;
    }_responder;
}

- (instancetype)initWithURL:(NSURL *)url {
    if (self = [super init]) {
        self.fileManager = [NSFileManager defaultManager];
        self.downloadManager = [[SEEDownloadManager alloc]init];
        self.downloadManager.delegate = self;
        self.url = url;
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(see_checkTask) name:SEEPlayerCheckTaskNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    SEEPlayerLog(@"dataManager销毁");
}

#pragma mark - public method
- (void)downLoadDataWithRange:(SEEDataRange)range
{
    //如果当前处于缓存播放状态，则不发出请求 直接调用下载完成的方法通知resourceLoader填充数据
    if (self.isCache) {
        if (_responder.didComplete) {
            [self.delegate dataManagerDidCompleteWithError:nil];
        }
        return;
    }
    
    if (self.isTemp && self.downloadManager.startOffset <= range.offset) {
        if (_responder.didComplete) {
            [self.delegate dataManagerDidCompleteWithError:nil];
        }
        return;
    }
    
    //如果当前没有缓存数据
    //判断如果请求的数据比当前下载的数据大500k(向后拖拽) 或者比当前起始数据小(向前拖拽)则删除临时文件重新下载
    if (self.downloadManager.task == nil || self.downloadManager.task.error != nil || range.offset >= 300 * 1024 + self.downloadManager.currentOffset || range.offset < self.downloadManager.startOffset) {
        self.isTemp = NO;
        [self.downloadManager downLoadWithOffset:range.offset url:self.url];
    }
}

- (NSData *)readData:(SEEDataRange)range {
    //如果当前处于缓存播放状态直接返回数据
    if (self.isCache) {
        return [self see_dataWithRange:range];
    }
    
    //如果当前非缓存播放状态
    //请求的位置如果小于下载的起始位置不返回数据
    if (range.offset < self.downloadManager.startOffset) {
        return [NSData data];
    }
    //请求的位置如果大于下载到的位置不返回数据，等待后续数据下载后再返回
    if (range.offset > self.downloadManager.currentOffset) {
        return [NSData data];
    }
    //返回相对于整个文件指定位置大小的数据
    long long offset = range.offset;
    long long length = self.downloadManager.currentOffset - range.offset > range.length ? range.length : self.downloadManager.currentOffset - range.offset;
    SEEDataRange targetRange = {offset, length};
    return [self see_dataWithRange:targetRange];
}

//在缓冲过程中检测task是否正常 如果task出错则重新请求
- (void)see_checkTask {
    if (self.downloadManager.task.error != nil || self.downloadManager.task.state != NSURLSessionTaskStateRunning) {
        [self downLoadDataWithRange:(SEEDataRange){self.downloadManager.currentOffset - 1,2}];
    }
}

/**
 返回相对于临时文件的指定位置大小的数据

 @param range 相对于整个文件的位置大小
 @return 临时文件的指定位置大小的数据
 */
- (NSData *)see_dataWithRange:(SEEDataRange)range {
    NSData * data;
    SEEDataRange subRange;
    if (self.isCache) {
        data = [NSData dataWithContentsOfFile:[self see_cachePath:self.downloadManager.fileName]];
        subRange = range;
    }
    else {
        data = [NSData dataWithContentsOfFile:[self see_tempPath:self.downloadManager.fileName]];
        //计算出所需的位置相对于临时文件的位置
        subRange = (SEEDataRange){(range.offset - self.downloadManager.startOffset),range.length};
    }
    //SEEPlayerLog(@"从文件中截取的数据范围 offset:%lld length: %lld 文件大小%zd", subRange.offset, subRange.length, data.length);
    return [data subdataWithRange:NSMakeRange((NSUInteger)subRange.offset, (NSUInteger)subRange.length)];
}

- (BOOL)isExistsFile:(NSString *)fileName {
    return [self.fileManager fileExistsAtPath:[self see_cachePath:fileName]];
}

#pragma mark - SEEDownloadManagerDelegate
- (void)managerDidReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    self.mimeType = response.MIMEType;
    self.contentLength = response.expectedContentLength;
    //如果存在缓存文件中断下载加载缓存
    if ([self isExistsFile:self.downloadManager.fileName]) {
        NSData * data = [NSData dataWithContentsOfFile:[self see_cachePath:self.downloadManager.fileName]];
        if (data.length != self.contentLength) {
            //SEEPlayerLog(@"缓存中目标文件错误，重新加载");
            self.isCache = NO;
            completionHandler(NSURLSessionResponseAllow);
            return;
        }
        //SEEPlayerLog(@"缓存中存在目标资源，从缓存读取");
        self.isCache = YES;
        completionHandler(NSURLSessionResponseCancel);
        if (_responder.didComplete) {
            [self.delegate dataManagerDidCompleteWithError:nil];
        }
    }
    else {
        //SEEPlayerLog(@"缓存中无目标文件，从网络请求");
        self.isCache = NO;
        completionHandler(NSURLSessionResponseAllow);
    }
}

- (void)managerDidReceiveData:(NSData *)data {
    if (self.outputStream == nil) {
        NSError * error;
//        创建流并打开 如果有临时文件则将临时文件删除
        if ([[NSFileManager defaultManager]fileExistsAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:self.downloadManager.fileName]]) {
            //SEEPlayerLog(@"删除临时文件");
            [[NSFileManager defaultManager] removeItemAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:self.downloadManager.fileName] error:&error];
        }
        if (error == nil) {
            self.outputStream = [NSOutputStream outputStreamToFileAtPath:[self see_tempPath:self.downloadManager.fileName] append:YES];
            [self.outputStream open];
        }
    }
    //写入数据
    //SEEPlayerLog(@"写入数据");
    [self.outputStream write:data.bytes maxLength:data.length];
    if (_responder.didDidWriteData) {
        [self.delegate dataManagerDidWriteData];
    }
}

- (void)managerHadDownLoadAllDataWithError:(NSError *)error {
    //关闭流
    [self.outputStream close];
    self.outputStream = nil;
    //如果文件完整 保存
    if (self.downloadManager.startOffset == 0 && error == nil) {
        NSError * error;
        [self.fileManager moveItemAtPath:[self see_tempPath:self.downloadManager.fileName] toPath:[self see_cachePath:self.downloadManager.fileName] error:&error];
        if (error == nil) {
            self.isCache = YES;
            //SEEPlayerLog(@"文件下载完成，已保存到缓存，下一次resourceLoader接收到请求后走缓存文件取数据");
        }
    }
    self.isTemp = YES;
    if (_responder.didComplete) {
        [self.delegate dataManagerDidCompleteWithError:error];
    }
}


- (NSString *)see_cachePath:(NSString *)fileName {
    return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:fileName];
}

- (NSString *)see_tempPath:(NSString *)fileName {
    return [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
}

#pragma mark - getter & setter
- (void)setDelegate:(id<SEEDataManagerDelegate>)delegate {
    _delegate = delegate;
    _responder.didDidWriteData = [delegate respondsToSelector:@selector(dataManagerDidWriteData)];
    _responder.didComplete = [delegate respondsToSelector:@selector(dataManagerDidCompleteWithError:)];
}


@end
