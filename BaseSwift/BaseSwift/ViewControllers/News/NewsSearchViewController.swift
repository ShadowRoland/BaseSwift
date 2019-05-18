//
//  NewsSearchViewController.swift
//  BaseSwift
//
//  Created by Gary on 2016/12/28.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import SRKit
import SwiftyJSON
import Cartography

class NewsSearchViewController: BaseViewController {
    enum PageStatus {
        case history, inputing, searching
    }
    
    var pageStatus: PageStatus = .history
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var tableHeaderView: UIView!
    var newsListVC: NewsListViewController!
    
    var history: [String] = []
    var suggestions: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        if let array = UserStandard[UDKey.searchSuggestionHistory] as? [String] {
            history = array
        }
        initView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.isNavigationBarHidden = true
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
        static let cellTextLabelTag = 100
        static let historyMaxCount = 20 //搜索历史最多保存的个数
    }
    
    func initView() {
        initSearchBar()
        updateTableHeaderView()
        tableView.tableFooterView = UIView()
        
        let channel = ChannelModel(JSON: [Param.Key.id : String(int: Int.random(in: 1 ..< 10000))])!
        newsListVC = NewsMainViewController.createNewsListVC(channel)
        newsListVC.delegate = self
        addChild(newsListVC)
        view.addSubview(newsListVC.view)
        constrain(newsListVC.view, searchBar) { (view1, view2) in
            view1.top == view2.bottom
            view1.bottom == view1.superview!.bottom
            view1.leading == view1.superview!.leading
            view1.trailing == view1.superview!.trailing
        }
        newsListVC.view.isHidden = true
    }
    
    func initSearchBar() {
        searchBar.placeholder = "Please enter the text you want to search for".localized
        searchBar.barTintColor = UIColor.white
        if let button = searchBar.value(forKey: "cancelButton") as? UIButton {
            button.isUserInteractionEnabled = true
            button.isEnabled = true
            button.titleColor = UIColor.darkGray
        }
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
            background.backgroundColor = UIColor.groupTableViewBackground
            background.subviews.forEach {
                if let imageView = $0 as? UIImageView {
                    imageView.image = nil
                }
                $0.backgroundColor = UIColor.groupTableViewBackground
            }
        }
    }
    
    //MARK: - 业务处理
    
    override func performViewDidLoad() {
        searchBar.becomeFirstResponder()
        newsListVC.backToTopButtonBottomConstraint.constant = 0
    }
    
    func getSearchSuggestions(_ key: String) {
        var params = ["ver" : "1", "Refer" : "sina_sug"]
        params[Param.Key.cb] = "func_" + String(longLong: CLongLong(Date().timeIntervalSince1970 * 1000))
        params[Param.Key.t] = String(float: Float(Int.random(in: 1 ..< 10000)) / 10000.0)
        params[Param.Key.key] = key
        httpRequest(.get("http://interface.sina.cn/ajax/jsonp/suggestion", params), success: { [weak self] response in
            guard let strongSelf = self,
                let json = response as? JSON,
                let array = json[Param.Key.data].rawValue as? [String],
                strongSelf.pageStatus == .inputing else {
                    return
            }
            
            strongSelf.suggestions = array
            strongSelf.updateTableHeaderView()
            strongSelf.tableView.reloadData()
        }, bfail: { [weak self] method, response in
            self?.logBFail(method, response: response, show: false)
        }, fail: { _, error in
        })
    }
    
    func updateTableHeaderView() {
        tableView.tableHeaderView =
            pageStatus == .history && !history.isEmpty ? tableHeaderView : nil
    }
    
    func updateHistory(_ newKey: String) {
        //将新增的key放在第一个，后面的不再添加相同的key
        var array = history.filter { $0 != newKey }
        if array.count <= Const.historyMaxCount {
            history = array
        } else {
            let upper = array.index(array.startIndex, offsetBy: Const.historyMaxCount)
            let range = Range<Array<Any>.Index>(uncheckedBounds: (lower: array.startIndex,
                                                                  upper: upper))
            history = Array(array[range])
        }
        UserStandard[UDKey.searchSuggestionHistory] = history
    }
    
    func enableSearchBarCancelButton() {
        searchBar.resignFirstResponder() //失去第一响应
        if let button = searchBar.value(forKey: "cancelButton") as? UIButton {
            button.isUserInteractionEnabled = true
            button.isEnabled = true
            button.titleColor = UIColor.darkGray
        }
    }
    
    //MARK: - 事件响应
    
    @objc func clickHistoryDeleteButton(_ sender: Any) {
        guard MutexTouch else { return }
        if let button = sender as? UIButton, button.tag >= 0, button.tag < history.count {
            history.remove(at: button.tag)
            UserStandard[UDKey.searchSuggestionHistory] = history
            updateTableHeaderView()
            tableView.reloadData()
        }
    }
    
    @IBAction func clickClearHistoryButton(_ sender: Any) {
        guard MutexTouch else { return }
        Keyboard.hide()
        let alert = SRAlert()
        alert.addButton("OK".localized,
                        backgroundColor: NavigationBar.backgroundColor,
                        action:
            { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.history.removeAll()
                UserStandard[UDKey.searchSuggestionHistory] = nil
                strongSelf.updateTableHeaderView()
                strongSelf.tableView.reloadData()
        })
        alert.show(.notice,
                   title: "Confirm clear all search history?".localized,
                   message: "",
                   closeButtonTitle: "Cancel".localized)
    }
}

