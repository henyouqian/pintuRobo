//
//  BlogPostsController.m
//  pintuRobo
//
//  Created by 李炜 on 14/12/28.
//  Copyright (c) 2014年 李炜. All rights reserved.
//

#import "BlogPostsController.h"
#import "BlogListController.h"
#import "MdlImage.h"
#import "lwUtil.h"
#import "MdlInt.h"
#import "MdlBlog.h"
#import "SldHttpSession.h"
#import "RoboData.h"
#import "ImageBrowserController.h"

//===========================
@implementation BlogPostsCell
@end

//===========================
@interface BlogPostHeader : UICollectionReusableView
@property (weak, nonatomic) IBOutlet UITextView *outputView;
@property (weak, nonatomic) IBOutlet UIButton *syncButton;
@property (weak, nonatomic) IBOutlet UISwitch *portraitSwitch;

@end

@implementation BlogPostHeader

@end


//===========================
@interface BlogPostsController ()

@property (nonatomic) NSMutableArray *images;
@property BlogPostHeader *header;

@property BOOL buttonSyncing;
@property BOOL syncing;
@property NSString *lastKey;
@property SInt64 lastScore;
@property TumblrBlog *blog;
@property BOOL isPortrait;

@end

@implementation BlogPostsController

- (void)setImage:(MdlImage*)image dict:(NSDictionary*)dict postId:(NSNumber*)postId blogName:(NSString*)blogName {
    image.postId = postId;
    image.blogName = blogName;
    image.imageUrl = dict[@"original_size"][@"url"];
    lwInfo("%@", dict[@"original_size"]);
    
    NSArray *sizes = [dict objectForKey:@"alt_sizes"];
    if (sizes.count > 3) {
        image.thumbUrl = sizes[3][@"url"];
    } else {
        image.thumbUrl = sizes[sizes.count-1][@"url"];
    }
    
    NSString *lurl = [image.imageUrl lowercaseString];
    NSRange range = [lurl rangeOfString:@".gif"];
    if (range.location != NSNotFound) {
        image.thumbUrl = sizes[sizes.count-1][@"url"];
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

- (void)viewDidLoad {
    [super viewDidLoad];
//    _blogName = @"pussysushi";
//    _blogName = @"idoljapan.tumblr.com";
//    _blogName = @"chikcz.tumblr.com";
    
    _buttonSyncing = NO;
    _syncing = NO;
    _lastKey = @"";
    _blog = [RoboData inst].blog;
    _images = [NSMutableArray array];
    
    self.collectionView.alwaysBounceVertical = YES;
    
    float top = self.navigationController.navigationBar.frame.size.height+20;
    float bottom = 50;
    UIEdgeInsets insect = UIEdgeInsetsMake(top, 0, bottom, 0);
    self.collectionView.contentInset = insect;
    self.collectionView.scrollIndicatorInsets = insect;
    
    
    
//    [[TMAPIClient sharedInstance] posts:_blog.name
//                                   type:@"photo"
//                             parameters:nil
//                               callback:^ (id result, NSError *error)
//    {
//        NSDictionary *dict = result;
////        lwInfo(@"%@", dict[@"blog"]);
//        NSArray *posts = [dict objectForKey:@"posts"];
//        for (NSDictionary *postDict in posts) {
//            NSArray *photos = [postDict objectForKey:@"photos"];
//            for (NSDictionary *photoDict in photos) {
//                MdlImage *image = [MdlImage MR_createEntity];
//                [self setImage:image dict:photoDict];
//                [_images addObject:image];
//            }
//        }
//        [self.collectionView reloadData];
////        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:nil];
//    }];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([RoboData inst].hasImageDeleted) {
        [self.collectionView reloadData];
    }
}


- (IBAction)onSyncButton:(id)sender {
    _buttonSyncing = !_buttonSyncing;
    if (_buttonSyncing) {
        [_header.syncButton setTitle:@"暂停" forState:UIControlStateNormal];
        if (!_syncing) {
            [self syncPost];
        }
    } else {
        [_header.syncButton setTitle:@"同步" forState:UIControlStateNormal];
    }
}

- (void)syncPost {
    _syncing = YES;
    [[TMAPIClient sharedInstance] posts:_blog.Name
                                   type:@"photo"
                             parameters:@{ @"offset" : @(_blog.ImageFetchOffset) }
                               callback:^ (id result, NSError *error)
     {
         NSMutableDictionary *body = [NSMutableDictionary dictionaryWithCapacity:4];
         body[@"BlogName"] = _blog.Name;
         
         NSDictionary *dict = result;
         int postNum = [(NSNumber*)[dict objectForKey:@"total_posts"] intValue];
         NSArray *posts = [dict objectForKey:@"posts"];
         if (posts.count == 0) {
             NSString *output = [NSString stringWithFormat:@"已完成。postNum:%d", postNum];
             _header.outputView.text = output;
             
             SldHttpSession *session = [SldHttpSession defaultSession];
             NSDictionary *body = @{@"BlogName":_blog.Name};
             [session postToApi:@"tumblr/setFetchFinish" body:body completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                 if (error) {
                     [lwUtil alertHTTPError:error data:data];
                     return;
                 }
                 _blog.FetchFinish = YES;
                 _syncing = NO;
             }];
             
             return;
         }
         
         NSMutableArray *images = [NSMutableArray arrayWithCapacity:16];
         for (NSDictionary *postDict in posts) {
             NSNumber *postId = [postDict objectForKey:@"id"];
             NSArray *photos = [postDict objectForKey:@"photos"];
             int i = 0;
             for (NSDictionary *photoDict in photos) {
                 NSMutableDictionary *image = [NSMutableDictionary dictionary];
                 image[@"PostId"] = postId;
                 image[@"IndexInPost"] = @(i);
                 NSArray *altsizes = photoDict[@"alt_sizes"];
                 NSMutableArray *sizes = [NSMutableArray array];
                 for (NSDictionary *sizeDict in altsizes) {
                     NSMutableDictionary *size = [NSMutableDictionary dictionary];
                     size[@"Width"] = sizeDict[@"width"];
                     size[@"Height"] = sizeDict[@"height"];
                     size[@"Url"] = sizeDict[@"url"];
                     [sizes addObject:size];
                 }
                 image[@"Sizes"] = sizes;
                 [images addObject:image];
                 i++;
             }
         }
         body[@"Images"] = images;
         
         int offset = _blog.ImageFetchOffset + (int)posts.count;
         body[@"ImageFetchOffset"] = @(offset);
         
         SldHttpSession *session = [SldHttpSession defaultSession];
         [session postToApi:@"tumblr/addImages" body:body completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
             if (error) {
                 [lwUtil alertHTTPError:error data:data];
                 return;
             }
             _blog.ImageFetchOffset = offset;
             NSString *output = [NSString stringWithFormat:@"postNum:%d, offset:%d", postNum, offset];
             _header.outputView.text = output;
             if (self.navigationController && _buttonSyncing) {
                 [self syncPost];
             } else {
                 _syncing = NO;
             }
         }];
     }];
}


- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (IBAction)onRefreshButton:(id)sender {
    _isPortrait = _header.portraitSwitch.on;
    
    
    SldHttpSession *session = [SldHttpSession defaultSession];
    int limit = 30;
    NSDictionary *body = @{
                           @"BlogName":_blog.Name,
                           @"LastKey":@"",
                           @"LastScore":@(0),
                           @"Limit":@(limit),
                           @"IsPortrait":@(_isPortrait),
                           };
    [session postToApi:@"tumblr/listImage" body:body completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            [lwUtil alertHTTPError:error data:data];
            return;
        }
        
        [_images removeAllObjects];
        
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (error) {
            lwError("Json error:%@", [error localizedDescription]);
            return;
        }
        
        _lastKey = dict[@"LastKey"];
        _lastScore = [(NSNumber*)dict[@"LastScore"] longLongValue];
        NSArray *images = dict[@"Images"];
        for (NSDictionary *imageDict in images) {
            TumblrImage *image = [[TumblrImage alloc] initWithDict:imageDict];
            [_images addObject:image];
        }
        [self.collectionView reloadData];
    }];
    
    
}

- (IBAction)onMoreButton:(id)sender {
    if (_isPortrait != _header.portraitSwitch.on) {
        [self onRefreshButton:nil];
        return;
    }
    
    UIButton *button = sender;
    [button setTitle:@"加载中..." forState:UIControlStateDisabled];
    button.enabled = NO;
    
    SldHttpSession *session = [SldHttpSession defaultSession];
    int limit = 30;
    NSDictionary *body = @{
                           @"BlogName":_blog.Name,
                           @"LastKey":_lastKey,
                           @"LastScore":@(_lastScore),
                           @"Limit":@(limit),
                           @"IsPortrait":@(_isPortrait),
                           };
    [session postToApi:@"tumblr/listImage" body:body completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        [button setTitle:@"更多" forState:UIControlStateDisabled];
        button.enabled = YES;
        if (error) {
            [lwUtil alertHTTPError:error data:data];
            return;
        }
        
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (error) {
            lwError("Json error:%@", [error localizedDescription]);
            return;
        }
        
        _lastKey = dict[@"LastKey"];
        _lastScore = [(NSNumber*)dict[@"LastScore"] longLongValue];
        NSArray *images = dict[@"Images"];
        NSMutableArray *inserts = [NSMutableArray arrayWithCapacity:limit];
        for (NSDictionary *imageDict in images) {
            TumblrImage *image = [[TumblrImage alloc] initWithDict:imageDict];
            [inserts addObject:[NSIndexPath indexPathForRow:_images.count inSection:0]];
            [_images addObject:image];
        }
        [self.collectionView insertItemsAtIndexPaths:inserts];
        
        if (images.count < limit) {
            [button setTitle:@"后面没有了" forState:UIControlStateDisabled];
            button.enabled = NO;
        }
    }];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if (segue.identifier && [segue.identifier compare:@"segueImageBrowser"] == 0) {
        ImageBrowserController *vc = segue.destinationViewController;
        
        BlogPostsCell *cell = sender;
        vc.image = cell.image;
        vc.images = _images;
    }
}


#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _images.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BlogPostsCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"postCell" forIndexPath:indexPath];
    if (indexPath.row < _images.count) {
        TumblrImage *image = _images[indexPath.row];
        [cell.imageView asyncLoadImageWithUrl:image.thumbUrl localPath:[BlogPostsController makeImagePath:image.thumbUrl] showIndicator:NO completion:nil];
        cell.image = image;
    }
    
    // Configure the cell
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if (kind == UICollectionElementKindSectionFooter) {
        return [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"footer" forIndexPath:indexPath];
    } else if (kind == UICollectionElementKindSectionHeader) {
        _header = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"header" forIndexPath:indexPath];
        _header.outputView.text = @"";
        
        return _header;
    }
    return nil;
}

@end

