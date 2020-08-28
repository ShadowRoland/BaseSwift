//
//  BaseTableViewController.swift
//  Base
//
//  Created by Gary on 2019/9/23.
//  Copyright © 2019 shadowR. All rights reserved.
//

import UIKit
import SRKit
import MJRefresh
import SwiftyJSON

public protocol BaseTableLoadData {
    var tableView: UITableView  { get }
    var dataArray: AnyArray { get set } //数据列表
    var noDataMessage: String? { get set } //无数据时显示的文字信息
    var noDataImage: UIImage? { get set } //无数据时显示的图片
    var currentOffset: Int { get set } //当前加载的页数
    var lastlastRowOfPreloadMore: Int { get set } //预加载倒数的行
    func getDataArray(_ isAddMore: Bool) //加载数据，isAddMore: true加载下一页，数据加载后列表追加，false加载第一页，数据加载后列表刷新
    func refreshNew(_ array: AnyArray?, errorMessage: String?) //列表刷新，array: 第一页数据，errorMessage：列表数据获取失败的提示信息
    func addMore(_ array: AnyArray?, errorMessage: String?) //列表追加新数据，array: 新一页数据，errorMessage：列表数据获取失败的提示信息
    var dataEqual: ((Any, Any) -> Bool)? { get } //数据重复判断，addMore时比较新增数据与已存数据，若数据相等（如关键key “id”相同则用
    func showNoDataView() //列表数据为空时的展示
    func dismissNoDataView()
}

public extension BaseTableLoadData {
    func getDataArray() {
        getDataArray(false)
    }
    
    func refreshNew(_ array: AnyArray?) {
        refreshNew(array, errorMessage: nil)
    }
    
    func addMore(_ array: AnyArray?) {
        addMore(array, errorMessage: nil)
    }
    
    func getDataArray(_ isAddMore: Bool) {
        
    }
}

open class BaseTableViewController: BaseViewController,
    BaseTableLoadData,
    UITableViewDelegate,
    UITableViewDataSource,
