//
//  Pay.h
//  Qmsocks
//
//  Created by 杰刘 on 2017/7/5.
//  Copyright © 2017年 qm1024.com. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^payErrorBlock)(NSString *error);
typedef void(^paySuccessBlock)(NSDictionary *dict);


@interface Pay : NSObject

+ (instancetype)sharedPay;

- (void)requestForProductID:(NSString *)productID;

- (void)sendFailedIapFiles;
//获取购买的凭证
-(void)sendAppStoreRequestBuyPlist:(NSString *)plistPath;


-(void)StateRestored;


@property (nonatomic,copy) payErrorBlock payBlock;

@property (nonatomic,copy) paySuccessBlock payBlockSuccess;
@end
