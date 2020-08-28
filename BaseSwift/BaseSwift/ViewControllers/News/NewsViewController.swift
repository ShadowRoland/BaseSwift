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
    @IBOutlet weak var tabBarHeightConstraint: NSLayoutConstraint!
    
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
        srNavigationBarAppear = .hidden
        srPageBackGestureStyle = .edge
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
            mainVC.currentNewsListVC?.getDataArray(progressType: .clearMask)
        }
        
        //查询当前指令而执行的操作，加入状态机
        if let event = Common.events.first(where: { $0.option == .showProfile || $0.option == .showSetting }) {
            Common.removeEvent(event)
            DispatchQueue.main.async { [weak self] in
                self?.srStateMachine.append(event)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTabBarFrame()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Autorotate Orientation
    
    override func deviceOrientationDidChange(_ sender: AnyObject? = nil) {
        super.deviceOrientationDidChange(sender)
        
        updateChildViewFrame()
        updateTabBarFrame()
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
        childBackgroundView.removeFromSuperview()
        srAddSubview(underTop: childBackgroundView)
        view.insertSubview(childBackgroundView, belowSubview: tabBar)
        initTabBar()
        
        mainVC = UIViewController.srViewController("NewsMainViewController",
                                       storyboard: "News") as? NewsMainViewController
        mainVC.parentVC = self
        
        secondaryVC = UIViewController.srViewController("NewsSecondaryViewController",
                                            storyboard: "News") as? NewsSecondaryViewController
        secondaryVC.parentVC = self
        
        yellowVC = UIViewController.srViewController("NewsYellowViewController",
                                         storyboard: "News") as? NewsYellowViewController
        
        moreVC = UIViewController.srViewController("MoreViewController",
                                       storyboard: "More") as? MoreViewController
    }
    
    //添加约束，可以比较方便地进行横竖屏的屏幕适配
    func updateChildViewFrame() {
        currentChildVC.view.isHidden = false
        if currentChildVC.view.superview == nil {
            view.addSubview(currentChildVC.view)
            constrain(currentChildVC.view) { $0.edges == inset($0.superview!.edges, 0) }
//            if currentChildVC === mainVC || currentChildVC === secondaryVC {
//                currentChildVC.view.frame = CGRect(0, 0, ScreenWidth, ScreenHeight)
//            } else if currentChildVC === yellowVC { //不带导航栏的子视图frame
//                currentChildVC.view.frame =
//                    CGRect(0,
//                           srTopLayoutGuide,
//                           childBackgroundView.frame.size.width,
//                           childBackgroundView.frame.size.height)
//            } else if currentChildVC === moreVC {
//                //为了实现更多列表的tableHeaderView的背景色和导航栏完全一致，需要往上移一点点
//                //因为在group模式下的UITableView中tableHeaderView边缘会自带一条分隔线
//                currentChildVC.view.frame = CGRect(0,
//                                                   topLayoutGuide.length - C.sectionHeaderGroupNoHeight,
//                                                   ScreenWidth,
//                                                   ScreenHeight - topLayoutGuide.length
//                                                    + C.sectionHeaderGroupNoHeight)
//            }
        }
    }
    
    func updateTabBarFrame() {
        let window = view.window != nil ? view.window! : UIApplication.shared.keyWindow!
        var safeBottom = 0 as CGFloat
        if #available(iOS 11.0, *) {
            safeBottom = window.safeAreaInsets.bottom
        } else {
            // Fallback on earlier versions
        }
        if safeBottom > 0 {
            let frame = window.convert(view.frame, from: view.superview)
            let bottom = frame.origin.y + frame.size.height
            if bottom > safeBottom {
                safeBottom = 34.0
            } else {
                safeBottom = 0
            }
        }
        let height = 49.0 + safeBottom
        if height != tabBarHeightConstraint.constant {
            tabBarHeightConstraint.constant = height
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
        
//        item.setTitleTextAttributes([.foregroundColor : NavigationBar.backgroundColor],
//                                    for: .selected)
        
        guard let normalImage = UIImage(named: normal),
            normalImage.size.width > 0 && normalImage.size.height > 0,
            let highlightedImage = UIImage(named: highlighted),
            highlightedImage.size.width > 0 && highlightedImage.size.height > 0 else {
                return
        }
        
        var width = C.tabBarImageHeight * normalImage.size.width / normalImage.size.height
        var image = normalImage.imageScaled(to: CGSize(width, C.tabBarImageHeight))
        item.image = image?.withRenderingMode(.alwaysOriginal)
        
        width = C.tabBarImageHeight * highlightedImage.size.width / highlightedImage.size.height
        image = highlightedImage.imageScaled(to: CGSize(width, C.tabBarImageHeight))
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
            { [weak self] finished in
                guard finished, let strongSelf = self else {
                    childVC.removeFromParent()
                    self?.currentChildVC?.view.isUserInteractionEnabled = true
                    return
                }
                
                childVC.didMove(toParent: strongSelf)
                childVC.view.isUserInteractionEnabled = true
                strongSelf.currentChildVC.willMove(toParent: strongSelf)
                strongSelf.currentChildVC.removeFromParent()
                strongSelf.currentChildVC.view.isHidden = true
                strongSelf.currentChildVC = childVC
                strongSelf.currentChildVC.view.isHidden = false
                if strongSelf.currentChildVC.view.superview == nil {
                    strongSelf.view.addSubview(strongSelf.currentChildVC.view)
                    constrain(strongSelf.currentChildVC.view) { $0.edges == inset($0.superview!.edges, 0) }
                    if strongSelf.srNavigationBarType == .sr {
                        if strongSelf.currentChildVC === strongSelf.secondaryVC {
                            
                        }
                    }
                }
                if strongSelf.currentChildVC === strongSelf.mainVC {
                    if strongSelf.srNavigationBarType == .system {
                        strongSelf.navigationController?.isNavigationBarHidden = true
                    }
                    if let vc = strongSelf.mainVC.currentNewsListVC, !vc.isTouched {
                        vc.getDataArray(progressType: .clearMask)
                    }
                } else if strongSelf.currentChildVC === strongSelf.secondaryVC {
                    if strongSelf.srNavigationBarType == .system {
                        strongSelf.navigationController?.isNavigationBarHidden = true
                        strongSelf.currentChildVC.srNavigationBarAppear = .hidden
                    }
                    if let vc = strongSelf.secondaryVC.currentNewsListVC, !vc.isTouched {
                        vc.getDataArray(progressType: .clearMask)
                    }
                } else  if strongSelf.currentChildVC === strongSelf.yellowVC {
                    if strongSelf.srNavigationBarType == .system {
                        strongSelf.navigationController?.isNavigationBarHidden = false
                        strongSelf.currentChildVC.srNavigationBarAppear = .visible
                    }
                    strongSelf.title = "Title Party".localized
                } else if strongSelf.currentChildVC === strongSelf.moreVC {
                    if strongSelf.srNavigationBarType == .system {
                        strongSelf.navigationController?.isNavigationBarHidden = false
                        strongSelf.currentChildVC.srNavigationBarAppear = .visible
                    }
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
                top.srIsTop else {
                    break
            }
            
            if !(moreVC === currentChildVC) {
                Common.clearPops()
                top.srDismissModals()
                srPopBack(to: self)
                tabBar.selectedItem = tabBar.items?[3]
                bringChildVCFront(moreVC)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + C.viewControllerTransitionInterval, execute: { [weak self] in
                self?.srStateMachine.end(event)
            })
            
        default:
            super.stateMachine(stateMachine, didFire: event)
        }
    }
}

//MARK: - NewsListDelegate

extension NewsViewController: NewsListDelegate {
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
                let model = newsListVC.dataArray[index] as! SinaNewsModel
                dictionary[Param.Key.url] = URL(string: NonNull.string(model.link))
                dictionary[Param.Key.title] = "News".localized
                let webpageVC = UIViewController.srViewController("WebpageViewController",
                                                      storyboard: "Utility") as! WebpageViewController
                webpageVC.srParams = dictionary
                webpageVC.srIsPreviewed = true
                return webpageVC
            }
        }
        
        return nil
    }
    
    @available(iOS 9.0, *)
    public func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                                  commit viewControllerToCommit: UIViewController) {
        srShow(viewControllerToCommit)
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
                    mainVC.currentNewsListVC?.getDataArray()
                } else if childVC === secondaryVC {
                    secondaryVC.currentNewsListVC?.getDataArray()
                }
            }
        }
    }
}
