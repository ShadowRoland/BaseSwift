//
//  ChatListViewController.swift
//  BaseSwift
//
//  Created by Shadow on 20176/1/1.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import SRKit
import Cartography
import SwiftyJSON

class ChatListViewController: BaseTableViewController {
    public weak var parentVC: SNSViewController?
    var isTouched = false //视图已经被父视图载入过
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        ChatListCell.updateCellHeight()
        needRefreshNewHeader = false
        needAddMoreFooter = false
    }
    
    deinit {
        LogDebug("\(NSStringFromClass(type(of: self))).\(#function)")
        NotifyDefault.remove(self)
    }
    
    override func layoutSubviews() {
        if parentVC != nil {
            
        } else {
            super.layoutSubviews()
        }
    }
    
    /*
     * Debug 在IM中注册新用户
     *
     static var timer: Timer?
     static var index: NSInteger = 0
     
     func startLoginTimer() {
     ChatListViewController.index = 0
     ChatListViewController.timer = Timer.scheduledTimer(timeInterval: 5.0,
     target: self,
     selector: #selector(loginUser),
     userInfo: nil,
     repeats: true)
     }
     
     func loginUser() {
     let index = ChatListViewController.index
     guard index < dataArray.count else {
     ChatListViewController.timer?.invalidate()
     ChatListViewController.timer = nil
     return
     }
     
     let model = dataArray[index]
     ChatListViewController.index += 1
     //调试，注册新用户
     let userparams =
     [Param.Key.userId : NonNull.string(model.userId),
     Param.Key.name : NonNull.string(model.userName),
     Param.Key.portraitUri : NonNull.string(model.headPortrait)]
     BF.callBusiness(BF.businessId(.im, Manager.IM.funcId(.login)), userParam)
     }
     */
    
    //MARK: - 事件响应
    
    override func contentSizeCategoryDidChange() {
        ChatListCell.updateCellHeight()
        tableView.reloadData()
    }
    
    //MARK: - BaseTableLoadData
    
    func getDataArray(_ addMore: Bool) {
        getDataArray(addMore, progressType: .none)
    }
    
    func getDataArray(_ addMore: Bool = false,
                      progressType: TableLoadData.ProgressType = .none) {
        switch progressType {
        case .clearMask:
            showProgress()
        case .opaqueMask:
            showProgress(.opaque)
        default:
            break
        }
        
        var params = [:] as ParamDictionary
        params[Param.Key.limit] = TableLoadData.row
        params[Param.Key.offset] = 0
        httpRequest(.get("data/getMessages", params: params), success:{ [weak self] response in
            guard let strongSelf = self else { return }
            if let json = response as? JSON,
                let array = json[HTTP.Key.Response.data][Param.Key.list].array {
                let models = array.compactMap({ (element) -> MessageModel? in
                    if let dictionary = element.dictionaryObject {
                        return MessageModel(JSON: dictionary)
                    } else {
                        return nil
                    }
                })
                strongSelf.httpRespond(success: models, offset: 0)
            } else {
                strongSelf.httpRespond(success: [], offset: 0)
            }
        })
    }
    
    //MARK: - UITableViewDelegate, UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return ChatListCell.height()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell =
            tableView.dequeueReusableCell(withIdentifier: C.reuseIdentifier) as? ChatListCell
        if cell == nil {
            cell = ChatListCell(style: .default, reuseIdentifier: C.reuseIdentifier)
            cell?.initView()
        }
        cell?.message = dataArray[indexPath.row] as? MessageModel
        
        //添加3d touch功能
        if !cell!.isPreviewRegistered && traitCollection.forceTouchCapability == .available,
            let previewingDelegate = parentVC {
            parentVC?.registerForPreviewing(with: previewingDelegate, sourceView: cell!.contentView)
            cell?.isPreviewRegistered = true
        }
        cell?.contentView.tag = indexPath.row
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView,
                   titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Delete".localized
    }
    
    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        dataArray.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard MutexTouch else { return }
        
        let message = dataArray[indexPath.row] as? MessageModel
        let vc = ChatViewController()
        vc.targetId = message?.userId
        vc.nickname = message?.userName
        vc.conversationType = .ConversationType_PRIVATE
        show(vc)
    }
}
