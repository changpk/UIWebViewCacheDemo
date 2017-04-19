//
//  MyURLProtocol.m
//  UIWebViewCache
//
//  Created by pengkai on 2017/4/12.
//  Copyright © 2017年 changpengkai. All rights reserved.
//

#import "MyURLProtocol.h"
#import "WebCacheResponse.h"
#import "CustomWebCacheManager.h"

static NSString * const MyURLProtocolHandledKey = @"MyURLProtocolHandledKey";

@interface MyURLProtocol ()<NSURLConnectionDelegate>
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *mutableData;
@property (nonatomic, strong) NSURLResponse *response;
@end

@implementation MyURLProtocol

// 每次发送请求前，URL loading system 会询问所有注册的URLProtcol子类（自定义注册的URLProtcol表）是否需要接管处理这个请求，只要其中一个处理了，那么就自动忽略所有其它的protocol，所以多个protocol同时存在的时候，注册顺序对后续处理请求是有关系的；都不处理的话，则走系统默认的系统行为,返回YES则同时会创建一个MyURLProtocol实例
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    
    static NSUInteger requestCount = 0;
    NSLog(@"MyURLProtocol Request #%lu: URL = %@", (unsigned long)requestCount++, request.URL.absoluteString);
    if ([NSURLProtocol propertyForKey:MyURLProtocolHandledKey inRequest:request]) {
        return NO;
    }
    return YES;
}

// 规范请求形式并返回（一般不需要,可以设置请求头，修改host等）
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    
    //    [self redirectHostInRequset:[NSMutableURLRequest requestWithURL:request.URL]];
    return request;
}

// 判断两个请求是否相等，如果相同并且有缓存则使用缓存（一般调用父类的缓存实现即可）
+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
    return [super requestIsCacheEquivalent:a toRequest:b];
}

// URL loading system 开始加载的入口（主要是实现connection的请求）
- (void)startLoading {
    
    WebCacheResponse *cachedResponse = [self cachedResponseForCurrentRequest];
    if (cachedResponse) {
        NSLog(@" from cache");
    
        NSData *data = cachedResponse.data;
        NSString *mimeType = cachedResponse.mimeType;
        NSString *encoding = cachedResponse.encoding;
        

        NSURLResponse *response = [[NSURLResponse alloc] initWithURL:self.request.URL
                                                            MIMEType:mimeType
                                               expectedContentLength:data.length
                                                    textEncodingName:encoding];

        [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [self.client URLProtocol:self didLoadData:data];
        [self.client URLProtocolDidFinishLoading:self];
        
    } else {
        // 5.
        NSLog(@"serving response from NSURLConnection, url is %@",self.request.URL.absoluteString);
        
        // 下面方法要求的参数是NSMutableURLRequest
        NSMutableURLRequest *newRequest = [self.request mutableCopy];
        // 标记此request已经处理过了
        [NSURLProtocol setProperty:@YES forKey:MyURLProtocolHandledKey inRequest:newRequest];
        self.connection = [NSURLConnection connectionWithRequest:newRequest delegate:self];
    }

}

// URL loading system  结束加载的入口（主要是取消一个connection）
- (void)stopLoading {
    
    [self.connection cancel];
    self.connection = nil;
}


#pragma mark - NSURLConnectionDelegate

/*
 NSURLProtocolClient 主要是用来告诉URL loading system中请求的处理，数据，失败等回调
 */

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    self.response = response;
    self.mutableData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
    [self.mutableData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self.client URLProtocolDidFinishLoading:self];
    [self saveCachedResponse];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self.client URLProtocol:self didFailWithError:error];
}

- (WebCacheResponse *)cachedResponseForCurrentRequest {

   return [[CustomWebCacheManager shareWebCacheManager]cacheResponseWithURL:self.request.URL.absoluteString];
    
}


- (void)saveCachedResponse {
    
    NSLog(@"saving cached response url is %@",self.request.URL.absoluteString);
    
    WebCacheResponse *cachedResponse = [[WebCacheResponse alloc]init];
    cachedResponse.data = self.mutableData;
    cachedResponse.url = self.request.URL.absoluteString;
    cachedResponse.timestamp = [NSString stringWithFormat:@"%f",[[NSDate date]timeIntervalSince1970]];
    cachedResponse.mimeType = self.response.MIMEType;
    cachedResponse.encoding = self.response.textEncodingName;
    
    [[CustomWebCacheManager shareWebCacheManager]saveWebCacheResponse:cachedResponse];
}


/* 修改host的例子  */
+(NSMutableURLRequest*)redirectHostInRequset:(NSMutableURLRequest*)request
{
    if ([request.URL host].length == 0) {
        return request;
    }
    
    NSString *originUrlString = [request.URL absoluteString];
    NSString *originHostString = [request.URL host];
    NSRange hostRange = [originUrlString rangeOfString:originHostString];
    if (hostRange.location == NSNotFound) {
        return request;
    }
    //定向到bing搜索主页
    NSString *ip = @"www.google.com";
    
    // 替换域名
    NSString *urlString = [originUrlString stringByReplacingCharactersInRange:hostRange withString:ip];
    NSURL *url = [NSURL URLWithString:urlString];
    request.URL = url;
    
    return request;
}

@end
