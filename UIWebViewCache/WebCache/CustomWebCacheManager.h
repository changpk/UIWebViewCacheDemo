//
//  CustomWebCacheManager.h
//  UIWebViewCache
//
//  Created by pengkai on 2017/4/12.
//  Copyright © 2017年 changpengkai. All rights reserved.
//

#import <Foundation/Foundation.h>
@class WebCacheResponse;
@interface CustomWebCacheManager : NSObject
+ (instancetype)shareWebCacheManager;
- (void)loadCacheTable;
- (void)saveWebCacheResponse:(WebCacheResponse *)cache;
- (WebCacheResponse *)cacheResponseWithURL:(NSString *)url;
@end
