//
//  ImageBrowserController.h
//  pintuRobo
//
//  Created by 李炜 on 15/1/8.
//  Copyright (c) 2015年 李炜. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TumblrImage;

@interface ImageBrowserController : UIViewController
@property TumblrImage *image;
@property NSMutableArray *images;
@end
