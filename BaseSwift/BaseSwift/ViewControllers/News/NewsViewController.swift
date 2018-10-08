//
//  NewsViewController.swift
//  BaseSwift
//
//  Created by Gary on 2016/12/28.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import UIKit
import Cartography
import Alamofire

class NewsViewController: BaseViewController {
    @IBOutlet weak var childBackgroundView: UIView!
    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var tabBarBottomConstraint: NSLayoutConstraint!
    
    weak var currentChildVC: UIViewController!
    var mainVC: NewsMainViewController!
    var secondaryVC: NewsSecondaryViewController!
    var yellowVC: NewsYellowViewController!
    var moreVC: MoreViewController!
    
    var mainConstraintGroup = ConstraintGroup()
    var secondaryConstraintGroup = ConstraintGroup()
    var yellowConstraintGroup = ConstraintGroup()
    var moreConstraintGroup = ConstraintGroup()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        defaultNavigationBar()
        pageBackGestureStyle = .edge
        NotifyDefault.add(self,
                          selector: #selector(newAction(_:)),
                          name: Notification.Name.Base.newAction)
        initView()
        
        //查询当前指令而执行的操作
        if let action = Common.currentActionParams()?[ParamKey.action] as? String,
            Event.Option.showMore == Event.option(action) {
            tabBar.selectedItem = tabBar.items?[3]
            addChildViewController(moreVC)
            childBackgroundView.addSubview(moreVC.view)
            currentChildVC = moreVC
            title = "Me".localized
            moreVC.deviceOrientationDidChange()
            
            Common.clearActionParams(Event.Option.showMore)
        } else {
            tabBar.selectedItem = tabBar.items?.first
            addChildViewController(mainVC)
            childBackgroundView.addSubview(mainVC.view)
            currentChildVC = mainVC
            mainVC.currentNewsListVC?.loadData(TableLoadData.new, progressType: .clearMask)
        }
        
