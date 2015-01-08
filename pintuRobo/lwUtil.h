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
+ (NSString*)sha1WithString:(NSString*)string;
+ (UIAlertView*)alertWithTitle:(NSString*)title text:(NSString*)text buttonTitle:(NSString*)buttonTitle action:(void (^)(void))action;
+ (void)alertHTTPError:(NSError*)error data:(NSData*)data;

+ (NSString*)makeImagePath:(NSString*)url;
+ (NSString*)makeImagePathWithKey:(NSString*)key;
@end
