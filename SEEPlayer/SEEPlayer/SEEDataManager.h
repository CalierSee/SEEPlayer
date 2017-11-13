//
//  SEEFileManager.h
//  SEEPlayer
//
//  Created by 三只鸟 on 2017/10/28.
//  Copyright © 2017年 景彦铭. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SEEDownloadManager.h"

typedef struct DataRange{
    long long offset;
    long long length;
} SEEDataRange;



@protocol SEEDataManagerDelegate <NSObject>

- (void)dataManagerDidWriteData;

- (void)dataManagerDidCompleteWithError:(NSError *)error;

@end

@interface SEEDataManager : NSObject

@property (nonatomic,weak)id <SEEDataManagerDelegate> delegate;

- (instancetype)initWithURL:(NSURL *)url;

@property (nonatomic,strong,readonly)SEEDownloadManager * downloadManager;

/**
 读数据

 @param range 范围
 @return 数据
 */
- (NSData *)readData:(SEEDataRange)range;

- (void)downLoadDataWithRange:(SEEDataRange)range;

//文件类型
@property (nonatomic,copy,readonly)NSString * mimeType;
//contentLength
@property (nonatomic,assign,readonly)long long contentLength;




@end
