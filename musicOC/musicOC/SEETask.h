//
//  SEETask.h
//  musicOC
//
//  Created by 三只鸟 on 2017/9/19.
//  Copyright © 2017年 三只鸟. All rights reserved.
//  数据下载 缓存

#import <Foundation/Foundation.h>

@class SEETask;

@protocol SEETaskDelegate <NSObject>

- (void)task:(SEETask *)task didReceiveData:(NSData *)data;

- (void)task:(SEETask *)task didCompleteWithError:(NSError *)error;

@end

@interface SEETask : NSObject <NSURLSessionDataDelegate>

/**
 数据总量
 */
@property (nonatomic,assign,readonly)NSUInteger  totalBytes;

/**
 当前下载数据总量
 */
@property (nonatomic,assign,readonly)NSUInteger  downloadTotalBytes;

/**
 当前下载起始位置偏移量
 */
@property (nonatomic,assign,readonly)NSUInteger  startOffset;

/**
 数据类型
 */
@property (nonatomic,copy)NSString * mimeType;

/**
 文件名
 */
@property (nonatomic,copy,readonly)NSString * fileName;

/**
 类型
 */
@property (nonatomic,copy,readonly)NSString * contentType;

- (void)downloadRequest:(NSURLRequest *)request startOffset:(NSUInteger)offset;

@property (nonatomic,weak)id <SEETaskDelegate> delegate;

@end
