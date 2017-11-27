//
//  PayVerification.h
//  MMCalculator
//
//  Created by 杰刘 on 2017/11/27.
//

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
