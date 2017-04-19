//
//  CustomWebCacheManager.m
//  UIWebViewCache
//
//  Created by pengkai on 2017/4/12.
//  Copyright © 2017年 changpengkai. All rights reserved.
//

#import "CustomWebCacheManager.h"
#import "FMDB.h"
#import "WebCacheResponse.h"

@interface CustomWebCacheManager ()
@property (nonatomic, strong) FMDatabaseQueue *dbQueue;
@end

@implementation CustomWebCacheManager

+ (instancetype)shareWebCacheManager {
    static dispatch_once_t onceToken;
    static CustomWebCacheManager * webCacheManager = nil;
    dispatch_once(&onceToken, ^{
        webCacheManager = [[CustomWebCacheManager alloc]init];
    });
    return webCacheManager;
}

- (void)loadCacheTable {
    [[CustomWebCacheManager shareWebCacheManager] createURLCacheTable];
}

- (void)initCacheDB {
    
    NSString *docsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *dbPath   = [docsPath stringByAppendingPathComponent:@"webucache.db"];
    NSLog(@"dbPath is %@",dbPath);
//    self.db = [FMDatabase databaseWithPath:dbPath];
    self.dbQueue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
}

// 每次操作前是否需要打开和关闭数据库
- (void)createURLCacheTable {
    
    [self initCacheDB];
    
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *sql = @"create table if not exists URLCacheList (url TEXT,data BLOB,timestamp TEXT,mimeType TEXT,textEncoding TEXT)";
        [db executeUpdate:sql];
    }];

}

- (void)saveWebCacheResponse:(WebCacheResponse *)cache {
    
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdateWithFormat:@"insert into URLCacheList (url,data,timestamp,mimeType,textEncoding)values(%@,%@,%@,%@,%@)",cache.url,cache.data,cache.timestamp,cache.mimeType,cache.encoding];
    }];
}

- (WebCacheResponse *)cacheResponseWithURL:(NSString *)url {
    
    __block WebCacheResponse *cacheResponse = nil;
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *resultSet = [db executeQueryWithFormat:@"select * from URLCacheList where url = %@",url];
        
        while ([resultSet next]) {
            NSDictionary *resultDic = [resultSet resultDictionary];
            cacheResponse = [[WebCacheResponse alloc]initWithDictionary:resultDic error:nil];
        }
        
    }];
    return cacheResponse;
}

@end
