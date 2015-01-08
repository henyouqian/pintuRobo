//
//  lwUtil.m
//  pintuRobo
//
//  Created by 李炜 on 14/12/29.
//  Copyright (c) 2014年 李炜. All rights reserved.
//

#import "lwUtil.h"

@implementation lwUtil

+ (NSString*)makeDocPath:(NSString*) path {
    NSString *docsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    return [docsPath stringByAppendingPathComponent:path];
}

+ (NSString*)sha1WithString:(NSString*)string {
    SHA1 *sha1 = [SHA1 sha1WithString:string];
    NSData *nsd = [NSData dataWithBytes:sha1.buffer length:sha1.bufferSize];
    NSString *output = [nsd hexadecimalString];
    return output;
}

+ (UIAlertView*)alertWithTitle:(NSString*)title text:(NSString*)text buttonTitle:(NSString*)buttonTitle action:(void (^)(void))action {
    RIButtonItem *buttonItem = nil;
    if (buttonTitle && buttonTitle.length > 0) {
        buttonItem = [RIButtonItem itemWithLabel:buttonTitle action:action];
    }
    UIAlertView *view = [[UIAlertView alloc] initWithTitle:title
                                                   message:text
                                          cancelButtonItem:buttonItem
                                          otherButtonItems:nil];
    [view show];
    return view;
}

+ (void)alertHTTPError:(NSError*)error data:(NSData*)data {
    if (error == nil) return;
    if (error.code == 400 || error.code == 500) {
        NSError *jsonErr;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonErr];
        if (jsonErr) {
            [lwUtil alertWithTitle:@"Json error" text:[jsonErr localizedDescription] buttonTitle:@"OK" action:nil];
            return;
        }
        NSString *errorType = [dict objectForKey:@"Error"];
        NSString *errorString = [dict objectForKey:@"ErrorString"];
        if (errorType && errorString) {
            [lwUtil alertWithTitle:errorType text:errorString buttonTitle:@"OK" action:nil];
            return;
        } else {
            [lwUtil alertWithTitle:@"Error format error" text:[jsonErr localizedDescription] buttonTitle:@"OK" action:nil];
            return;
        }
    } else {
        lwError("网络异常:%@", [error localizedDescription]);
    }
}

+ (NSString*)makeImagePath:(NSString*)url {
    static dispatch_once_t onceToken;
    NSString *imgFolder = @"img";
    dispatch_once(&onceToken, ^{
        //creat image cache dir
        NSString *imgCacheDir = [lwUtil makeDocPath:imgFolder];
        [[NSFileManager defaultManager] createDirectoryAtPath:imgCacheDir withIntermediateDirectories:YES attributes:nil error:nil];
    });
    
    NSString *imageName = [lwUtil sha1WithString:url];
    NSString *lurl = [url lowercaseString];
    NSRange range = [lurl rangeOfString:@".jpg"];
    if (range.location != NSNotFound) {
        return [lwUtil makeDocPath:[NSString stringWithFormat:@"%@/%@.jpg", imgFolder, imageName]];
    }
    range = [lurl rangeOfString:@".jpeg"];
    if (range.location != NSNotFound) {
        return [lwUtil makeDocPath:[NSString stringWithFormat:@"%@/%@.jpg", imgFolder, imageName]];
    }
    range = [lurl rangeOfString:@".gif"];
    if (range.location != NSNotFound) {
        return [lwUtil makeDocPath:[NSString stringWithFormat:@"%@/%@.gif", imgFolder, imageName]];
    }
    range = [lurl rangeOfString:@".png"];
    if (range.location != NSNotFound) {
        return [lwUtil makeDocPath:[NSString stringWithFormat:@"%@/%@.png", imgFolder, imageName]];
    }
    return [lwUtil makeDocPath:[NSString stringWithFormat:@"%@/%@", imgFolder, imageName]];
}

+ (NSString*)makeImagePathWithKey:(NSString*)key {
    static dispatch_once_t onceToken;
    NSString *imgFolder = @"img";
    dispatch_once(&onceToken, ^{
        //creat image cache dir
        NSString *imgCacheDir = [lwUtil makeDocPath:imgFolder];
        [[NSFileManager defaultManager] createDirectoryAtPath:imgCacheDir withIntermediateDirectories:YES attributes:nil error:nil];
    });
    
    return [lwUtil makeDocPath:[NSString stringWithFormat:@"%@/%@", imgFolder, key]];
}

@end

