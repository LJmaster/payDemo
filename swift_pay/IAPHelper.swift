//
//  IAPHelper.swift
//  iMessageKeyboard
//
//  Created by 杰刘 on 2018/3/29.
//  Copyright © 2018年 刘杰. All rights reserved.
//

import UIKit
import StoreKit
import Alamofire


protocol iapDelegate:class {
    
    func paysuccess()
    func payError()
    
}

class IAPHelper: NSObject,SKProductsRequestDelegate,SKPaymentTransactionObserver {
    
//    static let shared = IAPHelper()
    weak var paydelegate: iapDelegate?
    
    override init() {
        super.init()
       
    }
    deinit{
         SKPaymentQueue.default().remove(self)
    }
    
    func payForProductWithProductID(productID:String)  {
        //填写商品的id
        let ids = NSSet.init(object: productID)
        let request: SKProductsRequest = SKProductsRequest.init(productIdentifiers: ids as! Set<String>)//上面的商品还要到苹果服务器进行验证, 看下哪些商品是可以真正被销售的（创建一个商品请求并设置请求的代理，由代理告知结果）
        request.delegate = self//设置代理, 接收可以被销售的商品列表数据
        request.start()//转到extension ViewController: SKProductsRequestDelegate {
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        //当请求完毕之后, 从苹果服务器获取到数据之后调用
        print(response.products)
        print(response.invalidProductIdentifiers)
        let product = response.products.first
        if product == nil {
            //错误的商品信息
            self.paydelegate?.payError()
            return
        }
        
        if SKPaymentQueue.canMakePayments() {//判断当前的支付环境, 是否可以支付
            let payment = SKPayment(product: product!)
            SKPaymentQueue.default().add(payment)//添加到支付队列
            SKPaymentQueue.default().add(self)//监听交易状态
        }else{
            //错误的支付环境
            self.paydelegate?.payError()
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        //验证失败
        self.paydelegate?.payError()
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {// 当交易队列里面添加的每一笔交易状态发生变化的时候调用
            
            print("订阅失败信息  \(String(describing: transaction.error))")
            switch transaction.transactionState {
            case .deferred:
                print("延迟处理")
            case .failed:
                print("支付失败")
                 SKPaymentQueue.default().finishTransaction(transaction)
                queue.finishTransaction(transaction)
                self.paydelegate?.payError()
            case .purchased:
                print("支付成功")
                //写入本地
//                let receipt = GTMBase64.string(byEncoding: NSData.init(contentsOf: Bundle.main.appStoreReceiptURL!)! as? NSData)
                let receipt = GTMBase64.string(byEncoding: try? Data.init(contentsOf: Bundle.main.appStoreReceiptURL!))
                
                if receipt != nil {
                  self.saveReceipt(receipt: receipt!)
                }
                queue.finishTransaction(transaction)
                self.paydelegate?.paysuccess()
                queue.finishTransaction(transaction)
            case .purchasing:
                print("正在支付")
            case .restored:
                print("恢复购买")
                 SKPaymentQueue.default().finishTransaction(transaction)
                self.paydelegate?.paysuccess()
                queue.finishTransaction(transaction)
            }
        }
        
//         SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    //持久化存储用户购买凭证
    func saveReceipt(receipt:String) {
        
        let fm = FileManager.default
        
        let documnetPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0] as NSString
        
        let dicPath = documnetPath.appendingPathComponent("EACEF35FE363A75A")
        
        if !fm.fileExists(atPath: dicPath) {
            
            do {
             try fm.createDirectory(atPath: dicPath, withIntermediateDirectories: true, attributes: nil)
            }catch {
            }
            
        }
        
        let savedPath = dicPath.appending("/localTransactionReceipt.plist")
        
        if !fm.fileExists(atPath: dicPath) {
        
             let rrr = fm.createFile(atPath: savedPath, contents: nil, attributes: nil)
            if rrr {
                print("创建文件成功")
            }else{
                print("创建文件失败")
            }
        }
        let dict = NSDictionary.init(object: receipt, forKey: "transactionReceipt" as NSCopying)
        let u = dict.write(toFile: savedPath, atomically: true)
        print("写入是否成功 \(u)")
    }
    
    func restore() {
        //恢复购买
                SKPaymentQueue.default().restoreCompletedTransactions()
                SKPaymentQueue.default().add(self)
    }
}
