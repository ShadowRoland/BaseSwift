//
//  SRShareToolDefaultDelegate.swift
//  BaseSwift
//
//  Created by Gary on 2017/5/12.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit
import MessageUI

class SRShareToolDefaultDelegate: NSObject {
    class var shared: SRShareToolDefaultDelegate {
        return sharedInstance
    }
    
    private static var sharedInstance = SRShareToolDefaultDelegate()
    
    private override init() {
        super.init()
    }
    
    //var qqDelegate: SRQQDelegate { return SRQQDelegate.shared } /* QQ第三方库文件添加到工程后放开注释 */
    
    //MARK: - Response after click cell
    
    func sms(_ shareTool: SRShareTool) {
        guard MFMessageComposeViewController.canSendText() else {
            Common.showToast("The device does not support SMS function".localized)
            return
        }
        
        let vc = MFMessageComposeViewController()
        vc.navigationBar.tintColor = NavigartionBar.backgroundColor
        vc.body = String(format: "%@ %@ %@", shareTool.option.title ?? EmptyString,
                         shareTool.option.description ?? EmptyString,
                         shareTool.option.url ?? EmptyString)
        vc.messageComposeDelegate = self
        let lastVC = Common.rootVC?.navigationController?.topViewController!
        lastVC?.present(vc, animated: true, completion: nil)
        vc.title = "Send message".localized
    }
    
    //MARK: Call third share api
    
    func shareInWechatMoments(_ shareTool: SRShareTool) {
        //shareWithWechat(shareTool, scene: WXSceneTimeline) /* 微信第三方库文件添加到工程后放开注释 */
    }

    func shareInWechat(_ shareTool: SRShareTool) {
        //shareWithWechat(shareTool, scene: WXSceneSession) /* 微信第三方库文件添加到工程后放开注释 */
    }
    
    /* 微信第三方库文件添加到工程后放开注释
    func shareWithWechat(_ shareTool: SRShareTool, scene: WXScene) {
        guard WXApi.isWXAppInstalled() && WXApi.isWXAppSupport() else {
            Common.showAlert(message: "请先安装微信！")
            return
        }
        
        let message = WXMediaMessage()
        if let title = shareTool.option.title {
            message.title = title
        }
        if let description = shareTool.option.description {
            message.description = description
        }
        if let image = shareTool.option.image {
            message.setThumbImage(image)
        }
        if let url = shareTool.option.url {
            let mediaObject = WXWebpageObject()
            mediaObject.webpageUrl = url
            message.mediaObject = mediaObject
        }
        
        let req = SendMessageToWXReq()
        req.bText = false
        req.message = message
        req.scene = Int32(scene.rawValue)
        
        WXApi.send(req)
    }
    ****************************/
    
    func shareInQQZone(_ shareTool: SRShareTool) {
        shareWithQQ(shareTool, sendToZone: true)
    }
    
    func shareInQQ(_ shareTool: SRShareTool) {
        shareWithQQ(shareTool)
    }
    
    func shareWithQQ(_ shareTool: SRShareTool, sendToZone: Bool = false) {
        /* QQ第三方库文件添加到工程后放开注释
        let previewImageData: Data!
        if let image = shareTool.option.image {
            previewImageData = UIImagePNGRepresentation(image)
        } else {
            previewImageData = UIImagePNGRepresentation(Resource.defaultImage(.min)!)
        }
        let newsObject =
            QQApiNewsObject(url: URL(string: shareTool.option.url ?? EmptyString),
                                     title: shareTool.option.title ?? EmptyString,
                                     description: shareTool.option.description ?? EmptyString,
                                     previewImageData: previewImageData,
                                     targetContentType: QQApiURLTargetTypeNews)
        
        let resultCode: QQApiSendResultCode!
        if sendToZone {
            resultCode = QQApiInterface.send(SendMessageToQQReq(content: newsObject))
        } else {
            resultCode = QQApiInterface.sendReq(toQZone: SendMessageToQQReq(content: newsObject))
        }
        switch resultCode {
        case EQQAPISENDSUCESS, EQQAPIQQNOTSUPPORTAPI_WITH_ERRORSHOW:
            break
            
        case EQQAPIQQNOTINSTALLED, EQQAPIQQNOTSUPPORTAPI:
            Common.showAlert(message: "请先安装QQ！")
            
        case EQQAPIMESSAGETYPEINVALID, EQQAPIMESSAGECONTENTNULL, EQQAPIMESSAGECONTENTINVALID:
            Common.showAlert(message: "参数有误！")
            
        case EQQAPIAPPNOTREGISTED:
            Common.showAlert(message: "应用未注册，请在腾讯开放平台完成注册！")

        default:
            Common.showAlert(message: "分享失败，错误码：" + String(int: Int(resultCode.rawValue)))
        }
        ****************************/
    }
    
    var wbtoken: String?
    var wbCurrentUserID: String?
    var wbRefreshToken: String?
    
    func shareInWeibo(_ shareTool: SRShareTool) {
        /* 微博第三方库文件添加到工程后放开注释
        let authRequest = WBAuthorizeRequest()
        authRequest.redirectURI = SinaRedirectURI
        authRequest.scope = "all"
        
        let webpage = WBWebpageObject()
        webpage.objectID = "identifier1"
        if let title = shareTool.option.title {
            webpage.title = title
        }
        if let description = shareTool.option.description {
            webpage.description = description
        }
        if let image = shareTool.option.image {
            webpage.thumbnailData = UIImagePNGRepresentation(image)
        }
        if let url = shareTool.option.url {
            webpage.webpageUrl = url
        }

        let message = WBMessageObject()
        message.mediaObject = webpage
        let request =
            WBSendMessageToWeiboRequest.request(withMessage: message,
                                                authInfo: authRequest,
                                                access_token: wbtoken)
                as! WBSendMessageToWeiboRequest
        request.userInfo = [:]
        WeiboSDK.send(request)
        ****************************/
    }
    
