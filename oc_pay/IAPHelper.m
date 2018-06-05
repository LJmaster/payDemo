//
//  ViewController.m
//  KingScanner
//
//  Created by 杰刘 on 2018/5/21.
//  Copyright © 2018年 刘杰. All rights reserved.

#import "IAPHelper.h"
#import "GTMBase64.h"

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
- (void)payForProductWithProductID:(NSString *)productID success:(void(^)(void))success fail:(void(^)(NSError *error))fail {
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
    
    
//
//    NSArray *myProduct = response.products;
//    if (myProduct.count == 0) {
//                NSError *error = [[NSError alloc] initWithDomain:@"calculator.app.mmcalculator" code:0 userInfo:@{@"error": @"requested product not found"}];
//                if (_fail) {
//                    _fail(error);
//                }
//                return;
//    }
//
//    // populate UI
//    for(SKProduct *product in myProduct){
//
//        NSLog(@"product info");
//        NSLog(@"SKProduct描述信息%@", [product description]);
//        NSLog(@"产品标题%@", product.localizedTitle);
//        NSLog(@"价格: %@", product.price);
//        NSLog(@"Product id: %@", product.productIdentifier);
//        SKPayment *payment = [SKPayment paymentWithProduct:product];
//        [[SKPaymentQueue defaultQueue] addPayment:payment];
//        //addPayment 将支付信息添加进苹果的支付队列后，苹果会自动完成后续的购买请求，在用户购买成功或者点击取消购买的选项后回调
//    }
//
    

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
                [queue finishTransaction:transaction];
            {
                //支付成功的通知
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
                [queue finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
            {
                //支付成功的通知
                NSNotification *notification =[NSNotification notificationWithName:@"Restoredtongzhi" object:nil userInfo:nil];
                [[NSNotificationCenter defaultCenter] postNotification:notification];
                [queue finishTransaction:transaction];
            }
                errorReason = @"already pay for this product";
                [queue finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateDeferred:
                errorReason = @"payment state deferred";
                [queue finishTransaction:transaction];
                break;
            default:
                break;
        }
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
    purchasedItemIDs = [[NSMutableArray alloc] init];
    NSLog(@"received restored transactions: %i", queue.transactions.count);
    for (SKPaymentTransaction *transaction in queue.transactions)
    {
       //恢复购买成功以后 做处理 ，这里需要自己去操作
    }
}
//持久化存储用户购买凭证
-(void)saveReceipt {
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

