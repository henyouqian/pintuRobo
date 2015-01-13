//
//  lwUtil.h
//  pintuRobo
//
//  Created by 李炜 on 14/12/29.
//  Copyright (c) 2014年 李炜. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface lwUtil : NSObject

+ (NSString*)makeDocPath:(NSString*) path;
+ (NSString*)makeTempPath:(NSString*)fileName;

+ (NSString*)sha1WithString:(NSString*)string;
+ (NSString*)sha1WithData:(NSData*)data;

+ (UIAlertView*)alertWithTitle:(NSString*)title text:(NSString*)text buttonTitle:(NSString*)buttonTitle action:(void (^)(void))action;
+ (void)alertHTTPError:(NSError*)error data:(NSData*)data;

+ (NSString*)makeImagePathWithUrl:(NSString*)url;
+ (NSString*)makeImagePathWithKey:(NSString*)key;

+ (BOOL)isGifUrl:(NSString*)url;

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;

@end
