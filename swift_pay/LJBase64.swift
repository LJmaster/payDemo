//
//  LJBase64.swift
//  iMessageKeyboard
//
//  Created by 刘杰 on 2018/6/6.
//  Copyright © 2018年 刘杰. All rights reserved.
//

import UIKit

class LJBase64: NSObject {
    /// swift Base64处理
    /**
     *   编码
     */
   static func base64Encoding(plainData:Data)->String
    {
        let base64String = plainData.base64EncodedString(options: NSData.Base64EncodingOptions.init(rawValue: 0))
        return base64String
    }
    
    /**
     *   解码
     */
   static func base64Decoding(encodedString:String)->String
    {
        let decodedData = NSData(base64Encoded: encodedString, options: NSData.Base64DecodingOptions.init(rawValue: 0))
        let decodedString = NSString(data: decodedData! as Data, encoding: String.Encoding.utf8.rawValue)! as String
        return decodedString
    }
}

