//
//  NewsListViewController.swift
//  BaseSwift
//
//  Created by Shadow on 2016/12/7.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import UIKit
import MJRefresh
import SDWebImage

protocol NewsListDelegate: class {
    func getNewsList(_ loadType: String?, sendVC: NewsListViewController)
    func newsListVC(_ newsListVC: NewsListViewController, didSelect model: SinaNewsModel)
}

extension NewsListDelegate {
    func newsListVC(_ newsListVC: NewsListViewController, didSelect model: SinaNewsModel) { }
}

class NewsListViewController: BaseViewController {
    public weak var parentVC: UIViewController?
    public weak var delegate: NewsListDelegate?
    var isTouched = false //视图已经被父视图载入过
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var backToTopButton: UIButton!
    @IBOutlet public weak var backToTopButtonBottomConstraint: NSLayoutConstraint!
    var contentInset = UIEdgeInsets()
    private(set) var currentOffset = 0
    
    var noDataView = LoadDataStateView(.empty)
    var loadDataFailView = LoadDataStateView(.fail)
    
    var channelId: String?
    var dataArray: [SinaNewsModel] = []
    
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
    
    struct Const {
        static let preloadLastPostion = 3 //列表预加载的位置，从滑到倒数第1个cell时加载更多
    }
    
    func initView() {
        tableView.backgroundColor = UIColor.groupTableViewBackground
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        view.progressMaskColor = tableView.backgroundColor!
        
        //Refresh header & footer
        tableView.mj_header = SRMJRefreshHeader(refreshingBlock: { [weak self] in
            self?.loadData(TableLoadData.new, progressType: .none)
        })
        tableView.mj_header.endRefreshing()
        tableView.mj_footer = MJRefreshAutoNormalFooter(refreshingBlock: { [weak self] in
            self?.loadData(TableLoadData.more, progressType: .none)
        })
        tableView.mj_footer.endRefreshingWithNoMoreData()
        tableView.mj_footer.isHidden = true
        
        noDataView.backgroundColor = tableView.backgroundColor
        loadDataFailView.backgroundColor = tableView.backgroundColor
        loadDataFailView.delegate = self
        
        backToTopButton.isHidden = true
    }
    
    //MARK: - 业务处理
    
    func loadData(_ loadType: String, progressType: TableLoadData.ProgressType) {
        isTouched = true
        switch progressType {
        case .clearMask:
            view.showProgress()
        case .opaqueMask:
            view.showProgress(.opaque)
        default:
            break
        }
        delegate?.getNewsList(loadType, sendVC: self)
    }
    
    public func updateNew(_ dictionary: [AnyHashable : Any]?, errMsg: String? = nil) {
        view.dismissProgress(true)
        tableView.mj_header.endRefreshing()
        guard let dictionary = dictionary else {
            if dataArray.count == 0 {
                showLoadDataFailView(errMsg) //加载失败
            }
            return
        }
        
        dataArray = NonNull.array(dictionary[HttpKey.Response.data]) as! [SinaNewsModel]
        guard dataArray.count > 0 else { //没有数据
            showNoDataView()
            return
        }
        
        tableView.tableHeaderView = nil
        
        tableView.mj_footer.isHidden = false
        if dataArray.count < ParamDefaultValue.limit { //若加载的数据小于一页的数据，表示已经全部加载完毕
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
    
    public func updateMore(_ dictionary: [AnyHashable : Any]?, errMsg: String? = nil) {
        view.dismissProgress(true)
        guard let dictionary = dictionary else {
            if dataArray.count == 0 {
                showLoadDataFailView(errMsg) //加载失败
            } else {
                tableView.mj_footer.endRefreshing()
            }
            return
        }
        
        let list = NonNull.array(dictionary[HttpKey.Response.data]) as! [SinaNewsModel]
        if list.count < ParamDefaultValue.limit { //小于一页的数据
            tableView.mj_footer.endRefreshingWithNoMoreData()
        } else {
            tableView.mj_footer.endRefreshing()
            tableView.mj_footer.resetNoMoreData()
        }
        
        tableView.tableHeaderView = nil
        tableView.mj_footer.isHidden = false
        
        //去重
        var array = [] as [SinaNewsModel]
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
    
    func showNoDataView() {
        noDataView.frame =
            CGRect(0,
                    0,
                    tableView.width,
                    tableView.height - contentInset.top - contentInset.bottom)
        noDataView.layout()
        tableView.tableHeaderView = noDataView
        tableView.mj_footer.endRefreshingWithNoMoreData()
        tableView.mj_footer.isHidden = true
    }
    
    override func showLoadDataFailView(_ text: String?) {
        loadDataFailView.text = text
        //这里必须使用contentInset，而不能使用tableView.contentInset，原因在于MJRefresh在拉回之前会改变tableView.contentInset，导致不准
        loadDataFailView.frame =
            CGRect(0,
                    0,
                    tableView.width,
                    tableView.height - contentInset.top - contentInset.bottom)
        loadDataFailView.layout()
        tableView.tableHeaderView = loadDataFailView
        tableView.mj_footer.endRefreshingWithNoMoreData()
        tableView.mj_footer.isHidden = true
    }
    
    //MARK: - 事件响应
    
    @IBAction func clickBackToTopButton(_ sender: Any) {
        tableView.setContentOffset(CGPoint(0, -tableView.contentInset.top), animated: true)
    }
    
    //MARK: - LoadDataStateDelegate
    
    override func retryLoadData() {
        loadData(TableLoadData.new, progressType: .opaqueMask)
    }
}

//MARK: - UITableViewDelegate, UITableViewDataSource

extension NewsListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return NewsCell.Const.height
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
        let cell =
            tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier) as! NewsCell
        cell.update(dataArray[indexPath.row])
        
        //添加3d touch功能
        if !cell.isPreviewRegistered && traitCollection.forceTouchCapability == .available,
            let vc = delegate as? UIViewController,
            let previewingDelegate = vc as? UIViewControllerPreviewingDelegate {
            vc.registerForPreviewing(with: previewingDelegate, sourceView: cell.contentView)
            cell.isPreviewRegistered = true
        }
        cell.contentView.tag = indexPath.row
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard Common.mutexTouch() else { return }
        delegate?.newsListVC(self, didSelect: dataArray[indexPath.row])
    }
    
    //MARK: - UIScrollViewDelegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >=  scrollView.height
            && scrollView.contentSize.height >= scrollView.height {
            backToTopButton.isHidden = false
        } else {
            backToTopButton.isHidden = true
        }
    }
}