// MARK: - UISearchBarDelegate

extension NewsSearchViewController: UISearchBarDelegate {
    public func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool { // return NO to not become first responder
        return true
    }
    
    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) { // called when text starts editing
        newsListVC.view.isHidden = true
    }
    
    public func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool { // return NO to not resign first responder
        return true
    }
    
    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) { // called when text ends editing
        DispatchQueue.main.asyncAfter(deadline: .now() + PerformDelay, execute: { [weak self] in
            self?.enableSearchBarCancelButton()
        })
    }
    
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) { // called when text changes (including clear)
        guard !isEmptyString(searchText) else {
            pageStatus = .history
            updateTableHeaderView()
            tableView.reloadData()
            return
        }
        
        pageStatus = .inputing
        getSearchSuggestions(searchText)
    }
    
    public func searchBar(_ searchBar: UISearchBar,
                          shouldChangeTextIn range: NSRange,
                          replacementText text: String) -> Bool { // called before text changes
        return true
    }
    
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) { // called when keyboard search button pressed
        guard !isEmptyString(searchBar.text) else {
            SRAlert.showToast("Please enter the text you want to search for".localized)
            return
        }
        enableSearchBarCancelButton()
        updateHistory(searchBar.text!)
        Keyboard.hide { [weak self] in
            self?.newsListVC.view.isHidden = false
            self?.newsListVC.loadData()
        }
    }
    
    public func searchBarBookmarkButtonClicked(_ searchBar: UISearchBar) { // called when bookmark button pressed
        
    }
    
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) { // called when cancel button pressed
        popBack()
    }
    
    public func searchBarResultsListButtonClicked(_ searchBar: UISearchBar) { // called when search results button pressed
        
    }
    
    public func searchBar(_ searchBar: UISearchBar,
                          selectedScopeButtonIndexDidChange selectedScope: Int) {
        
    }
}

//MARK: - NewsListDelegate