        //查询当前指令而执行的操作，加入状态机
        if let action = Common.currentActionParams()?[ParamKey.action] as? String,
            let event = Event.option(action),
            Event.Option.showProfile == event
                || Event.Option.showSetting == event {
            DispatchQueue.main.async { [weak self] in
                self?.stateMachine.append(option: event)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Autorotate Orientation
    
    override func deviceOrientationDidChange(_ sender: AnyObject? = nil) {
        super.deviceOrientationDidChange(sender)
        
        updateChildViewFrame()
        if currentChildVC === mainVC {
            mainVC.deviceOrientationDidChange(sender)
        } else if currentChildVC === secondaryVC {
            secondaryVC.deviceOrientationDidChange(sender)
        } else if currentChildVC === moreVC {
            moreVC.deviceOrientationDidChange(sender)
        }
    }
    
    //MARK: - 视图初始化
    
    struct Const {
        static let sendChildVC = "sendChildVC"
        static let sendNewsListVC = "sendNewsListVC"
    }
    
    func initView() {
        initTabBar()
        
        mainVC = Common.viewController("NewsMainViewController",
                                       storyboard: "News") as? NewsMainViewController
        mainVC.parentVC = self
        
        secondaryVC = Common.viewController("NewsSecondaryViewController",
                                            storyboard: "News") as? NewsSecondaryViewController
        secondaryVC.parentVC = self
        
        yellowVC = Common.viewController("NewsYellowViewController",
                                         storyboard: "News") as? NewsYellowViewController
        
        moreVC = Common.viewController("MoreViewController",
                                       storyboard: "More") as? MoreViewController
    }
    
    //添加约束，可以比较方便地进行横竖屏的屏幕适配
    func updateChildViewFrame() {
        if currentChildVC === mainVC || currentChildVC === secondaryVC {
            currentChildVC.view.frame = CGRect(0, 0, ScreenWidth(), ScreenHeight())
        } else if currentChildVC === yellowVC { //不带导航栏的子视图frame
            currentChildVC.view.frame =
                CGRect(0,
                       topLayoutGuide.length,
                       ScreenWidth(),
                       ScreenHeight() - topLayoutGuide.length)
        } else if currentChildVC === moreVC {
            //为了实现更多列表的tableHeaderView的背景色和导航栏完全一致，需要往上移一点点
            //因为在group模式下的UITableView中tableHeaderView边缘会自带一条分隔线
            currentChildVC.view.frame = CGRect(0,
                                               topLayoutGuide.length - SectionHeaderGroupNoHeight,
                                               ScreenWidth(),
                                               ScreenHeight() - topLayoutGuide.length
                                                + SectionHeaderGroupNoHeight)
        }
    }
    
    func initTabBar() {
        setTabBarImage(0, normal: "acgirl_20", highlighted: "acgirl_20_color")
        setTabBarImage(1, normal: "acgirl_28", highlighted: "acgirl_28_color")
        setTabBarImage(2, normal: "acgirl_16", highlighted: "acgirl_16_color")
        setTabBarImage(3, normal: "acgirl_34", highlighted: "acgirl_06_color")
    }
    
    func setTabBarImage(_ index: Int, normal: String, highlighted: String) {
        guard let items = tabBar.items,
            index >= 0 && index < items.count,
            let item = tabBar.items?[index] else {
                return
        }
        
        item.setTitleTextAttributes([.foregroundColor : NavigartionBar.backgroundColor],
                                    for: .selected)
        
        guard let normalImage = UIImage(named: normal),
            normalImage.size.width > 0 && normalImage.size.height > 0,
            let highlightedImage = UIImage(named: highlighted),
            highlightedImage.size.width > 0 && highlightedImage.size.height > 0 else {
                return
        }
        
        var width = TabBarImageHeight * normalImage.size.width / normalImage.size.height
        var image = normalImage.imageScaled(to: CGSize(width, TabBarImageHeight))
        item.image = image?.withRenderingMode(.alwaysOriginal)
        
        width = TabBarImageHeight * highlightedImage.size.width / highlightedImage.size.height
        image = highlightedImage.imageScaled(to: CGSize(width, TabBarImageHeight))
        item.selectedImage = image?.withRenderingMode(.alwaysOriginal)
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
        addChildViewController(childVC)
        transition(from: currentChildVC!,
                   to: childVC,
                   duration: 0,
                   options: UIViewAnimationOptions(rawValue: 0),
                   animations: nil,
                   completion:
            { [weak self] (finished) in
                guard finished else {
                    childVC.removeFromParentViewController()
                    self?.currentChildVC?.view.isUserInteractionEnabled = true
                    return
                }
                
                childVC.didMove(toParentViewController: self)
                childVC.view.isUserInteractionEnabled = true
                self?.currentChildVC?.willMove(toParentViewController: self)
                self?.currentChildVC?.removeFromParentViewController()
                self?.currentChildVC = childVC
                self?.childBackgroundView.addSubview((self?.currentChildVC.view)!)
                self?.updateChildViewFrame()
                if self?.currentChildVC === self?.mainVC {
                    self?.navigationController?.isNavigationBarHidden = true
                    if let vc = self?.mainVC.currentNewsListVC, !vc.isTouched {
                        vc.loadData(TableLoadData.new, progressType: .clearMask)
                    }
                } else if self?.currentChildVC === self?.secondaryVC {
                    self?.navigationController?.isNavigationBarHidden = true
                    if let vc = self?.secondaryVC.currentNewsListVC, !vc.isTouched {
                        vc.loadData(TableLoadData.new, progressType: .clearMask)
                    }
                } else  if self?.currentChildVC === self?.yellowVC {
                    self?.navigationController?.isNavigationBarHidden = false
                    self?.title = "Title Party".localized
                } else if self?.currentChildVC === self?.moreVC {
                    self?.navigationController?.isNavigationBarHidden = false
                    self?.title = "Me".localized
                    self?.moreVC.deviceOrientationDidChange()
                }
        })
    }
    
    func sendNewsListVC(_ sendChildVC: String?,
                        sendNewsListVC: String?) ->NewsListViewController? {
        guard let sendChildVC = sendChildVC, let sendNewsListVC = sendNewsListVC else {
            return nil
        }
        
        if sendChildVC == String(pointer: mainVC) {
            return mainVC.newsListVC(sendNewsListVC)
        } else if sendChildVC == String(pointer: secondaryVC) {
            return secondaryVC.newsListVC(sendNewsListVC)
        } else {
            return nil
        }
    }
    
    //MARK: - 事件响应
    
    //在程序运行中收到指令，基本都可以通过走状态机实现
    @objc func newAction(_ notification: Notification) {
        guard let action = Common.currentActionParams()?[ParamKey.action] as? String,
            let event = Event.option(action) else {
                return
        }
        
        switch event {
        case Event.Option.showMore, Event.Option.showProfile, Event.Option.showSetting:
            stateMachine.append(option: event)
        default:
            break
        }
    }
    
    //MARK: - SRStateMachineDelegate
    
    override func stateMachine(_ stateMachine: SRStateMachine, didFire event: Int) {
        switch event {
        case Event.Option.showMore:
            if !(isFront && moreVC === currentChildVC) {
                Common.clearPops()
                Common.clearModals(viewController: self)
                popBack(to: self)
                tabBar.selectedItem = tabBar.items?[3]
                bringChildVCFront(moreVC)
            }
            Common.clearActionParams(event)
            stateMachine.end(event)
            
        case Event.Option.showProfile:
            let viewControllers = navigationController!.viewControllers
            let profileVCs = viewControllers.filter { $0.isKind(of: ProfileViewController.self) }
            if viewControllers.last!.isKind(of: ProfileViewController.self) { //当前页面是Profile页面
                Common.clearActionParams(event)
                stateMachine.end(event)
            } else if profileVCs.count > 0 { //Profile页面在当前页面之前
                Common.clearActionParams(event)
                stateMachine.end(event)
                Common.clearPops()
                Common.clearModals(viewController: profileVCs.last!)
                popBack(to: profileVCs.last!)
            } else { //视图栈中没有Profile页面，退出到主页
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
                        self.moreVC.presentLoginVC(params)
                    } else { //push新的Profile页面入栈
                        self.show("ProfileViewController",
                                  storyboard: "Profile",
                                  params: params)
                    }
                }
            }
            
        case Event.Option.showSetting:
            let viewControllers = navigationController!.viewControllers
            let settingVCs = viewControllers.filter { $0 is SettingViewController }
            if viewControllers.last! is SettingViewController { //当前页面是Setting页面
                Common.clearActionParams(event)
                stateMachine.end(event)
            } else if settingVCs.count > 0 { //Setting页面在当前页面之前
                Common.clearActionParams(event)
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
                    self.show("SettingViewController",
                              storyboard: "Profile",
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
        
        if Event.Option.showProfile == event || Event.Option.showSetting == event {
            NotifyDefault.remove(self, name: Notification.Name.Base.didEndStateMachineEvent)
        }
    }
}

//MARK: - NewsListDelegate

extension NewsViewController: NewsListDelegate {
    //使用第三方新闻客户端的请求参数
    func getNewsList(_ loadType: String?, sendVC: NewsListViewController) {
        var params = sendVC.params
        let time = CLongLong(Date().timeIntervalSince1970 * 1000)
        params["t"] = String(longLong: time)
        params["_"] = String(longLong: time + 2)
        params["show_num"] = "10"
        params["act"] = loadType == TableLoadData.more ? "more" : "new"
        let offset = loadType == TableLoadData.more ? sendVC.currentOffset + 1 : 0
        params["page"] = String(int: offset + 1)
        var sendChildVC: String?
        if let parentVC = sendVC.parentVC {
            sendChildVC = String(pointer: parentVC)
        }
        let sendNewsListVC = String(pointer: sendVC)
        //httpReq(.get(.sinaNewsList), params, userInfo, url: "http://interface.sina.cn")
        httpRequest(.get(.sinaNewsList),
                    params,
                    url: "http://interface.sina.cn",
                    success:
            { response in
                guard let vc = self.sendNewsListVC(sendChildVC,
                                                   sendNewsListVC: sendNewsListVC) else {
                                                    return
                }
                
                if loadType == TableLoadData.more {
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
            
            if loadType == TableLoadData.more {
                let offset = params[ParamKey.offset] as! Int
                if offset == vc.currentOffset + 1 {
                    return
                }
            } else {
                if vc.dataArray.count > 0 { //已经有数据，保留原数据，显示提示框
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
            
            if loadType == TableLoadData.more {
                let offset = params[ParamKey.offset] as! Int
                if offset == vc.currentOffset + 1 {
                    if vc.dataArray.count > 0 { //若当前有数据，则进行弹出toast的交互，列表恢复刷新状态
                        vc.updateMore(nil)
                    } else { //当前为空的话则交给列表展示错误信息，一般在加载更多的时候是不会走到这个逻辑的，因为空数据的时候上拉加载更多是被禁止的
                        vc.updateMore(nil, errMsg: error.errorDescription)
                    }
                }
            } else {
                if vc.dataArray.count > 0 { //若当前有数据，则进行弹出toast的交互
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

//MARK: - UIViewControllerPreviewingDelegate

extension NewsViewController: UIViewControllerPreviewingDelegate {
    @available(iOS 9.0, *)
    public func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                                  viewControllerForLocation location: CGPoint) -> UIViewController? {
        var newsListVC: NewsListViewController?
        if currentChildVC === mainVC, let vc = mainVC.currentNewsListVC {
            newsListVC = vc
        } else if currentChildVC === secondaryVC, let vc = secondaryVC.currentNewsListVC {
            newsListVC = vc
        }
        
        if let newsListVC = newsListVC {
            let index = previewingContext.sourceView.tag
            if index < newsListVC.dataArray.count {
                var dictionary = EmptyParams()
                dictionary[ParamKey.url] = URL(string: NonNull.string(newsListVC.dataArray[index].link))
                dictionary[ParamKey.title] = "News".localized
                let webpageVC = Common.viewController("WebpageViewController",
                                                      storyboard: "Utility") as! WebpageViewController
                webpageVC.params = dictionary
                webpageVC.isPreviewed = true
                return webpageVC
            }
        }
        
        return nil
    }
    
    @available(iOS 9.0, *)
    public func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                                  commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
}

//MARK: - UITabBarDelegate

extension NewsViewController: UITabBarDelegate {
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        let index = item.tag
        var childVC: UIViewController?
        switch index {
        case 0:
            childVC = mainVC as UIViewController
        case 1:
            childVC = secondaryVC as UIViewController
        case 2:
            childVC = yellowVC as UIViewController
        case 3:
            childVC = moreVC as UIViewController
        default:
            break
        }
        if let childVC = childVC {
            bringChildVCFront(childVC)
            if childVC === currentChildVC { //重复点击下方，会重新加载列表或发送请求
                if childVC === mainVC {
                    mainVC.currentNewsListVC?.loadData(TableLoadData.new, progressType: .opaqueMask)
                } else if childVC === secondaryVC {
                    secondaryVC.currentNewsListVC?.loadData(TableLoadData.new,
                                                            progressType: .opaqueMask)
                }
            }
        }
    }
}
