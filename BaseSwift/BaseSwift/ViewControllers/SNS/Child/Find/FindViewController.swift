//
//  FindViewController.swift
//  BaseSwift
//
//  Created by Shadow on 2016/12/9.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import SRKit
import SwiftyJSON
import MJRefresh
//import MWPhotoBrowser

class FindViewController: BaseViewController, FindCellDelegate {
    public weak var parentVC: SNSViewController?
    var isTouched = false //视图已经被父视图载入过
    @IBOutlet weak var tableView: UITableView!
    private(set) var currentOffset = 0
    var selectedModel: MessageModel?
    private(set) var overlayAlpha = 0 as CGFloat
    
    @IBOutlet var tableHeaderView: UIView!
    @IBOutlet weak var headerImageView: UIImageView! //header背景图片的拉伸目前使用frame赋值实现，也可以用约束，只是相对麻烦点
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var headPortraitBackgroundView: UIView!
    @IBOutlet weak var headPortraitImageView: UIImageView!
    
    var headerImageSize: CGSize! //图片的尺寸
    var headerImageHeight: CGFloat! //图片的高度
    var headerImageHeightOffset: CGFloat! //图片比tableHeaderHeight多出的高度
    
    var refreshNewImageView: UIImageView!
    //weak var photoBrowser: MWPhotoBrowser?
    //var photoBrowserGR: UITapGestureRecognizer?
    //var photos: [MWPhoto] = []
    
    struct Const {
        static let tableHeaderHeight = screenSize().width * 10.0 / 16.0 as CGFloat
        static let nameFont = UIFont.system(16)
        static let nameTextColor =  UIColor(233.0, 233.0, 216.0)
        static let nameShadowColor = UIColor.black
        static let nameShadowOffset = CGSize(1.0, 1.0)
        static let preloadLastPostion = 1 //列表预加载的位置，从滑到倒数第1个cell时加载更多
        
        static let dragDiffForRefreshNew = 80.0 as CGFloat
        static let refreshNewWidth = 40.0 as CGFloat
        static let refreshNewHeight = refreshNewWidth
        static let refreshNewMarginLeft = 30.0 as CGFloat
        static let refreshNewFrameHidden = CGRect(refreshNewMarginLeft,
                                                  5.0 - refreshNewHeight,
                                                  refreshNewWidth,
                                                  refreshNewHeight)
        static let refreshNewFrameShown = CGRect(refreshNewMarginLeft,
                                                 62.0,
                                                 refreshNewWidth,
                                                 refreshNewHeight)
    }
    
    var loadDataState: SRLoadDataState?
    var loadDataViewHeight = 0 as CGFloat
    var loadingDataView = SRLoadDataStateView(.loading)
    var noDataView = SRLoadDataStateView(.empty)
    var loadDataFailView = SRLoadDataStateView(.fail)
    
    var dataArray: [MessageModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
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
        tableView.tableFooterView = UIView()
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        view.progressMaskColor = tableView.backgroundColor!
        tableView.mj_footer = MJRefreshBackNormalFooter(refreshingBlock: { [weak self] in
            self?.loadData(.more, progressType: .none)
        })
        tableView.mj_footer.endRefreshingWithNoMoreData()
        tableView.mj_footer.isHidden = true
        
        loadingDataView.backgroundColor = tableView.backgroundColor
        noDataView.backgroundColor = tableView.backgroundColor
        loadDataFailView.backgroundColor = tableView.backgroundColor
        loadDataFailView.delegate = self
        
        refreshNewImageView = UIImageView(frame: Const.refreshNewFrameHidden)
        var array = [] as [UIImage]
        for i in 0 ..< 30 {
            array.append(UIImage(named: "huaji_\(i)")!)
        }
        refreshNewImageView.animationImages = array
        refreshNewImageView.animationDuration = 1.0
        refreshNewImageView.animationRepeatCount = 0
        refreshNewImageView.alpha = 0
        view.addSubview(refreshNewImageView)
        
        FindCell.updateCellHeight()
        
        initTableHeaderView()
        showLoadingDataView()
        reloadProfile()
    }
    
