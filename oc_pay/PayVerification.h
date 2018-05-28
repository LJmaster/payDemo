//
//  ViewController.m
//  KingScanner
//
//  Created by 杰刘 on 2018/5/21.
//  Copyright © 2018年 刘杰. All rights reserved.

#import <Foundation/Foundation.h>

@protocol PayDelegate <NSObject>

-(void)payVerificationSuccess;

-(void)payVerificationfailed;

@end

@interface PayVerification : NSObject

@property(nonatomic,weak) id<PayDelegate> payVerificationDelegate;

//获取购买的凭证
// App进入验证
- (void)sendFailedIapFiles;

@end
