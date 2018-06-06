# 本文主要是说明了苹果订阅流程

oc:

购买类 IAPHelper
验证类 PayVerification
处理类 MMExpired

调用IAPHelpe类中方法开启订阅
购买方法
- (void)payForProductWithProductID:(NSString *)productID success:(void(^)())success fail:(void(^)(NSError *error))fail;
  参数说明： productID  ==商品的id
IAPHelpe  主要是调用了系统的购买方法，
 
购买完成需要验证真假 以及 购买的相关数据
验证方法
- (void)sendFailedIapFiles;

swift：

购买类 IAPHelper.swift
验证类 IAPVerification.swift


调用IAPHelpe类中方法开启订阅
购买方法
func payForProductWithProductID(productID:String)  {}
IAPHelpe  主要是调用了系统的购买方法，
 
购买完成需要验证真假 以及 购买的相关数据
验证方法
func sendFailedIapFiles() {}

----------------------------------
购买成功的数据需要加密

