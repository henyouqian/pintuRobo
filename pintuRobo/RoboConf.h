//
//  RoboConf.h
//  pintuRobo
//
//  Created by 李炜 on 15/1/6.
//  Copyright (c) 2015年 李炜. All rights reserved.
//

@interface RoboConf : NSObject

@property NSString *SERVER_HOST;
@property NSString *SERVER_SECRET;
@property NSString *IMAGE_DOWNLOAD_HOST;
@property NSString *UPLOAD_HOST;
@property NSString *PRIVATE_UPLOAD_HOST;

+(instancetype)inst;

@end
