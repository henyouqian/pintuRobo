//
//  RoboData.h
//  pintuRobo
//
//  Created by 李炜 on 15/1/7.
//  Copyright (c) 2015年 李炜. All rights reserved.
//

@class TumblrBlog;

@interface RoboData : NSObject

+ (instancetype)inst;

@property TumblrBlog *blog;
@property BOOL hasImageDeleted;

@end


#pragma mark - TumblrBlog
@interface TumblrBlog : NSObject

@property NSString *Name;
@property NSString *Url;
@property NSString *Description;
@property BOOL IsNswf;
@property NSString *Avartar64;
@property NSString *Avartar128;
@property int ImageFetchOffset;
@property int FetchFinish;

- (instancetype)initWithDict:(NSDictionary*)dict;
- (instancetype)initWithRawDict:(NSDictionary*)dict;

@end


#pragma mark - TumblrImageSize
@interface TumblrImageSize : NSObject

@property int Width;
@property int Height;
@property NSString *Url;

@end

#pragma mark - TumblrImage
@interface TumblrImage : NSObject

@property NSString *Key;
@property SInt64 PostId;
@property NSMutableArray *Sizes;

@property NSString *thumbUrl;
@property NSString *imageUrl;

@property TumblrImageSize *fitSize;

- (instancetype)initWithDict:(NSDictionary*)dict;

@end