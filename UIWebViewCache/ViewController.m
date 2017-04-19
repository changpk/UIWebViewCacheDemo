//
//  ViewController.m
//  UIWebViewCache
//
//  Created by pengkai on 2017/4/12.
//  Copyright © 2017年 changpengkai. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import "FMDatabaseQueue.h"
@interface ViewController ()
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self addWebView];
}

- (void)addWebView {
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    UIWebView *mainWebView = [[UIWebView alloc]initWithFrame:CGRectMake(20, 20, screenWidth - 2 * 20, screenHeight - 2 * 20)];
    mainWebView.backgroundColor = [UIColor brownColor];
    [mainWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://news.163.com"]]];
    [self.view addSubview:mainWebView];
    
}

@end
