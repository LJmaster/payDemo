//
//  IAPHelper.h
//  BookClient
//
//  Created by Leo on 2016/12/18.
//  Copyright © 2016年 Leo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>


@interface IAPHelper : NSObject

+ (instancetype)sharedHelper;

- (void)payForProductWithProductID:(NSString *)productID success:(void(^)())success fail:(void(^)(NSError *error))fail;

- (void)stateRestored;

@property(nonatomic) NSString* receipt;

@end
