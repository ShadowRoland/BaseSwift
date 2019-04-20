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

class ChatListViewController: BaseViewController {
    public weak var parentVC: SNSViewController?
    var isTouched = false //视图已经被父视图载入过
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        view.addSubview(tableView)
        constrain(tableView) { $0.edges == inset($0.superview!.edges, 0) }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.groupTableViewBackground
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(0, ChatListCell.Const.headerMargin, 0, 0)
        view.progressMaskColor = tableView.backgroundColor!
        tableView.contentInset = UIEdgeInsets(0, 0, TabBarHeight, 0)
        
        return tableView
    }()
    
    lazy var noDataView: SRLoadDataStateView = {
        let noDataView = SRLoadDataStateView(.empty)
        noDataView.backgroundColor = tableView.backgroundColor
        return noDataView
    }()
    lazy var loadDataFailView: SRLoadDataStateView = {
        let loadDataFailView = SRLoadDataStateView(.fail)
        loadDataFailView.backgroundColor = tableView.backgroundColor
        loadDataFailView.delegate = self
        return loadDataFailView
    }()
    
    lazy var dataArray: [MessageModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        ChatListCell.updateCellHeight()
    }
    
    deinit {
        LogDebug("\(NSStringFromClass(type(of: self))).\(#function)")
        NotifyDefault.remove(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - 业务处理
    
    func loadData(_ progressType: TableLoadData.ProgressType = .none) {
        switch progressType {
        case .clearMask:
            view.showProgress()
        case .opaqueMask:
            view.showProgress(.opaque)
        default:
            break
        }
        
        var params = [:] as ParamDictionary
        params[Param.Key.limit] = TableLoadData.row
        params[Param.Key.offset] = 1000
        httpRequest(.get(.messages), success:
            { [weak self] response in
                guard let strongSelf = self else { return }
                strongSelf.update(response as? JSON)
            }, bfail: { [weak self] (url, response) in
                guard let strongSelf = self else { return }
                if !strongSelf.dataArray.isEmpty { //若当前有数据，则进行弹出提示框的交互
                    strongSelf.update(nil)
                    strongSelf.showToast(strongSelf.logBFail(.get(.messages),
                                                             response: response,
                                                             show: false))
                } else { //当前为空的话则交给列表展示错误信息
                    strongSelf.update(nil, errMsg: strongSelf.logBFail(.get(.messages),
                                                                       response: response,
                                                                       show: false))
                }
            }, fail: { [weak self] (url, error) in
                guard let strongSelf = self else { return }
                if !strongSelf.dataArray.isEmpty { //若当前有数据，则进行弹出toast的交互
                    strongSelf.update(nil)
                    strongSelf.showToast(error.errorDescription)
                } else { //当前为空的话则交给列表展示错误信息
                    strongSelf.update(nil, errMsg: error.errorDescription)
                }
        })
    }
    
    public func update(_ json: JSON?, errMsg: String? = nil) {
        view.dismissProgress(true)
        guard let json = json?[HTTP.Key.Response.data] else {
            if dataArray.count == 0 {
                showLoadDataFailView(errMsg) //加载失败
            }
            return
        }
        
        dataArray = messageModels(json[Param.Key.list])
        guard !dataArray.isEmpty else { //没有数据
            showNoDataView()
            return
        }
        
        tableView.tableHeaderView = nil
        tableView.reloadData()
        DispatchQueue.main.async { [weak self] in //tableView更新完数据后再设置contentOffset
            guard let strongSelf = self else { return }
            strongSelf.tableView.setContentOffset(CGPoint(0, -strongSelf.tableView.contentInset.top),
                                                  animated: true)
        }
    }
    
    func messageModels(_ list: JSON?) -> [MessageModel] {
        if let list = list, let models = list.array?.compactMap({ (JSON) -> MessageModel? in
            if let dictionary = JSON.dictionaryObject {
                return MessageModel(JSON: dictionary)
            }
            return nil
        }) {
            return models
        }
        return []
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
    
    func showNoDataView() {
        noDataView.frame = tableView.bounds
        noDataView.layout()
        tableView.tableHeaderView = noDataView
    }
    
    override func showLoadDataFailView(_ text: String?) {
        loadDataFailView.text = text
        loadDataFailView.frame = tableView.bounds
        loadDataFailView.layout()
        tableView.tableHeaderView = loadDataFailView
    }
    
    //MARK: - 事件响应
    
    override func contentSizeCategoryDidChange() {
        ChatListCell.updateCellHeight()
        tableView.reloadData()
    }
    
    //MARK: - SRLoadDataStateDelegate
    
    override func retryLoadData() {
        loadData(.opaqueMask)
    }
}

//MARK: - UITableViewDelegate, UITableViewDataSource

extension ChatListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return ChatListCell.height()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell =
            tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier) as? ChatListCell
        if cell == nil {
            cell = ChatListCell(style: .default, reuseIdentifier: ReuseIdentifier)
            cell?.initView()
        }
        cell?.message = dataArray[indexPath.row]
        
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
        
        let vc = ChatViewController()
        vc.targetId = dataArray[indexPath.row].userId
        vc.nickname = dataArray[indexPath.row].userName
        vc.conversationType = .ConversationType_PRIVATE
        show(vc)
    }
}
