//
//  Expired.swift
//  bcnews
//
//  Created by 杰刘 on 2018/4/11.
//  Copyright © 2018年 onchaintech. All rights reserved.
//

import UIKit

class Expired: NSObject {
    
    class func getSubscriptionIsExpired() -> Bool{
        
        let sss = UserDefaults.standard.object(forKey: "expires_date_ms")
        
       
        
         var longExpires  = Int()
        
        if sss == nil {
            longExpires = 0
        }else{
             let expiresauto = sss as! String
            longExpires = Int(expiresauto)!
        }
        
//        let expiresauto :String = UserDefaults.standard.object(forKey: "expires_date_ms") as! String
        //计算是否过期
       
        
        //获取当前时间
        let now = NSDate()
        //当前时间的时间戳
        let timeInterval:TimeInterval = now.timeIntervalSince1970
        let longCurrent = Int(timeInterval)
        //比较
        let diff = (longCurrent * 1000) - longExpires
        
        if diff > 0 {
            //过期
            return true
        }else{
            return false
        }
        
    }
    

}