    func shareInFacebook() {
        
    }
    
    func shareInTwitter() {
        
    }
}

//MARK: - SRShareToolDelegate

extension SRShareToolDefaultDelegate: SRShareToolDelegate {
    func shareTool(types shareTool: SRShareTool) -> [SRShareTool.CellType]? {
        return SRShareTool.defaultTypes
    }
    
    func shareTool(logo shareTool: SRShareTool, type: SRShareTool.CellType) -> UIImage? {
        switch type {
        case .tool(.copyLink):
            return UIImage(named: "link")
        case .tool(.openLinkInSafari):
            return UIImage(named: "safari")
        case .tool(.sms):
            return UIImage(named: "sms")
        case .tool(.refresh):
            return UIImage(named: "refresh")
        case .share(.wechatMoments):
            return UIImage(named: "wechat_moments")
        case .share(.wechat):
            return UIImage(named: "wechat")
        case .share(.qqZone):
            return UIImage(named: "qq_zone")
        case .share(.qq):
            return UIImage(named: "qq")
        case .share(.weibo):
            return UIImage(named: "weibo")
        case .share(.facebook):
            return UIImage(named: "facebook")
        case .share(.twitter):
            return UIImage(named: "twitter")
        }
    }
    
    func shareTool(title shareTool: SRShareTool, type: SRShareTool.CellType) -> String? {
        switch type {
        case .tool(.copyLink):
            return "Copy link".localized
        case .tool(.openLinkInSafari):
            return "Open link in Safari".localized
        case .tool(.sms):
            return "Send message".localized
        case .tool(.refresh):
            return "Refresh".localized
        case .share(.wechatMoments):
            return "Wechat moments".localized
        case .share(.wechat):
            return "Wechat".localized
        case .share(.qqZone):
            return "QQ Zone".localized
        case .share(.qq):
            return "QQ".localized
        case .share(.weibo):
            return "Weibo".localized
        case .share(.facebook):
            return "Facebook".localized
        case .share(.twitter):
            return "Twitter".localized
        }
    }
    
    func shareTool(didSelect shareTool: SRShareTool, type: SRShareTool.CellType) -> Bool {
        switch type {
        case .tool(.copyLink):
            UIPasteboard.general.string = shareTool.option.url
            Common.showToast("Link has been copied to clipboard".localized)
            
        case .tool(.openLinkInSafari):
            if let url = shareTool.option.url, let openURL = URL(string: url) {
                UIApplication.shared.openURL(openURL)
            }
            
        case .tool(.sms):
            sms(shareTool)
            
        case .tool(.refresh):
            return true
            
        case .share(.wechatMoments):
            shareInWechatMoments(shareTool)
            
        case .share(.wechat):
            shareInWechat(shareTool)
            
        case .share(.qqZone):
            shareInQQZone(shareTool)
            
        case .share(.qq):
            shareInQQ(shareTool)
            
        case .share(.weibo):
            shareInWeibo(shareTool)
            
        case .share(.facebook):
            shareInFacebook()
            
        case .share(.twitter):
            shareInTwitter()
        }
        
        return true
    }
}

//MARK: - MFMessageComposeViewControllerDelegate

extension SRShareToolDefaultDelegate: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                      didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }
}

//MARK: - WXApiDelegate

/* 微信第三方库文件添加到工程后放开注释
extension SRShareToolDefaultDelegate: WXApiDelegate {
    func onReq(_ req: BaseReq!) {
        
    }
    
    func onResp(_ resp: BaseResp!) {
        
    }
}
 ****************************/

//MARK: - WeiboSDKDelegate

/* 微博第三方库文件添加到工程后放开注释
extension SRShareToolDefaultDelegate: WeiboSDKDelegate {
    func didReceiveWeiboRequest(_ request: WBBaseRequest!) {
        
    }
    
    func didReceiveWeiboResponse(_ response: WBBaseResponse!) {
        if response.isKind(of: WBSendMessageToWeiboResponse.self) {
            let sendMessageToWeiboResponse = response as! WBSendMessageToWeiboResponse
            if let accessToken = sendMessageToWeiboResponse.authResponse.accessToken,
                !Common.isEmptyString(accessToken) {
                wbtoken = accessToken
            }
            if let userID = sendMessageToWeiboResponse.authResponse.userID,
                !Common.isEmptyString(userID) {
                wbCurrentUserID = userID
            }
        } else if response.isKind(of: WBAuthorizeResponse.self) {
            let authorizeResponse = response as! WBAuthorizeResponse
            wbtoken = authorizeResponse.accessToken
            wbCurrentUserID = authorizeResponse.userID
            wbRefreshToken = authorizeResponse.refreshToken
        }
    }
}
****************************/

/* QQ第三方库文件添加到工程后放开注释
//由于QQ分享delegate和微信分享delegate的方法名重名了，而QQ分享delegate不重要，但是Swift的语法又设定了回调函数
//QQApiInterface.handleOpen(url, delegate: delegate!)
//的第二个参数不能为空，必须存在，所以将QQApiInterfaceDelegate单独抽出来
class SRQQDelegate: NSObject, QQApiInterfaceDelegate {
    class var shared: SRQQDelegate {
 
            return sharedInstance!
        }
    }
    
    private static let sharedInstance = SRQQDelegate()
 
    private override init() {
        super.init()
    }

    func onReq(_ req: QQBaseReq!) {
        
    }
    
    func onResp(_ resp: QQBaseResp!) {
        
    }
    
    func isOnlineResponse(_ response: [AnyHashable : Any]!) {
        
    }
}
****************************/
