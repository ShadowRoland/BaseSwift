//
//  NewsSearchViewController.swift
//  BaseSwift
//
//  Created by Gary on 2016/12/28.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import UIKit
import Cartography
import SDWebImage
import SwiftyJSON

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
        if let array = UserStandard[USKey.searchSuggestionHistory] as? [String] {
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
        
        let channel = ChannelModel(JSON: [ParamKey.id : String(int: Int.random(in: 1 ..< 10000))])!
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
        params[ParamKey.cb] =
            "func_" + String(longLong: CLongLong(Date().timeIntervalSince1970 * 1000))
        params[ParamKey.t] = String(float: Float(Int.random(in: 1 ..< 10000)) / 10000.0)
        params[ParamKey.key] = key
        //httpReq(.get(.newsSuggestions), params, userInfo, url : "http://s.weibo.com")
        httpRequest(.get(.newsSuggestions), success: { response in
            guard let json = response as? JSON,
                let array = json[ParamKey.data].rawValue as? [String],
                self.pageStatus == .inputing else {
                    return
            }
            
            self.suggestions = array
            self.updateTableHeaderView()
            self.tableView.reloadData()
        }, bfail: { response in
            self.logBFail(.get(.newsSuggestions), response: response, show: false)
        }, fail: { error in
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
        UserStandard[USKey.searchSuggestionHistory] = history
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
        guard Common.mutexTouch() else { return }
        if let button = sender as? UIButton, button.tag >= 0, button.tag < history.count {
            history.remove(at: button.tag)
            UserStandard[USKey.searchSuggestionHistory] = history
            updateTableHeaderView()
            tableView.reloadData()
        }
    }
    
    @IBAction func clickClearHistoryButton(_ sender: Any) {
        guard Common.mutexTouch() else { return }
        Keyboard.hide()
        let alert = SRAlert()
        alert.addButton("OK".localized,
                        backgroundColor: NavigartionBar.backgroundColor,
                        action:
            { [weak self] in
                self?.history.removeAll()
                UserStandard[USKey.searchSuggestionHistory] = nil
                self?.updateTableHeaderView()
                self?.tableView.reloadData()
        })
        alert.show(.notice,
                   title: "Confirm clear all search history?".localized,
                   message: EmptyString,
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
        DispatchQueue.main.asyncAfter(deadline: .now() + PerformDelay,
                                      execute:
            { [weak self] in
                self?.enableSearchBarCancelButton()
        })
    }
    
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) { // called when text changes (including clear)
        guard !Common.isEmptyString(searchText) else {
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
        guard !Common.isEmptyString(searchBar.text) else {
            Common.showToast("Please enter the text you want to search for".localized)
            return
        }
        enableSearchBarCancelButton()
        updateHistory(searchBar.text!)
        Keyboard.hide { [weak self] in
            self?.newsListVC.view.isHidden = false
            self?.newsListVC.loadData(.new, progressType: .opaqueMask)
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
    func getNewsList(_ loadType: TableLoadData.Page?, sendVC: NewsListViewController) {
        var params = sendVC.params
        let time = CLongLong(Date().timeIntervalSince1970 * 1000)
        params["t"] = String(longLong: time)
        params["_"] = String(longLong: time + 2)
        params["show_num"] = "10"
        params["act"] = loadType == .more ? "more" : "new"
        let offset = loadType == .more ? sendVC.currentOffset + 1 : 0
        params["page"] = String(int: offset + 1)
        //httpReq(.get(.sinaNewsList), params, userInfo, url: "http://interface.sina.cn")
        httpRequest(.get(.sinaNewsList), success: { response in
            let responseData = NonNull.dictionary(response)
            if .more == loadType {
                let offset = Int(params[ParamKey.offset] as! String)
                if offset == self.newsListVC.currentOffset + 1 { //只刷新新的一页数据，旧的或者更新的不刷
                    self.newsListVC.updateMore(responseData)
                }
            } else {
                self.newsListVC.updateNew(responseData)
            }
        }, bfail: { response in
            if .more == loadType {
                let offset = Int(params[ParamKey.offset] as! String)
                if offset == self.newsListVC.currentOffset + 1 {
                    return
                }
            } else {
                if !self.newsListVC.dataArray.isEmpty { //已经有数据，保留原数据，显示提示框
                    self.newsListVC?.updateNew(nil)
                } else { //当前为空的话则交给列表展示错误信息
                    self.newsListVC.updateNew(nil, errMsg: self.logBFail(.get(.sinaNewsList),
                                                                         response: response,
                                                                         show: false))
                }
            }
        }, fail: { error in
            if .more == loadType {
                let offset = Int(params[ParamKey.offset] as! String)
                if offset == self.newsListVC.currentOffset + 1 {
                    if !self.newsListVC.dataArray.isEmpty { //若当前有数据，则进行弹出toast的交互，列表恢复刷新状态
                        self.newsListVC.updateMore(nil)
                    } else { //当前为空的话则交给列表展示错误信息，一般在加载更多的时候是不会走到这个逻辑的，因为空数据的时候上拉加载更多是被禁止的
                        self.newsListVC.updateMore(nil, errMsg: error.errorDescription)
                    }
                }
            } else {
                if !self.newsListVC.dataArray.isEmpty { //若当前有数据，则进行弹出toast的交互
                    self.newsListVC.updateNew(nil)
                } else { //当前为空的话则交给列表展示错误信息
                    self.newsListVC.updateNew(nil, errMsg: error.errorDescription)
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
        guard Common.mutexTouch() else { return }
        if let cell = tableView.cellForRow(at: indexPath),
            let label = cell.contentView.viewWithTag(Const.cellTextLabelTag) as? UILabel,
            !Common.isEmptyString(label.text) {
            updateHistory(label.text!)
            searchBar.text = label.text
            Keyboard.hide { [weak self] in
                self?.newsListVC.view.isHidden = false
                self?.newsListVC.loadData(.new, progressType: .opaqueMask)
            }
        }
    }
}

