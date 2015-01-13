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
#import "UIImage+ImageEffects.h"

static const int IMAGE_SIZE_LIMIT_MB = 5;
static const int IMAGE_SIZE_LIMIT_BYTE = IMAGE_SIZE_LIMIT_MB * 1024 * 1024;

//===========================
@interface PublishHeader : UICollectionReusableView
@property (weak, nonatomic) IBOutlet UITextField *sliderNumInput;
@property (weak, nonatomic) IBOutlet UISegmentedControl *ratioSeg;

@end

@implementation PublishHeader

@end


//===========================
@interface PublishController ()

@property PublishHeader *header;

@property (nonatomic) NSMutableArray *images;
@property int imageNum;
@property TumblrBlog *blog;

@property NSString *coverKey;
@property NSString *coverBlurKey;
@property NSString *thumbKey;
@property NSMutableArray *imgs;
@property NSMutableArray *thumbs;
@property NSMutableArray *filePathes;
@property NSMutableArray *fileKeys;
@property NSMutableArray *privateFilePathes;
@property NSMutableArray *privateFileKeys;
@property (nonatomic) QNUploadManager *upManager;
@property int totalSize;
@property BOOL privatePublish;

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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([RoboData inst].hasImageDeleted) {
        [self.collectionView reloadData];
    }
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
        [cell.imageView asyncLoadImageWithUrl:image.thumbUrl localPath:[lwUtil makeImagePathWithUrl:image.thumbUrl] showIndicator:NO completion:nil];
        NSString *str = @"no fit";
        if (image.fitSize) {
            str = [NSString stringWithFormat:@"%d*%d", image.fitSize.Width, image.fitSize.Height];
            
            NSString *localPath = [lwUtil makeImagePathWithUrl:image.fitSize.Url];
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
    UIButton *button = sender;
    if (button) {
        _imageNum = button.tag;
    } else if (_imageNum == 0) {
        _imageNum = 9;
    }
    
    _images = [NSMutableArray array];
    
    SldHttpSession *session = [SldHttpSession defaultSession];
    int limit = _imageNum;
    BOOL isPortrait = YES;
    if (_header) {
        isPortrait = _header.ratioSeg.selectedSegmentIndex == 0;
    }
    NSDictionary *body = @{
                           @"BlogName":_blog.Name,
                           @"LastKey":@"",
                           @"LastScore":@(0),
                           @"Limit":@(limit),
                           @"IsPortrait":@(isPortrait),
                           };
    [session postToApi:@"tumblr/listImage" body:body completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            [lwUtil alertHTTPError:error data:data];
            NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            lwError("%@", str);
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
        NSString *localPath = [lwUtil makeImagePathWithUrl:image.fitSize.Url];
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
        NSString *localPath = [lwUtil makeImagePathWithUrl:url];
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
        NSString *localPath = [lwUtil makeImagePathWithUrl:image.fitSize.Url];
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
            NSString *localPath = [lwUtil makeImagePathWithUrl:url];
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

- (IBAction)onPublishButton:(id)sender {
    [[[UIAlertView alloc] initWithTitle:@"发布吗?"
                                message:nil
                       cancelButtonItem:[RIButtonItem itemWithLabel:@"取消" action:nil]
                       otherButtonItems:[RIButtonItem itemWithLabel:@"发布" action:^{
        UIButton *button = sender;
        _privatePublish = button.tag == 1;
        _imgs = [NSMutableArray array];
        _thumbs = [NSMutableArray array];
        _filePathes = [NSMutableArray array];
        _fileKeys = [NSMutableArray array];
        _privateFilePathes = [NSMutableArray array];
        _privateFileKeys = [NSMutableArray array];
        
        __block UIAlertView *alert = [lwUtil alertWithTitle:@"生成中" text:nil buttonTitle:@"OK" action:nil];
        
        if (_images.count != _imageNum) {
            [alert dismissWithClickedButtonIndex:0 animated:NO];
            [lwUtil alertWithTitle:@"图片数量错误" text:nil buttonTitle:@"OK" action:nil];
            return;
        }
        
        int i = 0;
        for (TumblrImage *image in _images) {
            if (image.fitSize == nil) {
                [alert dismissWithClickedButtonIndex:0 animated:NO];
                [lwUtil alertWithTitle:@"有图片尺寸不合适" text:nil buttonTitle:@"OK" action:nil];
                return;
            }
            NSString *localPath = [lwUtil makeImagePathWithUrl:image.fitSize.Url];
            if (![[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
                [alert dismissWithClickedButtonIndex:0 animated:NO];
                [lwUtil alertWithTitle:@"有图片未下载" text:nil buttonTitle:@"OK" action:nil];
                return;
            }
            
            NSString *thumbPath = [lwUtil makeImagePathWithUrl:image.thumbUrl];
            if (![[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
                [alert dismissWithClickedButtonIndex:0 animated:NO];
                [lwUtil alertWithTitle:@"有缩略图未下载" text:nil buttonTitle:@"OK" action:nil];
                return;
            }
            
            //check size
            NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:localPath error:NULL];
            
            int size = (int)attrs.fileSize;
            if (size > IMAGE_SIZE_LIMIT_BYTE) {
                [alert dismissWithClickedButtonIndex:0 animated:NO];
                [lwUtil alertWithTitle:@"图片过大（>5mb）" text:nil buttonTitle:@"OK" action:nil];
                return;
            }
            _totalSize += size;
            
            //calc key
            NSData* imageData = [[NSData alloc] initWithContentsOfFile:localPath];
            UIImage *uiImage = nil;
            
            //image
            NSString *key = [lwUtil sha1WithData:imageData];
            BOOL isGif = [lwUtil isGifUrl:image.fitSize.Url];
            if (isGif) {
                key = [NSString stringWithFormat:@"%@.gif", key];
            } else {
                key = [NSString stringWithFormat:@"%@.jpg", key];
            }
            [_privateFileKeys addObject:key];
            [_privateFilePathes addObject:localPath];
            [_imgs addObject:@{@"Url":@"1", @"Key":key}];
            
            //blur first image as cover
            if (i == 0) {
                UIColor *tintColor = [UIColor colorWithWhite:1.0 alpha:0.3];
                uiImage = [UIImage imageWithData:imageData];
                UIImage *bluredImage = [uiImage applyBlurWithRadius:25 tintColor:tintColor saturationDeltaFactor:1.4 maskImage:nil];
                
                //save
                NSData *data = UIImageJPEGRepresentation(bluredImage, 0.85);
                NSString *filePath = [lwUtil makeTempPath:@"coverBlur.jpg"];
                [data writeToFile:filePath atomically:YES];
                
                _coverKey = key;
                _coverBlurKey = [NSString stringWithFormat:@"%@.jpg", [lwUtil sha1WithData:data]];
                
                [_filePathes addObject:filePath];
                [_fileKeys addObject:_coverBlurKey];
            }
            
            //thumbs
            if (isGif) {
                NSData *data = [[NSData alloc] initWithContentsOfFile:thumbPath];
                key = [NSString stringWithFormat:@"%@.gif", [lwUtil sha1WithData:data]];
                
                [_thumbs addObject:key];
                if (i == 0) {
                    _thumbKey = key;
                }
                [_filePathes addObject:thumbPath];
                [_fileKeys addObject:key];
                
            } else {
                if (uiImage == nil) {
                    uiImage = [UIImage imageWithData:imageData];
                }
                float s = MIN(uiImage.size.width, uiImage.size.height);
                float l = 200.0;
                float scale = l/s;
                float w = uiImage.size.width * scale;
                float h = uiImage.size.height * scale;
                uiImage = [lwUtil imageWithImage:uiImage scaledToSize:CGSizeMake(w, h)];
                CGRect cropRect = CGRectMake(0, 0, l, l);
                if (uiImage.size.width >= uiImage.size.height) {
                    cropRect.origin.x = (w-l)*0.5;
                } else {
                    cropRect.origin.y = (h-l)*0.5;
                }
                
                CGImageRef imageRef = CGImageCreateWithImageInRect([uiImage CGImage], cropRect);
                uiImage = [UIImage imageWithCGImage:imageRef];
                
                //thumb save
                NSData *data = UIImageJPEGRepresentation(uiImage, 0.85);
                NSString *fileName = [NSString stringWithFormat:@"thumb%d.jpg", i];
                
                NSString *filePath = [lwUtil makeTempPath:fileName];
                [data writeToFile:filePath atomically:YES];
                
                key = [NSString stringWithFormat:@"%@.jpg", [lwUtil sha1WithData:data]];
                
                [_thumbs addObject:key];
                if (i == 0) {
                    _thumbKey = key;
                }
                [_filePathes addObject:filePath];
                [_fileKeys addObject:key];
            }
            
            
            i++;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            alert.title = @"上传中... 0%";
            
            SldHttpSession *session = [SldHttpSession defaultSession];
            [session postToApi:@"tumblr/getUptoken" body:nil completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                if (error) {
                    [lwUtil alertHTTPError:error data:data];
                    [alert dismissWithClickedButtonIndex:0 animated:YES];
                    alert = nil;
                    return;
                }
                
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                if (error) {
                    lwError("Json error:%@", [error localizedDescription]);
                    [alert dismissWithClickedButtonIndex:0 animated:YES];
                    alert = nil;
                    return;
                }
                
                NSString *token = [dict objectForKey:@"Token"];
                NSString *privateToken = [dict objectForKey:@"PrivateToken"];
                
                _upManager = [[QNUploadManager alloc] init];
                
                __block int uploadNum = (int)(_filePathes.count + _privateFilePathes.count);
                __block int finishNum = 0;
                
                RoboConf *conf = [RoboConf inst];
                int i = 0;
                for (NSString *filePath in _filePathes) {
                    NSString *key = [_fileKeys objectAtIndex:i];
                    i++;
                    NSString *strUrl = [NSString stringWithFormat:@"%@/%@", conf.UPLOAD_HOST, key];
                    
                    //check exist
                    NSURL *url = [NSURL URLWithString: strUrl];
                    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url];
                    [request setHTTPMethod: @"HEAD"];
                    dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                        NSHTTPURLResponse *response;
                        NSError *error;
                        [NSURLConnection sendSynchronousRequest: request returningResponse: &response error: &error];
                        
                        dispatch_async( dispatch_get_main_queue(), ^{
                            if (response.statusCode != 200) {
                                //upload
                                [_upManager putFile:filePath
                                               key:key
                                             token:token
                                          complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
                                              if (info.ok) {
                                                  finishNum++;
                                                  if (finishNum >= uploadNum) {
                                                      [self addMatch:alert];
                                                  } else {
                                                      float f = (float)finishNum/uploadNum;
                                                      int n = f*100;
                                                      alert.title = [NSString stringWithFormat:@"上传中... %d%%", n];
                                                  }
                                              } else {
                                                  [alert dismissWithClickedButtonIndex:0 animated:NO];
                                                  alert = nil;
                                                  [lwUtil alertWithTitle:@"上传失败" text:nil buttonTitle:@"OK" action:nil];
                                                  lwError(@"uploadFailed: %@", filePath);
                                              }
                                          }
                                            option:nil];
                            } else {
                                finishNum++;
                                if (finishNum >= uploadNum) {
                                    [self addMatch:alert];
                                } else {
                                    float f = (float)finishNum/uploadNum;
                                    int n = f*100;
                                    alert.title = [NSString stringWithFormat:@"上传中... %d%%", n];
                                }
                            }
                        });
                    });
                }
                
                SldHttpSession *session = [SldHttpSession defaultSession];
                NSDictionary *body = @{@"FileKeys":_privateFileKeys};
                [session postToApi:@"etc/checkPrivateFilesExist" body:body completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    if (error) {
                        [lwUtil alertHTTPError:error data:data];
                        return;
                    }
                    
                    NSDictionary *existDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                    if (error) {
                        lwError("Json error:%@", [error localizedDescription]);
                        return;
                    }
                    
                    int i = 0;
                    for (NSString *filePath in _privateFilePathes) {
                        NSString *key = [_privateFileKeys objectAtIndex:i];
                        i++;
                        if ([existDict objectForKey:key]) {
                            finishNum++;
                            if (finishNum >= uploadNum) {
                                [self addMatch:alert];
                                return;
                            } else {
                                float f = (float)finishNum/uploadNum;
                                int n = f*100;
                                alert.title = [NSString stringWithFormat:@"上传中... %d%%", n];
                            }
                        } else {
//                            NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:NULL];
//                            
//                            int size = (int)attrs.fileSize;
//                            lwInfo("fileSize:%d", size);
                            
                            [_upManager putFile:filePath
                                           key:key
                                         token:privateToken
                                      complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
                                          if (info.ok) {
                                              finishNum++;
                                              if (finishNum >= uploadNum) {
                                                  [self addMatch:alert];
                                              } else {
                                                  float f = (float)finishNum/uploadNum;
                                                  int n = f*100;
                                                  alert.title = [NSString stringWithFormat:@"上传中... %d%%", n];
                                              }
                                          } else {
                                              [alert dismissWithClickedButtonIndex:0 animated:YES];
                                              alert = nil;
                                              [lwUtil alertWithTitle:@"上传失败" text:nil buttonTitle:@"OK" action:nil];
                                              lwError(@"uploadFailed: %@, %@", filePath, info);
                                          }
                                      }
                                        option:nil];
                        }
                    }
                }];
            }];
        });
    }], nil] show];
}

