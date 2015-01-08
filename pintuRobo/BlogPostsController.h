//
//  BlogPostsController.h
//  pintuRobo
//
//  Created by 李炜 on 14/12/28.
//  Copyright (c) 2014年 李炜. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TumblrImage;

@interface BlogPostsController : UICollectionViewController

@end

//===========================
@interface BlogPostsCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet SldAsyncImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *bottomLabel;
@property TumblrImage* image;
@end