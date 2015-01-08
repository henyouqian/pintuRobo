//
//  MdlInt.h
//  pintuRobo
//
//  Created by 李炜 on 14/12/29.
//  Copyright (c) 2014年 李炜. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface MdlInt : NSManagedObject

@property (nonatomic, retain) NSString * key;
@property (nonatomic, retain) NSNumber * value;

@end
