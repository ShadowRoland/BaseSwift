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
        srPageBackGestureStyle = .none
        Common.rootVC = self
        initView()
        
        addChild(latestVC)
        childBackgroundView.addSubview(latestVC.view)
        currentChildVC = latestVC
        title = "Latest".localized
        latestVC.backToTopButtonBottomConstraint.constant = 0
        latestVC.getDataArray(progressType: .clearMask)
        
        if UserStandard[UDKey.showAdvertisingGuide] != nil {
            UserStandard[UDKey.showAdvertisingGuide] = nil
            srStateMachine.append(Event(.showAdvertisingGuard))
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
        navBarLeftButtonOptions = [.image(UIImage("list")!)]
        navBarRightButtonOptions = [.image(UIImage("search_white")!)]
        
        latestVC =
            NewsMainViewController.createNewsListVC(ChannelModel(id: String(int: 0)))
        latestVC.parentVC = self
        latestVC.delegate = self
        
        hottestVC =
            UIViewController.srViewController("HottestViewController",
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
            { [weak self] finished in
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
                        vc.getDataArray(progressType: .clearMask)
                    }
                } else if strongSelf.currentChildVC === strongSelf.latestVC {
                    strongSelf.navigationController?.isNavigationBarHidden = false
                    strongSelf.title = "Latest".localized
                    if !strongSelf.latestVC.isTouched {
                        strongSelf.latestVC.backToTopButtonBottomConstraint.constant = 0
                        strongSelf.latestVC.getDataArray(progressType: .clearMask)
                    }
                } else if strongSelf.currentChildVC === strongSelf.jokersVC {
                    strongSelf.navigationController?.isNavigationBarHidden = false
                    strongSelf.title = "Jokers".localized
                    if !strongSelf.jokersVC.isTouched {
                        strongSelf.jokersVC.backToTopButtonBottomConstraint.constant = 0
                        strongSelf.jokersVC.getDataArray(progressType: .clearMask)
                    }
                } else  if strongSelf.currentChildVC === strongSelf.videosVC {
                    strongSelf.navigationController?.isNavigationBarHidden = false
                    strongSelf.title = "Videos".localized
                    if !strongSelf.videosVC.isTouched {
                        strongSelf.videosVC.backToTopButtonBottomConstraint.constant = 0
                        strongSelf.videosVC.getDataArray(progressType: .clearMask)
                    }
                } else if strongSelf.currentChildVC === strongSelf.picturesVC {
                    strongSelf.navigationController?.isNavigationBarHidden = false
                    strongSelf.title = "Pictures".localized
                    if !strongSelf.picturesVC.isTouched {
                        strongSelf.picturesVC.backToTopButtonBottomConstraint.constant = 0
                        strongSelf.picturesVC.getDataArray(progressType: .clearMask)
                    }
                } else if strongSelf.currentChildVC === strongSelf.favoritesVC {
                    strongSelf.navigationController?.isNavigationBarHidden = false
                    strongSelf.title = "Favorites".localized
                    if !strongSelf.favoritesVC.isTouched {
                        strongSelf.favoritesVC.backToTopButtonBottomConstraint.constant = 0
                        strongSelf.favoritesVC.getDataArray(progressType: .clearMask)
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
        srShow("NewsSearchViewController", storyboard: "News")
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
