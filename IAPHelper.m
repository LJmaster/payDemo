//
//  IAPHelper.m
//  BookClient
//
//  Created by Leo on 2016/12/18.
//  Copyright © 2016年 Leo. All rights reserved.
//

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

@implementation IAPHelper {
    void(^_success)();
    void(^_fail)(NSError *error);
}

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

- (void)payForProductWithProductID:(NSString *)productID success:(void(^)())success fail:(void(^)(NSError *error))fail {
    if (![SKPaymentQueue canMakePayments]) {             //替换项目时此处需修改
        NSError *error = [[NSError alloc] initWithDomain:@"audio.book.cast.review" code:0 userInfo:@{@"error": @"cannot make payments"}];
        fail(error);
        return;
    }
    _success = success;
    _fail = fail;
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
    SKProduct *product = response.products.firstObject;
    if (product == nil) {
        NSError *error = [[NSError alloc] initWithDomain:@"audio.book.cast.review" code:0 userInfo:@{@"error": @"requested product not found"}];
        if (_fail) {
            _fail(error);
        }
        return;
    }
    SKPayment *pay = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:pay];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    if (_fail) {
        _fail(error);
    }
}
#pragma Restored

-(void)stateRestored{

[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];

}

-(void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue{

   NSMutableArray * purchasedItemIDs = [[NSMutableArray alloc] init];
    if (purchasedItemIDs.count == 0) {
        NSNotification *notification =[NSNotification notificationWithName:@"paymentfailedtongzhi" object:nil userInfo:nil];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
    }
    
    NSLog(@"received restored transactions: %lu", (unsigned long)queue.transactions.count);
    for (SKPaymentTransaction *transaction in queue.transactions)
    {
        NSString *productID = transaction.payment.productIdentifier;
        [purchasedItemIDs addObject:productID];
        NSLog(@"%@",purchasedItemIDs);
    }

}

#pragma mark - Observer
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    NSString *errorReason = @"";
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
//                 获取并加密支付凭证
//                transaction.transactionReceipt
                self.receipt = [GTMBase64 stringByEncodingData:[NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]]];
                [self saveReceipt];
                [queue finishTransaction:transaction];
                if (_success) {
                    _success();
                }
                _success = nil;
                _fail = nil;
                
            {
                
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setBool:YES forKey:@"paySuccess"];
                [defaults synchronize];
                

                NSNotification *notification =[NSNotification notificationWithName:@"tongzhi" object:nil userInfo:nil];
                [[NSNotificationCenter defaultCenter] postNotification:notification];
            }
                return;
            case SKPaymentTransactionStatePurchasing:
                return;
            case SKPaymentTransactionStateFailed:
                errorReason = @"payment failed";
            {
                NSNotification *notification =[NSNotification notificationWithName:@"paymentfailedtongzhi" object:nil userInfo:nil];
                [[NSNotificationCenter defaultCenter] postNotification:notification];
            
            }
                [queue finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                
            {
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setBool:YES forKey:@"paySuccess"];
                [defaults synchronize];
            
                [queue finishTransaction:transaction];
                
                errorReason = @"already pay for this product";
                NSNotification *notification =[NSNotification notificationWithName:@"tongzhi" object:nil userInfo:nil];
                [[NSNotificationCenter defaultCenter] postNotification:notification];

            }
                
                break;
            case SKPaymentTransactionStateDeferred:
                errorReason = @"payment state deferred";
                [queue finishTransaction:transaction];
                break;
            default:
                break;
        }
    }
    NSError *error = [[NSError alloc] initWithDomain:@"audio.book.cast.review" code:0 userInfo:@{@"error": errorReason}];
    if (_fail) _fail(error);
    _success = nil;
    _fail = nil;
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
}


@end
