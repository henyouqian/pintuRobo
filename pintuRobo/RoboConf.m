//
//  RoboConf.m
//  pintuRobo
//
//  Created by 李炜 on 15/1/6.
//  Copyright (c) 2015年 李炜. All rights reserved.
//

#import "RoboConf.h"

@implementation RoboConf

static RoboConf* _inst = nil;

+ (instancetype)inst {
    if (_inst == nil) {
        _inst = [[RoboConf alloc] init];
    }
    return _inst;
}

- (instancetype)init {
    if (self = [super init]) {
        _SERVER_HOST = @"http://192.168.2.55:9998";
//        _SERVER_HOST = @"http://192.168.1.43:9998";
//        _SERVER_HOST = @"http://sld.pintugame.com";
        _SERVER_SECRET = @"isjdifj242i0o;a;lidf";
        _IMAGE_DOWNLOAD_HOST = @"http://sld.pintugame.com";
    }
    return self;
}

@end