    //MARK: tableHeaderView
    
    func initTableHeaderView() {
        var frame = tableHeaderView.frame
        frame.size.height = Const.tableHeaderHeight
        tableHeaderView.frame = frame
        
        //顶部背景图
        let imageFilePath = ResourceDirectory.appending(pathComponent: "image/snow_house.jpg")
        let image = UIImage(contentsOfFile: imageFilePath)
        headerImageSize = image?.size
        headerImageView.image = image
        headerImageView.contentMode = .scaleAspectFill
        headerImageView.clipsToBounds = true
        deviceOrientationDidChange()
        
        //头像
        headPortraitBackgroundView.backgroundColor = NavigationBar.backgroundColor
        
        //Name
        nameLabel.font = Const.nameFont
        nameLabel.textColor = Const.nameTextColor
        nameLabel.shadowColor = Const.nameShadowColor
        nameLabel.shadowOffset = Const.nameShadowOffset
        nameLabel.numberOfLines = 0
    }
    
    //MARK: Autorotate Orientation
    
    override func deviceOrientationDidChange(_ sender: AnyObject? = nil) {
        super.deviceOrientationDidChange(sender)
        
        headerImageHeight = ScreenWidth * headerImageSize.height / headerImageSize.width
        headerImageHeightOffset = headerImageHeight - Const.tableHeaderHeight
        headerImageView.frame =
            CGRect(0, -headerImageHeightOffset, ScreenWidth, headerImageHeight)
        
        loadDataViewHeight = ScreenHeight - Const.tableHeaderHeight - TabBarHeight
        if let loadDataState = loadDataState {
            var resultView: SRLoadDataStateView?
            switch loadDataState {
            case .loading:
                resultView = loadingDataView
            case .empty:
                resultView = noDataView
            case .fail:
                resultView = loadDataFailView
            default:
                break
            }
            resultView?.frame =
                CGRect(0, 0, ScreenWidth, max(loadDataViewHeight, noDataView.minHeight()))
            resultView?.layout()
            tableView.tableFooterView = resultView
        }
        tableView.reloadData()
    }
    
    //MARK: - 业务处理
    
    func reloadProfile() {
        let url = URL(string: NonNull.string(Common.currentProfile()?.headPortrait))
        headPortraitImageView.sd_setImage(with: url,
                                          placeholderImage: Configs.Resource.defaultHeadPortrait(.normal))
        nameLabel.text = Common.currentProfile()?.name?.fullName
    }
    
