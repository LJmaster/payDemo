

//
//  PayVerification.m
//  MMCalculator
//
//  Created by 杰刘 on 2017/11/27.
//

#import "PayVerification.h"

#ifdef DEBUG
#define checkURL @"https://sandbox.itunes.apple.com/verifyReceipt"
#else
#define checkURL @"https://buy.itunes.apple.com/verifyReceipt"
#endif
#define AppStoreInfoLocalFilePath [NSString stringWithFormat:@"%@/%@/", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],@"EACEF35FE363A75A"]

@implementation PayVerification
// App进入验证
- (void)sendFailedIapFiles{
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
    NSString *payload = [NSString stringWithFormat:@"{\"receipt-data\" : \"%@\", \"password\" : \"%@\"}", encodeStr, @"97867822ceb24aa6b5b86902c00312d9"];
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
            //本地存储第一次订阅时间
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
                    if (self.payVerificationDelegate && [self.payVerificationDelegate respondsToSelector:@selector(payVerificationfailed)]) {
                        [self.payVerificationDelegate payVerificationfailed];
                    }
                } else {
                    //未过期  本地存储信息 （expires_date_ms：到期日的时间戳）
                    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                    [defaults setObject:expires forKey:@"expires_date_ms"];
                    [defaults setObject:purchase forKey:@"purchase_date_ms"];
                    [defaults synchronize];
                    
                    if (self.payVerificationDelegate && [self.payVerificationDelegate respondsToSelector:@selector(payVerificationSuccess)]) {
                        [self.payVerificationDelegate payVerificationSuccess];
                    }
                }
            }
        }else{
            if (self.payVerificationDelegate && [self.payVerificationDelegate respondsToSelector:@selector(payVerificationSuccess)]) {
                [self.payVerificationDelegate payVerificationSuccess];
            }
        }
    }
}



@end
