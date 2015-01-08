//
//  BlogListController.m
//  pintuRobo
//
//  Created by 李炜 on 14/12/29.
//  Copyright (c) 2014年 李炜. All rights reserved.
//

#import "BlogListController.h"
#import "MdlBlog.h"
#import "lwUtil.h"
#import "BlogPostsController.h"
#import "SldHttpSession.h"
#import "RoboData.h"

static const int _FATCH_LIMIT = 20;

//============================
@interface BlogListCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIView *avatarView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
//@property MdlBlog* blog;
@property TumblrBlog *blog;
@end

@implementation BlogListCell

@end


//============================
static BlogListController *_blogListController = nil;
@interface BlogListController ()

@property NSMutableArray *blogs;
@property NSString *lastBlogKey;
@property SInt64 lastBlogScore;


@end

@implementation BlogListController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    _blogs = [NSMutableArray arrayWithArray:[MdlBlog MR_findAllSortedBy:@"addTime" ascending:NO]];
    _blogs = [NSMutableArray arrayWithCapacity:20];
    
    SldHttpSession *session = [SldHttpSession defaultSession];
    NSDictionary *body = @{@"LastKey":@"", @"LastScore":@(0), @"Limit":@(_FATCH_LIMIT)};
    [session postToApi:@"tumblr/listBlog" body:body completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            [lwUtil alertHTTPError:error data:data];
            return;
        }
        
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (error) {
            lwError("Json error:%@", [error localizedDescription]);
            return;
        }
        _lastBlogKey = [dict objectForKey:@"LastKey"];
        _lastBlogScore = [(NSNumber*)[dict objectForKey:@"LastScore"] intValue];
        NSArray *jsBlogs = [dict objectForKey:@"Blogs"];
        for (NSDictionary *blogDict in jsBlogs) {
            TumblrBlog *blog = [[TumblrBlog alloc] initWithDict:blogDict];
            [_blogs addObject:blog];
        }
        
        [self.tableView reloadData];
    }];

    _blogListController = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _blogs.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 50;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BlogListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"blogCell" forIndexPath:indexPath];
    
    TumblrBlog *blog = [_blogs objectAtIndex:indexPath.row];
    NSString *str = [NSString stringWithFormat:@"%@, %d", blog.Name, blog.ImageFetchOffset];
    if (blog.FetchFinish) {
        str = [NSString stringWithFormat:@"%@, AF", str];
    }
    cell.nameLabel.text = str;
    cell.blog = blog;
    
//    MdlBlog *blog = _blogs[indexPath.row];
//    cell.nameLabel.text = blog.name;
//    cell.blog = blog;
    
    return cell;
}

- (void)addBlogWithBlogName:(NSString*)blogName dict:(NSDictionary*)dict {
//    NSDictionary *blogDict = dict[@"blog"];
//    MdlBlog *blog = [MdlBlog MR_findFirstOrCreateByAttribute:@"name" withValue:blogName];
//    blog.addTime = [NSDate dateWithTimeIntervalSinceNow:0];
//    blog.postNum = blogDict[@"posts"];
//    
//    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:nil];
//    _blogs = [NSMutableArray arrayWithArray:[MdlBlog MR_findAllSortedBy:@"addTime" ascending:NO]];
//    [self.tableView reloadData];
    
}

- (void)addBlogWithDict:(NSDictionary*)dict {
    TumblrBlog *blog = [[TumblrBlog alloc] initWithRawDict:dict];
    
    SldHttpSession *session = [SldHttpSession defaultSession];
    NSDictionary *body = @{
                           @"Name":blog.Name,
                           @"Url":blog.Url,
                           @"Description":blog.Description,
                           @"IsNswf":@(blog.IsNswf),
                           @"Avartar64":blog.Avartar64,
                           @"Avartar128":blog.Avartar128,
                           };
    [session postToApi:@"tumblr/addBlog" body:body completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            [lwUtil alertHTTPError:error data:data];
            return;
        }
        
        [_blogs insertObject:blog atIndex:0];
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

- (IBAction)onDeleteButton:(id)sender {
    [[[UIAlertView alloc] initWithTitle:@"确定删除?"
                                message:nil
                       cancelButtonItem:[RIButtonItem itemWithLabel:@"取消" action:^{
        // Handle "Cancel"
    }]
                       otherButtonItems:[RIButtonItem itemWithLabel:@"删除！" action:^{
//        UIButton *button = sender;
//        BlogListCell *cell = (BlogListCell*)button.superview.superview;
//        [cell.blog MR_deleteEntity];
//        
//        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:nil];
//        
//        _blogs = [NSMutableArray arrayWithArray:[MdlBlog MR_findAllSortedBy:@"addTime" ascending:NO]];
//        [self.tableView reloadData];
        
        UIButton *button = sender;
        BlogListCell *cell = (BlogListCell*)button.superview.superview;
        NSIndexPath *ip = [self.tableView indexPathForCell:cell];
        
        SldHttpSession *session = [SldHttpSession defaultSession];
        NSDictionary *body = @{
                               @"BlogName":cell.blog.Name,
                               };
        [session postToApi:@"tumblr/delBlog" body:body completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                [lwUtil alertHTTPError:error data:data];
                return;
            }
            
            [_blogs removeObject:cell.blog];
            [self.tableView deleteRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationAutomatic];
        }];
    }], nil] show];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if (segue.identifier && [segue.identifier compare:@"segueEnterBlog"] == 0) {
        BlogListCell *cell = sender;
        [RoboData inst].blog = cell.blog;
    }
}


@end

//============================
@interface BlogAddController : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *blogNameInput;

@end

@implementation BlogAddController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [_blogNameInput becomeFirstResponder];
}

- (IBAction)onAddButton:(id)sender {
    if (_blogNameInput.text == nil || _blogNameInput.text.length == 0) {
        [lwUtil alertWithTitle:@"填写账号" text:nil buttonTitle:@"OK" action:nil];
        return;
    }
    
    UIAlertView *alert = [lwUtil alertWithTitle:@"获取中..." text:nil buttonTitle:nil action:nil];
    NSString *name = _blogNameInput.text;
//    NSString *name = [NSString stringWithFormat:@"%@.tumblr.com", _blogNameInput.text];
    [[TMAPIClient sharedInstance] blogInfo:name
                                  callback:^ (id result, NSError *error)
    {
        [alert dismissWithClickedButtonIndex:0 animated:NO];
        if (error) {
            [lwUtil alertWithTitle:@"获取失败" text:[error localizedDescription] buttonTitle:@"OK" action:nil];
            return;
        }
        
//        [lwUtil alertWithTitle:@"添加成功" text:nil buttonTitle:@"OK" action:^{
//            [self.navigationController popViewControllerAnimated:YES];
//        }];
//        [_blogListController addBlogWithBlogName:name dict:result];
        [_blogListController addBlogWithDict:result[@"blog"]];
    }];
}

@end



