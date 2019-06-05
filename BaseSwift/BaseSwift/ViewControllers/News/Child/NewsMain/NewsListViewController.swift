//
//  NewsListViewController.swift
//  BaseSwift
//
//  Created by Shadow on 2016/12/7.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import SRKit
import MJRefresh

protocol NewsListDelegate: class {
    func getNewsList(_ isNextPage: Bool, sendVC: NewsListViewController)
    func newsListVC(_ newsListVC: NewsListViewController, didSelect model: SinaNewsModel)
}

extension NewsListDelegate {
    func newsListVC(_ newsListVC: NewsListViewController, didSelect model: SinaNewsModel) { }
}

class NewsListViewController: BaseViewController, SRSimplePromptDelegate {
    public weak var parentVC: UIViewController?
    public weak var delegate: NewsListDelegate?
    var isTouched = false //视图已经被父视图载入过
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var backToTopButton: UIButton!
    @IBOutlet public weak var backToTopButtonBottomConstraint: NSLayoutConstraint!
    var contentInset = UIEdgeInsets()
    private(set) var currentOffset = 0
    
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
            self?.loadData(progressType: .none)
        })
        tableView.mj_header.endRefreshing()
        tableView.mj_footer = MJRefreshAutoNormalFooter(refreshingBlock: { [weak self] in
            self?.loadData(progressType: .none)
        })
        tableView.mj_footer.endRefreshingWithNoMoreData()
        tableView.mj_footer.isHidden = true
        
        backToTopButton.isHidden = true
    }
    
    //MARK: - 业务处理
    
    func loadData(_ isNextPage: Bool = false,
                  progressType: TableLoadData.ProgressType = .opaqueMask) {
        isTouched = true
        switch progressType {
        case .clearMask:
            view.showProgress()
        case .opaqueMask:
            view.showProgress(maskType: .opaque)
        default:
            break
        }
        delegate?.getNewsList(isNextPage, sendVC: self)
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
        
        dataArray = NonNull.array(dictionary[HTTP.Key.Response.data]) as! [SinaNewsModel]
        guard !dataArray.isEmpty else { //没有数据
            showNoDataView()
            return
        }
        
        tableView.tableHeaderView = nil
        
        tableView.mj_footer.isHidden = false
        if dataArray.isEmpty {
            tableView.mj_footer.endRefreshingWithNoMoreData()
        } else {
            tableView.mj_footer.resetNoMoreData()
        }
        
        currentOffset = 0 //页数重置
        tableView.reloadData()
        DispatchQueue.main.async { [weak self] in //tableView更新完数据后再设置contentOffset
            if let strongSelf = self {
                strongSelf.tableView.setContentOffset(CGPoint(0, -strongSelf.tableView.contentInset.top),
                                                      animated: true)
            }
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
        
        let list = NonNull.array(dictionary[HTTP.Key.Response.data]) as! [SinaNewsModel]
        if list.isEmpty {
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
        let view = SRSimplePromptView("No record".localized, image: UIImage("no_data"))
        view.frame = //这里必须使用contentInset，而不能使用tableView.contentInset，原因在于MJRefresh在拉回之前会改变tableView.contentInset，导致不准
            CGRect(0,
                   0,
                   tableView.width,
                   tableView.height - contentInset.top - contentInset.bottom)
        view.delegate = self
        view.backgroundColor = tableView.backgroundColor
        tableView.tableHeaderView = view
        tableView.mj_footer.endRefreshingWithNoMoreData()
        tableView.mj_footer.isHidden = true
    }
    
    override func showLoadDataFailView(_ text: String?, image: UIImage? = nil) {
        let view = SRSimplePromptView(text, image: UIImage("request_fail"))
        view.frame =
            CGRect(0,
                   0,
                   tableView.width,
                   tableView.height - contentInset.top - contentInset.bottom)
        view.delegate = self
        view.backgroundColor = tableView.backgroundColor
        tableView.tableHeaderView = view
        tableView.mj_footer.endRefreshingWithNoMoreData()
        tableView.mj_footer.isHidden = true
    }
    
    //MARK: - 事件响应
    
    @IBAction func clickBackToTopButton(_ sender: Any) {
        tableView.setContentOffset(CGPoint(0, -tableView.contentInset.top), animated: true)
    }
    
    //MARK: - SRSimplePromptDelegate
    
    func didClickSimplePromptView(_ view: SRSimplePromptView) {
        loadData()
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
        guard MutexTouch else { return }
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

func getNewsList(_ isNextPage: Bool, sendVC: NewsListViewController) {
    
}
