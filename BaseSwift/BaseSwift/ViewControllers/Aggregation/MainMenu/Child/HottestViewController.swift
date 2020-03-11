//
//  HottestViewController.swift
//  BaseSwift
//
//  Created by Gary on 2017/3/7.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import SRKit

class HottestViewController: BaseViewController {
    public weak var parentVC: MainMenuViewController? {
        didSet {
            newsListVCs.forEach { $0.delegate = parentVC }
        }
    }
    @IBOutlet weak var tabHeader: SRTabHeader!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var isSilent = false //scrollView左右滚动和停下时是否会触发tabHeader的事件
    
    var currentNewsListVC: NewsListViewController?
    var newsListVCs: [NewsListViewController] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        initView()
    }
    
    deinit {
        LogDebug("\(NSStringFromClass(type(of: self))).\(#function)")
        NotifyDefault.remove(self)
        if scrollView != nil {
            scrollView.delegate = nil
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Autorotate Orientation
    
    override func deviceOrientationDidChange(_ sender: AnyObject? = nil) {
        super.deviceOrientationDidChange(sender)
        
        tabHeader.layout()
        if let vc = currentNewsListVC, let channelId = vc.channelId {
            layoutNewsListVCs(channelId)
        }
    }
    
    //MARK: - 视图初始化
    
    struct Const {
        static let tabHeaderHeight = 40.0 as CGFloat
    }
    
    func initView() {
        initTabHeader()
        initScrollView()
    }
    
    func initTabHeader() {
        tabHeader.delegate = self
        tabHeader.frame =
            CGRect(0, 0, ScreenWidth, Const.tabHeaderHeight)
        tabHeader.titles = "Day,Week,Month".localized.components(separatedBy: ",")
        tabHeader.layout()
    }
    
    func initScrollView() {
        var array = [] as [NewsListViewController]
        for i in 0 ..< tabHeader.titles.count {
            let channel = ChannelModel()
            if i == 0 {
                channel.id = String(int: 5)
            } else if i == 1 {
                channel.id = String(int: 4)
            } else if i == 2 {
                channel.id = String(int: 7)
            } else {
                channel.id = String(int: 0)
            }
            let newsListVC = NewsMainViewController.createNewsListVC(channel)
            newsListVC.parentVC = self
            newsListVC.delegate = parentVC
            addChild(newsListVC)
            scrollView.addSubview((newsListVC.view)!)
            array.append(newsListVC)
        }
        
        newsListVCs = array
        let index = tabHeader != nil ? tabHeader.selectedIndex : 0
        let selectedChannelId =
            0 < index && index < newsListVCs.count ? newsListVCs[index].channelId : nil
        layoutNewsListVCs(selectedChannelId)
    }
    
    func layoutNewsListVCs(_ selectedChannelId: String?) {
        var selectedIndex = 0
        let count = newsListVCs.count
        for i in 0 ..< count {
            let vc = newsListVCs[i]
            vc.view.frame = CGRect(CGFloat(i) * ScreenWidth,
                                   0,
                                   ScreenWidth,
                                   scrollView.height)
            vc.tableView.contentInset = UIEdgeInsets(Const.tabHeaderHeight, 0, 0, 0)
            vc.contentInset = vc.tableView.contentInset
            if let channelId = vc.channelId, channelId == selectedChannelId {
                selectedIndex = i
            }
        }
        scrollView.contentSize = CGSize(ScreenWidth * CGFloat(count),
                                        scrollView.height)
        scrollView.setContentOffset(CGPoint(ScreenWidth * CGFloat(selectedIndex), 0),
                                    animated: false)
        currentNewsListVC = newsListVCs[selectedIndex]
    }
    
    //MARK: - 业务处理
    
    public func newsListVC(_ pointerString: String) -> NewsListViewController? {
        return newsListVCs.first { pointerString == String(pointer: $0) }
    }
    
    //MARK: - UIScrollViewDelegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !isSilent {
            var page = Int(scrollView.contentOffset.x / ScreenWidth)
            page = max(0, page)
            var offsetRate =
                (scrollView.contentOffset.x - CGFloat(page) * ScreenWidth) / ScreenWidth //向右偏移的比率
            offsetRate = max(0, offsetRate)
            offsetRate = min(1.0, offsetRate)
            tabHeader.update(page, offsetRate: offsetRate)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        resetAfterScrollViewDidEndScroll(scrollView)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            resetAfterScrollViewDidEndScroll(scrollView)
        }
    }
    
    func resetAfterScrollViewDidEndScroll(_ scrollView: UIScrollView) {
        let index = Int(scrollView.contentOffset.x / ScreenWidth)
        tabHeader.activeTab(index, animated: true)
        currentNewsListVC = newsListVCs[index]
        if !(currentNewsListVC?.isTouched)! {
            currentNewsListVC?.backToTopButtonBottomConstraint.constant = 0
            currentNewsListVC?.getDataArray(progressType: .clearMask)
        }
        isSilent = false
    }
}

//MARK: - SRTabHeaderDelegate

extension HottestViewController: SRTabHeaderDelegate {
    func tabHeader(_ tabHeader: SRTabHeader, didSelect index: Int) {
        let page = Int(scrollView.contentOffset.x / ScreenWidth)
        if page == index {
            currentNewsListVC = newsListVCs[index]
            if !(currentNewsListVC?.isTouched)! {
                currentNewsListVC?.getDataArray(progressType: .clearMask)
            }
        } else {
            let animated = abs(page - index) == 1 //页数差为1，添加切换动画
            scrollView.setContentOffset(CGPoint(CGFloat(index) * ScreenWidth, 0),
                                        animated: animated)
            isSilent = animated
            if !animated {
                currentNewsListVC = newsListVCs[index]
                if !(currentNewsListVC?.isTouched)! {
                    currentNewsListVC?.getDataArray(progressType: .clearMask)
                }
            }
        }
    }
}
