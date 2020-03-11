//
//  NewsListViewController.swift
//  BaseSwift
//
//  Created by Shadow on 2016/12/7.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import SRKit
import MJRefresh
import SwiftyJSON

protocol NewsListDataSource: class {
    func getNewsList(_ viewController: NewsListViewController, addMore: Bool)
}

protocol NewsListDelegate: class {
    func newsListVC(_ newsListVC: NewsListViewController, didSelect model: SinaNewsModel)
}

extension NewsListDelegate {
    func newsListVC(_ newsListVC: NewsListViewController, didSelect model: SinaNewsModel) { }
}

class NewsListViewController: BaseTableViewController {
    public weak var parentVC: UIViewController?
    public weak var dataSource: NewsListDataSource?
    public weak var delegate: NewsListDelegate?
    var isTouched = false //视图已经被父视图载入过
    @IBOutlet weak var backToTopButton: UIButton!
    @IBOutlet public weak var backToTopButtonBottomConstraint: NSLayoutConstraint!
    var contentInset = UIEdgeInsets()
    
    var channelId: String?
    
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
        
        needRefreshNewHeader = true
        needAddMoreFooter = true
        tableView.mj_footer.isHidden = true
        backToTopButton.isHidden = true
    }
    
    override func layoutSubviews() {
        view.bringSubviewToFront(backToTopButton)
    }
    
    //MARK: - BaseTableLoadData
    
    @IBOutlet weak var _tableView: UITableView!
    override var tableView: UITableView {
        return _tableView
    }
    
    func getDataArray(_ addMore: Bool) {
        getDataArray(addMore, progressType: .none)
    }
    
    func getDataArray(_ addMore: Bool = false,
                  progressType: TableLoadData.ProgressType = .opaqueMask) {
        isTouched = true
        switch progressType {
        case .clearMask:
            showProgress()
        case .opaqueMask:
            showProgress(.opaque)
        default:
            break
        }
        
        if let dataSource = dataSource {
            dataSource.getNewsList(self, addMore: addMore)
        } else {
            var params = self.params
            let time = CLongLong(Date().timeIntervalSince1970 * 1000)
            params["t"] = String(longLong: time)
            params["_"] = String(longLong: time + 2)
            params["show_num"] = "10"
            params["act"] = addMore ? "more" : "new"
            let offset = addMore ? currentOffset + 1 : 0
            params["page"] = String(int: offset + 1)
            httpRequest(.get("http://interface.sina.cn/ent/feed.d.json", params: params), success:
                { [weak self] response in
                    guard let strongSelf = self else { return }
                    let json = response as? JSON ?? JSON()
                    let array = json[HTTP.Key.Response.data].arrayObject?.compactMap { (element) -> SinaNewsModel? in
                        if let json = element as? ParamDictionary {
                            return SinaNewsModel(JSON: json)
                        } else if let model = element as? SinaNewsModel {
                            return model
                        } else {
                            return nil
                        }
                    }
                    strongSelf.httpRespond(success: array ?? [], offset: offset)
            }) { [weak self] failure in
                guard let strongSelf = self else { return }
                strongSelf.httpRespond(failure: failure, offset: offset)
            }
        }
    }
    
    private var _dataEqual: ((Any, Any) -> Bool) = { ($0 as! SinaNewsModel) == ($1 as! SinaNewsModel) }
    public override var dataEqual: ((Any, Any) -> Bool)? {
        get { return _dataEqual }
        set { }
    }
    
    //MARK: - 事件响应
    
    @IBAction func clickBackToTopButton(_ sender: Any) {
        tableView.setContentOffset(CGPoint(0, -tableView.contentInset.top), animated: true)
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
    
    //MARK: - UITableViewDelegate, UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return NewsCell.Const.height
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =
            tableView.dequeueReusableCell(withIdentifier: C.reuseIdentifier) as! NewsCell
        cell.model = (dataArray[indexPath.row] as! SinaNewsModel)
        
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
        delegate?.newsListVC(self, didSelect: dataArray[indexPath.row] as! SinaNewsModel)
    }
}
