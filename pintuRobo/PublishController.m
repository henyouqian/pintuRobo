//
//  PublishController.m
//  pintuRobo
//
//  Created by 李炜 on 15/1/7.
//  Copyright (c) 2015年 李炜. All rights reserved.
//

#import "PublishController.h"
#import "BlogPostsController.h"
#import "ImageBrowserController.h"
#import "RoboData.h"
#import "SldHttpSession.h"
#import "lwUtil.h"
#import "RoboConf.h"

//===========================
@interface PublishHeader : UICollectionReusableView

@end

@implementation PublishHeader

@end


//===========================
@interface PublishController ()

@property PublishHeader *header;

@property (nonatomic) NSMutableArray *images;
@property TumblrBlog *blog;

@end

@implementation PublishController

static NSString * const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.collectionView.alwaysBounceVertical = YES;
    
    float top = self.navigationController.navigationBar.frame.size.height+20;
    float bottom = 50;
    UIEdgeInsets insect = UIEdgeInsetsMake(top, 0, bottom, 0);
    self.collectionView.contentInset = insect;
    self.collectionView.scrollIndicatorInsets = insect;
    
    _blog = [RoboData inst].blog;
    
    [self onUpdateButton:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _images.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BlogPostsCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    if (indexPath.row < _images.count) {
        TumblrImage *image = _images[indexPath.row];
        [cell.imageView asyncLoadImageWithUrl:image.thumbUrl localPath:[lwUtil makeImagePath:image.thumbUrl] showIndicator:NO completion:nil];
        NSString *str = @"no fit";
        if (image.fitSize) {
            str = [NSString stringWithFormat:@"%d*%d", image.fitSize.Width, image.fitSize.Height];
            
            NSString *localPath = [lwUtil makeImagePath:image.fitSize.Url];
            if ([[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
                str = [NSString stringWithFormat:@"%@ L", str];
            }
        }
        cell.bottomLabel.text = str;
        cell.image = image;
    }
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if (kind == UICollectionElementKindSectionHeader) {
        _header = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"header" forIndexPath:indexPath];
        return _header;
    }
    return nil;
}

- (IBAction)onUpdateButton:(id)sender {
    _images = [NSMutableArray array];
    
    SldHttpSession *session = [SldHttpSession defaultSession];
    int limit = 9;
    NSDictionary *body = @{
                           @"BlogName":_blog.Name,
                           @"LastKey":@"",
                           @"LastScore":@(0),
                           @"Limit":@(limit),
                           };
    [session postToApi:@"tumblr/listImage" body:body completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            [lwUtil alertHTTPError:error data:data];
            return;
        }
        
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (error) {
            lwError("Json error:%@", [error localizedDescription]);
            return;
        }
        
        NSArray *images = dict[@"Images"];
        for (NSDictionary *imageDict in images) {
            TumblrImage *image = [[TumblrImage alloc] initWithDict:imageDict];
            [_images addObject:image];
        }
        [self.collectionView reloadData];
    }];
}

