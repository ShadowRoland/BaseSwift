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
import IDMPhotoBrowser

class FindViewController: BaseTableViewController, FindCellDelegate {
    public weak var parentVC: SNSViewController?
    var isTouched = false //视图已经被父视图载入过
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
    
    struct Const {
        static let tableHeaderHeight = C.screenSize().width * 10.0 / 16.0 as CGFloat
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        initView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - 视图初始化
    
    func initView() {
        initTableHeaderView()
        layoutHeaderImage()
        tableView.contentInset = UIEdgeInsets(C.navigationBarHeight(), 0, C.tabBarHeight(), 0)
        needAddMoreFooter = true
        view.progressMaskColor = tableView.backgroundColor!
        
        refreshNewImageView = UIImageView(frame: Const.refreshNewFrameHidden)
        refreshNewImageView.animationImages = SRProgressHUD.defaultGif?.images
        refreshNewImageView.animationDuration = SRProgressHUD.defaultGif!.duration
        refreshNewImageView.animationRepeatCount = 0
        refreshNewImageView.alpha = 0
        view.addSubview(refreshNewImageView)
        
        FindCell.updateCellHeight()
        
        reloadProfile()
    }
    
    func layoutHeaderImage() {
        headerImageHeight = ScreenWidth * headerImageSize.height / headerImageSize.width
        headerImageHeightOffset = headerImageHeight - Const.tableHeaderHeight
        headerImageView.frame =
            CGRect(0, -headerImageHeightOffset, ScreenWidth, headerImageHeight)
    }
    
    //MARK: tableHeaderView
    
    func initTableHeaderView() {
        var frame = tableHeaderView.frame
        frame.size.height = Const.tableHeaderHeight
        tableHeaderView.frame = frame
        
        //顶部背景图
        let imageFilePath = C.resourceDirectory.appending(pathComponent: "image/snow_house.jpg")
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
        
        layoutHeaderImage()
        if let view = tableView.tableFooterView as? SRSimplePromptView {
            view.frame =
                CGRect(0,
                       0,
                       ScreenWidth,
                       ScreenHeight - C.navigationBarHeight() - Const.tableHeaderHeight - C.tabBarHeight())
            tableView.tableFooterView = view
        }
        tableView.reloadData()
    }
    
    //MARK: - 业务处理
    
    override func performViewDidLoad() {
        showLoadPromptView("Loading ...".localized, image: UIImage("loading"))
        (tableView.tableFooterView as? SRSimplePromptView)?.delegate = nil
    }
    
    func reloadProfile() {
        let url = URL(string: NonNull.string(ProfileManager.currentProfile?.headPortrait))
        headPortraitImageView.sd_setImage(with: url,
                                          placeholderImage: Config.Resource.defaultHeadPortrait(.normal))
        nameLabel.text = ProfileManager.currentProfile?.name?.fullName
    }
    
    enum RefreshState: Int {
        case idle
        case busy
        case started
    }
    
    private var needStartRefresh = false
    private var refreshState: RefreshState = .idle
    
    func startRefreshNew() {
        guard refreshState != .idle else {
            needStartRefresh = true
            return
        }
        
        refreshState = .busy
        refreshNewImageView.startAnimating()
        refreshNewImageView.frame = Const.refreshNewFrameHidden
        refreshNewImageView.alpha = 0
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            self?.refreshNewImageView.frame = Const.refreshNewFrameShown
            self?.refreshNewImageView.alpha = 1.0
        }) { [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.getDataArray(progressType: .none)
            strongSelf.refreshState = .started
            if !strongSelf.needStartRefresh {
                DispatchQueue.main.async { [weak self] in
                    self?.endRefreshNew()
                }
            }
        }
    }
    
