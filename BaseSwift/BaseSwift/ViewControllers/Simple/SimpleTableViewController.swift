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
import Cartography
import IDMPhotoBrowser

class SimpleTableViewController: BaseTableViewController {
    lazy var tableHeaderView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        
        let scrollView = UIScrollView()
        view.addSubview(scrollView)
        constrain(scrollView) { $0.edges == inset($0.superview!.edges, 0) }
        scrollView.backgroundColor = .white
        scrollView.isPagingEnabled = true
        scrollView.delegate = self
        scrollView.tag = 100
        
        return view
    }()
    
    lazy var tableHeaderScrollView: UIScrollView = {
        return tableHeaderView.viewWithTag(100) as! UIScrollView
    }()
    
    var headerImages: [String]? = [] {
        didSet {
            headerImageViews.forEach { $0.removeFromSuperview() }
            headerImageViews.removeAll()
            guard let headerImages = headerImages, !headerImages.isEmpty else {
                tableView.tableHeaderView = nil
                return
            }
            
            tableView.tableHeaderView = tableHeaderView
            for i in 0 ..< headerImages.count {
                let imageView = UIImageView()
                imageView.tag = i
                headerImageViews.append(imageView)
                imageView.showProgress([.imageProgressSize(.normal)])
                imageView.sd_setImage(with: URL(string: headerImages[i]),
                                      placeholderImage: Config.Resource.defaultImage(.normal),
                                      options: [],
                                      progress:
                    { [weak imageView] (current, total, url) in
                        if let imageView = imageView, current > 0 && total > 0 {
                            imageView.progressComponent.setProgress(CGFloat(current / total),
                                                                    animated: true)
                        }
                }, completed: { [weak imageView]  (image, error, cacheType, url) in
                    if let imageView = imageView {
                        imageView.progressComponent.dismiss(true)
                    }
                })
                tableHeaderScrollView.addSubview(imageView)
                
                let button = UIButton(type: .custom)
                tableHeaderScrollView.addSubview(button)
                constrain(button, imageView) { (view1, view2) in
                    view1.top == view2.top
                    view1.bottom == view2.bottom
                    view1.leading == view2.leading
                    view1.trailing == view2.trailing
                }
                button.tag = 10000 + i
                button.addTarget(self, action: #selector(clickHeadImageView(_:)), for: .touchUpInside)
            }
            layoutHeaderImages()
            tableHeaderScrollView.setContentOffset(CGPoint(), animated: false)
        }
    }
    
    var headerImageViews: [UIView] = []
    
    func layoutHeaderImages() {
        let count = headerImageViews.count
        for i in 0 ..< count {
            headerImageViews[i].frame =
                CGRect(ScreenWidth * CGFloat(i), 0, ScreenWidth, headerImageHeight)
        }
        tableHeaderScrollView.contentSize = CGSize(ScreenWidth * CGFloat(count), headerImageHeight)
    }
    
    var headerImageHeight: CGFloat {
        return ScreenWidth * 548.0 / 1080.0 as CGFloat
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        setDefaultNavigationBar("List".localized)
        navBarRightButtonOptions = [.text([.title("Submit".localized)])]
        pageBackGestureStyle = .edge
        initView()
        showProgress(.opaque)
        getDataArray()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - 视图初始化
    
    func initView() {
        tableView.backgroundColor = UIColor.groupTableViewBackground
        tableHeaderView.frame = CGRect(0, 0, ScreenWidth, headerImageHeight)
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets()
    }
    
    override func deviceOrientationDidChange(_ sender: AnyObject?) {
        super.deviceOrientationDidChange(sender)
        guard guardDeviceOrientationDidChange(sender) else { return }
        
        if !headerImageViews.isEmpty {
            tableHeaderView.frame = CGRect(0, 0, ScreenWidth, headerImageHeight)
            layoutHeaderImages()
            tableView.tableHeaderView = tableHeaderView
        }
//        layoutViews()
        tableView.reloadData()
    }
    
    //MARK: - 业务处理
    
    func getDataArray(_ addMore: Bool = false) {
        var params = [:] as ParamDictionary
        params[Param.Key.limit] = TableLoadData.row
        let offset = addMore ? currentOffset + 1 : 0
        params[Param.Key.offset] = offset
        httpRequest(.get("data/getSimpleList", params: params), success: { [weak self] response in
            guard let strongSelf = self else { return }
            let dictionary = NonNull.dictionary((response as! JSON)[HTTP.Key.Response.data].object)
            if addMore {
                if offset == strongSelf.currentOffset + 1 { //只刷新新的一页数据，旧的或者更新的不刷
                    strongSelf.dismissProgress()
                    strongSelf.addMore(NonNull.array(dictionary[Param.Key.list]))
                }
            } else {
                strongSelf.headerImages = NonNull.array(dictionary[Param.Key.images]) as? [String]
                strongSelf.dismissProgress()
                strongSelf.refreshNew(NonNull.array(dictionary[Param.Key.list]))
            }
        }) { [weak self] failure in
            guard let strongSelf = self else { return }
            if addMore {
                if offset == strongSelf.currentOffset + 1 {
                    strongSelf.dismissProgress()
                    strongSelf.addMore(nil, errorMessage: failure.errorMessage)
                }
            } else {
                strongSelf.dismissProgress()
                strongSelf.addMore(nil, errorMessage: failure.errorMessage)
            }
        }
    }
    
    
    @objc func clickHeadImageView(_ sender: UIButton) {
        let urls = headerImages?.compactMap { URL(string: $0)}
        let index = sender.tag - 10000
        guard MutexTouch,
            let photoURLs = urls,
            !photoURLs.isEmpty,
            let headerImages = headerImages,
            let view = sender.superview?.viewWithTag(index),
            let browser = IDMPhotoBrowser(photoURLs: photoURLs, animatedFrom: view) else {
                return
        }
        
        browser.displayActionButton = false
        browser.displayArrowButton = !photoURLs.isEmpty
        browser.displayCounterLabel = !photoURLs.isEmpty
        browser.displayDoneButton = false
        browser.disableVerticalSwipe = true
        browser.dismissOnTouch = true
        if index < headerImages.count {
            browser.setInitialPageIndex(UInt(index))
        }
        navigationController?.present(browser, animated: true, completion: nil)
    }
    
    //MARK: - 事件响应
    
    override func clickNavigationBarRightButton(_ button: UIButton) {
        guard MutexTouch else { return }
        show("SimpleSubmitViewController", storyboard: "Simple")
    }
    
    //MARK: - UITableViewDelegate, UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return SimpleCell.Const.height
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell =
            tableView.dequeueReusableCell(withIdentifier: C.reuseIdentifier) as? SimpleCell
        if cell == nil {
            cell = Bundle.main.loadNibNamed("SimpleCell", owner: nil, options: nil)?.first as? SimpleCell
        }
        cell!.update(dataArray[indexPath.row] as! ParamDictionary)
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard MutexTouch else { return }
        
        if let dictionary = dataArray[indexPath.row] as? ParamDictionary,
            let url = dictionary[Param.Key.url] as? String {
            showWebpage(URL(string: url)!)
        }
    }
}
