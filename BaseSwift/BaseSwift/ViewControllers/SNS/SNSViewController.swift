//
//  SNSViewController.swift
//  BaseSwift
//
//  Created by Shadow on 2016/12/7.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import UIKit

class SNSViewController: BaseViewController {
    @IBOutlet weak var childBackgroundView: UIView!
    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var chatListItem: UITabBarItem!
    @IBOutlet weak var contactsItem: UITabBarItem!
    @IBOutlet weak var findItem: UITabBarItem!
    @IBOutlet weak var moreItem: UITabBarItem!
    
    weak var currentChildVC: UIViewController?
    lazy var chatListVC: ChatListViewController = {
        let vc = Common.viewController("ChatListViewController", storyboard: "SNS")
            as! ChatListViewController
        vc.parentVC = self
        return vc
    }()
    lazy var contactsVC: ContactsViewController = {
        let vc = Common.viewController("ContactsViewController", storyboard: "SNS")
            as! ContactsViewController
        vc.parentVC = self
        return vc
    }()
    lazy var findVC: FindViewController = {
        let vc = Common.viewController("FindViewController", storyboard: "SNS")
            as! FindViewController
        vc.parentVC = self
        return vc
    }()
    lazy var moreVC: MoreViewController =
        Common.viewController("MoreViewController", storyboard: "More") as! MoreViewController
    
    lazy var contactsSC: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Friends".localized, "Official Accounts".localized])
        sc.setTitleTextAttributes([NSAttributedStringKey.font : UIFont.title],
                                  for: .normal)
        sc.sizeToFit()
        sc.selectedSegmentIndex = 0
        sc.addTarget(self,
                     action: #selector(clickContactsSC(_:)),
                     for: .valueChanged)
        return sc
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        pageBackGestureStyle = .none
        NotifyDefault.add(self,
                          selector: #selector(newAction(_:)),
                          name: Notification.Name.Base.newAction)
        
        initNavigationBar()
        navigationItem.leftBarButtonItem =
            UIBarButtonItem(title: EmptyString, style: .plain, target: nil, action: nil)
        tabBar.backgroundColor = UIColor.clear
        tabBar.isTranslucent = true
        
