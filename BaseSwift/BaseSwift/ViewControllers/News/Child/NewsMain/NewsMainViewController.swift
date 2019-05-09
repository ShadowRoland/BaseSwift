//
//  NewsMainViewController.swift
//  BaseSwift
//
//  Created by Gary on 2016/12/28.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import SRKit
import Cartography
import TBIconTransitionKit
//import Spring

class NewsMainViewController: BaseViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout,
SRTabHeaderDelegate {
    public weak var parentVC: NewsViewController? {
        didSet {
            newsListVCs.forEach { $0.delegate = parentVC }
        }
    }
    @IBOutlet weak var searchHeaderView: UIView!
    @IBOutlet var searchHeaderGr: UITapGestureRecognizer!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var tabScrollHeaderView: UIView!
    @IBOutlet weak var tabAddGradientView: UIView!
    @IBOutlet weak var tabAddButton: TBAnimationButton!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var tabScrollHeaderBlurView: UIVisualEffectView!
    var tabScrollHeader: SRScrollTabHeader!
    var isSilent = false //scrollView左右滚动和停下时是否会触发tabScrollHeader的事件
    
    var currentNewsListVC: NewsListViewController?
    var newsListVCs: [NewsListViewController] = []
    
    @IBOutlet var channelEditBackgroundView: UIView!
    @IBOutlet var channelEditBackgroundBlurView: UIVisualEffectView!
    //@IBOutlet var channelEditView: SpringView!
    @IBOutlet var channelEditView: UIView!
    @IBOutlet var channelCollectionView: UICollectionView!
    var isChannelsEditing = false
    var isChannelsEdited = false //频道是否被编辑并保存过，若没有编辑并保存过，不需要更新主页列表
    var isEditViewAnimating = false
    var isEditViewShowing: Bool {
        return channelEditBackgroundView.superview != nil
    }
    
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
        if channelCollectionView != nil {
            channelCollectionView.dataSource = nil
            channelCollectionView.delegate = nil
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Autorotate Orientation
    
    override func deviceOrientationDidChange(_ sender: AnyObject? = nil) {
        super.deviceOrientationDidChange(sender)
        
        tabScrollHeader.layout()
        if let vc = currentNewsListVC, let channelId = vc.channelId {
            layoutNewsListVCs(channelId)
        }
        if isEditViewShowing {
            channelEditBackgroundView.frame =
                CGRect(0,
                       tabScrollHeaderView.frame.origin.y,
                       ScreenWidth,
                       view.height - tabScrollHeaderView.frame.origin.y)
            channelEditBackgroundBlurView.frame = channelEditBackgroundView.bounds
            channelEditView.frame = channelEditBackgroundView.frame
            channelCollectionView.frame =
                CGRect(Const.channelCollectionViewMarginHorizontal,
                       0,
                       channelEditView.width - 2.0 * Const.channelCollectionViewMarginHorizontal,
                       channelEditView.height)
            channelCollectionView.reloadData()
        }
    }
    
    //MARK: - 视图初始化
    
    struct Const {
        static let tabScrollHeaderHeight = 40.0 as CGFloat
        static let channelCollectionViewMarginHorizontal = SubviewMargin
        static let channelLabelMarginHorizontal = 12.0 as CGFloat
        static let channelLabelMarginVertical = 8.0 as CGFloat
        static let channelLabelFont = UIFont.system(15.0)
        static let channelCellEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 2.0, right: 2.0)
        static let channelLabelTotalMarginHorizontal = 2.0 * channelCollectionViewMarginHorizontal + 2.0 * channelLabelMarginHorizontal + channelCellEdgeInsets.left + channelCellEdgeInsets.right
        static let channelAnimationDuration = 0.5 as TimeInterval
    }
    
    func initView() {
        initSearchBar()
        initChannels()
        initTabScrollHeader()
        initChannelEdit()
    }
    
    func initSearchBar() {
        searchBar.barTintColor = UIColor.white
        if let ofClass = NSClassFromString("UISearchBarTextField") {
            let textField = searchBar.viewWithClass(ofClass) as? UITextField
            textField?.backgroundColor = UIColor.white
            textField?.layer.borderWidth = 1.0
            textField?.layer.borderColor = UIColor.lightGray.cgColor
            textField?.layer.cornerRadius = 5.0
            textField?.clipsToBounds = true
            textField?.leftViewMode = .always
        }
        
        if let ofClass = NSClassFromString("_UISearchBarSearchFieldBackgroundView"),
            let background = searchBar.viewWithClass(ofClass) as? UIImageView {
            background.image = nil
            background.backgroundColor = UIColor.white
            background.subviews.forEach {
                if let imageView = $0 as? UIImageView {
                    imageView.image = nil
                }
                $0.backgroundColor = UIColor.white
            }
        }
    }
    
    func initTabScrollHeader() {
        tabScrollHeaderBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        //tabScrollHeaderBlurView.frame = CGRect(0, 0, ScreenWidth, Const.tabScrollHeaderHeight)
        tabScrollHeaderView.backgroundColor = UIColor(white: 1.0, alpha: 0.6)
        tabScrollHeaderView.insertSubview(tabScrollHeaderBlurView, belowSubview: tabAddGradientView)
        constrain(tabScrollHeaderBlurView) { $0.edges == inset($0.superview!.edges, 0) }
        
        tabScrollHeader = SRScrollTabHeader()
        tabScrollHeader.delegate = self
        //tabScrollHeader.frame = tabScrollHeaderBlurView.frame
        tabScrollHeader.lastItemMarginRight = tabAddButton.bounds.size.width
        var titles = [] as [String]
        selectedChannels.forEach { titles.append(NonNull.string($0.name)) }
        tabScrollHeaderView.insertSubview(tabScrollHeader, aboveSubview: tabScrollHeaderBlurView)
        constrain(tabScrollHeader) { $0.edges == inset($0.superview!.edges, 0) }
        
        tabScrollHeader.titles = titles
        DispatchQueue.main.async { [weak self] in
            if let strongSelf = self {
                strongSelf.tabScrollHeader.layout()
                strongSelf.tabScrollHeader.activeTab(strongSelf.tabScrollHeader.selectedIndex,
                                                     animated: false)
            }
        }
        
        //为加号添加渐变背景色
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = tabAddGradientView.bounds
        //设置渐变颜色数组，可以加透明度的渐变，目前的效果是只有左边半个有渐变透明，右边不透明
        gradientLayer.colors = [UIColor(white: 1, alpha: 0.3).cgColor,
                                UIColor(white: 1, alpha: 0.8).cgColor,
                                UIColor(white: 1, alpha: 1.0).cgColor,
                                UIColor(white: 1, alpha: 1.0).cgColor]
        //设置渐变区域的起始和终止位置（范围为0-1）
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0)
        //设置蒙版，用来改变layer的透明度
        tabAddGradientView.layer.mask = gradientLayer
        tabAddButton.lineColor = UIColor.gray
        tabAddButton.lineWidth = tabAddButton.height / 3.0
        tabAddButton.currentState = .plus
    }
    
    func initChannels() {
        let dictionary: [AnyHashable : Any]?
        if let newsChannels = UserStandard[USKey.newsChannels] {
            dictionary = newsChannels as? [AnyHashable : Any]
        } else {
            let filePath = ResourceDirectory.appending(pathComponent: "json/debug/channels.json")
            dictionary = filePath.fileJsonObject as! [AnyHashable : Any]?
        }
        
        unselectedChannels = channelModels(NonNull.array(dictionary?["unselected"]))
        selectedChannels = channelModels(NonNull.array(dictionary?["selected"]))
    }
    
    func channelModels(_ dictionarys: [Any]) -> [ChannelModel] {
        return dictionarys.compactMap {
            guard let dictionary = $0 as? ParamDictionary,
                let channel = ChannelModel(JSON:dictionary) else {
                    return nil
            }
            channel.cellHeight = Const.channelLabelFont.lineHeight + 2.0 * Const.channelLabelMarginVertical
            var width = (channel.name ?? "").textSize(Const.channelLabelFont,
                                                      maxHeight: Const.channelLabelFont.lineHeight).width
            width = max(Const.channelLabelFont.lineHeight, ceil(width))
            width = min(screenSize().width - Const.channelLabelTotalMarginHorizontal, width)
            channel.cellWidth = width + 2.0 * Const.channelLabelMarginHorizontal
            return channel
        }
    }
    
    var unselectedChannels: [ChannelModel] = []
    var selectedChannels: [ChannelModel] = [] {
        didSet {
            guard selectedChannels != oldValue else { return}
            
            //获取当前选中的channelId
            let index = tabScrollHeader != nil ? tabScrollHeader.selectedIndex : 0
            let selectedChannelId =
                0 < index && index < newsListVCs.count ? newsListVCs[index].channelId : nil
            
            objc_sync_exit(selectedChannels)
            objc_sync_enter(newsListVCs)
            let array = selectedChannels.map { channel -> NewsListViewController in
                let channelId = NonNull.string(channel.id)
                //已存在的NewsListViewController就不用浪费重新添加了
                if let newsListVC = newsListVCs.first(where: { channelId == $0.channelId }) {
                    return newsListVC
                } else {
                    //重新创建一个新的NewsListViewController
                    let newsListVC = NewsMainViewController.createNewsListVC(channel)
                    newsListVC.parentVC = self
                    newsListVC.delegate = parentVC
                    addChild(newsListVC)
                    scrollView.addSubview(newsListVC.view)
                    return newsListVC
                }
            }
            
            //remove旧的vc
            newsListVCs.forEach { vc in
                if !array.contains(vc) {
                    vc.removeFromParent()
                    vc.view.removeFromSuperview()
                }
            }
            
            newsListVCs = array
            layoutNewsListVCs(selectedChannelId)
            
            objc_sync_exit(newsListVCs)
            objc_sync_exit(selectedChannels)
        }
    }
    var editingSelectedChannels: [ChannelModel] = []
    var editingUnselectedChannels: [ChannelModel] = []
    var editingSelectedChannelId: String?
    
    public class func createNewsListVC(_ channel: ChannelModel) -> NewsListViewController {
        let vc =
            UIViewController.viewController("NewsListViewController",
                                  storyboard: "News") as! NewsListViewController
        vc.channelId = channel.id
        
        //设置不同参数以尽量让每个分页显示不同的新闻
        var params = [:] as ParamDictionary
        params[Param.Key.jsonCallback] = "callback"
        params[Param.Key.callback] = "callback"
        var newsType = "news"
        var id = 0
        if let channelId = vc.channelId, let intValue = Int(channelId) {
            id = intValue % 10 + 1 //力求相邻的频道内容不同，做了区分
        }
        switch id {
        case 1:
            newsType = "news" //新浪新闻
        case 2:
            //http://interface.sina.cn/ent/feed.d.json?ch=sports&col=sports&act=more&t=1483426856149&show_num=10&page=2&jsoncallback=callback&_=1483426856152&callback=callback
            newsType = "sports" //新浪体育
        case 3:
            //http://interface.sina.cn/ent/feed.d.json?ch=ent&col=ent&act=more&t=1483426977479&show_num=10&page=2&jsoncallback=callback&_=1483426977483&callback=callback
            newsType = "ent" //新浪娱乐
        case 4:
            //http://interface.sina.cn/ent/feed.d.json?ch=mil&col=mil&act=more&t=1483427004909&show_num=10&page=2&jsoncallback=callback&_=1483427004913&callback=callback
            newsType = "mil" //新浪军事
        case 5:
            //http://interface.sina.cn/ent/feed.d.json?ch=edu&col=edu&show_num=20&page=2&act=more&jsoncallback=callbackFunction&_=1483427071299&callback=jsonp1
            newsType = "edu" //新浪教育
            params[Param.Key.jsonCallback] = "callbackFunction"
            params[Param.Key.callback] = "jsonp1"
        case 6:
            //http://interface.sina.cn/ent/feed.d.json?ch=blog&col=blog&act=more&jsoncallback=jsonpCallback_0&t=1483427113039&show_num=10&page=2&_=1483427113040&callback=jsonp2
            newsType = "blog" //新浪博客
            params[Param.Key.jsonCallback] = "jsonpCallback_0"
            params[Param.Key.callback] = "jsonp2"
        case 76:
            //https://interface.sina.cn/ent/feed.d.json?ch=tech&col=tech&act=more&t=1483427997896&show_num=10&page=2&jsoncallback=callback&_=1483427997899&callback=callback
            newsType = "tech" //新浪科技
        case 8:
            //http://interface.sina.cn/ent/feed.d.json?ch=fashion&col=fashion&show_num=20&page=2&act=more&jsoncallback=callbackFunction&_=1483428211812&callback=jsonp1
            newsType = "fashion" //新浪时尚
            params[Param.Key.jsonCallback] = "callbackFunction"
            params[Param.Key.callback] = "jsonp1"
        case 9:
            //http://interface.sina.cn/ent/feed.d.json?ch=ast&col=ast&show_num=20&page=2&act=more&jsoncallback=callbackFunction&_=1483428277357&callback=jsonp1
            newsType = "ast" //新浪星座
            params[Param.Key.jsonCallback] = "callbackFunction"
            params[Param.Key.callback] = "jsonp1"
        case 10:
            //http://interface.sina.cn/ent/feed.d.json?ch=eladies&col=eladies&show_num=20&page=2&act=more&jsoncallback=callbackFunction&_=1483428333950&callback=jsonp1
            newsType = "eladies" //新浪女性
            params[Param.Key.jsonCallback] = "callbackFunction"
            params[Param.Key.callback] = "jsonp1"
        default:
            break
        }
        params["ch"] = newsType
        params["col"] = newsType
        vc.params = params
        return vc
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
            vc.tableView.contentInset =
                UIEdgeInsets(top: Const.tabScrollHeaderHeight, left: 0, bottom: TabBarHeight, right: 0)
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
    
    func initChannelEdit() {
        channelEditBackgroundView.removeFromSuperview()
        channelEditView.removeFromSuperview()
        channelCollectionView.alwaysBounceVertical = true
        let gr = UILongPressGestureRecognizer(target: self,
                                              action: #selector(handleLongPressed(_:)))
        channelCollectionView.addGestureRecognizer(gr)
    }
    
    //MARK: - 业务处理
    
    public func newsListVC(_ pointerString: String) -> NewsListViewController? {
        return newsListVCs.first { pointerString == String(pointer: $0) }
    }
    
    func showChannelEditView() {
        channelCollectionView.reloadData()
        isEditViewAnimating = true
        editingSelectedChannels = selectedChannels
        editingUnselectedChannels = unselectedChannels
        editingSelectedChannelId = nil
        
        tabAddButton.animationTransform(to: .cross)
        
        view.insertSubview(channelEditBackgroundView, belowSubview: tabAddGradientView)
        channelEditBackgroundView.alpha = 1.0
        channelEditBackgroundView.frame =
            CGRect(0,
                   tabScrollHeaderView.frame.origin.y,
                   ScreenWidth,
                   view.height - tabScrollHeaderView.frame.origin.y)
        channelEditBackgroundBlurView.frame = channelEditBackgroundView.bounds
        
        view.insertSubview(channelEditView, belowSubview: tabAddGradientView)
        channelEditView.frame = channelEditBackgroundView.frame
        channelCollectionView.frame =
            CGRect(Const.channelCollectionViewMarginHorizontal,
                   0,
                   channelEditView.width - 2.0 * Const.channelCollectionViewMarginHorizontal,
                   channelEditView.height)
//        channelEditView.animation = Spring.AnimationPreset.SlideDown.rawValue
//        channelEditView.animateNext(completion: { [weak self] in
//            self?.isEditViewAnimating = false
//            self?.searchHeaderView.addGestureRecognizer((self?.searchHeaderGr)!)
//            self?.searchButton.isUserInteractionEnabled = false
//        })
        UIView.animate(withDuration: Const.channelAnimationDuration, animations: { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.parentVC?.tabBarBottomConstraint.constant = -TabBarHeight
            strongSelf.parentVC?.view.layoutIfNeeded()
            
            strongSelf.isEditViewAnimating = false
            strongSelf.searchHeaderView.addGestureRecognizer(strongSelf.searchHeaderGr)
            strongSelf.searchButton.isUserInteractionEnabled = false
        })
    }
    
    func hideChannelEditView() {
        isChannelsEditing = false
        if isChannelsEdited {
            isChannelsEdited = false
            var selected = [] as [ParamDictionary]
            editingSelectedChannels.forEach { selected.append($0.toJSON()) }
            var unselected = [] as [ParamDictionary]
            editingUnselectedChannels.forEach { unselected.append($0.toJSON()) }
            UserStandard[USKey.newsChannels] = ["selected" : selected, "unselected" : unselected]
            
            var selectedChannelId: String?
            if let vc = currentNewsListVC, let channelId = vc.channelId {
                selectedChannelId = channelId
            }
            if editingSelectedChannelId != nil {
                selectedChannelId = editingSelectedChannelId!
            }
            var selectedIndex = 0
            var titles = [] as [String]
            for i in 0 ..< editingSelectedChannels.count {
                let channel = editingSelectedChannels[i]
                titles.append(NonNull.string(channel.name))
                if channel.id == selectedChannelId {
                    selectedIndex = i
                }
            }
            
            unselectedChannels = editingUnselectedChannels
            selectedChannels = editingSelectedChannels
            
            tabScrollHeader.titles = titles
            tabScrollHeader.layout()
            tabScrollHeader.activeTab(selectedIndex, animated: false)
            tabHeader(tabScrollHeader, didSelect: selectedIndex)
        } else { //单击跳转
            var selectedChannelId: String?
            if let vc = currentNewsListVC, let channelId = vc.channelId {
                selectedChannelId = channelId
            }
            if editingSelectedChannelId != nil {
                selectedChannelId = editingSelectedChannelId!
            }
            var selectedIndex = 0
            for i in 0 ..< selectedChannels.count {
                if editingSelectedChannels[i].id == selectedChannelId {
                    selectedIndex = i
                }
            }
            tabScrollHeader.activeTab(selectedIndex, animated: true)
            tabHeader(tabScrollHeader, didSelect: selectedIndex)
        }
        
        channelCollectionView.reloadData()
        
        isEditViewAnimating = true
        tabAddButton.animationTransform(to: .plus)
        let frame = channelEditView.frame.offsetBy(dx: 0, dy: -channelEditView.height)
        UIView.animate(withDuration: Const.channelAnimationDuration, animations: { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.channelEditView.frame = frame
            strongSelf.channelEditBackgroundView.alpha = 0
            strongSelf.parentVC?.tabBarBottomConstraint.constant = 0
            strongSelf.parentVC?.view.layoutIfNeeded()
            }, completion: { [weak self] finished in
                guard finished, let strongSelf = self else { return }
                
                strongSelf.isEditViewAnimating = false
                strongSelf.channelEditView.removeFromSuperview()
                strongSelf.channelEditBackgroundView.removeFromSuperview()
                strongSelf.searchButton.isUserInteractionEnabled = true
                strongSelf.searchHeaderView.removeGestureRecognizer(strongSelf.searchHeaderGr)
        })
    }
    
    //MARK: - 事件响应
    
    @IBAction func handleSearchHeaderTap(_ sender: Any) {
        clickTabAddButton(tabAddButton as Any)
    }
    
    @IBAction func clickSearchButton(_ sender: Any) {
        guard MutexTouch else { return }
        show("NewsSearchViewController", storyboard: "News")
    }
    
    @IBAction func clickTabAddButton(_ sender: Any) {
        guard MutexTouch && !isEditViewAnimating else { return }
        
        if !isEditViewShowing {
            showChannelEditView()
        } else {
            hideChannelEditView()
        }
    }
    
    @objc func handleLongPressed(_ gr: UILongPressGestureRecognizer) {
        //判断手势状态
        switch (gr.state) {
        case .began:
            if !isChannelsEditing {
                isChannelsEditing = true
                channelCollectionView.reloadData()
            }
            //判断手势落点位置是否在路径上
            if let indexPath = channelCollectionView.indexPathForItem(at: gr.location(in: channelCollectionView)) {
                if !(indexPath.section == 0 && indexPath.row == 0) {
                    channelCollectionView.beginInteractiveMovementForItem(at: indexPath) //在路径上则开始移动该路径上的cell
                }
            }
        case .changed:
            if let indexPath = channelCollectionView.indexPathForItem(at: gr.location(in: channelCollectionView)),
                indexPath.section == 0 && indexPath.row == 0 {
                break
            }
            //移动过程当中随时更新cell位置
            channelCollectionView.updateInteractiveMovementTargetPosition(gr.location(in: channelCollectionView))
        case .ended:
            //移动结束后关闭cell移动
            channelCollectionView.endInteractiveMovement()
        default:
            channelCollectionView.cancelInteractiveMovement()
            break
        }
    }
    
    @objc func clickChannelEditButton(_ sender: Any) {
        guard MutexTouch && !isEditViewAnimating else { return }
        if isChannelsEditing {
            isChannelsEdited = true
        }
        isChannelsEditing = !isChannelsEditing
        channelCollectionView.reloadData()
    }
    
    @objc func clickChannelCloseButton(_ sender: Any) {
        guard MutexTouch else { return }
        let indexPath = IndexPath(row: (sender as! UIButton).tag, section: 0)
        let channel = editingSelectedChannels[indexPath.row]
        editingSelectedChannels.remove(at: indexPath.row)
        editingUnselectedChannels.insert(channel, at: 0)
        channelCollectionView.performBatchUpdates({ [weak self] in
            self?.channelCollectionView.moveItem(at: indexPath, to: IndexPath(row: 0, section: 1))
        }) { [weak self] (finished) in
            self?.channelCollectionView.reloadData()
        }
    }
    
    //MARK: - SRTabHeaderDelegate
    
    func tabHeader(_ tabHeader: SRTabHeader, didSelect index: Int) {
        let page = Int(scrollView.contentOffset.x / ScreenWidth)
        if page == index {
            currentNewsListVC = newsListVCs[index]
            if !(currentNewsListVC?.isTouched)! {
                currentNewsListVC?.loadData(progressType: .clearMask)
            }
        } else {
            let animated = abs(page - index) == 1 //页数差为1，添加切换动画
            isSilent = animated
            scrollView.setContentOffset(CGPoint(CGFloat(index) * ScreenWidth, 0),
                                        animated: animated)
            if !animated {
                currentNewsListVC = newsListVCs[index]
                if !(currentNewsListVC?.isTouched)! {
                    DispatchQueue.main.async { [weak self] in
                        self?.currentNewsListVC?.loadData(progressType: .clearMask)
                    }
                }
            }
        }
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
            tabScrollHeader.update(page, offsetRate: offsetRate)
        }
    }
    
    //列表停止滑动后恢复图片下载
    func scrollViewDidEndDragging(_ scrollView: UIScrollView,
                                           willDecelerate decelerate: Bool) {
        if !decelerate {
            resetAfterScrollViewDidEndScroll(scrollView)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        resetAfterScrollViewDidEndScroll(scrollView)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        resetAfterScrollViewDidEndScroll(scrollView)
    }
    
    func resetAfterScrollViewDidEndScroll(_ scrollView: UIScrollView) {
        let index = Int(scrollView.contentOffset.x / ScreenWidth)
        tabScrollHeader.activeTab(index, animated: true)
        currentNewsListVC = newsListVCs[index]
        if !(currentNewsListVC?.isTouched)! {
            DispatchQueue.main.async { [weak self] in
                self?.currentNewsListVC?.loadData(progressType: .clearMask)
            }
        }
        isSilent = false
    }
    
    // MARK: - UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        let header =
            collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                            withReuseIdentifier: ReuseIdentifier,
                                                            for: indexPath) as! CollectionHeader
        if indexPath.section == 0 {
            header.titleLabel.text = "Current Channels".localized
            header.editButton.isHidden = false
            header.editButton.setTitle((isChannelsEditing ? "Done" : "Edit").localized,
                                       for: .normal)
            if !header.editButton.allTargets.contains(self) {
                header.editButton.clicked(self, action: #selector(clickChannelEditButton(_:)))
            }
        } else {
            header.titleLabel.text = "Channels Recommend".localized
            header.editButton.isHidden = true
        }
        return header
    }
    
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return section == 0 ? editingSelectedChannels.count : editingUnselectedChannels.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReuseIdentifier,
                                                      for: indexPath) as! ChannelCell
        if !cell.closeButton.allTargets.contains(self) {
            cell.closeButton.clicked(self, action: #selector(clickChannelCloseButton(_:)))
        }
        let channels = indexPath.section == 0 ? editingSelectedChannels : editingUnselectedChannels
        let channel = channels[indexPath.row]
        cell.textLabel.text = channel.name
        cell.textLabel.textColor = tabScrollHeader.unselectedTextColor
        let isFirst = indexPath.section == 0 && indexPath.row == 0
        if isFirst {
            cell.textLabel.textColor = UIColor.darkGray
        }
        if let vc = currentNewsListVC,
            let channelId = vc.channelId,
            channelId == channel.id {
            cell.textLabel.textColor = tabScrollHeader.selectedTextColor
        }
        
        if !isChannelsEditing {
            cell.closeButton.isHidden = true
        } else {
            cell.closeButton.isHidden = !(indexPath.section == 0 && !isFirst)
        }
        cell.closeButton.tag = indexPath.row
        cell.cellSize = CGSize(channel.cellWidth, channel.cellHeight)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        canMoveItemAt indexPath: IndexPath) -> Bool {
        guard isChannelsEditing else {
            return false
        }
        return !(indexPath.section == 0 && indexPath.row == 0)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        moveItemAt sourceIndexPath: IndexPath,
                        to destinationIndexPath: IndexPath) {
        var fromChannels =
            sourceIndexPath.section == 0 ? editingSelectedChannels : editingUnselectedChannels
        var toChannels =
            destinationIndexPath.section == 0 ? editingSelectedChannels : editingUnselectedChannels
        if fromChannels == toChannels { //前后相同，只需要交换位置
            let channel = fromChannels[sourceIndexPath.row]
            fromChannels[sourceIndexPath.row] = fromChannels[destinationIndexPath.row]
            fromChannels[destinationIndexPath.row] = channel
            if sourceIndexPath.section == 0 {
                editingSelectedChannels = fromChannels
            } else {
                editingUnselectedChannels = fromChannels
            }
        } else {
            let channel = fromChannels[sourceIndexPath.row]
            fromChannels.remove(at: sourceIndexPath.row)
            toChannels.insert(channel, at: destinationIndexPath.row)
            if sourceIndexPath.section == 0 {
                editingSelectedChannels = fromChannels
                editingUnselectedChannels = toChannels
            } else {
                editingUnselectedChannels = fromChannels
                editingSelectedChannels = toChannels
            }
        }
        collectionView.reloadData()
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let cell = collectionView.cellForItem(at: indexPath) { //拖拽时逻辑判断有效
            return (cell as! ChannelCell).cellSize
        }
        let channels = indexPath.section == 0 ? editingSelectedChannels : editingUnselectedChannels
        if indexPath.row < channels.count {
            return CGSize(channels[indexPath.row].cellWidth, channels[indexPath.row].cellHeight)
        }
        return CGSize(TableCellHeight, TableCellHeight) //必须提供一个默认值，不然若从不同section中拖拽一个cell，会crash
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return Const.channelCellEdgeInsets
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(channelCollectionView.width, tabScrollHeaderView.height)
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView,
                        shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return !(isEditing && indexPath.section == 0 && indexPath.row == 0)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard MutexTouch && !isEditViewAnimating else { return }
        
        if !isChannelsEditing && indexPath.section == 0 {
            let channel = editingSelectedChannels[indexPath.row]
            editingSelectedChannelId = channel.id
            hideChannelEditView()
        }
        
        if isChannelsEditing && indexPath.section == 1 {
            let channel = editingUnselectedChannels[indexPath.row]
            editingUnselectedChannels.remove(at: indexPath.row)
            editingSelectedChannels.append(channel)
            collectionView.performBatchUpdates({
                collectionView.moveItem(at: indexPath,
                                        to: IndexPath(row: self.editingSelectedChannels.count - 1,
                                                      section: 0))
            }, completion: { (finished) in
                collectionView.reloadData()
            })
            
        }
    }
}

