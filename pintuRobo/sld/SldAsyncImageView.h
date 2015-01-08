//
//  UIImageView+sldAsyncLoad.h
//  Sld
//
//  Created by Wei Li on 14-5-11.
//  Copyright (c) 2014年 Wei Li. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SldAsyncImageView : UIImageView
@property (atomic) BOOL loading;
@property (atomic) BOOL loadCanceling;
@property (atomic) NSString *serverUrl;
@property (atomic) NSString *localPath;
@property (atomic) NSURLSessionDownloadTask *task;
@property (atomic) NSString *key;

- (void)asyncLoadLocalImageWithPath:(NSString*)localPath anim:(BOOL)anim thumbSize:(int)thumbSize completion:(void (^)(void))completion;

- (void)asyncLoadImageWithUrl:(NSString*)url localPath:(NSString*)localPath showIndicator:(BOOL)showIndicator completion:(void (^)(void))completion;
- (void)releaseImage;
@end