//
//  ViewController.m
//  KingScanner
//
//  Created by 杰刘 on 2018/5/21.
//  Copyright © 2018年 刘杰. All rights reserved.

#import "PayVerification.h"
#import "URLMacros.h"


#ifdef DEBUG
#define checkURL @"https://sandbox.itunes.apple.com/verifyReceipt"
#else
#define checkURL @"https://buy.itunes.apple.com/verifyReceipt"
#endif
#define AppStoreInfoLocalFilePath [NSString stringWithFormat:@"%@/%@/", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],@"EACEF35FE363A75A"]

@implementation PayVerification

+ (instancetype)shared {
    static PayVerification *helper;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        helper = [[self alloc] init];
    });
    return helper;
}


+(BOOL)getSubscriptionIsExpired{
    
    //获取本地到期时间
    NSString * expiresauto = [[NSUserDefaults standardUserDefaults] objectForKey:@"expires_date_ms"];
    //计算是否过期
    long long longExpires = [expiresauto longLongValue];
    //获取本地时间
    NSTimeInterval current = [[NSDate date] timeIntervalSince1970];
    long long longCurrent = (long long)current;
    long long diff = (long long)(longCurrent * 1000 - longExpires );
    if( diff > 0){
        //过期
        return YES;
    }else{
        return NO;
    }
}

// App进入验证
- (void)sendFailedIapFiles{

    [self sendAppStoreRequestBuyWithUrl:@"https://buy.itunes.apple.com/verifyReceipt"];
}
/// 向网络请求数据
- (void)sendAppStoreRequestBuyWithUrl:(NSString *)urlStr
{
    
    NSDictionary *pathdic;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    //搜索该目录下的所有文件和目录
    NSArray *cacheFileNameArray = [fileManager subpathsAtPath:AppStoreInfoLocalFilePath];
    if (error == nil)
    {
        for (NSString *name in cacheFileNameArray)
        {
            if ([name hasSuffix:@".plist"])//如果有plist后缀的文件，说明就是存储的购买凭证
            {
                NSString *filePath = [NSString stringWithFormat:@"%@/%@", AppStoreInfoLocalFilePath, name];
                pathdic = [NSDictionary dictionaryWithContentsOfFile:filePath];
            }
        }
    }
    
    NSURL *url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0f];
    request.HTTPMethod = @"POST";
    NSString *encodeStr = [pathdic objectForKey:@"transactionReceipt"];
    NSString *payload = [NSString stringWithFormat:@"{\"receipt-data\" : \"%@\", \"password\" : \"%@\"}", encodeStr, Ipa_Verification_password];//购买秘钥 ，要在修改
    NSData *payloadData = [payload dataUsingEncoding:NSUTF8StringEncoding];
    request.HTTPBody = payloadData;
    
    // 1.创建url
    NSURLSession *sharedSession = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [sharedSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        // 网络请求完成之后就会执行，NSURLSession自动实现多线程
        NSLog(@"%@",[NSThread currentThread]);
        if (data && (error == nil)) {
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            
            NSString *status = [NSString stringWithFormat:@"%@",dict[@"status"]];
            if (status && [status isEqualToString:@"21007"] ) {
                [self sendAppStoreRequestBuyWithUrl:@"https://sandbox.itunes.apple.com/verifyReceipt"];
                return;
            }
            
            if (status && [status isEqualToString:@"0"]) {
                [self dataAnalysis:dict];
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    //过期
                    if (self.payVerificationDelegate && [self.payVerificationDelegate respondsToSelector:@selector(payVerificationfailedstatus:)]) {
                        [self.payVerificationDelegate payVerificationfailedstatus:status];
                    }
                });
            }
   
        } else {
            NSLog(@"error=%@",error);
        }
    }];
    [dataTask resume];
}

///返回的数据解析
-(void)dataAnalysis:(NSDictionary *)dict{
    // 验证成功,通知
    NSArray *receiptInfo = dict[@"latest_receipt_info"];
    NSDictionary *lastReceiptInfo = receiptInfo.lastObject;
    //从得到信息中选取最大的时间作为当前时间
    for (int i = 0; i < receiptInfo.count; i++) {
        NSDictionary * ReceiptDict = receiptInfo[i];
        NSString *lastexpires = lastReceiptInfo[@"expires_date_ms"];
        NSString * Receiptexpires =ReceiptDict[@"expires_date_ms"];
        if (Receiptexpires.intValue > lastexpires.intValue) {
            lastReceiptInfo = ReceiptDict;
        }
    }
    if (lastReceiptInfo != nil) {
        //到期时间
        NSString *expires = lastReceiptInfo[@"expires_date_ms"];
        //第一次订阅时间
        long long longExpires = [expires longLongValue];
        NSTimeInterval current = [[NSDate date] timeIntervalSince1970];
        long long longCurrent = (long long)current;
        long diff = (long)(longCurrent * 1000 - longExpires );
        if( diff > 0){
            
            dispatch_async(dispatch_get_main_queue(), ^{
                //过期
                if (self.payVerificationDelegate && [self.payVerificationDelegate respondsToSelector:@selector(payVerificationfailedstatus:)]) {
                    [self.payVerificationDelegate payVerificationfailedstatus:@" "];
                }
            });
            
        } else {
            //未过期  本地存储信息 （expires_date_ms：到期日的时间戳）
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:expires forKey:@"expires_date_ms"];
            [defaults synchronize];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.payVerificationDelegate && [self.payVerificationDelegate respondsToSelector:@selector(payVerificationSuccess)]) {
                    [self.payVerificationDelegate payVerificationSuccess];
                }
            });
        }
    } 
}

@end
