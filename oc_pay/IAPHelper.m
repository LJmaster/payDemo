//
//  ViewController.m
//  KingScanner
//
//  Created by 杰刘 on 2018/5/21.
//  Copyright © 2018年 刘杰. All rights reserved.

#import "IAPHelper.h"
#import "GTMBase64.h"
#import "PayVerification.h"

#ifdef DEBUG
#define checkURL @"https://sandbox.itunes.apple.com/verifyReceipt"
#else
#define checkURL @"https://buy.itunes.apple.com/verifyReceipt"
#endif
#define AppStoreInfoLocalFilePath [NSString stringWithFormat:@"%@/%@/", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],@"EACEF35FE363A75A"]

@interface IAPHelper () <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@end

@implementation IAPHelper

+ (instancetype)sharedHelper {
    static IAPHelper *helper;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        helper = [[self alloc] init];
    });
    return helper;
}

- (void)dealloc {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

- (instancetype)init {
    if (self = [super init]) {
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}
- (void)payForProductWithProductID:(NSString *)productID fail:(void(^)(NSError *error))fail {
    if (![SKPaymentQueue canMakePayments]) {             //替换项目时此处需修改
        NSError *error = [[NSError alloc] initWithDomain:@"calculator.app.mmcalculator" code:0 userInfo:@{@"error": @"cannot make payments"}];
        fail(error);
        return;
    }

    NSSet *IDs = [NSSet setWithObject:productID];
    [self requestProductsWithProductIDs:IDs];
}

- (void)requestProductsWithProductIDs:(NSSet *)productIDs {
    SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:productIDs];
    request.delegate = self;
    [request start];
}

#pragma mark - SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    NSLog(@"-----------收到产品反馈信息--------------");
    
    SKProduct *product = response.products.firstObject;
    if (product == nil) {
        NSError *error = [[NSError alloc] initWithDomain:@"calculator.app.mmcalculator" code:0 userInfo:@{@"error": @"requested product not found"}];
            //失败的通知
        NSNotification * notification =[NSNotification notificationWithName:@"paymentfailedtongzhi" object:nil userInfo:nil];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
        return;
    }
    SKPayment *pay = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:pay];
}
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    NSNotification *notification =[NSNotification notificationWithName:@"paymentfailedtongzhi" object:nil userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

#pragma mark - Observer
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    NSString *errorReason = @"";
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                //                 获取并加密支付凭证
                self.receipt = [GTMBase64 stringByEncodingData:[NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]]];
                [self saveReceipt];
                //订阅特殊处理
                if(transaction.originalTransaction){
                    //如果是自动续费的订单originalTransaction会有内容
                    [[PayVerification shared] sendFailedIapFiles];
                }else{
                    // 普通购买，以及 第一次购买 自动订阅
                    NSNotification *notification =[NSNotification notificationWithName:@"paysuccesstongzhi" object:nil userInfo:nil];
                    [[NSNotificationCenter defaultCenter] postNotification:notification];
                }
         
                return;
            case SKPaymentTransactionStatePurchasing:
                return;
            case SKPaymentTransactionStateFailed:
                errorReason = @"payment failed";
            {
                switch (transaction.error.code) {
                        
                    case SKErrorUnknown:
                        NSLog(@"SKErrorUnknown");
                        NSLog(@"未知的错误，您可能正在使用越狱手机");
                        break;
                        
                    case SKErrorClientInvalid:
                        NSLog(@"SKErrorClientInvalid");
                        NSLog(@"当前苹果账户无法购买商品(如有疑问，可以询问苹果客服)");
                        break;
                        
                    case SKErrorPaymentCancelled:
                        NSLog(@"SKErrorPaymentCancelled");
                        NSLog(@"订单已取消");
                        break;
                    case SKErrorPaymentInvalid:
                        NSLog(@"SKErrorPaymentInvalid");
                        NSLog(@"订单无效(如有疑问，可以询问苹果客服)");
                        break;
                        
                    case SKErrorPaymentNotAllowed:
                        NSLog(@"SKErrorPaymentNotAllowed");
                        NSLog(@"当前苹果设备无法购买商品(如有疑问，可以询问苹果客服)");
                        break;
                    case SKErrorStoreProductNotAvailable:
                        NSLog(@"SKErrorStoreProductNotAvailable");
                        NSLog(@"当前商品不可用");
                        break;
                    default:
                        NSLog(@"No Match Found for error");
                        NSLog(@"未知错误");
                        break;
                }
                //支付失败的通知
                NSNotification *notification =[NSNotification notificationWithName:@"paymentfailedtongzhi" object:nil userInfo:nil];
                [[NSNotificationCenter defaultCenter] postNotification:notification];
            }
                break;
            case SKPaymentTransactionStateRestored://已经购买过该商品
                break;
            case SKPaymentTransactionStateDeferred://商品添加进列表
                break;
            default:
                break;
        }
        
        [queue finishTransaction:transaction];

    }
    
}
//恢复复购买
-(void)stateRestored{
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}
- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error{
  NSNotification *notification =[NSNotification notificationWithName:@"Restoredpaymentfailedtongzhi" object:nil userInfo:nil];
  [[NSNotificationCenter defaultCenter] postNotification:notification];
}
- (void) paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    //恢复购买成功以后 做处理 ，这里需要自己去操作
    NSLog(@"received restored transactions: %lu", (unsigned long)queue.transactions.count);
    for (SKPaymentTransaction *transaction in queue.transactions)
    {
    }
    //支付成功的通知
    NSNotification *notification =[NSNotification notificationWithName:@"Restoredtongzhi" object:nil userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
    self.receipt = [GTMBase64 stringByEncodingData:[NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]]];
    [self saveReceipt];
}
//持久化存储用户购买凭证
-(void)saveReceipt {
    
    if (self.receipt == nil) {
        self.receipt = [GTMBase64 stringByEncodingData:[NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]]];
    }
    NSFileManager* fm = [NSFileManager defaultManager];
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *dicPath = [documentPath stringByAppendingPathComponent:@"EACEF35FE363A75A"];
    if (![fm fileExistsAtPath:dicPath]) {
        [fm createDirectoryAtPath:dicPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *savedPath = [dicPath stringByAppendingString:@"/localTransactionReceipt.plist"];
    if (![fm fileExistsAtPath:savedPath]) {
        BOOL rrr = [fm createFileAtPath:savedPath contents:nil attributes:nil];
        if (rrr) {
            NSLog(@"%@",savedPath);
            NSLog(@"创建文件成功");
        } else {
            NSLog(@"创建文件失败");
        }
    }
    NSDictionary *dic =[ NSDictionary dictionaryWithObjectsAndKeys:
                        self.receipt,                           @"transactionReceipt",
                        nil];
    BOOL u =  [dic writeToFile:savedPath atomically:YES];
    NSLog(@"%d",u);
}



@end

