//
//  ViewController.m
//  KingScanner
//
//  Created by 杰刘 on 2018/5/21.
//  Copyright © 2018年 刘杰. All rights reserved.

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface IAPHelper : NSObject

+ (instancetype)sharedHelper;

/**
 恢复订阅
 */
-(void)stateRestored;

/**
 订阅购买

 @param productID 订阅产品的id
 @param success 成功回调
 @param fail 失败回调
 */
- (void)payForProductWithProductID:(NSString *)productID fail:(void(^)(NSError *error))fail;

/**
验证信息
 */
@property(nonatomic) NSString* receipt;

-(void)saveReceipt;
@end
