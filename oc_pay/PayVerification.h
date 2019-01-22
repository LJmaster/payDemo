//
//  PayVerification.h
//  MMCalculator
//
//  Created by 杰刘 on 2017/11/27.
//

#import <Foundation/Foundation.h>

@protocol PayDelegate <NSObject>

-(void)payVerificationSuccess;

-(void)payVerificationfailedstatus:(NSString *)status;




@end

@interface PayVerification : NSObject

+ (instancetype)shared;

@property(nonatomic,weak) id<PayDelegate> payVerificationDelegate;

//获取购买的凭证
// App进入验证
- (void)sendFailedIapFiles;
//验证是否过期
+(BOOL)getSubscriptionIsExpired;

@end
