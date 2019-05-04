//
//  SimpleTableViewController.swift
//  BaseSwift
//
//  Created by Gary on 2017/6/12.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import SRKit
import SwiftyJSON
import MJRefresh

class SimpleTableViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var tableHeaderView: UIView!
    @IBOutlet weak var tableHeaderScrollView: UIScrollView!
    
    var currentOffset = 0
    var noDataView = SRLoadDataStateView(.empty)
    var loadDataFailView = SRLoadDataStateView(.fail)
    
    var images: [String] = []
    var dataArray: [ParamDictionary] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        defaultNavigationBar("List".localized)
        initView()
        
        baseBusinessComponent.progressContainerView.progressMaskColor =
            UIColor.groupTableViewBackground
        showProgress(.opaque)
        getSimpleList()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - 视图初始化
    
    struct Const {
        static let headerImageHeight = screenSize().width * 548.0 / 1080.0 as CGFloat
    }
    
    func initView() {
        setNavigationBarRightButtonItems()
        
        tableView.backgroundColor = UIColor.groupTableViewBackground
        tableView.tableHeaderView = nil
        tableHeaderView.frame = CGRect(0, 0, screenSize().width, Const.headerImageHeight)
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets()
        
        //Refresh header & footer
        tableView.mj_header = MJRefreshNormalHeader(refreshingBlock: { [weak self] in
            self?.getSimpleList()
        })
        tableView.mj_header.endRefreshing()
        tableView.mj_footer = MJRefreshBackNormalFooter(refreshingBlock: { [weak self] in
            self?.getSimpleList(.more)
        })
        tableView.mj_footer.endRefreshingWithNoMoreData()
        tableView.mj_footer.isHidden = true
        
        noDataView.backgroundColor = tableView.backgroundColor
        loadDataFailView.backgroundColor = tableView.backgroundColor
        loadDataFailView.delegate = self
    }
    
    func setNavigationBarRightButtonItems() {
        var setting = NavigationBar.buttonFullSetting
        setting[.style] = NavigationBar.ButtonItemStyle.text
        setting[.title] = "Submit".localized
        navBarRightButtonSettings = [setting]
    }
    
    //MARK: - Autorotate Orientation
    
    override var shouldAutorotate: Bool { return false }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    //MARK: - 业务处理
    
    func updateHeaderImages(_ images: [String]? = []) {
        guard images! != self.images else {
            return
        }
        
        self.images = images!
        tableHeaderScrollView.subviews.forEach { $0.removeFromSuperview() }
        if self.images.isEmpty {
            tableView.tableHeaderView = nil
            return
        }
        
        tableView.tableHeaderView = tableHeaderView
        let count = self.images.count
        for i in 0 ..< count {
            let url = self.images[i]
            let imageView = UIImageView(frame: CGRect(screenSize().width * CGFloat(i),
                                                      0,
                                                      screenSize().width,
                                                      Const.headerImageHeight))
           //imageView.sd_setImage(with: URL(string: url),
            //                      placeholderImage: Config.Resource.defaultImage(.normal))
            imageView.showProgress(.clear,
                                   progressType: .infinite,
                                   progress: nil,
                                   options: [.imageProgressSize : SRProgressHUD.ImageProgressSize.normal])
            imageView.sd_setImage(with: URL(string: url),
                                  placeholderImage: Config.Resource.defaultImage(.normal),
                                  options: [],
                                  progress:
                { (current, total, url) in
                    //print("current: \(current), total: \(total), progress: \(Double(current)/Double(total))")
                    if current > 0 && total > 0 {
                        imageView.progressComponent.setProgress(CGFloat(current / total),
                                                                animated: true)
                    }
            }, completed: { (image, error, cacheType, url) in
                imageView.progressComponent.dismiss(true)
            })
            tableHeaderScrollView.addSubview(imageView)
        }
        tableHeaderScrollView.setContentOffset(CGPoint(), animated: false)
        tableHeaderScrollView.contentSize =
            CGSize(screenSize().width * CGFloat(count), Const.headerImageHeight)
    }
    
    func updateNew(_ dictionary: [AnyHashable : Any]?, errMsg: String? = nil) {
        dismissProgress(true)
        tableView.mj_header.endRefreshing()
        guard let dictionary = dictionary else {
            if dataArray.isEmpty {
                showLoadDataFailView(errMsg) //加载失败
                tableView.reloadData()
            }
            return
        }
        
        updateHeaderImages(NonNull.array(dictionary[Param.Key.images]) as? [String])
        dataArray = NonNull.array(dictionary[Param.Key.list]) as! [ParamDictionary]
        guard !dataArray.isEmpty else { //没有数据
            showNoDataView()
            tableView.reloadData()
            return
        }
        
        tableView.tableFooterView = UIView()
        tableView.mj_footer.isHidden = false
        
        currentOffset = 0 //页数重置
        tableView.reloadData()
        DispatchQueue.main.async { [weak self] in //tableView更新完数据后再设置contentOffset
            self?.tableView.setContentOffset(CGPoint(0, -(self?.tableView.contentInset.top)!),
                                             animated: true)
        }
    }
    
    func updateMore(_ dictionary: [AnyHashable : Any]?, errMsg: String? = nil) {
        dismissProgress(true)
        guard let dictionary = dictionary else {
            if dataArray.isEmpty {
                showLoadDataFailView(errMsg) //加载失败
                tableView.reloadData()
            } else {
                tableView.mj_footer.endRefreshing()
            }
            return
        }
        
        let list = NonNull.array(dictionary[Param.Key.list]) as! [ParamDictionary]
        if list.isEmpty { //已无数据
            tableView.mj_footer.endRefreshingWithNoMoreData()
        } else {
            tableView.mj_footer.endRefreshing()
            tableView.mj_footer.resetNoMoreData()
        }
        
        tableView.tableFooterView = UIView()
        tableView.mj_footer.isHidden = false
        
        //去重
        var array = [] as [ParamDictionary]
        list.forEach { dictionary in
            if let index = (0 ..< dataArray.count).first(where: {
                if let id = dictionary[Param.Key.id] as? String,
                    id == dataArray[$0][Param.Key.id] as? String {
                    return true
                } else {
                    return false
                }
            }) {
                dataArray[index] = dictionary //如果已经存在该数据，更新之
            } else { //否则添加到新的数据中
                array.append(dictionary)
            }
        }
        currentOffset += 1 //自动增加页面
        dataArray += array //拼接数组
        tableView.reloadData()
    }
    
    func showNoDataView() {
        let height =
            tableView.height - (tableView.tableHeaderView == nil ? 0 : Const.headerImageHeight)
        noDataView.frame =
            CGRect(0, 0, ScreenWidth, max(height, noDataView.minHeight()))
        noDataView.layout()
        tableView.tableFooterView = noDataView
        tableView.mj_footer.endRefreshingWithNoMoreData()
        tableView.mj_footer.isHidden = true
    }
    
    override func showLoadDataFailView(_ text: String?) {
        loadDataFailView.text = text
        let height =
            tableView.height - (tableView.tableHeaderView == nil ? 0 : Const.headerImageHeight)
        loadDataFailView.frame =
            CGRect(0, 0, ScreenWidth, max(height, loadDataFailView.minHeight()))
        loadDataFailView.layout()
        tableView.tableFooterView = loadDataFailView
        tableView.mj_footer.endRefreshingWithNoMoreData()
        tableView.mj_footer.isHidden = true
    }
    
    //MARK: Http request
    
    func getSimpleList(_ loadType: TableLoadData.Page? = .new) {
        var params = [:] as ParamDictionary
        params[Param.Key.limit] = TableLoadData.row
        params[Param.Key.offset] = loadType == .more ? currentOffset + 1 : 0
        httpRequest(.get("data/getSimpleList", params), success: { [weak self] response in
            guard let strongSelf = self else { return }
            let responseData = NonNull.dictionary((response as! JSON)[HTTP.Key.Response.data].rawValue)
            if loadType == .more {
                let offset = params[Param.Key.offset] as! Int
                if offset == strongSelf.currentOffset + 1 { //只刷新新的一页数据，旧的或者更新的不刷
                    strongSelf.updateMore(responseData)
                }
            } else {
                strongSelf.updateNew(responseData)
            }
            }, bfail: { [weak self] (method, response) in
                guard let strongSelf = self else { return }
                if loadType == .more {
                    let offset = params[Param.Key.offset] as! Int
                    if offset == strongSelf.currentOffset + 1 {
                        if !strongSelf.dataArray.isEmpty { //若当前有数据，则进行弹出提示框的交互，列表恢复刷新状态
                            strongSelf.updateMore(nil)
                        } else { //当前为空的话则交给列表展示错误信息，一般在加载更多的时候是不会走到这个逻辑的，因为空数据的时候上拉加载更多是被禁止的
                            strongSelf.updateMore(nil,
                                                  errMsg: strongSelf.logBFail(method,
                                                                              response:response,
                                                                              show: false))
                        }
                    }
                } else {
                    if !strongSelf.dataArray.isEmpty { //若当前有数据，则进行弹出提示框的交互
                        strongSelf.updateNew(nil)
                    } else { //当前为空的话则交给列表展示错误信息
                        strongSelf.updateNew(nil, errMsg: strongSelf.logBFail(method,
                                                                              response: response,
                                                                              show: false))
                    }
                }
            }, fail: { [weak self] (_, error) in
                guard let strongSelf = self else { return }
                if loadType == .more {
                    let offset = params[Param.Key.offset] as! Int
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
    
    //MARK: - 事件响应
    
    override func clickNavigationBarRightButton(_ button: UIButton) {
        guard MutexTouch else { return }
        show("SimpleSubmitViewController", storyboard: "Simple")
    }
    
    //MARK: - SRLoadDataStateDelegate
    
    override func retryLoadData() {
        showProgress(.opaque)
        getSimpleList()
    }
}

//MARK: - UITableViewDelegate, UITableViewDataSource

extension SimpleTableViewController: UITableViewDelegate, UITableViewDataSource {    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return SimpleCell.Const.height
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =
            tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier) as! SimpleCell
        cell.update(dataArray[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard MutexTouch else { return }
        
        if let url = dataArray[indexPath.row][Param.Key.url] as? String {
            showWebpage(URL(string: url)!)
        }
    }
}
