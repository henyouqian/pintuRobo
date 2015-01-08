//
//  SldHttpSession.h
//  Sld
//
//  Created by Wei Li on 14-4-19.
//  Copyright (c) 2014年 Wei Li. All rights reserved.
//

@interface SldHttpSession : NSObject<NSURLSessionDelegate>

@property NSURL *serverUrl;
+ (instancetype)defaultSession;
- (instancetype)initWithHost:(NSString*)host;

- (NSURLSessionDownloadTask*)downloadFromUrl:(NSString*)url
                 toPath:(NSString*)path
               withData:(id)data
      completionHandler:(void (^)(NSURL *location, NSURLResponse *response, NSError *error, id data))completionHandler;

- (void)cancelAllTask;

- (void)postToApi:(NSString*)api body:(NSDictionary*)body completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;



@end
