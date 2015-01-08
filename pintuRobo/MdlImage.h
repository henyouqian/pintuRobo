//
//  MdlImage.h
//  pintuRobo
//
//  Created by 李炜 on 14/12/29.
//  Copyright (c) 2014年 李炜. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MdlBlog;

@interface MdlImage : NSManagedObject

@property (nonatomic, retain) NSString * imageUrl;
@property (nonatomic, retain) NSString * thumbUrl;
@property (nonatomic, retain) NSNumber * postId;
@property (nonatomic, retain) NSString * blogName;
@property (nonatomic, retain) MdlBlog *blog;

@end
