//
//  RoboData.m
//  pintuRobo
//
//  Created by 李炜 on 15/1/7.
//  Copyright (c) 2015年 李炜. All rights reserved.
//

#import "RoboData.h"

@implementation RoboData

static RoboData* _inst;

+ (instancetype)inst {
    if (_inst == nil) {
        _inst = [[RoboData alloc] init];
    }
    return _inst;
}

@end

#pragma mark - TumblrBlog
@implementation TumblrBlog

- (instancetype)initWithDict:(NSDictionary*)dict {
    if (self = [super init]) {
        self.Name = [dict objectForKey:@"Name"];
        self.Url = [dict objectForKey:@"Url"];
        self.Description = [dict objectForKey:@"Description"];
        self.IsNswf = [(NSNumber*)[dict objectForKey:@"IsNswf"] boolValue];
        self.Avartar64 = [dict objectForKey:@"Avartar64"];
        self.Avartar128 = [dict objectForKey:@"Avartar128"];
        self.ImageFetchOffset = [(NSNumber*)[dict objectForKey:@"ImageFetchOffset"] intValue];
        self.FetchFinish = [(NSNumber*)[dict objectForKey:@"FetchFinish"] boolValue];
    }
    return self;
}

- (instancetype)initWithRawDict:(NSDictionary*)dict {
    if (self = [super init]) {
        self.Name = [dict objectForKey:@"name"];
        self.Url = [dict objectForKey:@"url"];
        self.Description = [dict objectForKey:@"description"];
        self.IsNswf = [(NSNumber*)[dict objectForKey:@"is_nsfw"] boolValue];
        self.Avartar64 = @"";
        self.Avartar128 = @"";
        self.ImageFetchOffset = 0;
        self.FetchFinish = NO;
    }
    return self;
}

@end

#pragma mark - TumblrImageSize
@implementation TumblrImageSize

- (instancetype)initWithDict:(NSDictionary*)dict {
    if (self = [super init]) {
        self.Width = [(NSNumber*)dict[@"Width"] intValue];
        self.Height = [(NSNumber*)dict[@"Height"] intValue];
        self.Url = dict[@"Url"];
    }
    return self;
}

@end

#pragma mark - TumblrImage
@implementation TumblrImage

- (instancetype)initWithDict:(NSDictionary*)dict {
    if (self = [super init]) {
        self.Key = dict[@"Key"];
        self.Sizes = [NSMutableArray array];
        self.PostId = [(NSNumber*)dict[@"PostId"] longLongValue];
        NSArray *sizes = dict[@"Sizes"];
        for (NSDictionary *sizeDict in sizes) {
            TumblrImageSize *size = [[TumblrImageSize alloc] initWithDict:sizeDict];
            [self.Sizes addObject:size];
        }
        TumblrImageSize *size = self.Sizes.lastObject;
        _thumbUrl = size.Url;
        
        //
        NSString *lurl = [_thumbUrl lowercaseString];
        NSRange range = [lurl rangeOfString:@".gif"];
        BOOL isGif = NO;
        if (range.location != NSNotFound) {
            isGif = YES;
        }
        
        int sizeLimit = 300 * 500;
        if (isGif) {
            sizeLimit = 150 * 250;
        }
        
        for (TumblrImageSize *size in self.Sizes) {
            if (size.Width * size.Height >= sizeLimit ) {
                _fitSize = size;
            } else {
                break;
            }
        }
        
        if (_fitSize) {
            _imageUrl = _fitSize.Url;
        } else {
            if (!isGif) {
                TumblrImageSize *size = [self.Sizes firstObject];
                if (size.Width * size.Height > 200 * 300) {
                    _fitSize = size;
                    _imageUrl = _fitSize.Url;
                }
            }
        }
    }
    return self;
}

@end