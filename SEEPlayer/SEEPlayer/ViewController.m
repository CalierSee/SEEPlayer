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
    UIScrollView * scrollView = [[UIScrollView alloc]init];
    scrollView.frame = self.view.bounds;
    scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, 1000);
    [self.view addSubview:scrollView];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"new url" style:UIBarButtonItemStyleDone target:self action:@selector(see_newURL:)];
    SEEPlayer * player = [[SEEPlayer alloc]initWithURL:@"http://he.yinyuetai.com/uploads/videos/common/88CE01595A940BC83C7AB2C616308D62.mp4?sc=9b0ddcaad115e009&br=3099&vid=2763591&aid=25339&area=KR&vst=0"];
    _player = player;
    [scrollView addSubview:_player.displayView];
    _player.delegate = self;
    _player.displayView.frame = CGRectMake(0, 0, self.view.bounds.size.width, 200);
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.player closeAndInvalidate];
}

- (void)dealloc {
//    NSLog(@"1111");
}

- (void)see_newURL:(UIButton *)sender {
    [self.player changeCurrentURL:@"http://183.60.197.26/5/r/u/s/f/rusfwvmgaychpihleskfkubbbsasds/he.yinyuetai.com/31BA015D2B8D04657E61B4BF0B448B79.mp4?sc=17e20a129678898e&br=3135&vid=2907537&aid=1108&area=HT&vst=0"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
