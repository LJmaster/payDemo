//
//  Pay.m
//  Qmsocks
//
//  Created by 杰刘 on 2017/7/5.
//  Copyright © 2017年 qm1024.com. All rights reserved.
//

#import "Pay.h"
#import "IAPHelper.h"

#ifdef DEBUG
#define checkURL @"https://sandbox.itunes.apple.com/verifyReceipt"
#else
#define checkURL @"https://buy.itunes.apple.com/verifyReceipt"
#endif
#define AppStoreInfoLocalFilePath [NSString stringWithFormat:@"%@/%@/", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],@"EACEF35FE363A75A"]

@implementation Pay

+ (instancetype)sharedPay {
    static Pay *helper;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        helper = [[self alloc] init];
    });
    return helper;
}
- (void)requestForProductID:(NSString *)productID {
    [[IAPHelper sharedHelper] payForProductWithProductID:productID success:^{
        [self sendFailedIapFiles];
        
    } fail:^(NSError *error) {
        NSLog(@"%@",error);
           self.payBlock(@"错误");
     
    }];
}
-(void)StateRestored{
    [[IAPHelper sharedHelper] stateRestored];

}

// App进入验证
- (void)sendFailedIapFiles{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    //搜索该目录下的所有文件和目录
    NSArray *cacheFileNameArray = [fileManager contentsOfDirectoryAtPath:AppStoreInfoLocalFilePath error:&error];
    if (error == nil)
    {
        for (NSString *name in cacheFileNameArray)
        {
            if ([name hasSuffix:@".plist"])//如果有plist后缀的文件，说明就是存储的购买凭证
            {
                NSString *filePath = [NSString stringWithFormat:@"%@/%@", AppStoreInfoLocalFilePath, name];
                [self sendAppStoreRequestBuyPlist:filePath];
            }
        }
    }
}
//获取购买的凭证
-(void)sendAppStoreRequestBuyPlist:(NSString *)plistPath
{
    NSDictionary *dic = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    NSURL *url = [NSURL URLWithString:checkURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0f];
    request.HTTPMethod = @"POST";
    NSString *encodeStr = [dic objectForKey:@"transactionReceipt"];
    NSString *payload = [NSString stringWithFormat:@"{\"receipt-data\" : \"%@\", \"password\" : \"%@\"}", encodeStr, @"56cc46d967104e88b523b4c3f8837747"];
    NSData *payloadData = [payload dataUsingEncoding:NSUTF8StringEncoding];
    request.HTTPBody = payloadData;
    // 提交验证请求，并获得官方的验证JSON结果
    NSData *result = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    if (result != nil) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:result
                                                             options:NSJSONReadingAllowFragments error:nil];
        if (dict != nil) {
            // 验证成功,通知
            NSArray *receiptInfo = dict[@"latest_receipt_info"];
            NSDictionary *lastReceiptInfo = receiptInfo.lastObject;
            //本地存储第一次订阅时间（purchase_date_ms：第一次订阅的时间戳）
            NSDictionary * firstReceiptInfo = receiptInfo.firstObject;
            NSString * purchase = firstReceiptInfo[@"purchase_date_ms"];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:purchase forKey:@"purchase_date_ms"];
            [defaults synchronize];
            if (lastReceiptInfo != nil) {
                //到期时间
                NSString *expires = lastReceiptInfo[@"expires_date_ms"];
                //第一次订阅时间
                long long longExpires = [expires longLongValue];
                NSTimeInterval current = [[NSDate date] timeIntervalSince1970];
                long long longCurrent = (long long)current;
                long diff = (long)(longCurrent * 1000 - longExpires );
                if( diff > 0){
                    //过期
                } else {
                    //未过期  本地存储信息 （expires_date_ms：到期日的时间戳）
                    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                    [defaults setObject:expires forKey:@"expires_date_ms"];
                    [defaults setObject:purchase forKey:@"purchase_date_ms"];
                    [defaults synchronize];
                    
                    self.payBlockSuccess(dic);
                    
                }
            }
        }
    }
}



@end
