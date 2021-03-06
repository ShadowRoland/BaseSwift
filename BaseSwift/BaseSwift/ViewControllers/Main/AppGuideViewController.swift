//
//  AppGuideViewController.swift
//  BaseSwift
//
//  Created by Shadow on 2016/12/7.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import SRKit
import SlideMenuControllerSwift

class AppGuideViewController: BaseViewController, UIScrollViewDelegate {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var scrollViewWidthConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        srNavigationBarAppear = .hidden
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
        scrollViewWidthConstraint.constant = ScreenWidth
        
        //引导图片文件存储目录
        var dir = C.resourceDirectory.appending(pathComponent: "image/guide")
        if C.screenScale == .iPhone4 {
            dir = dir.appending(pathComponent: "640x960")
        } else {
            dir = dir.appending(pathComponent: "640x1136")
        }
        
        (1...4).forEach { i in
            let filePath = dir.appending(pathComponent: String(format: "page%d.png", i))
            let imageView = UIImageView(image: UIImage(contentsOfFile: filePath))
            imageView.frame =
                CGRect(ScreenWidth * CGFloat(i - 1), 0, ScreenWidth, ScreenHeight)
            scrollView.addSubview(imageView)
            
            if i == 4 {
                let button = UIButton(frame: CGRect(imageView.right - 80.0 - 20.0,
                                                    ScreenWidth - C.tableCellHeight - 20.0,
                                                    80.0,
                                                    C.tableCellHeight))
                let image = UIImage.rect(C.maskBackgroundColor, size: CGSize(80.0, C.tableCellHeight))
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
        scrollView.contentSize = CGSize(width: 4 * ScreenWidth, height: ScreenHeight)
        
        pageControl.backgroundColor = C.maskBackgroundColor
    }
    
    //MARK: - 业务处理
    
    func changePageControl() {
        let quo = scrollView.contentOffset.x / ScreenWidth
        let page = lround(Double(quo)) as Int
        if pageControl.currentPage != page {
            pageControl.currentPage = page
        }
    }
    
    func next() {
        if UserStandard[UDKey.enterAggregationEntrance] == nil {
            srShow("ViewController", storyboard: "Main", animated: false)
            return;
        }
        
        Config.entrance = .aggregation
        
        SlideMenuOptions.leftViewWidth = 240.0
        let mainMenuVC = UIViewController.srViewController("MainMenuViewController", storyboard: "Aggregation")
            as! MainMenuViewController
        let leftMenuVC = UIViewController.srViewController("LeftMenuViewController", storyboard: "Aggregation")
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
        
        srShow(aggregationVC, animated: false)
    }
    
    //MARK: - 事件响应
    
    @objc func clickEnterButton(_ sender: Any) {
        guard MutexTouch else { return }
        next()
    }
    
    @objc func handleTap(_ gr: UITapGestureRecognizer) {
        guard MutexTouch else { return }
        next()
    }
    
    @IBAction func pageControlValueChanged(_ sender: Any) {
        scrollView.setContentOffset(CGPoint(ScreenWidth * CGFloat(pageControl.currentPage), 0),
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
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        changePageControl()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            changePageControl()
        }
    }
}
