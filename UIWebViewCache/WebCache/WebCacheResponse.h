//
//  WebCacheResponse.h
//  UIWebViewCache
//
//  Created by pengkai on 2017/4/12.
//  Copyright © 2017年 changpengkai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSONModelLib.h"

@interface WebCacheResponse : JSONModel
@property (nonatomic, strong) NSData<Optional> *data;
@property (nonatomic, strong) NSString<Optional> *url;
@property (nonatomic, strong) NSString<Optional> *timestamp;
@property (nonatomic, strong) NSString<Optional> *encoding;
@property (nonatomic, strong) NSString<Optional> *mimeType;

@end
