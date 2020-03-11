//
//  ContactsViewController.swift
//  BaseSwift
//
//  Created by Shadow on 2016/12/9.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import SRKit

class ContactsViewController: BaseViewController, UIScrollViewDelegate {
    public weak var parentVC: SNSViewController?
    public weak var currentChildVC: UIViewController!
    @IBOutlet weak var scrollView: UIScrollView!
    lazy var singleVC: SingleContactViewController =
        UIViewController.viewController("SingleContactViewController", storyboard: "SNS")
            as! SingleContactViewController
    lazy var officialAccountVC: OfficialAccountsViewController =
        UIViewController.viewController("OfficialAccountsViewController", storyboard: "SNS")
            as! OfficialAccountsViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        initView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let width = scrollView.width
        let height = scrollView.height
        scrollView.contentSize = CGSize(2.0 * width, height)
        singleVC.view.frame = CGRect(0, 0, width, height)
        officialAccountVC.view.frame = CGRect(width, 0, width, height)
    }
    
    deinit {
        LogDebug("\(NSStringFromClass(type(of: self))).\(#function)")
        NotifyDefault.remove(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - 视图初始化
    
    func initView() {
        //let height = ScreenHeight - C.navigationHeaderHeight() - C.tabBarHeight()
        scrollView.isPagingEnabled = true
        scrollView.bounces = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        
        addChild(singleVC)
        scrollView.addSubview(singleVC.view)
        
        addChild(officialAccountVC)
        scrollView.addSubview(officialAccountVC.view)
    }
    
    //MARK: Autorotate Orientation
    
    override func deviceOrientationDidChange(_ sender: AnyObject? = nil) {
        super.deviceOrientationDidChange(sender)
        
        var index = 0
        if currentChildVC === officialAccountVC {
            index = 1
        }
        scrollView.setContentOffset(CGPoint(x: CGFloat(index) * ScreenWidth, y: 0),
                                    animated: false)
    }
    
    //MARK: - 业务处理
    
    public func bringChildVC(toFront index: Int) {
        var childVC: UIViewController = singleVC
        if index == 1 {
            childVC = officialAccountVC
        }
        guard childVC != currentChildVC else {
            return
        }
        
        scrollView.setContentOffset(CGPoint(x: CGFloat(index) * ScreenWidth, y: 0),
                                    animated: false)
        currentChildVC = childVC
    }
    
    //MARK: - UIScrollViewDelegate
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView,
                                  willDecelerate decelerate: Bool) {
        if !decelerate {
            resetAfterScrollViewDidEndScroll(scrollView)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        resetAfterScrollViewDidEndScroll(scrollView)
    }
    
    func resetAfterScrollViewDidEndScroll(_ scrollView: UIScrollView) {
        let width = scrollView.width
        if width > 0 {
            let index = floor(scrollView.contentOffset.x / width)
            if index == 0 {
                currentChildVC = singleVC
            } else if index == 1 {
                currentChildVC = officialAccountVC
            }
            parentVC?.contactsSC.selectedSegmentIndex = Int(index)
        }
    }
}
