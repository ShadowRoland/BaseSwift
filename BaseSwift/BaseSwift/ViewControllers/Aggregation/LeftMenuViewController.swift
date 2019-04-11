//
//  LeftMenuViewController.swift
//  BaseSwift
//
//  Created by Gary on 2017/2/25.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit
import SlideMenuControllerSwift

class LeftMenuViewController: BaseViewController {
    public weak var aggregationVC: AggregationViewController!
    public weak var mainMenuVC: MainMenuViewController!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var tableHeaderView: UIView!
    @IBOutlet weak var headerImageView: UIImageView! //header背景图片的拉伸目前使用frame赋值实现，也可以用约束，只是相对麻烦点
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var profileButton: UIButton!
    @IBOutlet weak var headPortraitBackgroundView: UIView!
    @IBOutlet weak var headPortraitImageView: UIImageView!
    
    var headerImageSize: CGSize! //图片的尺寸
    var headerImageHeight: CGFloat! //图片的高度
    var headerImageHeightOffset: CGFloat! //图片比tableHeaderHeight多出的高度
    
    struct Const {
        static let tableHeaderHeight = SlideMenuOptions.leftViewWidth * 8.0 / 16.0 as CGFloat
        static let nameFont = UIFont.system(16)
        static let nameTextColor = UIColor(hue: 192.0, saturation: 2.0, brightness: 95.0)
        static let nameShadowColor = UIColor.black
        static let nameShadowOffset = CGSize(1.0, 1.0)
        static let backgroundColorHighlighted = UIColor(255.0, 241.0, 136.0)
        static let loginTextColor = UIColor(hue: 42.0, saturation: 30.0, brightness: 84.0)
    }
    
    @IBOutlet var footerView: UIView!
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var settingButton: UIButton!
    @IBOutlet weak var exitButton: UIButton!
    
    var cells: [UITableViewCell] = []
    private var _selectedIndex = -1
    var selectedIndex: Int {
        get {
            return _selectedIndex
        }
        set(newValue) {
            guard newValue >= 0 else {
                return
            }
            
            var index = newValue
            if !cells.isEmpty && newValue > cells.count - 1 {
                index = cells.count - 1
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.tableView((self?.tableView)!,
                                didSelectRowAt: IndexPath(row: index, section: 0))
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        NotifyDefault.add(self,
                          selector: #selector(reloadProfile),
                          name:Configs.reloadProfileNotification)
        initView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - 视图初始化
    
    func initView() {
        tableView.tableFooterView = UIView()
        let titles = ["Latest".localized,
                      "Hottest".localized,
                      "Jokers".localized,
                      "Videos".localized,
                      "Pictures".localized,
                      "Favorites".localized]
        if _selectedIndex <= 0 {
            _selectedIndex = 0
        }
        for i in 0 ..< titles.count {
            let cell = UITableViewCell(style: .default, reuseIdentifier: ReuseIdentifier)
            cell.selectionStyle = .none
            cell.accessoryType = .disclosureIndicator
            cell.backgroundColor =
                i == _selectedIndex ? Const.backgroundColorHighlighted : UIColor.white
            cell.textLabel?.text = titles[i]
            cells.append(cell)
        }
        
        initTableHeaderView()
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
        headPortraitBackgroundView.backgroundColor = Const.backgroundColorHighlighted
        
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
        
        headerImageHeight =
            SlideMenuOptions.leftViewWidth * headerImageSize.height / headerImageSize.width
        headerImageHeightOffset = headerImageHeight - Const.tableHeaderHeight
        headerImageView.frame = CGRect(0,
                                       -headerImageHeightOffset,
                                       SlideMenuOptions.leftViewWidth,
                                       headerImageHeight)
    }
    
    //MARK: - 业务处理
    
    func getProfile() {
        httpRequest(.get(.profile), success: { response in
            self.reloadProfile()
        }, bfail: { response in
            let message = self.logBFail(.get(.profile), response: response, show: false)
            if !Common.isEmptyString(message) {
                Common.showToast(message)
            }
        }, fail: { _ in
            
        })
    }
    
    @objc func reloadProfile() {
        if !Common.isLogin() {
            headPortraitImageView.image = Configs.Resource.defaultHeadPortrait(.normal)
            nameLabel.text = "Please Login".localized
            return
        }
        
        let url = URL(string: NonNull.string(Common.currentProfile()?.headPortrait))
        headPortraitImageView.sd_setImage(with: url,
                                          placeholderImage: Configs.Resource.defaultHeadPortrait(.normal))
        nameLabel.text = Common.currentProfile()?.name?.fullName
    }
    
    //MARK: - 事件响应
    
    @IBAction func clickProfileButton(_ sender: Any) {
        guard Common.mutexTouch() else { return }
        aggregationVC.closeLeft()
        if !Common.isLogin() {
            mainMenuVC.presentLoginVC()
        } else {
            mainMenuVC.show("ProfileViewController", storyboard: "Profile")
        }
    }
    
    @IBAction func clickMessageButton(_ sender: Any) {
        guard Common.mutexTouch() else { return }
    }
    
    @IBAction func clickSettingButton(_ sender: Any) {
        guard Common.mutexTouch() else { return }
        aggregationVC.closeLeft()
        mainMenuVC.show("SettingViewController", storyboard: "Profile")
    }
    
    @IBAction func clickExitButton(_ sender: Any) {
        guard Common.mutexTouch() else { return }
        
        let alert = SRAlert()
        alert.addButton("OK".localized,
                        backgroundColor: NavigartionBar.backgroundColor,
                        action:
            {
                UserStandard[USKey.enterAggregationEntrance] = nil
                UserStandard.synchronize()
                exit(0)
        })
        alert.show(.notice,
                   title: EmptyString,
                   message: "Reopen the program to enter Homepage".localized,
                   closeButtonTitle: "Cancel".localized)
    }
}

//MARK: - UIScrollViewDelegate

extension LeftMenuViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = tableView.contentOffset.y
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
        } else { //上拉
            if headerImageView.height != headerImageHeight { //拉动幅度特别大，图片恢复
                var frame = headerImageView.frame
                frame.origin.y = -headerImageHeightOffset
                frame.size.height = headerImageHeight
                headerImageView.frame = frame
            }
        }
    }
}

//MARK: - UITableViewDelegate, UITableViewDataSource

extension LeftMenuViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cells[indexPath.row]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard _selectedIndex != indexPath.row else {
            return
        }
        
        var path = IndexPath(row: _selectedIndex, section: 0)
        tableView.cellForRow(at: path)?.backgroundColor = UIColor.white
        _selectedIndex = indexPath.row
        path = IndexPath(row: _selectedIndex, section: 0)
        tableView.cellForRow(at: path)?.backgroundColor = Const.backgroundColorHighlighted
        
        aggregationVC.closeLeft()
        switch indexPath.row {
        case 0:
            mainMenuVC.bringChildVCFront(mainMenuVC.latestVC)
        case 1:
            mainMenuVC.bringChildVCFront(mainMenuVC.hottestVC)
        case 2:
            mainMenuVC.bringChildVCFront(mainMenuVC.jokersVC)
        case 3:
            mainMenuVC.bringChildVCFront(mainMenuVC.videosVC)
        case 4:
            mainMenuVC.bringChildVCFront(mainMenuVC.picturesVC)
        case 5:
            mainMenuVC.bringChildVCFront(mainMenuVC.favoritesVC)
        default:
            break
        }
    }
}
