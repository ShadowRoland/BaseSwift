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
        if sharedInstance == nil {
            sharedInstance = SRShareToolDefaultDelegate()
        }
        return sharedInstance!
    }
    
    private static var sharedInstance: SRShareToolDefaultDelegate?
    
    private override init() {
        super.init()
    }
    
    //var qqDelegate: SRQQDelegate { return SRQQDelegate.shared } /* QQ第三方库文件添加到工程后放开注释 */
    
    //MARK: - Response after click cell
    
    func sms(_ shareTool: SRShareTool) {
        guard MFMessageComposeViewController.canSendText() else {
            SRAlert.showToast("[SR]The device does not support SMS function".srLocalized)
            return
        }
        
        let vc = MFMessageComposeViewController()
        vc.navigationBar.tintColor = NavigationBar.backgroundColor
        vc.body = String(format: "%@ %@ %@", shareTool.option.title ?? "",
                         shareTool.option.description ?? "",
                         shareTool.option.url ?? "")
        vc.messageComposeDelegate = self
        if let top = UIViewController.top {
            vc.title = "[SR]Send message".srLocalized
            top.present(vc, animated: true, completion: nil)
        }
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
            SRCommon.showAlert(message: "请先安装微信！")
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
            previewImageData = UIImagePNGRepresentation(Configs.Resource.defaultImage(.min)!)
        }
        let newsObject =
            QQApiNewsObject(url: URL(string: shareTool.option.url ?? ""),
                                     title: shareTool.option.title ?? "",
                                     description: shareTool.option.description ?? "",
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
            SRCommon.showAlert(message: "请先安装QQ！")
            
        case EQQAPIMESSAGETYPEINVALID, EQQAPIMESSAGECONTENTNULL, EQQAPIMESSAGECONTENTINVALID:
            SRCommon.showAlert(message: "参数有误！")
            
        case EQQAPIAPPNOTREGISTED:
            SRCommon.showAlert(message: "应用未注册，请在腾讯开放平台完成注册！")

        default:
            SRCommon.showAlert(message: "分享失败，错误码：" + String(int: Int(resultCode.rawValue)))
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
            return UIImage.srNamed("sr_link")
        case .tool(.openLinkInSafari):
            return UIImage.srNamed("sr_safari")
        case .tool(.sms):
            return UIImage.srNamed("sr_sms")
        case .tool(.refresh):
            return UIImage.srNamed("sr_refresh")
        case .share(.wechatMoments):
            return UIImage.srNamed("sr_wechat_moments")
        case .share(.wechat):
            return UIImage.srNamed("sr_wechat")
        case .share(.qqZone):
            return UIImage.srNamed("sr_qq_zone")
        case .share(.qq):
            return UIImage.srNamed("sr_qq")
        case .share(.weibo):
            return UIImage.srNamed("sr_weibo")
        case .share(.facebook):
            return UIImage.srNamed("sr_facebook")
        case .share(.twitter):
            return UIImage.srNamed("sr_twitter")
        }
    }
    
    func shareTool(title shareTool: SRShareTool, type: SRShareTool.CellType) -> String? {
        switch type {
        case .tool(.copyLink):
            return "[SR]Copy link".srLocalized
        case .tool(.openLinkInSafari):
            return "[SR]Open link in Safari".srLocalized
        case .tool(.sms):
            return "[SR]Send message".srLocalized
        case .tool(.refresh):
            return "[SR]Refresh".srLocalized
        case .share(.wechatMoments):
            return "[SR]Wechat moments".srLocalized
        case .share(.wechat):
            return "[SR]Wechat".srLocalized
        case .share(.qqZone):
            return "[SR]QQ Zone".srLocalized
        case .share(.qq):
            return "[SR]QQ".srLocalized
        case .share(.weibo):
            return "[SR]Weibo".srLocalized
        case .share(.facebook):
            return "[SR]Facebook".srLocalized
        case .share(.twitter):
            return "[SR]Twitter".srLocalized
        }
    }
    
    func shareTool(didSelect shareTool: SRShareTool, type: SRShareTool.CellType) -> Bool {
        switch type {
        case .tool(.copyLink):
            UIPasteboard.general.string = shareTool.option.url
            SRAlert.showToast("[SR]Link has been copied to clipboard".srLocalized)
            
        case .tool(.openLinkInSafari):
            if let url = shareTool.option.url, let openURL = URL(string: url) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(openURL)
                } else {
                    UIApplication.shared.openURL(openURL)
                }
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
                isEmptyString(accessToken) {
                wbtoken = accessToken
            }
            if let userID = sendMessageToWeiboResponse.authResponse.userID,
                isEmptyString(userID) {
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
    
    func isOnlineResponse(_ response: AnyDictionary!) {
        
    }
}
****************************/
