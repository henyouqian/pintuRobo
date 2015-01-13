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
#import "SldHttpSession.h"

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
    NSString *localPath = [lwUtil makeImagePathWithUrl:imageUrl];
    [_imageView asyncLoadImageWithUrl:imageUrl localPath:localPath showIndicator:YES completion:^{
        
    }];
    
    [self updateTitle];
    
    UISwipeGestureRecognizer *recognizerLeft;
    recognizerLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeLeftFrom:)];
    [recognizerLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
    [self.view addGestureRecognizer:recognizerLeft];
    
    UISwipeGestureRecognizer *recognizerRight;
    recognizerRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeRightFrom:)];
    [recognizerRight setDirection:UISwipeGestureRecognizerDirectionRight];
    [self.view addGestureRecognizer:recognizerRight];
}

- (void)handleSwipeRightFrom:(UISwipeGestureRecognizer *)gestureRecognizer {
    NSUInteger index = [_images indexOfObject:_image];
    if (NSNotFound == index) {
        return;
    }
    if (index == 0) {
        index = _images.count - 1;
    } else {
        index--;
    }
    
    _image = _images[index];
    
    NSString *imageUrl = _image.imageUrl;
    if (imageUrl == nil) {
        TumblrImageSize *size = _image.Sizes[0];
        imageUrl = size.Url;
    }
    NSString *localPath = [lwUtil makeImagePathWithUrl:imageUrl];
    [_imageView asyncLoadImageWithUrl:imageUrl localPath:localPath showIndicator:YES completion:nil];
    
    [self updateTitle];
}

- (void)handleSwipeLeftFrom:(UISwipeGestureRecognizer *)gestureRecognizer {
    NSUInteger index = [_images indexOfObject:_image];
    if (NSNotFound == index) {
        return;
    }
    index++;
    if (index >= _images.count) {
        index = 0;
    }
    
    _image = _images[index];
    
    NSString *imageUrl = _image.imageUrl;
    if (imageUrl == nil) {
        TumblrImageSize *size = _image.Sizes[0];
        imageUrl = size.Url;
    }
    NSString *localPath = [lwUtil makeImagePathWithUrl:imageUrl];
    [_imageView asyncLoadImageWithUrl:imageUrl localPath:localPath showIndicator:YES completion:nil];
    
    [self updateTitle];
}

- (IBAction)onDeleteButton:(id)sender {
    [[[UIAlertView alloc] initWithTitle:@"删除这张图片吗?"
                                message:nil
                       cancelButtonItem:[RIButtonItem itemWithLabel:@"取消" action:nil]
                       otherButtonItems:[RIButtonItem itemWithLabel:@"删除！" action:^{
        SldHttpSession *session = [SldHttpSession defaultSession];
        NSDictionary *body = @{
                               @"BlogName": [RoboData inst].blog.Name,
                               @"Key":_image.Key,
                               };
        [session postToApi:@"tumblr/delImage" body:body completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                [lwUtil alertHTTPError:error data:data];
                return;
            }
            
            [_images removeObject:_image];
            
            [RoboData inst].hasImageDeleted = YES;
            
            [lwUtil alertWithTitle:@"删除成功" text:nil buttonTitle:@"OK" action:^{
                [self.navigationController popViewControllerAnimated:YES];
            }];
        }];
    }], nil] show];
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