- (void)addMatch:(UIAlertView*)alert {
    alert.title = @"服务端生成中";
    
    SldHttpSession *session = [SldHttpSession defaultSession];
    float fMb = (float)_totalSize/(1024.f*1024.f);
    int sliderNum = [_header.sliderNumInput.text intValue];
    if (sliderNum < 4) {
        sliderNum = 4;
    } else if (sliderNum > 8) {
        sliderNum = 8;
    }
    
    NSMutableArray *imageKeys = [NSMutableArray array];
    for (TumblrImage *image in _images) {
        [imageKeys addObject:image.Key];
    }
    
    NSDictionary *body = @{
                           @"Title":@"",
                           @"Text":@"",
                           @"Thumb":_thumbKey,
                           @"Cover":_coverKey,
                           @"CoverBlur":_coverBlurKey,
                           @"Images":_imgs,
                           @"Thumbs":_thumbs,
                           @"SizeMb":@(fMb),
                           @"GoldCoinForPrize":@(0),
                           @"SliderNum":@(sliderNum),
                           @"PromoUrl":@"",
                           @"PromoImage":@"",
                           @"Private":@(_privatePublish),
                           @"BlogName":_blog.Name,
                           @"ImageKeys":imageKeys,
                           };
    [session postToApi:@"tumblr/publish" body:body completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            [alert dismissWithClickedButtonIndex:0 animated:NO];
            [lwUtil alertHTTPError:error data:data];
            return;
        }
        
        [alert dismissWithClickedButtonIndex:0 animated:NO];
        
        //
        [[[UIAlertView alloc] initWithTitle:@"发布成功！"
                                    message:nil
                           cancelButtonItem:[RIButtonItem itemWithLabel:@"好的" action:^{
            [self onUpdateButton:nil];
        }]
                           otherButtonItems:nil] show];
    }];
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


