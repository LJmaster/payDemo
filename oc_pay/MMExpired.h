//
//  MMExpired.h
//  MMListenBook
//
//  Created by heiheihei on 2017/6/8.
//  Copyright © 2017年 heiheihei. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MMExpired : NSObject


/**
 获取订阅是否过期

 @return yes:过期，no: 没有过期
 */
+(BOOL)getSubscriptionIsExpired;
@end
