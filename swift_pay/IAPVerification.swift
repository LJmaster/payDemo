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
        
        var urlstr:String = "https://buy.itunes.apple.com/verifyReceipt"
        #if DEBUG
        // 测试环境
        urlstr = "https://sandbox.itunes.apple.com/verifyReceipt"
        #endif
        self.sendAppStoreRequestBuyPlist(urlstr: urlstr)
    }
    func sendAppStoreRequestBuyPlist(urlstr:String ) {
        
        var filedict = NSDictionary()
        let fileManager = FileManager.default
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
                filedict = NSDictionary.init(contentsOfFile: filePath)!
            }
        }
        
        let url = URL.init(string: urlstr)
        var request = URLRequest.init(url: url!, cachePolicy: NSURLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: 20)
        request.httpMethod = "POST"
        let encodeStr = filedict.object(forKey: "transactionReceipt") as! String
        let payload = "{\"receipt-data\" : \"" + encodeStr + "\", \"password\" : \"" + "a28e0f370fac4d91822112bb606d20f6" + "\"}"////购买秘钥 ，要在切换产品时修改
        let payloadData = payload.data(using: String.Encoding.utf8)
        
        request.httpBody = payloadData
        // 提交验证请求，并获得官方的验证JSON结果
        
        let session = URLSession.init(configuration: .default)
        let task =  session.dataTask(with: request) { (data, res, error) in

            do{
                //              将二进制数据转换为字典对象
                if let jsonObj:NSDictionary = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions()) as? NSDictionary
                {
                    print(jsonObj)
                    //主线程
                    DispatchQueue.main.async{
//                        状态码
                        let statusStr = jsonObj["status"] as! String
                        if statusStr == "21007" {
//                           请求地址错误，测试环境请求成正式地址
                          self.sendAppStoreRequestBuyPlist(urlstr: "https://sandbox.itunes.apple.com/verifyReceipt")
                            return
                        }
                        if statusStr == "0" {
                            self.dataAnalysis(dict: jsonObj)
                        }else{
                           self.delegate?.payVerificationSuccess()
                        }
                    }
                }
            } catch{
                print("Error.")
                DispatchQueue.main.async{
                    self.delegate?.payVerificationSuccess()
                }
            }
        }
        task.resume()

    }
    
    func dataAnalysis(dict:NSDictionary) {
        //读取订阅信息
        let receiptInfo = dict["latest_receipt_info"] as! NSArray
        var lastReceiptInfo = NSDictionary()
        for i in 0 ..< receiptInfo.count {
            let receiptDict = receiptInfo[i] as? NSDictionary
            //到期时间
            let expires:String = receiptDict?["expires_date_ms"] as! String
            print( expires)
            if lastReceiptInfo["expires_date_ms"] == nil {
                lastReceiptInfo = receiptDict!
            }else{
                let lastexpires:String = lastReceiptInfo["expires_date_ms"] as! String
                if   Int(expires)! > Int(lastexpires)! {
                    lastReceiptInfo = receiptDict!
                }
            }
        }
        //判断最后一次购买有没有数据
            //到期时间
            let expires:String = (lastReceiptInfo["expires_date_ms"] as? String)!
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
//    验证是否过期
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
    
//    static func numberOfDaysWithFromDate(fromDatestr:String) -> Int{
//
//        let dateFormatter = DateFormatter.init()
//        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
//        let fromDate = dateFormatter.date(from: fromDatestr)
//
//        print(fromDate)
//        let calendar = NSCalendar.init(calendarIdentifier: NSCalendar.Identifier.gregorian)
//        calendar?.timeZone = NSTimeZone(abbreviation: "EST")! as TimeZone
//        let components = calendar?.components(NSCalendar.Unit.hour, from: fromDate!, to: Date(), options: NSCalendar.Options.wrapComponents)
//        print((components?.hour)!)
//        return (components?.hour)!
//    }
    
    static func numberOfDaysWithFromDate() -> Bool{
//        true  是在时间内
        //获取当前时间
        let now = Date()
        //当前时间的时间戳
        let nowTimestamp:TimeInterval = now.timeIntervalSince1970
        let timeStamp = Int(nowTimestamp)
        print("当前时间的时间戳：\(timeStamp)")
        
        let showAdTimeStamp:TimeInterval = 1548381074
        
        if nowTimestamp < showAdTimeStamp {
            return true
        }else{
            return false
        }
        
    }
    
}