    func startRefreshNew() {
        guard !refreshNewImageView.isAnimating else {
            return
        }
        
        refreshNewImageView.startAnimating()
        refreshNewImageView.frame = Const.refreshNewFrameHidden
        refreshNewImageView.alpha = 0
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            self?.refreshNewImageView.frame = Const.refreshNewFrameShown
            self?.refreshNewImageView.alpha = 1.0
        }) { [weak self] (finished) in
            self?.loadData(.new, progressType: .none)
        }
    }
    
    func endRefreshNew() {
        guard refreshNewImageView.isAnimating else {
            return
        }
        
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            self?.refreshNewImageView.frame = Const.refreshNewFrameHidden
            self?.refreshNewImageView.alpha = 0
        }) { [weak self] (finished) in
            self?.refreshNewImageView.stopAnimating()
        }
    }
    
    func loadData(_ loadType: TableLoadData.Page, progressType: TableLoadData.ProgressType) {
        switch progressType {
        case .clearMask:
            view.showProgress()
        case .opaqueMask:
            view.showProgress(.opaque)
        default:
            break
        }
        
        var params = [:] as ParamDictionary
        params[Param.Key.limit] = TableLoadData.limit
        let offset = loadType == .more ? currentOffset + 1 : 0
        params[Param.Key.offset] = offset
        httpRequest(.get(.messages), success: { [weak self] response in
            guard let strongSelf = self else { return }
            let currentOffset = strongSelf.currentOffset
            if .more == loadType {
                if offset == currentOffset + 1 { //只刷新新的一页数据，旧的或者更新的不刷
                    strongSelf.updateMore(response as? JSON)
                }
            } else {
                strongSelf.updateNew(response as? JSON)
            }
            }, bfail: { [weak self] (url, response) in
                guard let strongSelf = self else { return }
                if .more == loadType {
                    if offset == strongSelf.currentOffset + 1 {
                        if !strongSelf.dataArray.isEmpty { //若当前有数据，则进行弹出提示框的交互，列表恢复刷新状态
                            strongSelf.updateMore(nil)
                        } else { //当前为空的话则交给列表展示错误信息，一般在加载更多的时候是不会走到这个逻辑的，因为空数据的时候上拉加载更多是被禁止的
                            strongSelf.updateMore(nil,
                                                  errMsg: strongSelf.logBFail(.get(.messages),
                                                                              response: response,
                                                                              show: false))
                        }
                    }
                } else {
                    if !strongSelf.dataArray.isEmpty { //若当前有数据，则进行弹出提示框的交互
                        strongSelf.updateNew(nil)
                    } else { //当前为空的话则交给列表展示错误信息
                        strongSelf.updateNew(nil, errMsg: strongSelf.logBFail(.get(.messages),
                                                                              response: response,
                                                                              show: false))
                    }
                }
            }, fail: { [weak self] (url, error) in
                guard let strongSelf = self else { return }
                if .more == loadType {
                    if offset == strongSelf.currentOffset + 1 {
                        if !strongSelf.dataArray.isEmpty { //若当前有数据，则进行弹出toast的交互，列表恢复刷新状态
                            strongSelf.updateMore(nil)
                        } else { //当前为空的话则交给列表展示错误信息，一般在加载更多的时候是不会走到这个逻辑的，因为空数据的时候上拉加载更多是被禁止的
                            strongSelf.updateMore(nil, errMsg: error.errorDescription)
                        }
                    }
                } else {
                    if !strongSelf.dataArray.isEmpty { //若当前有数据，则进行弹出toast的交互
                        strongSelf.updateNew(nil)
                    } else { //当前为空的话则交给列表展示错误信息
                        strongSelf.updateNew(nil, errMsg: error.errorDescription)
                    }
                }
        })
    }
    
    public func updateNew(_ json: JSON?, errMsg: String? = nil) {
        view.dismissProgress(true)
        endRefreshNew()
        guard let json = json?[HTTP.Key.Response.data] else {
            if dataArray.count == 0 {
                showLoadDataFailView(errMsg) //加载失败
                tableView.reloadData()
            }
            return
        }
        
        dataArray = messageModels(json[Param.Key.list])
        
        guard !dataArray.isEmpty else { //没有数据
            showNoDataView()
            tableView.reloadData()
            return
        }
        
        loadDataState = .none
        tableView.tableFooterView = UIView()
        
        tableView.mj_footer.isHidden = false
        if dataArray.isEmpty { //第一页即无数据
            tableView.mj_footer.endRefreshingWithNoMoreData()
        } else {
            tableView.mj_footer.resetNoMoreData()
        }
        
        currentOffset = 0 //页数重置
        tableView.reloadData()
        DispatchQueue.main.async { [weak self] in //tableView更新完数据后再设置contentOffset
            self?.tableView.setContentOffset(CGPoint(0, -(self?.tableView.contentInset.top)!),
                                             animated: true)
        }
    }
    
    public func updateMore(_ json: JSON?, errMsg: String? = nil) {
        view.dismissProgress(true)
        guard let json = json?[HTTP.Key.Response.data] else {
            if dataArray.count == 0 {
                showLoadDataFailView(errMsg) //加载失败
                tableView.reloadData()
            } else {
                tableView.mj_footer.endRefreshing()
            }
            return
        }
        
        let list = messageModels(json[Param.Key.list])
        if list.count == 0 {
            tableView.mj_footer.endRefreshingWithNoMoreData()
        } else {
            tableView.mj_footer.endRefreshing()
            tableView.mj_footer.resetNoMoreData()
        }
        
        loadDataState = .none
        tableView.mj_footer.isHidden = false
        
        //去重
        var array = [] as [MessageModel]
        list.forEach { model in
            if let index = (0 ..< dataArray.count).first(where: { model == dataArray[$0] }) {
                dataArray[index] = model //如果已经存在该数据，更新之
            } else { //否则添加到新的数据中
                array.append(model)
            }
        }
        
        currentOffset += 1 //自动增加页面
        dataArray += array //拼接数组
        tableView.reloadData()
    }
    
    func messageModels(_ list: JSON?) -> [MessageModel] {
        if let list = list, let models = list.array?.compactMap({ (JSON) -> MessageModel? in
            if let dictionary = JSON.dictionaryObject, let model = MessageModel(JSON: dictionary) {
                model.cellHeight = FindCell.cellHeight(model)
                model.cellHeightLandscape = FindCell.cellHeight(model,
                                                                interfaceOrientation: .landscape)
                return model
            }
            return nil
        }) {
            return models
        }
        return []
    }
    
    func showLoadingDataView() {
        loadDataState = .loading
        loadingDataView.frame =
            CGRect(0, 0, ScreenWidth, max(loadDataViewHeight, noDataView.minHeight()))
        loadingDataView.layout()
        tableView.mj_footer.endRefreshingWithNoMoreData()
        tableView.mj_footer.isHidden = true
        tableView.tableFooterView = loadingDataView
    }
    
    func showNoDataView() {
        loadDataState = .empty
        noDataView.frame =
            CGRect(0, 0, ScreenWidth, max(loadDataViewHeight, noDataView.minHeight()))
        noDataView.layout()
        tableView.mj_footer.endRefreshingWithNoMoreData()
        tableView.mj_footer.isHidden = true
        tableView.tableFooterView = noDataView
    }
    
    override func showLoadDataFailView(_ text: String?) {
        loadDataState = .fail
        loadDataFailView.text = text
        loadDataFailView.frame =
            CGRect(0, 0, ScreenWidth, max(loadDataViewHeight, loadDataFailView.minHeight()))
        loadDataFailView.layout()
        tableView.mj_footer.endRefreshingWithNoMoreData()
        tableView.mj_footer.isHidden = true
        tableView.tableFooterView = loadDataFailView
    }
    
    //MARK: - 事件响应
    
    func clickPhotoBrowser() {
        //guard MutexTouch else { return }
        //photoBrowser?.dismiss(animated: true) { [weak self] in
        //    self?.photoBrowser = nil
        //}
    }
    
    /*
     //MARK: - MWPhotoBrowserDelegate
     
     func numberOfPhotos(in photoBrowser: MWPhotoBrowser!) -> UInt {
     return UInt((selectedModel?.images?.count)!)
     }
     
     func photoBrowser(_ photoBrowser: MWPhotoBrowser!, photoAt index: UInt) -> MWPhotoProtocol! {
     if Int(index) < photos.count {
     return photos[Int(index)]
     }
     return nil
     }
     */
    
    //MARK: - FindCellDelegate
    
    func showImage(_ model: MessageModel?, index: Int) {
        selectedModel = model
        //guard let selectedModel = selectedModel, let images = selectedModel.images else {
        //    return
        //}
        
        /*
         let photoBrowser: MWPhotoBrowser = MWPhotoBrowser(delegate: self)
         photoBrowser.displayActionButton = false
         photoBrowser.displayNavArrows = false
         photoBrowser.displaySelectionButtons = false
         photoBrowser.alwaysShowControls = false
         photoBrowser.zoomPhotosToFill = true
         photoBrowser.enableGrid = false
         photoBrowser.startOnGrid = false
         photoBrowser.enableSwipeToDismiss = true
         photoBrowser.modalTransitionStyle = .crossDissolve
         photoBrowser.modalPresentationStyle = .popover
         var array = [] as [MWPhoto]
         images.forEach { array.append(MWPhoto(url: URL(string: NonNull.string($0)))) }
         photos = array
         photoBrowser.setCurrentPhotoIndex(UInt(index))
         self.photoBrowser = photoBrowser
         navigationController?.present(photoBrowser, animated: true, completion: { [weak self] in
         guard let strongSelf = self else { return }
         if let scrollView =
         strongSelf.photoBrowser?.view.subviews.first(where: { $0 is UIScrollView }) {
         //添加消失的手势
         if strongSelf.photoBrowserGR == nil {
         strongSelf.photoBrowserGR =
         UITapGestureRecognizer(target: strongSelf,
         action: #selector(strongSelf.clickPhotoBrowser))
         }
         scrollView.addGestureRecognizer(strongSelf.photoBrowserGR!)
         
         }
         })
         */
    }
    
    func showShareWebpage(_ model: MessageModel?) {
        if let model = model, let url = model.shareUrl, let URL = URL(string: url) {
            parentVC?.showWebpage(URL)
        }
    }
    
    func reloadTableView() {
        tableView.reloadData()
    }
    
    //MARK: - UIScrollViewDelegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = tableView.contentOffset.y
        let navigationBar = parentVC?.navigationController?.navigationBar
        if offset < 0 { //下拉到顶后
            var frame = headerImageView.frame
            if offset < -headerImageHeightOffset { //图片放大
                frame.origin.y = offset
                frame.size.height = Const.tableHeaderHeight - offset
                headerImageView.frame = frame
            } else if headerImageView.height != headerImageHeight { //图片恢复
                frame.origin.y = -headerImageHeightOffset
                frame.size.height = headerImageHeight
                headerImageView.frame = frame
            }
            
            //确保导航栏背景透明
            //            if navigationBar?.overlay.alpha !ikolp[';uiiol;= 0 {
            //                navigationBar?.overlay.alpha = 0
            //                overlayAlpha = (navigationBar?.overlay.alpha)!
            //            }
        } else { //上拉
            if headerImageView.height != headerImageHeight { //拉动幅度特别大，图片恢复
                var frame = headerImageView.frame
                frame.origin.y = -headerImageHeightOffset
                frame.size.height = headerImageHeight
                headerImageView.frame = frame
            }
            
            //在上拉至图片下端与导航栏下端齐平时，导航栏背景图片完全不透明
            let offsetMax = Const.tableHeaderHeight - NavigationHeaderHeight
            if offset >= offsetMax {
                //                if navigationBar?.overlay.alpha != 1.0 {
                //                    navigationBar?.overlay.alpha = 1.0
                //                    overlayAlpha = (navigationBar?.overlay.alpha)!
                //                }
            } else {//否则逐渐变得不透明
                //                navigationBar?.overlay.alpha = offset / offsetMax
                //                overlayAlpha = (navigationBar?.overlay.alpha)!
            }
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView.contentOffset.y <= -Const.dragDiffForRefreshNew {
            startRefreshNew()
        }
    }
    
    //MARK: - SRLoadDataStateDelegate
    
    override func retryLoadData() {
        //loadData(.new, progressType: .opaqueMask)
        startRefreshNew()
    }
}

//MARK: - UITableViewDelegate, UITableViewDataSource

extension FindViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.row < dataArray.count else {
            return 0
        }
        
        return UIApplication.shared.statusBarOrientation.isPortrait
            ? dataArray[indexPath.row].cellHeight
            : dataArray[indexPath.row].cellHeightLandscape
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArray.count
    }
    
    func tableView(_ tableView: UITableView,
                   willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {
        //实现预加载
        if indexPath.row == dataArray.count - Const.preloadLastPostion {
            //print("mj_footer.state: \(tableView.mj_footer.state.hashValue)")
            if tableView.mj_footer.state == .idle {
                tableView.mj_footer.beginRefreshing()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell =
            tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier) as? FindCell
        if cell == nil {
            cell = FindCell(style: .default, reuseIdentifier: ReuseIdentifier)
            cell?.delegate = self
            cell?.initView()
        }
        cell?.model = dataArray[indexPath.row]
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