SRSimplePromptDelegate {
    class TableEventTarget: SRBaseViewController.EventTarget {
        @objc func tableViewRefreshNew() {
            DispatchQueue.main.async { [weak self] in
                if let viewController = self?.viewController as? BaseTableViewController {
                    viewController.getDataArray()
                }
            }
        }
        
        @objc func tableViewAddMore() {
            DispatchQueue.main.async { [weak self] in
                if let viewController = self?.viewController as? BaseTableViewController {
                    viewController.getDataArray(true)
                }
            }
        }
    }
    
    private var _eventTarget: SRBaseViewController.EventTarget!
    open override var eventTarget: SRBaseViewController.EventTarget {
        if _eventTarget == nil {
            _eventTarget = TableEventTarget(self)
        }
        return _eventTarget
    }
    
    public init(style: UITableView.Style) {
        self.tableStyle = style
        super.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        view.insertSubview(_firstSubview, at: 0)
        automaticallyAdjustsScrollViewInsets = false
        //layoutSubviews()
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.insertSubview(_firstSubview, at: 0)
        layoutSubviews()
    }
    
    open func layoutSubviews() {
        guard isViewLoaded else { return }
        
        var top = srTopLayoutGuide
        if let pageHeaderView = pageHeaderView,
            !pageHeaderView.isHidden && pageHeaderView.alpha != 0 {
            var frame = pageHeaderView.frame
            frame.origin.y = top
            pageHeaderView.frame = frame
            top = pageHeaderView.bottom
            
            view.insertSubview(tableView, belowSubview: pageHeaderView)
        }
        
        var bottom = 0 as CGFloat
        if let pageFooterView = pageFooterView,
            !pageFooterView.isHidden && pageFooterView.alpha != 0 {
            var frame = pageFooterView.frame
            frame.origin.y = ScreenHeight - pageFooterView.height
            pageFooterView.frame = frame
            bottom = pageFooterView.top
            
            view.insertSubview(tableView, belowSubview: pageFooterView)
        }
        
        tableView.frame = CGRect(0, top, view.width, view.height - top - bottom)
        if let view = tableView.tableFooterView,
            view === srBaseComponent.loadDataFailView {
            var height = tableView.height
            if let tableHeaderView = tableView.tableHeaderView {
                height -= tableHeaderView.height
            }
            view.frame =
                CGRect(0,
                       0,
                       tableView.width,
                       max(height, view.sizeThatFits(CGSize(tableView.width, 0)).height))
            tableView.tableFooterView = view
        }
    }
    
    private var _firstSubview = UIView()
    
    private var _pageHeaderView: UIView?
    public var pageHeaderView: UIView? {
        get {
            return _pageHeaderView
        }
        set {
            if _pageHeaderView !== newValue {
                _pageHeaderView?.removeFromSuperview()
            } else if let pageHeaderView = newValue {
                view.addSubview(pageHeaderView)
            }
            _pageHeaderView = newValue
            layoutSubviews()
        }
    }
    
    private var _pageFooterView: UIView?
    public var pageFooterView: UIView? {
        get {
            return _pageFooterView
        }
        set {
            if _pageFooterView !== newValue {
                _pageFooterView?.removeFromSuperview()
            } else if let pageFooterView = newValue {
                view.addSubview(pageFooterView)
            }
            _pageFooterView = newValue
            layoutSubviews()
        }
    }
    
    override open func deviceOrientationDidChange(_ sender: AnyObject?) {
        super.deviceOrientationDidChange(sender)
        guard srGuardDeviceOrientationDidChange(sender) else { return }
        
        layoutSubviews()
    }
    
    open override func showLoadDataFailView(_ text: String?,
                                            image: UIImage? = nil,
                                            insets: UIEdgeInsets? = nil) {
        noDataMessage = text ?? ""
        if let image = image {
            noDataImage = image
        } else {
            noDataImage = UIImage("request_fail")
        }
        showNoDataView()
    }
    
    //MARK: - Http respond
    
    public func httpRespond(success response: Any, offset: Int) {
        var array: AnyArray
        if let arr = response as? AnyArray {
            array = arr
        } else if let dictionary = response as? ParamDictionary,
            let arr = dictionary[HTTP.Key.Response.data] as? AnyArray {
            array = arr
        } else if let json = response as? JSON,
            let arr = json[HTTP.Key.Response.data].arrayObject {
            array = arr
        } else {
            array = []
        }
        if offset == 0 {
            dismissProgress()
            refreshNew(array)
        } else if offset == currentOffset + 1 {
            dismissProgress()
            addMore(array)
        }
    }
    
    public func httpRespond(failure result: HTTP.Result<Any>.Failure<Any>,
                            offset: Int) {
        let errorMessage = result.errorMessage
        if offset == 0 {
            dismissProgress()
            refreshNew(nil, errorMessage: errorMessage)
        } else if offset == currentOffset + 1 {
            dismissProgress()
            addMore(nil, errorMessage: errorMessage)
        }
    }

    //MARK: - TableView
    
    private var tableStyle: UITableView.Style = .plain
    
    public var needRefreshNewHeader = false {
        didSet {
            if needRefreshNewHeader {
                tableView.mj_header = MJRefreshNormalHeader(refreshingBlock: { [weak self] in
                    if let strongSelf = self {
                        (strongSelf.eventTarget as! TableEventTarget).tableViewRefreshNew()
                    }
                })
            } else {
                tableView.mj_header = nil
            }
        }
    }
    
    public var needAddMoreFooter = false {
        didSet {
            if needAddMoreFooter {
                tableView.mj_footer = MJRefreshBackNormalFooter(refreshingBlock: { [weak self] in
                    if let strongSelf = self {
                        (strongSelf.eventTarget as! TableEventTarget).tableViewAddMore()
                    }
                })
            } else {
                tableView.mj_footer = nil
            }
        }
    }
    
    //MARK: - BaseTableLoadData
    
    private var _tableView: UITableView!
    public var tableView: UITableView {
        if _tableView != nil {
            return _tableView
        }
        
        _tableView = UITableView(frame: CGRect(), style: tableStyle)
        _tableView.delegate = self
        _tableView.dataSource = self
        _tableView.tableFooterView = UIView()
        view.addSubview(_tableView)
        
        if #available(iOS 11, *) {
            _tableView.contentInsetAdjustmentBehavior = .never
            _tableView.estimatedRowHeight = 0
            _tableView.estimatedSectionHeaderHeight = 0
            _tableView.estimatedSectionFooterHeight = 0
        }
        
        return _tableView
    }
    
    private var _dataArray = [] as AnyArray
    public var dataArray: AnyArray {
        get {
            return _dataArray
        }
        set {
            _dataArray = newValue
        }
    }
    
    private var _noDataMessage: String? = "No record".localized
    public var noDataMessage: String? {
        get {
            return _noDataMessage
        }
        set {
            _noDataMessage = newValue
        }
    }
    
    private var _noDataImage = UIImage("no_data")
    public var noDataImage: UIImage? {
        get {
            return _noDataImage
        }
        set {
            _noDataImage = newValue
        }
    }
    
    private var _currentOffset = 0
    public var currentOffset: Int{
        get {
            return _currentOffset
        }
        set {
            _currentOffset = newValue
        }
    }
    
    private var _lastlastRowOfPreloadMore = -1
    public var lastlastRowOfPreloadMore: Int {
        get {
            return _lastlastRowOfPreloadMore
        }
        set {
            _lastlastRowOfPreloadMore = newValue
        }
    }
    
    public func refreshNew(_ array: AnyArray?, errorMessage: String?) {
        tableView.mj_header?.endRefreshing()
        
        if let errorMessage = errorMessage {
            noDataMessage = errorMessage
            if dataArray.isEmpty {
                showLoadDataFailView(noDataMessage, image: UIImage("request_fail")) //加载失败
                tableView.reloadData()
            } else {
                srShowToast(errorMessage)
            }
            return
        }
        
        noDataMessage = ""
        
        dataArray = array ?? []
        guard !dataArray.isEmpty else { //没有数据
            noDataMessage = "No record".localized
            noDataImage = UIImage("no_data")
            showNoDataView()
            tableView.reloadData()
            return
        }
        
        dismissNoDataView()
        
        currentOffset = 0 //页数重置
        tableView.reloadData()
        DispatchQueue.main.async { [weak self] in //tableView更新完数据后再设置contentOffset
            if let strongSelf = self {
                strongSelf.tableView.setContentOffset(CGPoint(0, -strongSelf.tableView.contentInset.top),
                                                      animated: true)
            }
        }
    }
    
    public func addMore(_ array: AnyArray?, errorMessage: String?) {
        if let errorMessage = errorMessage {
            noDataMessage = errorMessage
            if dataArray.isEmpty {
                showLoadDataFailView(noDataMessage, image: UIImage("request_fail")) //加载失败
                tableView.reloadData()
            } else {
                srShowToast(errorMessage)
            }
            return
        }
        
        noDataMessage = ""
        
        guard let array = array, !array.isEmpty else {
            tableView.mj_footer?.endRefreshingWithNoMoreData()
            tableView.mj_footer?.isHidden = false
            tableView.reloadData()
            return
        }
        
        tableView.mj_footer?.endRefreshing()
        tableView.mj_footer?.resetNoMoreData()
        
        if let dataEqual = dataEqual { //去重
            var moreArray = [] as AnyArray
            array.forEach { newData in
                if let index = (0 ..< dataArray.count).first(where: {
                    return dataEqual(newData, $0)
                }) {
                    dataArray[index] = newData //如果已经存在该数据，更新之
                } else {
                    moreArray.append(newData) //否则添加到新的列表中
                }
            }
            dataArray += moreArray
        } else { //直接追加新
            dataArray += array
        }
        currentOffset += 1 //自动增加页面
        
        tableView.reloadData()
    }
    
    //提供默认的根据数组的字典成员的"id"来去重
    public var dataEqual: ((Any, Any) -> Bool)? = { (newData, oldData) in
        if let newDictionary = newData as? ParamDictionary,
            let oldDictionary = oldData as? ParamDictionary{
            let newId = newDictionary[Param.Key.id]
            let oldId = oldDictionary[Param.Key.id]
            if newId != nil && oldId != nil {
                return String(describing: newId) == String(describing: oldId)
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    public func showNoDataView() {
        let view = SRSimplePromptView(noDataMessage, image: noDataImage)
        var height = tableView.height
        if let tableHeaderView = tableView.tableHeaderView {
            height -= tableHeaderView.height
        }
        view.frame =
            CGRect(0,
                   0,
                   tableView.width,
                   max(height - height, view.sizeThatFits(CGSize(tableView.width, 0)).height))
        view.delegate = self
        view.backgroundColor = tableView.backgroundColor
        tableView.tableFooterView = view
        tableView.mj_footer?.endRefreshingWithNoMoreData()
        tableView.mj_footer?.isHidden = true
        srBaseComponent.loadDataFailView = view
    }
    
    public func dismissNoDataView() {
        tableView.tableFooterView = UIView()
        tableView.mj_footer?.resetNoMoreData()
        tableView.mj_footer?.isHidden = true
        srBaseComponent.loadDataFailView = nil
    }
    
    open override var isShowingLoadDataFailView: Bool {
        if let view = srBaseComponent.loadDataFailView,
            view === tableView.tableFooterView {
            return true
        } else {
            return false
        }
    }
    
    //MARK: - UITableViewDelegate
    
    public func tableView(_ tableView: UITableView,
                          heightForRowAt indexPath: IndexPath) -> CGFloat {
        return C.tableCellHeight
    }
    
    //MARK: - UITableViewDataSource
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArray.count
    }
    
    public func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: C.reuseIdentifier) {
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    public func tableView(_ tableView: UITableView,
                          willDisplay cell: UITableViewCell,
                          forRowAt indexPath: IndexPath) {
        if dataArray.count > 0
            && lastlastRowOfPreloadMore >= 0
            && dataArray.count - indexPath.row < lastlastRowOfPreloadMore,
            let mj_footer = tableView.mj_footer,
            mj_footer.state == .idle {
            mj_footer.beginRefreshing()
        }
    }
    
    //MARK: - SRSimplePromptDelegate
    
    public func didClickSimplePromptView(_ view: SRSimplePromptView) {
        showProgress()
        getDataArray()
    }
}
