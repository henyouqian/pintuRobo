//
//  SldHttpSession.m
//  Sld
//
//  Created by Wei Li on 14-4-19.
//  Copyright (c) 2014年 Wei Li. All rights reserved.
//

#import "SldHttpSession.h"
#import "RoboConf.h"

@interface SldHttpSession()
@property (nonatomic) NSURLSession *session;
@end

@implementation SldHttpSession

+ (instancetype)defaultSession {
    static SldHttpSession *sharedSession = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSession = [[self alloc] initWithHost:[RoboConf inst].SERVER_HOST];
    });
    
    return sharedSession;
}

- (instancetype)initWithHost:(NSString*)host {
    if (self = [super init]) {
        _serverUrl = [NSURL URLWithString:host];
        
        NSURLSessionConfiguration *conf = [NSURLSessionConfiguration defaultSessionConfiguration];
        conf.timeoutIntervalForRequest = 300;
        self.session = [NSURLSession sessionWithConfiguration:conf delegate:self delegateQueue: [NSOperationQueue mainQueue]];
    }
    
    return self;
}

- (void)cancelAllTask {
    [_session invalidateAndCancel];
    NSURLSessionConfiguration *conf = [NSURLSessionConfiguration defaultSessionConfiguration];
    _session = [NSURLSession sessionWithConfiguration:conf delegate:nil delegateQueue: [NSOperationQueue mainQueue]];
}

- (NSURLSessionDownloadTask*)downloadFromUrl:(NSString*)url
                 toPath:(NSString*)path
               withData:(id)data
      completionHandler:(void (^)(NSURL *location, NSURLResponse *response, NSError *error, id data))completionHandler
{
    NSURL * nsurl = [NSURL URLWithString:url];
    
    NSURLSessionDownloadTask *task =[self.session downloadTaskWithURL:nsurl
        completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        if(error == nil) {
            NSError *err = nil;
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSURL *destURL = [NSURL fileURLWithPath:path];
            if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                completionHandler(destURL, response, nil, data);
            } else {
                if ([fileManager moveItemAtURL:location
                                         toURL:destURL
                                         error: &err]) {
                    completionHandler(destURL, response, nil, data);
                } else {
                    completionHandler(nil, response, err, data);
                }
            }
        } else {
            completionHandler(nil, response, error, data);
        }
    }];
    [task resume];
    return task;
}

- (void)postToApi:(NSString*)api body:(NSDictionary*)body completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    NSURL * url = [NSURL URLWithString:api relativeToURL:_serverUrl];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    
    NSMutableDictionary *bodyWithSecret = [NSMutableDictionary dictionary];
    
    if (body) {
        bodyWithSecret = [NSMutableDictionary dictionaryWithDictionary:body];
    }
    
    bodyWithSecret[@"Secret"] = [RoboConf inst].SERVER_SECRET;
    NSError *error;
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:bodyWithSecret options:0 error:&error];
    if (error) {
        lwError("json encode error: %@", error);
        return;
    }
    [request setHTTPBody:bodyData];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                     NSInteger code = [(NSHTTPURLResponse*)response statusCode];
                                                     if (!error && code != 200) {
                                                         //lwError("post error: statusCode=%ld", (long)code);
                                                         NSString *desc = [NSString stringWithFormat:@"Http error: statusCode=%ld", (long)code];
                                                         error = [NSError errorWithDomain:@"lw" code:code userInfo:@{NSLocalizedDescriptionKey:desc}];
                                                     }
                                                     completionHandler(data, response, error);
                                                 }];
    [task resume];
}

@end
