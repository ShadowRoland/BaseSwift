//
//  AppGuideViewController.swift
//  BaseSwift
//
//  Created by Shadow on 2016/12/7.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import UIKit
import SlideMenuControllerSwift

class AppGuideViewController: BaseViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var scrollViewWidthConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        navigartionBarAppear = .hidden
        initView()
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
        scrollView.delegate = self
        scrollViewWidthConstraint.constant = ScreenWidth()
        
        //引导图片文件存储目录
        var dir = ResourceDirectory.appending(pathComponent: "image/guide")
        if Common.screenScale() == .iPhone4 {
            dir = dir.appending(pathComponent: "640x960")
        } else {
            dir = dir.appending(pathComponent: "640x1136")
        }
        
        (1...4).forEach { i in
            let filePath = dir.appending(pathComponent: String(format: "page%d.png", i))
            let imageView = UIImageView(image: UIImage(contentsOfFile: filePath))
            imageView.frame =
                CGRect(ScreenWidth() * CGFloat(i - 1), 0, ScreenWidth(), ScreenHeight())
            scrollView.addSubview(imageView)
            
            if i == 4 {
                let button = UIButton(frame: CGRect(imageView.right - 80.0 - 20.0,
                                                    ScreenWidth() - TableCellHeight - 20.0,
                                                    80.0,
                                                    TableCellHeight))
                let image = UIImage.rect(MaskBackgroundColor, size: CGSize(80.0, TableCellHeight))
                button.backgroundImage = image
                button.title = "Enter".localized
                button.clicked(self, action: #selector(clickEnterButton(_:)))
                scrollView.addSubview(button)
            }
            
            //FIXME: FOR DEBUG，点击引导图可以快速消失引导页
            let gr = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            imageView.addGestureRecognizer(gr)
            imageView.isUserInteractionEnabled = true
        }
        scrollView.contentSize = CGSize(width: 4 * ScreenWidth(), height: ScreenHeight())
        
        pageControl.backgroundColor = MaskBackgroundColor
    }
    
    //MARK: - 业务处理
    
    func changePageControl() {
        let quo = scrollView.contentOffset.x / ScreenWidth()
        let page = lround(Double(quo)) as Int
        if pageControl.currentPage != page {
            pageControl.currentPage = page
        }
    }
    
    func next() {
        if UserStandard[USKey.enterAggregationEntrance] == nil {
            show("ViewController", storyboard: "Main", animated: false)
            return;
        }
        
        Entrance = .aggregation
        
        SlideMenuOptions.leftViewWidth = 240.0
        let mainMenuVC = Common.viewController("MainMenuViewController", storyboard: "Aggregation")
            as! MainMenuViewController
        let leftMenuVC = Common.viewController("LeftMenuViewController", storyboard: "Aggregation")
            as! LeftMenuViewController
        let navigationVC = SRNavigationController(rootViewController: mainMenuVC)
        let aggregationVC = AggregationViewController(mainViewController: navigationVC,
                                                      leftMenuViewController: leftMenuVC)
        aggregationVC.automaticallyAdjustsScrollViewInsets = true
        aggregationVC.delegate = mainMenuVC
        
        leftMenuVC.aggregationVC = aggregationVC
        leftMenuVC.mainMenuVC = mainMenuVC
        mainMenuVC.aggregationVC = aggregationVC
        mainMenuVC.leftMenuVC = leftMenuVC
        
        show(aggregationVC, animated: false)
    }
    
    //MARK: - 事件响应
    
    @objc func clickEnterButton(_ sender: Any) {
        guard Common.mutexTouch() else { return }
        next()
    }
    
    @objc func handleTap(_ gr: UITapGestureRecognizer) {
        guard Common.mutexTouch() else { return }
        next()
    }
    
    @IBAction func pageControlValueChanged(_ sender: Any) {
        scrollView.setContentOffset(CGPoint(ScreenWidth() * CGFloat(pageControl.currentPage), 0),
                                    animated: true)
    }
    
    //MARK: - Autorotate Orientation
    
    override public var shouldAutorotate: Bool { return false }
    
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override public var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    //MARK: - UIScrollViewDelegate
    
    override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        super.scrollViewDidEndScrollingAnimation(scrollView)
        changePageControl()
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        super.scrollViewDidEndDecelerating(scrollView)
        changePageControl()
    }
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        super.scrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
        changePageControl()
    }
}
