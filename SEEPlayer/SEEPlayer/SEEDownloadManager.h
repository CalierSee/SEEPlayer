//
//  SEEDownloadManager.h
//  SEEPlayer
//
//  Created by 三只鸟 on 2017/10/27.
//  Copyright © 2017年 景彦铭. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SEEDownloadManagerDelegate <NSObject>
//接收到数据的回调
- (void)managerDidReceiveData:(NSData *)data;

//下载完所有数据
- (void)managerHadDownLoadAllDataWithError:(NSError *)error;

//接收到响应
- (void)managerDidReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler;

@end

@interface SEEDownloadManager : NSObject

//当前下载的起始偏移量
@property (nonatomic,assign,readonly)long long startOffset;
//当前下载到的偏移量
@property (nonatomic,assign,readonly)long long  currentOffset;

//文件名
@property (nonatomic,copy,readonly)NSString * fileName;

@property (nonatomic,strong,readonly)NSURLSessionDataTask * task;

@property (nonatomic,weak)id<SEEDownloadManagerDelegate> delegate;

//下载数据
- (void)downLoadWithOffset:(long long)offset url:(NSURL *)url;

@end
