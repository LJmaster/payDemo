//
//  MMExpired.m
//  MMListenBook
//
//  Created by heiheihei on 2017/6/8.
//  Copyright © 2017年 heiheihei. All rights reserved.
//

#import "MMExpired.h"

@implementation MMExpired

+(BOOL)getSubscriptionIsExpired{

    //获取本地到期时间
        NSString * expiresauto = [[NSUserDefaults standardUserDefaults] objectForKey:@"expires_date_ms"];
        //计算是否过期
        long long longExpires = [expiresauto longLongValue];
        //获取本地时间
        NSTimeInterval current = [[NSDate date] timeIntervalSince1970];
        long long longCurrent = (long long)current;
        long diff = (long)(longCurrent * 1000 - longExpires );
        if( diff > 0){
            //过期
            return YES;
        }else{
            return NO;
        }

    
}

@end
