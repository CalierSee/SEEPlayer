//
//  avplayerVC.m
//  TBPlayer
//
//  Created by qianjianeng on 16/2/27.
//  Copyright © 2016年 SF. All rights reserved.
//

#import "avplayerVC.h"
#import "TBPlayer.h"

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height


@interface avplayerVC ()

@property (nonatomic, strong) TBPlayer *player;
@property (nonatomic, strong) UIView *showView;
@end

@implementation avplayerVC

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    
    self.showView = [[UIView alloc] init];
    self.showView.backgroundColor = [UIColor redColor];
    self.showView.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
    [self.view addSubview:self.showView];
    
    
    
    NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
    NSString *movePath =  [document stringByAppendingPathComponent:@"保存数据.mp4"];
    
    NSURL *localURL = [NSURL fileURLWithPath:movePath];
    
    NSURL *url2 = [NSURL URLWithString:@"http://zyvideo1.oss-cn-qingdao.aliyuncs.com/zyvd/7c/de/04ec95f4fd42d9d01f63b9683ad0"];
    //url2 = [NSURL URLWithString:@"http://61.130.25.197/file3.data.weipan.cn/20266848/548809575ec068839931d713f0fdeff698622d00?ip=1505904903,125.120.78.122&ssig=6JVZwkq%2By3&Expires=1505905503&KID=sae,l30zoo1wmz&fn=%E6%9D%A8%E5%AD%90%E5%A7%97%20-%20%E7%BB%99%E6%88%91%E4%B8%80%E4%B8%AA%E5%90%BB.mp3&skiprd=2&se_ip_debug=125.120.78.122&corp=2&from=1221134&wsiphost=local"];
    
    [[TBPlayer sharedInstance] playWithUrl:url2 showView:self.showView];

}




@end
