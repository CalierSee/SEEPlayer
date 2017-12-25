//
//  SEEPlayer_Header.h
//  SEEPlayer
//
//  Created by 三只鸟 on 2017/10/30.
//  Copyright © 2017年 景彦铭. All rights reserved.
//

#ifndef SEEPlayer_Header_h
#define SEEPlayer_Header_h

#ifdef DEBUG
#define SEEPlayerLog(...) NSLog(__VA_ARGS__)
#else
#define SEEPlayerLog(...)
#endif
//缓冲状态通知
#define SEEPlayerBufferingNotification @"SEEPlayerBufferingNotification"
//缓冲状态检查task
#define SEEPlayerCheckTaskNotification @"SEEPlayerCheckTaskNotification"
//播放器关闭通知
#define SEEPlayerClearNotification @"SEEPlayerClearNotification"
//获取到目标文件名通知
#define SEEDownloadManagerDidReceiveFileNameNotification @"SEEDownloadManagerDidReceiveFileNameNotification"

#define SEEPlayerWillResignActiveNotification @"SEEPlayerWillResignActiveNotification"

#define SEEPlayerDidBecomeActiveNotification @"SEEPlayerDidBecomeActiveNotification"

#endif /* SEEPlayer_Header_h */