    func endRefreshNew() {
        guard refreshState != .started else {
            needStartRefresh = false
            return
        }
        
        refreshState = .busy
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            self?.refreshNewImageView.frame = Const.refreshNewFrameHidden
            self?.refreshNewImageView.alpha = 0
        }) { [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.refreshNewImageView.stopAnimating()
            strongSelf.refreshState = .idle
            if strongSelf.needStartRefresh {
                DispatchQueue.main.async { [weak self] in
                    self?.startRefreshNew()
                }
            }
        }
    }
    
    func showLoadPromptView(_ text: String?, image: UIImage?) {
        let view = SRSimplePromptView(text, image: image)
        view.frame = CGRect(0, 0, ScreenWidth, ScreenHeight - C.navigationBarHeight() - Const.tableHeaderHeight - C.tabBarHeight())
        view.delegate = self
        view.backgroundColor = tableView.backgroundColor
        tableView.tableFooterView = view
        tableView.mj_footer.endRefreshingWithNoMoreData()
        tableView.mj_footer.isHidden = true
    }
    
    //MARK: - 事件响应
    
    func clickPhotoBrowser() {
        //guard MutexTouch else { return }
        //photoBrowser?.dismiss(animated: true) { [weak self] in
        //    self?.photoBrowser = nil
        //}
    }
    
    //MARK: - BaseTableLoadData
    
    @IBOutlet weak var _tableView: UITableView!
    public override var tableView: UITableView {
        return _tableView
    }
    
    private var _dataEqual: ((Any, Any) -> Bool) = { ($0 as! MessageModel) == ($1 as! MessageModel) }
    public override var dataEqual: ((Any, Any) -> Bool)? {
        get { return _dataEqual }
        set { }
    }
    
    override func showNoDataView() {
        showLoadPromptView("No record".localized, image: UIImage("no_data"))
        tableView.mj_footer?.endRefreshingWithNoMoreData()
        tableView.mj_footer?.isHidden = true
    }
    
    override func showLoadDataFailView(_ text: String?,
                                       image: UIImage? = nil,
                                       insets: UIEdgeInsets? = nil) {
        showLoadPromptView(text, image: UIImage("request_fail"))
        tableView.mj_footer?.endRefreshingWithNoMoreData()
        tableView.mj_footer?.isHidden = true
    }
    
    func getDataArray(_ addMore: Bool) {
        getDataArray(addMore, progressType: .none)
    }
    
    func getDataArray(_ addMore: Bool = false,
                      progressType: TableLoadData.ProgressType = .opaqueMask) {
        switch progressType {
        case .clearMask:
            showProgress()
        case .opaqueMask:
            showProgress(.opaque)
        default:
            break
        }
        
        var params = [:] as ParamDictionary
        params[Param.Key.limit] = TableLoadData.limit
        let offset = addMore ? currentOffset + 1 : 0
        params[Param.Key.offset] = offset
        httpRequest(.get("data/getMessages", params: params), success: { [weak self] response in
            guard let strongSelf = self else { return }
            if offset == 0 || offset == strongSelf.currentOffset + 1 {
                strongSelf.endRefreshNew()
            }
            if let json = response as? JSON,
                let array = json[HTTP.Key.Response.data][Param.Key.list].array {
                let models = array.compactMap({ (element) -> MessageModel? in
                    if let dictionary = element.dictionaryObject {
                        let model = MessageModel(JSON: dictionary)!
                        model.cellHeight = FindCell.cellHeight(model)
                        model.cellHeightLandscape = FindCell.cellHeight(model,
                                                                        isLandscape: true)
                        return model
                    } else {
                        return nil
                    }
                })
                strongSelf.httpRespond(success: models, offset: 0)
            } else {
                strongSelf.httpRespond(success: [], offset: 0)
            }
        }) { [weak self] failure in
            guard let strongSelf = self else { return }
            if offset == 0 || offset == strongSelf.currentOffset + 1 {
                strongSelf.endRefreshNew()
            }
            strongSelf.httpRespond(failure: failure, offset: offset)
        }
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
        guard let selectedModel = selectedModel,
            let images = selectedModel.images,
            let browser = IDMPhotoBrowser(photoURLs: images.compactMap({ URL(string: $0) })) else {
                return
        }
        
        browser.displayActionButton = false
//        browser.displayArrowButton = false
        browser.displayCounterLabel = false
        browser.displayDoneButton = false
        browser.disableVerticalSwipe = true
        browser.dismissOnTouch = true
        navigationController?.present(browser, animated: true, completion: nil)
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
            //            if navigationBar?.overlay.alpha {
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
            let offsetMax = Const.tableHeaderHeight - C.navigationHeaderHeight()
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
    
    //MARK: - SRSimplePromptDelegate
    
    override func didClickSimplePromptView(_ view: SRSimplePromptView) {
        startRefreshNew()
    }

    //MARK: - UITableViewDelegate, UITableViewDataSource

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.row < dataArray.count else {
            return 0
        }
        
        let message = dataArray[indexPath.row] as! MessageModel
        return UIApplication.shared.statusBarOrientation.isPortrait
            ? message.cellHeight
            : message.cellHeightLandscape
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell =
            tableView.dequeueReusableCell(withIdentifier: C.reuseIdentifier) as? FindCell
        if cell == nil {
            cell = FindCell(style: .default, reuseIdentifier: C.reuseIdentifier)
            cell?.delegate = self
            cell?.initView()
        }
        cell?.model =
            indexPath.row < dataArray.count ? dataArray[indexPath.row] as? MessageModel : nil
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
