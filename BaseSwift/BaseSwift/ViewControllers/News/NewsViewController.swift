//
//  NewsViewController.swift
//  BaseSwift
//
//  Created by Gary on 2016/12/28.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import SRKit
import Cartography

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
        setDefaultNavigationBar()
        pageBackGestureStyle = .edge
        initView()
        
        if let event = Common.events.first(where: { $0.option == .showMore }) {
            Common.removeEvent(event)
            tabBar.selectedItem = tabBar.items?[3]
            addChild(moreVC)
            childBackgroundView.addSubview(moreVC.view)
            currentChildVC = moreVC
            title = "Me".localized
            moreVC.deviceOrientationDidChange()
        } else {
            tabBar.selectedItem = tabBar.items?.first
            addChild(mainVC)
            childBackgroundView.addSubview(mainVC.view)
            currentChildVC = mainVC
            mainVC.currentNewsListVC?.loadData(progressType: .clearMask)
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
        
        mainVC = UIViewController.viewController("NewsMainViewController",
                                       storyboard: "News") as? NewsMainViewController
        mainVC.parentVC = self
        
        secondaryVC = UIViewController.viewController("NewsSecondaryViewController",
                                            storyboard: "News") as? NewsSecondaryViewController
        secondaryVC.parentVC = self
        
        yellowVC = UIViewController.viewController("NewsYellowViewController",
                                         storyboard: "News") as? NewsYellowViewController
        
        moreVC = UIViewController.viewController("MoreViewController",
                                       storyboard: "More") as? MoreViewController
    }
    
    //添加约束，可以比较方便地进行横竖屏的屏幕适配
    func updateChildViewFrame() {
        if currentChildVC === mainVC || currentChildVC === secondaryVC {
            currentChildVC.view.frame = CGRect(0, 0, ScreenWidth, ScreenHeight)
        } else if currentChildVC === yellowVC { //不带导航栏的子视图frame
            currentChildVC.view.frame =
                CGRect(0,
                       topLayoutGuide.length,
                       ScreenWidth,
                       ScreenHeight - topLayoutGuide.length)
        } else if currentChildVC === moreVC {
            //为了实现更多列表的tableHeaderView的背景色和导航栏完全一致，需要往上移一点点
            //因为在group模式下的UITableView中tableHeaderView边缘会自带一条分隔线
            currentChildVC.view.frame = CGRect(0,
                                               topLayoutGuide.length - SectionHeaderGroupNoHeight,
                                               ScreenWidth,
                                               ScreenHeight - topLayoutGuide.length
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
        
        item.setTitleTextAttributes([.foregroundColor : NavigationBar.backgroundColor],
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
                
                childVC.didMove(toParent: strongSelf)
                childVC.view.isUserInteractionEnabled = true
                strongSelf.currentChildVC?.willMove(toParent: self)
                strongSelf.currentChildVC?.removeFromParent()
                strongSelf.currentChildVC = childVC
                strongSelf.childBackgroundView.addSubview((strongSelf.currentChildVC.view)!)
                strongSelf.updateChildViewFrame()
                if strongSelf.currentChildVC === strongSelf.mainVC {
                    strongSelf.navigationController?.isNavigationBarHidden = true
                    if let vc = strongSelf.mainVC.currentNewsListVC, !vc.isTouched {
                        vc.loadData(progressType: .clearMask)
                    }
                } else if strongSelf.currentChildVC === strongSelf.secondaryVC {
                    strongSelf.navigationController?.isNavigationBarHidden = true
                    if let vc = strongSelf.secondaryVC.currentNewsListVC, !vc.isTouched {
                        vc.loadData(progressType: .clearMask)
                    }
                } else  if strongSelf.currentChildVC === strongSelf.yellowVC {
                    strongSelf.navigationController?.isNavigationBarHidden = false
                    strongSelf.title = "Title Party".localized
                } else if strongSelf.currentChildVC === strongSelf.moreVC {
                    strongSelf.navigationController?.isNavigationBarHidden = false
                    strongSelf.title = "Me".localized
                    strongSelf.moreVC.deviceOrientationDidChange()
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
    
    //MARK: - SRStateMachineDelegate
    
    override func stateMachine(_ stateMachine: SRStateMachine, didFire event: Event) {
        switch event.option {
        case .showMore:
            guard let viewControllers = navigationController?.viewControllers,
                let top = viewControllers.last,
                top.isTop else {
                    break
            }
            
            if !(moreVC === currentChildVC) {
                Common.clearPops()
                top.dismissModals()
                popBack(to: self)
                tabBar.selectedItem = tabBar.items?[3]
                bringChildVCFront(moreVC)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + ViewControllerTransitionInterval, execute: { [weak self] in
                self?.stateMachine.end(event)
            })
            
        default:
            super.stateMachine(stateMachine, didFire: event)
        }
    }
}

//MARK: - NewsListDelegate

extension NewsViewController: NewsListDelegate {
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
        httpRequest(.get("http://interface.sina.cn/ent/feed.d.json", params), success:
            { [weak self] response in
                guard let strongSelf = self,
                    let vc = strongSelf.sendNewsListVC(sendChildVC, sendNewsListVC: sendNewsListVC) else {
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
                    let vc = strongSelf.sendNewsListVC(sendChildVC, sendNewsListVC: sendNewsListVC) else {
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
                        vc.updateNew(nil, errMsg: strongSelf.logBFail(method, response: response, show: false))
                    }
                }
            }, fail: { [weak self] (_, error) in
                guard let strongSelf = self,
                    let vc = strongSelf.sendNewsListVC(sendChildVC, sendNewsListVC: sendNewsListVC) else {
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
                var dictionary = [:] as ParamDictionary
                dictionary[Param.Key.url] = URL(string: NonNull.string(newsListVC.dataArray[index].link))
                dictionary[Param.Key.title] = "News".localized
                let webpageVC = UIViewController.viewController("WebpageViewController",
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
                    mainVC.currentNewsListVC?.loadData()
                } else if childVC === secondaryVC {
                    secondaryVC.currentNewsListVC?.loadData()
                }
            }
        }
    }
}