        //查询当前指令而执行的操作
        if let action = Common.currentActionParams()?[ParamKey.action] as? String,
            Event.Option.showMore == Event.option(action) {
            tabBar.selectedItem = moreItem
            tabBar(tabBar, didSelect: moreItem)
            Common.clearActionParams(Event.Option.showMore)
        } else {
            tabBar.selectedItem = chatListItem
            tabBar(tabBar, didSelect: chatListItem)
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Autorotate Orientation
    
    override func deviceOrientationDidChange(_ sender: AnyObject? = nil) {
        super.deviceOrientationDidChange(sender)
        
        updateChildViewFrame()
        if currentChildVC === contactsVC {
            contactsVC.deviceOrientationDidChange(sender)
        } else if currentChildVC === findVC {
            findVC.deviceOrientationDidChange(sender)
        } else if currentChildVC === moreVC {
            moreVC.deviceOrientationDidChange(sender)
        }
    }
    
    //MARK: - 视图初始化
    
    struct Const {
        static let sendChildVC = "sendChildVC"
    }
    
    //直接计算和更新frame，可以更有效的进行屏幕适配 添加约束，可以比较方便地进行横竖屏的屏幕适配
    func updateChildViewFrame() {
        let height = ScreenHeight() - NavigationHeaderHeight
        let frame = CGRect(0, 0, ScreenWidth(), height) //正常带导航栏的子视图frame
        
        if currentChildVC === chatListVC || currentChildVC === contactsVC {
            currentChildVC?.view.frame = frame
        } else if currentChildVC === findVC {
            currentChildVC?.view.frame = CGRect(0, 0, ScreenWidth(), ScreenHeight() - TabBarHeight)
        } else if currentChildVC === moreVC {
            //为了实现更多列表的tableHeaderView的背景色和导航栏完全一致，需要往上移一点点
            //因为在group模式下的UITableView中tableHeaderView边缘会自带一条分隔线
            currentChildVC?.view.frame = CGRect(0,
                                                frame.origin.y - SectionHeaderGroupNoHeight,
                                                ScreenWidth(),
                                                height + SectionHeaderGroupNoHeight)
        }
    }
    
    func setNavigationBarRightButtonItems() {
        if currentChildVC === chatListVC {
            var setting = NavigartionBar.buttonFullSetting
            setting[.style] = NavigartionBar.ButtonItemStyle.image
            setting[.image] = UIImage(named: "qr")
            navBarRightButtonSettings = [setting]
        } else {
            navigationItem.rightBarButtonItems = nil
        }
    }
    
    //MARK: - 业务处理
    
    override func performViewDidLoad() {
        DispatchQueue.main.async { [weak self] in
            self?.updateChildViewFrame()
        }
    }
    
    func bringChildVC(toFront vc: UIViewController) {
        vc.didMove(toParentViewController: self)
        vc.view.isUserInteractionEnabled = true
        currentChildVC?.view.removeFromSuperview()
        currentChildVC?.willMove(toParentViewController: self)
        currentChildVC?.removeFromParentViewController()
        currentChildVC = vc
        childBackgroundView.addSubview(vc.view)
        updateChildViewFrame()
        if currentChildVC === chatListVC {
            title = "List".localized
            navigationItem.titleView = nil
            if !(chatListVC.isTouched) {
                chatListVC.isTouched = true
                chatListVC.loadData(.opaqueMask)
            }
        } else if currentChildVC === contactsVC {
            navigationItem.titleView = contactsSC
        } else  if currentChildVC === findVC {
            title = "Find".localized
            navigationItem.titleView = nil
            findVC.deviceOrientationDidChange()
            if !(findVC.isTouched) {
                findVC.isTouched = true
                //self?.findVC.loadData(TableLoadData.new, progressType: .opaqueMask)
                findVC.startRefreshNew()
            }
        } else if currentChildVC === moreVC {
            title = "More".localized
            navigationItem.titleView = nil
            moreVC.deviceOrientationDidChange()
        }
        setNavigationBarRightButtonItems()
    }
        
    //MARK: - 事件响应
    
    override func clickNavigationBarRightButton(_ button: UIButton) {
        guard Common.mutexTouch() else { return }
        
        if currentChildVC === chatListVC {
            show("QRCodeReaderViewController", storyboard: "Utility")
        }
    }
    
    @objc func clickContactsSC(_ sender: Any) {
        contactsVC.bringChildVC(toFront: contactsSC.selectedSegmentIndex)
    }
    
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
                bringChildVC(toFront: moreVC)
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
            } else { //视图栈中没有Profile页面，退出到主页，再push新的Profile页面入栈
                Common.clearPops()
                Common.clearModals(viewController: self)
                popBack(to: self, animated: false)
                NotifyDefault.add(self,
                                  selector: .didEndStateMachineEvent,
                                  name: Notification.Name.Base.didEndStateMachineEvent)
                DispatchQueue.main.async {
                    self.show("ProfileViewController",
                              storyboard: "Profile",
                              params: [ParamKey.sender : String(pointer: self),
                                       ParamKey.event : event])
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
            NotifyDefault.remove(self,
                                 name: Notification.Name.Base.didEndStateMachineEvent)
        }
    }
}

//MARK: - UIViewControllerPreviewingDelegate

extension SNSViewController: UIViewControllerPreviewingDelegate {
    @available(iOS 9.0, *)
    public func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                                  viewControllerForLocation location: CGPoint) -> UIViewController? {
        let index = previewingContext.sourceView.tag
        if index < chatListVC.dataArray.count {
            let vc = ChatViewController()
            vc.targetId = chatListVC.dataArray[index].userId
            vc.nickname = chatListVC.dataArray[index].userName
            vc.conversationType = .ConversationType_PRIVATE
            vc.previewedIndex = index
            return vc
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

extension SNSViewController: UITabBarDelegate {
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        var newVC: UIViewController!
        if item === chatListItem {
            newVC = chatListVC as UIViewController
        } else if item === contactsItem {
            newVC = contactsVC as UIViewController
        } else if item === findItem {
            newVC = findVC as UIViewController
        } else if item === moreItem {
            newVC = moreVC as UIViewController
        }
        
        if newVC === currentChildVC { //重复点击下方，会重新加载列表或发送请求
            if newVC === chatListVC {
                chatListVC.loadData()
            } else if newVC === findVC {
                //findVC.loadData(TableLoadData.new, progressType: .clearMask)
                findVC.startRefreshNew()
            }
        } else if (newVC != nil) {
            addChildViewController(newVC)
            if let currentChildVC = currentChildVC {
                currentChildVC.view.isUserInteractionEnabled = false
                transition(from: currentChildVC,
                           to: newVC,
                           duration: 0,
                           options: UIViewAnimationOptions(rawValue: 0),
                           animations: nil,
                           completion:
                    { (finished) in
                        self.bringChildVC(toFront: newVC)
                })
            } else {
                self.bringChildVC(toFront: newVC)
            }
        }
    }
}
