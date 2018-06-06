//
//  IAPVerification.swift
//  iMessageKeyboard
//
//  Created by 刘杰 on 2018/6/5.
//  Copyright © 2018年 刘杰. All rights reserved.
//

import UIKit

protocol PayVerificationDeleage:class {
    func payVerificationSuccess()
    func payVerificationError()
}

class IAPVerification: NSObject {
    
    weak var delegate:PayVerificationDeleage?
    
    func sendFailedIapFiles() {
        
        let fileManager = FileManager.default
        let error:Error
        //购买凭证 存储的路径
        let documentPath:String? = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask,true).last
        let appStoreInfoLocalFilePath = documentPath! + "/" + "EACEF35FE363A75A"
        print("AppStoreInfoLocalFilePath  =  \(appStoreInfoLocalFilePath)")
        //搜索该目录下的所有文件和目录
        let cacheFileNameArray = fileManager.subpaths(atPath: appStoreInfoLocalFilePath)
        
        for name:String in cacheFileNameArray! {
            if name.hasSuffix(".plist")//如果有plist后缀的文件，说明就是存储的购买凭证
            {
                let filePath = appStoreInfoLocalFilePath + "/" + name
                self.sendAppStoreRequestBuyPlist(plistPath: filePath)
                
            }
        }
    }
    func sendAppStoreRequestBuyPlist(plistPath:String) {
        let dict = NSDictionary.init(contentsOfFile: plistPath)
        
        var urlstr:String = "https://buy.itunes.apple.com/verifyReceipt"
        
        #if DEBUG
        // 测试环境下
        urlstr = "https://sandbox.itunes.apple.com/verifyReceipt"
        #endif
        
        let url = URL.init(string: urlstr)
        let request = NSMutableURLRequest.init(url: url!, cachePolicy: NSURLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: 20)
        request.httpMethod = "POST"
        let encodeStr = dict?.object(forKey: "transactionReceipt") as! String
        
        let payload = "{\"receipt-data\" : \"" + encodeStr + "\", \"password\" : \"" + "874945a37ea64ab9903c83102a71db79" + "\"}"////购买秘钥 ，要在切换产品时修改
        let payloadData = payload.data(using: String.Encoding.utf8)
        
        request.httpBody = payloadData
        // 提交验证请求，并获得官方的验证JSON结果
//        try? NSURLConnection.sendSynchronousRequest(request as URLRequest, returning: nil)
        
        let result = try? NSURLConnection.sendSynchronousRequest(request as URLRequest, returning: nil)
        
        if result != nil {
            let resultdict = try? JSONSerialization.jsonObject(with: result!, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
            
            if resultdict != nil {
                //读取订阅信息
                let receiptInfo = resultdict!["latest_receipt_info"] as! NSArray
                //本地存储最近一次订阅时间
                let lastReceiptInfo = receiptInfo.lastObject as? NSDictionary
                //本地存储第一次订阅时间
                let firstReceiptInfo = receiptInfo.firstObject as? NSDictionary
                let purchase = firstReceiptInfo!["purchase_date_ms"]
                UserDefaults.standard.set(purchase, forKey: "purchase_date_ms")
                UserDefaults.standard.synchronize()
                
                if lastReceiptInfo != nil  //判断最后一次购买有没有数据
                {
                    //到期时间
                    let expires:String = (lastReceiptInfo!["expires_date_ms"] as? String)!
                    //当前时间跟过期时间对比
                    let now = NSDate()
                    let timeInterval:TimeInterval = now.timeIntervalSince1970
                    
            
                    let expiresDoub:Double = Double(expires)!
                 
                    
                    let hhhh:Double = timeInterval * 1000
             
                    let diff = hhhh - expiresDoub
                    if diff > 0 {
                        self.delegate?.payVerificationError()
                        //过期
                    }else{
                        //未过期
                        //本地时间记录
                        UserDefaults.standard.set(expires, forKey: "expires_date_ms")
                        UserDefaults.standard.synchronize()
                        self.delegate?.payVerificationSuccess()
                    }
                }
            }
        }
    }
    
   static func getSubscriptionIsExpired() -> Bool{
        let sss = UserDefaults.standard.object(forKey: "expires_date_ms")
        if sss == nil {
             return true
        }else{
            //获取当前时间
            let now = NSDate()
            let timeInterval:TimeInterval = now.timeIntervalSince1970
            let hhhh:Double = timeInterval * 1000
            
            let expiresDoub:Double = Double(sss as! String)!
            
            let diff = hhhh - expiresDoub
            if diff > 0 {
                return true
                //过期
            }else{
                //未过期
               return false
            }
        }
    }
}
