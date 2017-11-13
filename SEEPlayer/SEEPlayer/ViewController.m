//
//  ViewController.m
//  SEEPlayer
//
//  Created by 三只鸟 on 2017/10/26.
//  Copyright © 2017年 景彦铭. All rights reserved.
//

#import "ViewController.h"
#import "SEEPlayer.h"
@interface ViewController () <SEEPlayerDelegate>

@property (nonatomic,strong)SEEPlayer * player;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _player = [[SEEPlayer alloc]initWithURL:@"http://he.yinyuetai.com/uploads/videos/common/88CE01595A940BC83C7AB2C616308D62.mp4?sc=9b0ddcaad115e009&br=3099&vid=2763591&aid=25339&area=KR&vst=0"];
    [self.view addSubview:_player.displayView];
    _player.delegate = self;
    _player.displayView.frame = CGRectMake(0, 0, self.view.bounds.size.width, 200);
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
