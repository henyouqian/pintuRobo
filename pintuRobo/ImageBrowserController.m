//
//  ImageBrowserController.m
//  pintuRobo
//
//  Created by 李炜 on 15/1/8.
//  Copyright (c) 2015年 李炜. All rights reserved.
//

#import "ImageBrowserController.h"
#import "RoboData.h"
#import "lwUtil.h"

@interface ImageBrowserController ()
@property (weak, nonatomic) IBOutlet SldAsyncImageView *imageView;

@end

@implementation ImageBrowserController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *imageUrl = _image.imageUrl;
    if (imageUrl == nil) {
        TumblrImageSize *size = _image.Sizes[0];
        imageUrl = size.Url;
    }
    NSString *localPath = [lwUtil makeImagePath:imageUrl];
    [_imageView asyncLoadImageWithUrl:imageUrl localPath:localPath showIndicator:YES completion:^{
        
    }];
    
    [self updateTitle];
    
    UISwipeGestureRecognizer *recognizer;
    recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
    [recognizer setDirection:UISwipeGestureRecognizerDirectionLeft|UISwipeGestureRecognizerDirectionRight];
    [self.view addGestureRecognizer:recognizer];
}

- (void)handleSwipeFrom:(UISwipeGestureRecognizer *)gestureRecognizer {
    int index = [_images indexOfObject:_image];
    if (NSNotFound == index) {
        return;
    }
    if (gestureRecognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
        index--;
        if (index < 0) {
            index = _images.count - 1;
        }
    } else {
        index++;
        if (index >= _images.count) {
            index = 0;
        }
    }
    
    _image = _images[index];
    
    NSString *imageUrl = _image.imageUrl;
    if (imageUrl == nil) {
        TumblrImageSize *size = _image.Sizes[0];
        imageUrl = size.Url;
    }
    NSString *localPath = [lwUtil makeImagePath:imageUrl];
    [_imageView asyncLoadImageWithUrl:imageUrl localPath:localPath showIndicator:YES completion:nil];
    
    [self updateTitle];
}

- (IBAction)onDeleteButton:(id)sender {
    
}

- (void)updateTitle {
    if (_image.fitSize) {
        self.title = [NSString stringWithFormat:@"%d*%d", _image.fitSize.Width, _image.fitSize.Height];
    } else {
        self.title = @"no fit size";
        TumblrImageSize *size = _image.Sizes[0];
        lwError("maxSize:%d*%d", size.Width, size.Height);
    }
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
