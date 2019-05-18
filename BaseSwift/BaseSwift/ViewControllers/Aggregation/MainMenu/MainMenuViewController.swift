//
//  MainMenuViewController.swift
//  BaseSwift
//
//  Created by Gary on 2017/2/25.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import SRKit
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
        setDefaultNavigationBar()
        pageBackGestureStyle = .none
        Common.rootVC = self
        initView()
        
        addChild(latestVC)
        childBackgroundView.addSubview(latestVC.view)
        currentChildVC = latestVC
        title = "Latest".localized
        latestVC.backToTopButtonBottomConstraint.constant = 0
        latestVC.loadData(progressType: .clearMask)
        
        if UserStandard[UDKey.showAdvertisingGuide] != nil {
            UserStandard[UDKey.showAdvertisingGuide] = nil
            stateMachine.append(Event(.showAdvertisingGuard))
        }
        
        //查询当前指令而执行的操作，加入状态机
        if let event = Common.events.first(where: { $0.option == .showProfile || $0.option == .showSetting }) {
            Common.removeEvent(event)
            DispatchQueue.main.async { [weak self] in
                self?.stateMachine.append(event)
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
            UIViewController.viewController("HottestViewController",
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
        var setting = NavigationBar.buttonFullSetting
        setting[.style] = NavigationBar.ButtonItemStyle.image
        setting[.image] = UIImage(named: "list")
        navBarLeftButtonSettings = [setting]
        
        setting[.style] = NavigationBar.ButtonItemStyle.image
        setting[.image] = UIImage(named: "search_white")
        navBarRightButtonSettings = [setting]
    }
    
    //添加约束，可以比较方便地进行横竖屏的屏幕适配
    func updateChildViewFrame() {
        if currentChildVC === hottestVC {
            currentChildVC.view.frame = CGRect(0, 0, ScreenWidth, ScreenHeight)
        } else {
            currentChildVC.view.frame =
                CGRect(0,
                       topLayoutGuide.length,
                       ScreenWidth,
                       ScreenHeight - topLayoutGuide.length)
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
                guard finished, let strongSelf = self else {
                    childVC.removeFromParent()
                    self?.currentChildVC?.view.isUserInteractionEnabled = true
                    return
                }
                
                childVC.didMove(toParent: self)
                childVC.view.isUserInteractionEnabled = true
                strongSelf.currentChildVC?.willMove(toParent: self)
                strongSelf.currentChildVC?.removeFromParent()
                strongSelf.currentChildVC = childVC
                strongSelf.childBackgroundView.addSubview((strongSelf.currentChildVC.view)!)
                strongSelf.updateChildViewFrame()
                if strongSelf.currentChildVC === strongSelf.hottestVC {
                    strongSelf.title = "Hottest".localized
                    strongSelf.navigationController?.isNavigationBarHidden = true
                    if let vc = strongSelf.hottestVC.currentNewsListVC, !vc.isTouched {
                        vc.backToTopButtonBottomConstraint.constant = 0
                        vc.loadData(progressType: .clearMask)
                    }
                } else if strongSelf.currentChildVC === strongSelf.latestVC {
                    strongSelf.navigationController?.isNavigationBarHidden = false
                    strongSelf.title = "Latest".localized
                    if !strongSelf.latestVC.isTouched {
                        strongSelf.latestVC.backToTopButtonBottomConstraint.constant = 0
                        strongSelf.latestVC.loadData(progressType: .clearMask)
                    }
                } else if strongSelf.currentChildVC === strongSelf.jokersVC {
                    strongSelf.navigationController?.isNavigationBarHidden = false
                    strongSelf.title = "Jokers".localized
                    if !strongSelf.jokersVC.isTouched {
                        strongSelf.jokersVC.backToTopButtonBottomConstraint.constant = 0
                        strongSelf.jokersVC.loadData(progressType: .clearMask)
                    }
                } else  if strongSelf.currentChildVC === strongSelf.videosVC {
                    strongSelf.navigationController?.isNavigationBarHidden = false
                    strongSelf.title = "Videos".localized
                    if !strongSelf.videosVC.isTouched {
                        strongSelf.videosVC.backToTopButtonBottomConstraint.constant = 0
                        strongSelf.videosVC.loadData(progressType: .clearMask)
                    }
                } else if strongSelf.currentChildVC === strongSelf.picturesVC {
                    strongSelf.navigationController?.isNavigationBarHidden = false
                    strongSelf.title = "Pictures".localized
                    if !strongSelf.picturesVC.isTouched {
                        strongSelf.picturesVC.backToTopButtonBottomConstraint.constant = 0
                        strongSelf.picturesVC.loadData(progressType: .clearMask)
                    }
                } else if strongSelf.currentChildVC === strongSelf.favoritesVC {
                    strongSelf.navigationController?.isNavigationBarHidden = false
                    strongSelf.title = "Favorites".localized
                    if !strongSelf.favoritesVC.isTouched {
                        strongSelf.favoritesVC.backToTopButtonBottomConstraint.constant = 0
                        strongSelf.favoritesVC.loadData(progressType: .clearMask)
                    }
                }
        })
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
        guard MutexTouch else { return }
        aggregationVC.openLeft()
    }
    
    override func clickNavigationBarRightButton(_ button: UIButton) {
        guard MutexTouch else { return }
        show("NewsSearchViewController", storyboard: "News")
    }
    
    //MARK: - SRStateMachineDelegate
    
    override func stateMachine(_ stateMachine: SRStateMachine, didFire event: Event) {
        switch event.option {
        case .openWebpage:
            if aggregationVC.isLeftOpen() {
                aggregationVC.closeLeft()
            }
            super.stateMachine(stateMachine, didFire: event)
            
        case .showAdvertisingGuard:
            publicBusinessComponent.showAdvertisingGuard()
            
        case .showAdvertising:
            publicBusinessComponent.showAdvertising()
            
        default:
            super.stateMachine(stateMachine, didFire: event)
        }
    }
}