extension NewsSearchViewController: NewsListDelegate {
    //使用第三方新闻客户端的请求参数
    func getNewsList(_ isNextPage: Bool, sendVC: NewsListViewController) {
        var params = sendVC.params
        let time = CLongLong(Date().timeIntervalSince1970 * 1000)
        params["t"] = String(longLong: time)
        params["_"] = String(longLong: time + 2)
        params["show_num"] = "10"
        params["act"] = isNextPage ? "more" : "new"
        let offset = isNextPage ? sendVC.currentOffset + 1 : 0
        params["page"] = String(int: offset + 1)
        httpRequest(.get("http://interface.sina.cn/ent/feed.d.json", params), success: { [weak self] response in
            guard let strongSelf = self else { return }
            let responseData = NonNull.dictionary(response)
            if isNextPage {
                let offset = Int(params[Param.Key.offset] as! String)
                if offset == strongSelf.newsListVC.currentOffset + 1 { //只刷新新的一页数据，旧的或者更新的不刷
                    strongSelf.newsListVC.updateMore(responseData)
                }
            } else {
                strongSelf.newsListVC.updateNew(responseData)
            }
            }, bfail: { [weak self] (method, response) in
                guard let strongSelf = self else { return }
                if isNextPage {
                    let offset = Int(params[Param.Key.offset] as! String)
                    if offset == strongSelf.newsListVC.currentOffset + 1 {
                        return
                    }
                } else {
                    if !strongSelf.newsListVC.dataArray.isEmpty { //已经有数据，保留原数据，显示提示框
                        strongSelf.newsListVC?.updateNew(nil)
                    } else { //当前为空的话则交给列表展示错误信息
                        strongSelf.newsListVC.updateNew(nil,
                                                        errMsg: strongSelf.logBFail(method,
                                                                                    response: response,
                                                                                    show: false))
                    }
                }
            }, fail: { [weak self] (_, error) in
                guard let strongSelf = self else { return }
                if isNextPage {
                    let offset = Int(params[Param.Key.offset] as! String)
                    if offset == strongSelf.newsListVC.currentOffset + 1 {
                        if !strongSelf.newsListVC.dataArray.isEmpty { //若当前有数据，则进行弹出toast的交互，列表恢复刷新状态
                            strongSelf.newsListVC.updateMore(nil)
                        } else { //当前为空的话则交给列表展示错误信息，一般在加载更多的时候是不会走到这个逻辑的，因为空数据的时候上拉加载更多是被禁止的
                            strongSelf.newsListVC.updateMore(nil, errMsg: error.errorDescription)
                        }
                    }
                } else {
                    if !strongSelf.newsListVC.dataArray.isEmpty { //若当前有数据，则进行弹出toast的交互
                        strongSelf.newsListVC.updateNew(nil)
                    } else { //当前为空的话则交给列表展示错误信息
                        strongSelf.newsListVC.updateNew(nil, errMsg: error.errorDescription)
                    }
                }
        })
    }
    
    func newsListVC(_ newsListVC: NewsListViewController, didSelect model: SinaNewsModel) {
        showWebpage(URL(string: NonNull.string(model.link))!, title: "News".localized)
    }
}

//MARK: - UITableViewDelegate, UITableViewDataSource

extension NewsSearchViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if pageStatus == .history {
            return history.count
        } else if pageStatus == .inputing {
            return suggestions.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = pageStatus == .inputing ? "suggestionsIdentifier" : "historyIdentifier"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier)!
        let label = cell.contentView.viewWithTag(Const.cellTextLabelTag) as! UILabel
        label.text = pageStatus == .inputing ? suggestions[indexPath.row] : history[indexPath.row]
        if pageStatus == .history, let cell = cell as? HistoryCell {
            cell.deleteButton.tag = indexPath.row
            if !cell.deleteButton.allTargets.contains(self) {
                cell.deleteButton.clicked(self, action: #selector(clickHistoryDeleteButton(_:)))
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard MutexTouch else { return }
        if let cell = tableView.cellForRow(at: indexPath),
            let label = cell.contentView.viewWithTag(Const.cellTextLabelTag) as? UILabel,
            !isEmptyString(label.text) {
            updateHistory(label.text!)
            searchBar.text = label.text
            Keyboard.hide { [weak self] in
                self?.newsListVC.view.isHidden = false
                self?.newsListVC.loadData()
            }
        }
    }
}

