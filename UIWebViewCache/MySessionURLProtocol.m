//
//  MySessionURLProtocol.m
//  UIWebViewCache
//
//  Created by pengkai on 2017/4/17.
//  Copyright © 2017年 changpengkai. All rights reserved.
//

#import "MySessionURLProtocol.h"
#import "WebCacheResponse.h"
#import "CustomWebCacheManager.h"

static NSString * const MyURLProtocolHandledKey = @"MySessionURLProtocolHandledKey";

@interface MySessionURLProtocol()<NSURLSessionDelegate,NSURLSessionDataDelegate>
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionDataTask *task;
@property (nonatomic, strong) NSMutableData *mutableData;
@property (nonatomic, strong) NSURLResponse *response;
@end

@implementation MySessionURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    
    static NSUInteger requestCount = 0;
    NSLog(@"MySessionURLProtocol Request #%lu: URL = %@", (unsigned long)requestCount++, request.URL.absoluteString);
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

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
    return [super requestIsCacheEquivalent:a toRequest:b];
}

// URL loading system 开始加载的入口（主要是实现session的请求）
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
        NSURLSessionConfiguration *configure = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.session = [NSURLSession sessionWithConfiguration:configure delegate:self delegateQueue:nil];
        self.task = [self.session dataTaskWithRequest:newRequest];
        [self.task resume];
    }
    
}

- (void)stopLoading
{
    [self.session invalidateAndCancel];
    self.session = nil;
}


#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error != nil) {
        [self.client URLProtocol:self didFailWithError:error];
    }else
    {
        [self.client URLProtocolDidFinishLoading:self];
        [self saveCachedResponse];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    completionHandler(NSURLSessionResponseAllow);
    
    self.response = response;
    self.mutableData = [[NSMutableData alloc] init];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    [self.client URLProtocol:self didLoadData:data];
    
    [self.mutableData appendData:data];

}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse * _Nullable))completionHandler
{
    completionHandler(proposedResponse);
}

////TODO: 重定向
//- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)newRequest completionHandler:(void (^)(NSURLRequest *))completionHandler
//{
//    NSMutableURLRequest*    redirectRequest;
//    redirectRequest = [newRequest mutableCopy];
//    [[self class] removePropertyForKey:MyURLProtocolHandledKey inRequest:redirectRequest];
//    [[self client] URLProtocol:self wasRedirectedToRequest:redirectRequest redirectResponse:response];
//    
//    [self.task cancel];
//    [[self client] URLProtocol:self didFailWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
//}

//- (instancetype)initWithRequest:(NSURLRequest *)request cachedResponse:(NSCachedURLResponse *)cachedResponse client:(id<NSURLProtocolClient>)client
//{
//    
////    NSMutableURLRequest*    redirectRequest;
////    redirectRequest = [request mutableCopy];
////    
////    //添加认证信息
////    NSString *authString = [[[NSString stringWithFormat:@"%@:%@", kGlobal.userInfo.sAccount, kGlobal.userInfo.sPassword] dataUsingEncoding:NSUTF8StringEncoding] base64EncodedString];
////    authString = [NSString stringWithFormat: @"Basic %@", authString];
////    [redirectRequest setValue:authString forHTTPHeaderField:@"Authorization"];
////    NSLog(@"拦截的请求:%@",request.URL.absoluteString);
//    
////    self = [super initWithRequest:redirectRequest cachedResponse:cachedResponse client:client];
//    if (self) {
//        
//        // Some stuff
//    }
//    return self;
//}

//- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler{
//    
//    NSLog(@"自定义Protocol开始认证...");
//    NSString *authMethod = [[challenge protectionSpace] authenticationMethod];
//    NSLog(@"%@认证...",authMethod);
//    
//    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
//        NSURLCredential *card = [[NSURLCredential alloc] initWithTrust:challenge.protectionSpace.serverTrust];
//        completionHandler(NSURLSessionAuthChallengeUseCredential,card);
//    }
//    
//    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodNTLM]) {
//        if ([challenge previousFailureCount] == 0) {
//            NSURLCredential *credential = [NSURLCredential credentialWithUser:kGlobal.userInfo.sAccount password:kGlobal.userInfo.sPassword persistence:NSURLCredentialPersistenceForSession];
//            [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
//            completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
//        }else{
//            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge,nil);
//        }
//    }
//
//    NSLog(@"自定义Protocol认证结束");
//}

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

- (WebCacheResponse *)cachedResponseForCurrentRequest {
    
    return [[CustomWebCacheManager shareWebCacheManager]cacheResponseWithURL:self.request.URL.absoluteString];
}

@end
