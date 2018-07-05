//
//  FreeIAPViewController.swift
//  iMessageKeyboard
//
//  Created by 杰刘 on 2018/4/3.
//  Copyright © 2018年 刘杰. All rights reserved.
//

import UIKit
import FacebookCore

protocol PayUserActiveDelegate:class {
    func payUserActiveSuccess()
}

class FreeIAPViewController: UIViewController{
    weak var payuserDelefate:PayUserActiveDelegate?
    var iaptype = Bool()
    var payVer = IAPVerification()
    var payHeleper = IAPHelper()
    
    override func loadView() {
        super.loadView()
        self.creatFreeView()
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.edgesForExtendedLayout = UIRectEdge.Element.all
        
        self.view.backgroundColor = UIColor.white
        //订阅
                self.payHeleper = IAPHelper.init()
                self.payHeleper.delegate = self
//        IAPHelper.shareiap.delegate = self
        payVer = IAPVerification.init()
        payVer.delegate = self
        
        
        let button = UIButton.init(type: UIButtonType.custom)
        button.backgroundColor = UIColor.red
        button.addTarget(self, action: #selector(payButton), for: UIControlEvents.touchUpInside)
        button.frame = CGRect.init(x: 100, y: 100, width: 100, height: 100)
        view.addSubview(button)
        
        
        let button2 = UIButton.init(type: UIButtonType.custom)
        button2.backgroundColor = UIColor.yellow
        button2.addTarget(self, action: #selector(restoreButton), for: UIControlEvents.touchUpInside)
        button2.frame = CGRect.init(x: 100, y: 300, width: 100, height: 100)
        view.addSubview(button2)
        
    }
    func creatFreeView() {
        
    }
    
    @objc func closeButton() {
        self.dismiss(animated: true, completion: nil)
    }
    @objc func termsButton() {
        let webVC = WebViewController()
        webVC.url = "https://myspacedata.nyc3.digitaloceanspaces.com/ZombieEmojiPlus/terms.html"
        webVC.titlestring = "Terms"
        self.present(webVC, animated: true, completion: nil)
    }
    @objc func privacyButton() {
        let webVC = WebViewController()
        webVC.url = "https://myspacedata.nyc3.digitaloceanspaces.com/ZombieEmojiPlus/privacy.html"
        webVC.titlestring = "Privacy Policy"
        self.present(webVC, animated: true, completion: nil)
    }
    @objc func payButton()   {
        //facebook  记录
        self.payHeleper.payForProductWithProductID(productID: "mr.emoji.plan.weekplan")
    }
    @objc func restoreButton() {
        self.payHeleper.restore()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
extension FreeIAPViewController:IAPDelegate{
    //MARK:  ==============  订阅的代理
    func paysuccess() {
        payVer.sendFailedIapFiles()
    }
    
    func payError() {
    }
    
    func payrestoreError() {
    }
    func payrestoresuccess() {
        payVer.sendFailedIapFiles()
    }
}
extension FreeIAPViewController:PayVerificationDeleage{
    //    MARK:验证 消息
    func payVerificationSuccess() {
        if self.iaptype == true {
            let rootVC = UIApplication.shared.delegate as! AppDelegate
            let rootrVC = MainViewController()
            let nvc = UINavigationController.init(rootViewController: rootrVC)
            rootVC.window?.rootViewController = nvc
        }else{
            self.dismiss(animated: true, completion: nil)
        }
        
    }
    func payVerificationError() {
        print("验证过期请重新购买")
    }
    
}
