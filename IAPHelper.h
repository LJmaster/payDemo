//
//  IAPHelper.h
//  BookClient
//
//  Created by Leo on 2016/12/18.
//  Copyright © 2016年 Leo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
@protocol PayDelegate <NSObject>

-(void)payVerificationSuccess;

-(void)payVerificationfailed;

@end

@interface IAPHelper : NSObject

+ (instancetype)sharedHelper;

/**
 恢复订阅
 */
+(void)stateRestored;

/**
 订阅购买

 @param productID 订阅产品的id
 @param success 成功回调
 @param fail 失败回调
 */
- (void)payForProductWithProductID:(NSString *)productID success:(void(^)())success fail:(void(^)(NSError *error))fail;

/**
验证数
 */
@property(nonatomic) NSString* receipt;

@property(nonatomic,weak) id<PayDelegate> payVerificationDelegate;

//获取购买的凭证
// App进入验证
- (void)sendFailedIapFiles;

@end