- (IBAction)onDownloadButton:(id)sender {
    NSMutableArray *downloadUrls = [NSMutableArray array];
    int totalNum = 0;
    __block int finishNum = 0;
    __block int failNum = 0;
    for (TumblrImage *image in _images) {
        if (image.fitSize == nil) {
            [lwUtil alertWithTitle:@"delete nofit first" text:nil buttonTitle:@"OK" action:nil];
            return;
        }
        NSString *localPath = [lwUtil makeImagePath:image.fitSize.Url];
        if (![[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
            [downloadUrls addObject:image.fitSize.Url];
        } else {
            finishNum++;
        }
        
        totalNum++;
    }
    
    SldHttpSession *session = [SldHttpSession defaultSession];
    
    NSString *str = [NSString stringWithFormat:@"%d/%d, fail:%d", finishNum, totalNum, failNum];
    UIAlertView *alert = [lwUtil alertWithTitle:str text:nil buttonTitle:@"OK" action:^{
        [session cancelAllTask];
        [self.collectionView reloadData];
    }];
    
    
    [session cancelAllTask];
    for (NSString *url in downloadUrls) {
        NSString *localPath = [lwUtil makeImagePath:url];
        __block NSURLSessionDownloadTask *task = [session downloadFromUrl:url
                              toPath:localPath
                            withData:nil completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error, id data)
             {
                 task = nil;
                 
                 if (error) {
                     failNum++;
                     alert.title = [NSString stringWithFormat:@"%d/%d,fail:%d", finishNum, totalNum, failNum];
                     return;
                 }
                 finishNum++;
                 if (finishNum+failNum == totalNum) {
                     alert.title = [NSString stringWithFormat:@"完成！%d/%d,fail:%d", finishNum, totalNum, failNum];
                 } else {
                     alert.title = [NSString stringWithFormat:@"%d/%d,fail:%d", finishNum, totalNum, failNum];
                 }
             }];
    }
    
    
}

- (IBAction)onProxyDownloadButton:(id)sender {
    NSMutableArray *downloadUrls = [NSMutableArray array];
    int totalNum = 0;
    __block int finishNum = 0;
    __block int failNum = 0;
    for (TumblrImage *image in _images) {
        if (image.fitSize == nil) {
            [lwUtil alertWithTitle:@"delete nofit first" text:nil buttonTitle:@"OK" action:nil];
            return;
        }
        NSString *localPath = [lwUtil makeImagePath:image.fitSize.Url];
        if (![[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
            [downloadUrls addObject:image.fitSize.Url];
        } else {
            finishNum++;
        }
        
        totalNum++;
    }
    
    SldHttpSession *session = [SldHttpSession defaultSession];
    SldHttpSession *proxySession = [[SldHttpSession alloc] initWithHost:[RoboConf inst].IMAGE_DOWNLOAD_HOST];
    
    NSString *str = [NSString stringWithFormat:@"%d/%d, fail:%d", finishNum, totalNum, failNum];
    UIAlertView *alert = [lwUtil alertWithTitle:str text:nil buttonTitle:@"OK" action:^{
        [session cancelAllTask];
        [proxySession cancelAllTask];
        [self.collectionView reloadData];
    }];
    
    
    [session cancelAllTask];
    [proxySession cancelAllTask];
    
    //proxy download
    for (NSString *url in downloadUrls) {
        NSDictionary *body = @{@"Urls":@[url]};
        [proxySession postToApi:@"etc/downloadFilesToQiniu" body:body completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                [lwUtil alertHTTPError:error data:data];
                failNum++;
                alert.title = [NSString stringWithFormat:@"%d/%d,fail:%d", finishNum, totalNum, failNum];
                return;
            }
            
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error) {
                lwError("Json error:%@", [error localizedDescription]);
                failNum++;
                alert.title = [NSString stringWithFormat:@"%d/%d,fail:%d", finishNum, totalNum, failNum];
                return;
            }
            NSDictionary *fileMap = dict[@"FileMap"];
            if (!fileMap || fileMap.count == 0) {
                lwError("no filemap");
                failNum++;
                alert.title = [NSString stringWithFormat:@"%d/%d,fail:%d", finishNum, totalNum, failNum];
                return;
            }
            NSString *key = [[fileMap allValues] firstObject];
            NSString *localPath = [lwUtil makeImagePath:url];
            NSString *qiniuUrl = [NSString stringWithFormat:@"http://lwswap.qiniudn.com/%@", key];
            if (![[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
                __block NSURLSessionDownloadTask *task =
                [session downloadFromUrl:qiniuUrl
                                  toPath:localPath
                                withData:nil
                       completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error, id data)
                 {
                     task = nil;
                     
                     if (error) {
                         failNum++;
                         alert.title = [NSString stringWithFormat:@"%d/%d,fail:%d", finishNum, totalNum, failNum];
                         return;
                     }
                     finishNum++;
                     if (finishNum+failNum == totalNum) {
                         alert.title = [NSString stringWithFormat:@"完成！%d/%d,fail:%d", finishNum, totalNum, failNum];
                     } else {
                         alert.title = [NSString stringWithFormat:@"%d/%d,fail:%d", finishNum, totalNum, failNum];
                     }
                 }];
            } else {
                finishNum++;
            }
        }];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if (segue.identifier && [segue.identifier compare:@"segueImageBrowser"] == 0) {
        ImageBrowserController *vc = segue.destinationViewController;
        
        BlogPostsCell *cell = sender;
        vc.image = cell.image;
        vc.images = _images;
    }
}

@end


