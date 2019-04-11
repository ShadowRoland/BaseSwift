//
//  MainMenuViewController.swift
//  BaseSwift
//
//  Created by Gary on 2017/2/25.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit
import Cartography
import SlideMenuControllerSwift

class MainMenuViewController: BaseViewController {
    public weak var aggregationVC: AggregationViewController!
    public weak var leftMenuVC: LeftMenuViewController!
    
    @IBOutlet weak var childBackgroundView: UIView!
    
    weak var currentChildVC: UIViewController!
    var latestVC: NewsListViewController!
    var hottestVC: HottestViewController!
    var jokersVC: NewsListViewController!
    var videosVC: NewsListViewController!
    var picturesVC: NewsListViewController!
    var favoritesVC: NewsListViewController!
    
    var mainConstraintGroup = ConstraintGroup()
    var secondaryConstraintGroup = ConstraintGroup()
    var yellowConstraintGroup = ConstraintGroup()
    var moreConstraintGroup = ConstraintGroup()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        defaultNavigationBar()
        pageBackGestureStyle = .none
        Common.rootVC = self
        NotifyDefault.add(self,
                          selector: #selector(newAction(_:)),
                          name: Notification.Name.Base.newAction)
        initView()
        
        addChild(latestVC)
        childBackgroundView.addSubview(latestVC.view)
        currentChildVC = latestVC
        title = "Latest".localized
        latestVC.backToTopButtonBottomConstraint.constant = 0
        latestVC.loadData(.new, progressType: .clearMask)
        
        if UserStandard[USKey.showAdvertisingGuide] != nil {
            UserStandard[USKey.showAdvertisingGuide] = nil
            stateMachine.append(Event.Option.showAdvertisingGuard.rawValue)
        }
        
