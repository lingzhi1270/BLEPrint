//
//  HomeViewController.m
//  PrintDemo
//
//  Created by lingzhi on 2017/5/10.
//  Copyright © 2017年 lingzhi. All rights reserved.
//

#import "HomeViewController.h"
#import "ViewController.h"
#import "SVProgressHUD.h"



@interface HomeViewController ()
@end

@implementation HomeViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.backgroundColor = [UIColor grayColor];
    
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"搜索" style:UIBarButtonItemStylePlain target:self action:@selector(searchAction)];
    
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
   }

- (void)searchAction
{
    ViewController *vc = [[ViewController alloc] init];
    vc.title = @"蓝牙搜索";
    [self.navigationController pushViewController:vc animated:YES];
}



@end
