//
//  ViewController.m
//  musicOC
//
//  Created by 三只鸟 on 2017/9/19.
//  Copyright © 2017年 三只鸟. All rights reserved.
//

#import "ViewController.h"
#import "SEEPlayerManager.h"
@interface ViewController ()

@property(nonatomic,strong)SEEPlayerManager * manager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _manager = [[SEEPlayerManager alloc]init];
    [_manager playWithURL:[NSURL URLWithString:@"http://61.130.25.197/file3.data.weipan.cn/20266848/548809575ec068839931d713f0fdeff698622d00?ip=1505904903,125.120.78.122&ssig=6JVZwkq%2By3&Expires=1505905503&KID=sae,l30zoo1wmz&fn=%E6%9D%A8%E5%AD%90%E5%A7%97%20-%20%E7%BB%99%E6%88%91%E4%B8%80%E4%B8%AA%E5%90%BB.mp3&skiprd=2&se_ip_debug=125.120.78.122&corp=2&from=1221134&wsiphost=local"]];

    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