        //查询当前指令而执行的操作，加入状态机
        if let option = Event.option(Common.currentActionParams?[ParamKey.action]),
            .showProfile == option || .showSetting == option {
            DispatchQueue.main.async { [weak self] in
                self?.stateMachine.append(option: option)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.isNavigationBarHidden = currentChildVC === hottestVC
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - 视图初始化
    
    struct Const {
        static let sendChildVC = "sendChildVC"
        static let sendNewsListVC = "sendNewsListVC"
    }
    
    func initView() {
        setNavigationBarButtonItems()
        
        latestVC =
            NewsMainViewController.createNewsListVC(ChannelModel(id: String(int: 0)))
        latestVC.parentVC = self
        latestVC.delegate = self
        
        hottestVC =
            Common.viewController("HottestViewController",
                                  storyboard: "Aggregation") as? HottestViewController
        hottestVC.parentVC = self
        
        jokersVC =
            NewsMainViewController.createNewsListVC(ChannelModel(id: String(int: 1)))
        jokersVC.parentVC = self
        jokersVC.delegate = self
        
        videosVC =
            NewsMainViewController.createNewsListVC(ChannelModel(id: String(int: 2)))
        videosVC.parentVC = self
        videosVC.delegate = self
        
        picturesVC =
            NewsMainViewController.createNewsListVC(ChannelModel(id: String(int: 3)))
        picturesVC.parentVC = self
        picturesVC.delegate = self
        
        favoritesVC =
            NewsMainViewController.createNewsListVC(ChannelModel(id: String(int: 4)))
        favoritesVC.parentVC = self
        favoritesVC.delegate = self
    }
    
    func setNavigationBarButtonItems() {
        var setting = NavigartionBar.buttonFullSetting
        setting[.style] = NavigartionBar.ButtonItemStyle.image
        setting[.image] = UIImage(named: "list")
        navBarLeftButtonSettings = [setting]
        
        setting[.style] = NavigartionBar.ButtonItemStyle.image
        setting[.image] = UIImage(named: "search_white")
        navBarRightButtonSettings = [setting]
    }
    
    //添加约束，可以比较方便地进行横竖屏的屏幕适配
    func updateChildViewFrame() {
        if currentChildVC === hottestVC {
            currentChildVC.view.frame = CGRect(0, 0, ScreenWidth(), ScreenHeight())
        } else {
            currentChildVC.view.frame =
                CGRect(0,
                       topLayoutGuide.length,
                       ScreenWidth(),
                       ScreenHeight() - topLayoutGuide.length)
        }
    }
    
    //MARK: - 业务处理
    
    override func performViewDidLoad() {
        DispatchQueue.main.async { [weak self] in
            self?.updateChildViewFrame()
        }
    }
    
    func bringChildVCFront(_ childVC: UIViewController) {
        guard childVC != currentChildVC else {
            return
        }
        
        currentChildVC?.view.isUserInteractionEnabled = false
        addChild(childVC)
        transition(from: currentChildVC!,
                   to: childVC,
                   duration: 0,
                   options: UIView.AnimationOptions(rawValue: 0),
                   animations: nil,
                   completion:
            { [weak self] (finished) in
                guard finished, self != nil else {
                    childVC.removeFromParent()
                    self?.currentChildVC?.view.isUserInteractionEnabled = true
                    return
                }
                
                childVC.didMove(toParent: self)
                childVC.view.isUserInteractionEnabled = true
                self?.currentChildVC?.willMove(toParent: self)
                self?.currentChildVC?.removeFromParent()
                self?.currentChildVC = childVC
                self?.childBackgroundView.addSubview((self?.currentChildVC.view)!)
                self?.updateChildViewFrame()
                if self?.currentChildVC === self?.hottestVC {
                    self?.title = "Hottest".localized
                    self?.navigationController?.isNavigationBarHidden = true
                    if let vc = self?.hottestVC.currentNewsListVC, !vc.isTouched {
                        vc.backToTopButtonBottomConstraint.constant = 0
                        vc.loadData(.new, progressType: .clearMask)
                    }
                } else if self?.currentChildVC === self?.latestVC {
                    self?.navigationController?.isNavigationBarHidden = false
                    self?.title = "Latest".localized
                    if !(self?.latestVC.isTouched)! {
                        self?.latestVC.backToTopButtonBottomConstraint.constant = 0
                        self?.latestVC.loadData(.new, progressType: .clearMask)
                    }
                } else if self?.currentChildVC === self?.jokersVC {
                    self?.navigationController?.isNavigationBarHidden = false
                    self?.title = "Jokers".localized
                    if !(self?.jokersVC.isTouched)! {
                        self?.jokersVC.backToTopButtonBottomConstraint.constant = 0
                        self?.jokersVC.loadData(.new, progressType: .clearMask)
                    }
                } else  if self?.currentChildVC === self?.videosVC {
                    self?.navigationController?.isNavigationBarHidden = false
                    self?.title = "Videos".localized
                    if !(self?.videosVC.isTouched)! {
                        self?.videosVC.backToTopButtonBottomConstraint.constant = 0
                        self?.videosVC.loadData(.new, progressType: .clearMask)
                    }
                } else if self?.currentChildVC === self?.picturesVC {
                    self?.navigationController?.isNavigationBarHidden = false
                    self?.title = "Pictures".localized
                    if !(self?.picturesVC.isTouched)! {
                        self?.picturesVC.backToTopButtonBottomConstraint.constant = 0
                        self?.picturesVC.loadData(.new, progressType: .clearMask)
                    }
                } else if self?.currentChildVC === self?.favoritesVC {
                    self?.navigationController?.isNavigationBarHidden = false
                    self?.title = "Favorites".localized
                    if !(self?.favoritesVC.isTouched)! {
                        self?.favoritesVC.backToTopButtonBottomConstraint.constant = 0
                        self?.favoritesVC.loadData(.new, progressType: .clearMask)
                    }
                }
        })
    }
    
    func presentLoginVC(_ params: ParamDictionary? = nil) {
        let vc = Common.viewController("LoginViewController", storyboard: "Profile") as! LoginViewController
        if let params = params {
            vc.params = params
        }
        present(SRModalViewController.standard(vc), animated: true, completion: nil)
    }
    
    func sendNewsListVC(_ sendChildVC: String?,
                        sendNewsListVC: String?) ->NewsListViewController? {
        guard let sendChildVC = sendChildVC, let sendNewsListVC = sendNewsListVC else {
            return nil
        }
        
        if sendChildVC == String(pointer: hottestVC) {
            return hottestVC.newsListVC(sendNewsListVC)
        }
        
        if sendChildVC == String(pointer: latestVC) {
            return latestVC
        } else if sendChildVC == String(pointer: jokersVC) {
            return jokersVC
        } else if sendChildVC == String(pointer: videosVC) {
            return videosVC
        } else if sendChildVC == String(pointer: picturesVC) {
            return picturesVC
        } else if sendChildVC == String(pointer: favoritesVC) {
            return favoritesVC
        } else {
            return nil
        }
    }
    
    //MARK: - 事件响应
    
    override func clickNavigationBarLeftButton(_ button: UIButton) {
        guard Common.mutexTouch() else { return }
        aggregationVC.openLeft()
    }
    
    override func clickNavigationBarRightButton(_ button: UIButton) {
        guard Common.mutexTouch() else { return }
        show("NewsSearchViewController", storyboard: "News")
    }
    
    //在程序运行中收到指令，基本都可以通过走状态机实现
    @objc func newAction(_ notification: Notification) {
        guard let option = Event.option(Common.currentActionParams?[ParamKey.action]) else {
            return
        }
        
        switch option {
        case .showProfile, .showSetting:
            stateMachine.append(option: option)
            
        default:
            break
        }
    }
    
    //MARK: - SRStateMachineDelegate
    
    override func stateMachine(_ stateMachine: SRStateMachine, didFire event: Int) {
        guard let option = Event.Option(rawValue: event) else {
            return
        }
        
        switch option {
        case .openWebpage:
            if aggregationVC.isLeftOpen() {
                aggregationVC.closeLeft()
            }
            super.stateMachine(stateMachine, didFire: event)
            
        case .showAdvertisingGuard:
            publicBusinessComponent.showAdvertisingGuard()
            
        case .showAdvertising:
            publicBusinessComponent.showAdvertising()
            
        case .showProfile:
            if aggregationVC.isLeftOpen() {
                aggregationVC.closeLeft()
            }
            let viewControllers = navigationController!.viewControllers
            let profileVCs = viewControllers.filter { $0.isKind(of: ProfileViewController.self) }
            if viewControllers.last!.isKind(of: ProfileViewController.self) { //当前页面是Profile页面
                Common.clearActionParams(option: option)
                stateMachine.end(event)
            } else if !profileVCs.isEmpty { //Profile页面在当前页面之前
                Common.clearActionParams(option: option)
                stateMachine.end(event)
                Common.clearPops()
                Common.clearModals(viewController: profileVCs.last!)
                popBack(to: profileVCs.last!)
            } else { //视图栈中没有Profile页面，退出到主页，再push新的Profile页面入栈
                Common.clearPops()
                Common.clearModals(viewController: self)
                popBack(to: self, animated: false)
                NotifyDefault.add(self,
                                  selector: .didEndStateMachineEvent,
                                  name: Notification.Name.Base.didEndStateMachineEvent)
                DispatchQueue.main.async {
                    let params = [ParamKey.sender : String(pointer: self),
                                  ParamKey.event : event] as ParamDictionary
                    //若是非登录状态，弹出登录页面，因为查看个人信息需要先登录
                    if !Common.isLogin() {
                        self.presentLoginVC(params)
                    } else { //push新的Profile页面入栈
                        self.show("ProfileViewController",
                                  storyboard: "Profile",
                                  params: params)
                    }
                }
            }
            
        case .showSetting:
            if aggregationVC.isLeftOpen() {
                aggregationVC.closeLeft()
            }
            let viewControllers = navigationController!.viewControllers
            let settingVCs = viewControllers.filter { $0 is SettingViewController }
            if viewControllers.last! is SettingViewController { //当前页面是Setting页面
                Common.clearActionParams(option: option)
                stateMachine.end(event)
            } else if !settingVCs.isEmpty { //Setting页面在当前页面之前
                Common.clearActionParams(option: option)
                stateMachine.end(event)
                Common.clearPops()
                Common.clearModals(viewController: settingVCs.last!)
                popBack(to: settingVCs.last!)
            } else { //视图栈中没有Setting页面，退出到主页，再push新的Setting页面入栈
                Common.clearPops()
                Common.clearModals(viewController: self)
                popBack(to: self, animated: false)
                NotifyDefault.add(self,
                                  selector: .didEndStateMachineEvent,
                                  name: Notification.Name.Base.didEndStateMachineEvent)
                DispatchQueue.main.async {
                    self.show("SettingViewController", storyboard: "Profile",
                              params: [ParamKey.sender : String(pointer: self),
                                       ParamKey.event : event])
                }
            }
            
        default:
            super.stateMachine(stateMachine, didFire: event)
        }
    }
    
    override func stateMachine(_ stateMachine: SRStateMachine, didEnd event: Int) {
        super.stateMachine(stateMachine, didEnd: event)
        
        if Event.Option.showProfile.rawValue == event
            || Event.Option.showSetting.rawValue == event {
            NotifyDefault.remove(self, name: Notification.Name.Base.didEndStateMachineEvent)
        }
    }
}

//MARK: - NewsListDelegate

extension MainMenuViewController: NewsListDelegate {
    //使用第三方新闻客户端的请求参数
    func getNewsList(_ loadType: TableLoadData.Page?, sendVC: NewsListViewController) {
        var params = sendVC.params
        let time = CLongLong(Date().timeIntervalSince1970 * 1000)
        params["t"] = String(longLong: time)
        params["_"] = String(longLong: time + 2)
        params["show_num"] = "10"
        params["act"] = loadType == .more ? "more" : "new"
        let offset = loadType == .more ? sendVC.currentOffset + 1 : 0
        params["page"] = String(int: offset + 1)
        var sendChildVC: String?
        if let parentVC = sendVC.parentVC {
            sendChildVC = String(pointer: parentVC)
        }
        let sendNewsListVC = String(pointer: sendVC)
        httpRequest(.get(.sinaNewsList),
                    params,
                    url: "http://interface.sina.cn",
                    success:
            { response in
                guard let vc = self.sendNewsListVC(sendChildVC,
                                                   sendNewsListVC: sendNewsListVC) else {
                                                    return
                }
                
                if loadType == .more {
                    let offset = params[ParamKey.offset] as! Int
                    if offset == vc.currentOffset + 1 { //只刷新新的一页数据，旧的或者更新的不刷
                        vc.updateMore(NonNull.dictionary(response))
                    }
                } else {
                    vc.updateNew(NonNull.dictionary(response))
                }
        }, bfail: { response in
            guard let vc = self.sendNewsListVC(sendChildVC,
                                               sendNewsListVC: sendNewsListVC) else {
                                                return
            }
            
            if loadType == .more {
                let offset = params[ParamKey.offset] as! Int
                if offset == vc.currentOffset + 1 {
                    return
                }
            } else {
                if !vc.dataArray.isEmpty { //已经有数据，保留原数据，显示提示框
                    vc.updateNew(nil)
                } else { //当前为空的话则交给列表展示错误信息
                    vc.updateNew(nil, errMsg: self.logBFail(.get(.sinaNewsList),
                                                            response: response,
                                                            show: false))
                }
            }
        }, fail: { error in
            guard let vc = self.sendNewsListVC(sendChildVC,
                                               sendNewsListVC: sendNewsListVC) else {
                                                return
            }
            
            if loadType == .more {
                let offset = params[ParamKey.offset] as! Int
                if offset == vc.currentOffset + 1 {
                    if !vc.dataArray.isEmpty { //若当前有数据，则进行弹出toast的交互，列表恢复刷新状态
                        vc.updateMore(nil)
                    } else { //当前为空的话则交给列表展示错误信息，一般在加载更多的时候是不会走到这个逻辑的，因为空数据的时候上拉加载更多是被禁止的
                        vc.updateMore(nil, errMsg: error.errorDescription)
                    }
                }
            } else {
                if !vc.dataArray.isEmpty { //若当前有数据，则进行弹出toast的交互
                    vc.updateNew(nil)
                } else { //当前为空的话则交给列表展示错误信息
                    vc.updateNew(nil, errMsg: error.errorDescription)
                }
            }
        })
    }
    
    func newsListVC(_ newsListVC: NewsListViewController, didSelect model: SinaNewsModel) {
        showWebpage(URL(string: NonNull.string(model.link))!, title: "News".localized)
    }
}

//MARK: - SlideMenuControllerDelegate

extension MainMenuViewController: SlideMenuControllerDelegate {
    func leftWillOpen() {
        //print("SlideMenuControllerDelegate: leftWillOpen")
    }
    
    func leftDidOpen() {
        //print("SlideMenuControllerDelegate: leftDidOpen")
    }
    
    func leftWillClose() {
        //print("SlideMenuControllerDelegate: leftWillClose")
    }
    
    func leftDidClose() {
        //print("SlideMenuControllerDelegate: leftDidClose")
    }
    
    func rightWillOpen() {
        //print("SlideMenuControllerDelegate: rightWillOpen")
    }
    
    func rightDidOpen() {
        //print("SlideMenuControllerDelegate: rightDidOpen")
    }
    
    func rightWillClose() {
        //print("SlideMenuControllerDelegate: rightWillClose")
    }
    
    func rightDidClose() {
        //print("SlideMenuControllerDelegate: rightDidClose")
    }
}
