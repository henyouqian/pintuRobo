//
//  UIImageView+sldAsyncLoad.m
//  Sld
//
//  Created by Wei Li on 14-5-11.
//  Copyright (c) 2014年 Wei Li. All rights reserved.
//

#import "SldAsyncImageView.h"
#import "UIImage+animatedGIF.h"
#import "SldHttpSession.h"
//#import <CommonCrypto/CommonHMAC.h>

@interface lwAsyncTask : NSObject
- (void)runWithTask:(void (^)(lwAsyncTask*))task complete:(void (^)(void))complete;
@end

@implementation lwAsyncTask
- (void)runWithTask:(void (^)(lwAsyncTask*))task complete:(void (^)(void))complete {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (task) {
            task(self);
        }
        if (complete) {
            dispatch_async(dispatch_get_main_queue(), ^{
                complete();
            });
        }
    });
}
@end


//==========================
@interface SldAsyncImageView()
@property (atomic) lwAsyncTask *at;
@property (atomic) UIActivityIndicatorView *indicatorView;
@end

@implementation SldAsyncImageView

-(UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 1.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (void)asyncLoadLocalImageWithPath:(NSString*)localPath anim:(BOOL)anim thumbSize:(int)thumbSize completion:(void (^)(void))completion{
    if (localPath == nil) {
        lwError("localPath == nil");
        return;
    }
    
    if (self.image && _localPath && [_localPath compare:localPath] == 0) {
        return;
    }
    
    if (_loading) {
        return;
    }
    //fixme?
//    _loading = YES;
    _localPath = localPath;
    
    _at = [[lwAsyncTask alloc] init];
    [_at runWithTask:^(lwAsyncTask *selfTask) {
        if (selfTask == _at) {
            BOOL isGif = [[[localPath pathExtension] lowercaseString] compare:@"gif"] == 0;
            if (isGif && anim) {
                NSURL *url = [NSURL fileURLWithPath:localPath];
                
                NSMutableArray* frames = [UIImage imageArrayWithAnimatedGIFURL:url];
                if (frames.count <= 1) {
                    return;
                }
                NSNumber *duration = [frames lastObject];
                [frames removeLastObject];
                self.animationDuration = [duration doubleValue];
                self.animationRepeatCount = 0;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (selfTask != _at) {
                        return;
                    }
                    self.animationImages = frames;
                    self.image = frames[0];
                    if (completion) {
                        completion();
                    }
                    _loading = false;
                    if (_loadCanceling) {
                        _loadCanceling = NO;
                        self.image = nil;
                        self.animationImages = nil;
                    } else {
                        [self startAnimating];
                    }
                });
            } else {
                UIImage *image = nil;
                if (thumbSize > 0) {
                    int size = thumbSize;
                    if ( thumbSize > 256 ) {
                        size = 256;
                    }
                    float fSize = (float)size;
                    NSString *path = [NSString stringWithFormat:@"%@_thumb%d", localPath, size];
                    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                        image = [UIImage imageWithContentsOfFile:path];
                    } else {
                        image = [UIImage imageWithContentsOfFile:localPath];
                        float s = MIN(image.size.width, image.size.height);
                        float scale = fSize/s;
                        float w = image.size.width * scale;
                        float h = image.size.height * scale;
                        image = [self imageWithImage:image scaledToSize:CGSizeMake(w, h)];
                        CGRect cropRect = CGRectMake(0, 0, fSize, fSize);
                        if (image.size.width >= image.size.height) {
                            cropRect.origin.x = w*0.5-fSize*0.5;
                        } else {
                            cropRect.origin.y = h*0.5-fSize*0.5;
                        }
                        
                        CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], cropRect);
                        image = [UIImage imageWithCGImage:imageRef];
                        
                        //thumb save
                        NSData *data = UIImageJPEGRepresentation(image, 0.85);
                        [data writeToFile:path atomically:YES];
                    }
                } else {
                    image = [UIImage imageWithContentsOfFile:localPath];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (selfTask != _at) {
                        return;
                    }
                    self.image = image;
                    self.animationImages = nil;
                    if (completion) {
                        completion();
                    }
                    _loading = false;
                    if (_loadCanceling) {
                        _loadCanceling = NO;
                        self.image = nil;
                        self.animationImages = nil;
                    }
                });
            }
        }
    } complete:nil];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
    });
}

- (void)asyncLoadImageWithUrl:(NSString*)url localPath:(NSString*)localPath showIndicator:(BOOL)showIndicator completion:(void (^)(void))completion {
    if (_loading) {
        return;
    }
    if (self.image && _key && [_key compare:url] == 0) {
        return;
    } else {
        _key = url;
    }
    
    self.image = nil;
    self.animationImages = nil;
    
    if (showIndicator && _indicatorView == nil) {
        _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _indicatorView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin
        | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        
        [_indicatorView sizeToFit];
        [_indicatorView startAnimating];
        _indicatorView.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
        
        [self addSubview:_indicatorView];
    }
    
    //local
    if ([[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
        [self asyncLoadLocalImageWithPath:localPath anim:YES thumbSize:0 completion:^{
            if (_indicatorView) {
                [_indicatorView removeFromSuperview];
                _indicatorView = nil;
            }
            if (completion) {
                completion();
            }
        }];
    }
    //remote
    else {
        _serverUrl = url;
        SldHttpSession *session = [SldHttpSession defaultSession];
        if (_task) {
            [_task cancel];
            lwInfo("_task cancel");
        }
        _task = [session downloadFromUrl:url
                          toPath:localPath
                        withData:nil completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error, id data)
         {
             if (_indicatorView) {
                 [_indicatorView removeFromSuperview];
                 _indicatorView = nil;
             }
             
             _task = nil;
             NSURL *nsurl = [NSURL URLWithString:_serverUrl];
             if (![response.URL isEqual:nsurl]) {
                 lwInfo("![response.URL isEqual:nsurl]");
                 return;
             }
             
             if (error) {
                 lwError("Download error: %@, url:%@", error.localizedDescription, location);
                 return;
             }
             
             [self asyncLoadLocalImageWithPath:localPath anim:YES thumbSize:0 completion:^{
                 if (completion) {
                     completion();
                 }
             }];
         }];
    }
}

- (void)releaseImage {
    if (_loading) {
        _loadCanceling = YES;
    } else {
        self.image = nil;
        self.animationImages = nil;
    }
}

@end