//MARK: - NewsListDelegate

extension MainMenuViewController: NewsListDelegate {
    //使用第三方新闻客户端的请求参数
    func getNewsList(_ isNextPage: Bool, sendVC: NewsListViewController) {
        var params = sendVC.params
        let time = CLongLong(Date().timeIntervalSince1970 * 1000)
        params["t"] = String(longLong: time)
        params["_"] = String(longLong: time + 2)
        params["show_num"] = "10"
        params["act"] = isNextPage ? "more" : "new"
        let offset = isNextPage ? sendVC.currentOffset + 1 : 0
        params["page"] = String(int: offset + 1)
        var sendChildVC: String?
        if let parentVC = sendVC.parentVC {
            sendChildVC = String(pointer: parentVC)
        }
        let sendNewsListVC = String(pointer: sendVC)
        httpRequest(.get("http://interface.sina.cn/ent/feed.d.json", params), success: { [weak self] response in
            guard let strongSelf = self,
                let vc = strongSelf.sendNewsListVC(sendChildVC,
                                                   sendNewsListVC: sendNewsListVC) else {
                                                    return
            }
            
            if isNextPage {
                let offset = params[Param.Key.offset] as! Int
                if offset == vc.currentOffset + 1 { //只刷新新的一页数据，旧的或者更新的不刷
                    vc.updateMore(NonNull.dictionary(response))
                }
            } else {
                vc.updateNew(NonNull.dictionary(response))
            }
            }, bfail: { [weak self] (method, response) in
                guard let strongSelf = self,
                    let vc = strongSelf.sendNewsListVC(sendChildVC,
                                                       sendNewsListVC: sendNewsListVC) else {
                                                        return
                }
                
                if isNextPage {
                    let offset = params[Param.Key.offset] as! Int
                    if offset == vc.currentOffset + 1 {
                        return
                    }
                } else {
                    if !vc.dataArray.isEmpty { //已经有数据，保留原数据，显示提示框
                        vc.updateNew(nil)
                    } else { //当前为空的话则交给列表展示错误信息
                        vc.updateNew(nil, errMsg: strongSelf.logBFail(method,
                                                                      response: response,
                                                                      show: false))
                    }
                }
            }, fail: { [weak self] (_, error) in
                guard let strongSelf = self,
                    let vc = strongSelf.sendNewsListVC(sendChildVC,
                                                       sendNewsListVC: sendNewsListVC) else {
                                                        return
                }
                
                if isNextPage {
                    let offset = params[Param.Key.offset] as! Int
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
