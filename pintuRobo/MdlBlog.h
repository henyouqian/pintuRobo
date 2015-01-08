//
//  MdlBlog.h
//  pintuRobo
//
//  Created by 李炜 on 14/12/30.
//  Copyright (c) 2014年 李炜. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface MdlBlog : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * avatarUrl;
@property (nonatomic, retain) NSDate * addTime;
@property (nonatomic, retain) NSNumber * postNum;

@end
