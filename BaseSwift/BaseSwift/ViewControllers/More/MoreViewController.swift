//
//  MoreViewController.swift
//  BaseSwift
//
//  Created by Shadow on 2016/12/9.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import SRKit
import IDMPhotoBrowser
import BarrageRenderer

class MoreViewController: BaseViewController {
    lazy var indexPathSet: SRIndexPath.Set = SRIndexPath.Set()
    var lastSection = -1
    var lastSectionWillAdd = -1
    var lastRow = -1
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var headPortraitImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var tableHeaderButton: UIButton!
    
    lazy var huangLiCell: UITableViewCell = tableCell("huangLiCell")
    lazy var qiuQianCell: UITableViewCell = tableCell("qiuQianCell")
    lazy var ceShiCell: UITableViewCell = tableCell("ceShiCell")
    lazy var guPiaoCell: UITableViewCell = tableCell("guPiaoCell")
    lazy var qiuYiCell: UITableViewCell = tableCell("qiuYiCell")
    lazy var danMuCell: UITableViewCell = tableCell("danMuCell")
    lazy var youXiCell: UITableViewCell = tableCell("youXiCell")
    lazy var settingCell: UITableViewCell = tableCell("settingCell")
    
    func tableCell(_ identifier: String) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: identifier)!
    }
    
    //MARK: Stock
    var stockExchange = ""
    var stockCode = ""
    var stockName = ""
    
    //MARK: Barrage
    var barrageView: UIView!
    var barrageRenderer: BarrageRenderer!
    var barrageTimer: Timer?
    var barrageIndex = 0
    var barrages: AnyArray!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotifyDefault.add(self,
                          selector: #selector(getProfile),
                          name: Config.refreshProfileNotification)
        NotifyDefault.add(self,
                          selector: #selector(reloadProfile),
                          name: Config.reloadProfileNotification)
        updateCellHeight()
        initView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isShowingBarrages {
            hideBarrages()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - 视图初始化
    
    struct Const {
        static var textFont: UIFont!
        static var detailFont: UIFont!
        static let textLabelMarginVertical = 5.0 as CGFloat
        static var cellHeight = C.tableCellHeight
    }
    
    func initView() {
        let freshHeader = SRMJRefreshHeader(refreshingBlock: { [weak self] in
            guard let strongSelf = self else { return }
            if ProfileManager.isLogin {
                strongSelf.getProfile()
            } else {
                strongSelf.tableView.mj_header?.endRefreshing()
                strongSelf.presentLoginVC()
            }
        })
        freshHeader.stateLabel?.isHidden = true
        freshHeader.lastUpdatedTimeLabel?.isHidden = true
        tableView.mj_header = freshHeader
        tableView.tableFooterView = UIView()
        initSections()
        reloadProfile()
        deviceOrientationDidChange()
        tableView.reloadData()
    }
    
    func initSections() {
        indexPathSet.removeAll()
        lastSection = -1
        initSection1()
        initSection2()
        initSection3()
    }
    
    func initSection1() {
        lastSection = lastSectionWillAdd
        lastRow = -1
        
        item(huangLiCell)
        item(qiuQianCell)
        item(ceShiCell)
        item(guPiaoCell)
        item(qiuYiCell)
    }
    
    func initSection2() {
        lastSection = lastSectionWillAdd
        lastRow = -1
        
        item(danMuCell)
        item(youXiCell)
    }
    
    func initSection3() {
        lastSection = lastSectionWillAdd
        lastRow = -1
        
        item(settingCell)
    }
    
    @discardableResult
    func item(_ cell: UITableViewCell) -> SRIndexPath.Table? {
        let item = SRIndexPath.Table()
        item.cell = cell
        lastSectionWillAdd = lastSection + 1 //确保section会自增
        lastRow += 1
        indexPathSet[IndexPath(row: lastRow, section: lastSectionWillAdd)] = item
        return item
    }
    
    //MARK: Autorotate Orientation
    
    override func deviceOrientationDidChange(_ sender: AnyObject? = nil) {
        super.deviceOrientationDidChange(sender)
        
        if isShowingBarrages {
            initBarrageFrame()
        }
    }
    
    //MARK: - 业务处理
    
    @objc func getProfile() {
        httpRequest(.get("user/profile"), success: { [weak self] _ in
            self?.tableView.mj_header?.endRefreshing()
            self?.reloadProfile()
        }) { failure in
            if failure.isBusiness {
                SRAlert.showToast(failure.errorMessage)
            }
        }
    }
    
    @objc func reloadProfile() {
        if let profile = ProfileManager.currentProfile, profile.isLogin {
            headPortraitImageView.sd_setImage(with: URL(string: NonNull.string(profile.headPortrait)),
                                              placeholderImage: Config.Resource.defaultHeadPortrait(.normal))
            nameLabel.text = profile.name?.fullName
            userNameLabel.text = profile.userName
        } else {
            headPortraitImageView.image = Config.Resource.defaultHeadPortrait(.normal)
            nameLabel.text = "Click Login".localized
            userNameLabel.text = "More money, more power".localized
        }
    }
    
    func updateCellHeight() {
        Const.textFont = UIFont.preferred.body
        Const.detailFont = UIFont.preferred.subheadline
        Const.cellHeight = max(C.tableCellHeight,
                               Const.textFont.lineHeight + 2.0 * Const.textLabelMarginVertical)
    }
    
    //MARK: Stock
    
    func showStockExchangeAlert() {
        let alert = SRAlert()
        alert.addButton("Shanghai Composite Index".localized,
                        backgroundColor: NavigationBar.backgroundColor,
                        action:
            { [weak self] in
                self?.stockExchange = "sh"
                self?.showStockCodeAlert()
        })
        alert.addButton("Shenzhen Composite Index".localized,
                        backgroundColor: NavigationBar.backgroundColor,
                        action:
            { [weak self] in
                self?.stockExchange = "sz"
                self?.showStockCodeAlert()
        })
        alert.show(.info,
                   title: "Select stock exchange".localized,
                   message: "",
                   closeButtonTitle: "Cancel".localized)
    }
    
    func showStockCodeAlert() {
        let alert = SRAlert()
        let textField = alert.addTextField()
        textField.keyboardType = .numberPad
        textField.delegate = self
        textField.text = stockCode
        
        alert.addButton("OK".localized,
                        backgroundColor: NavigationBar.backgroundColor,
                        action:
            { [weak self] in
                guard let strongSelf = self,
                    let text = textField.text?.condense,
                    !isEmptyString(textField.text) else {
                        return
                }
                
                strongSelf.stockCode = text
                strongSelf.httpRequest(.get("http://hq.sinajs.cn/list=\(strongSelf.stockExchange + text)"), success:
                    { [weak self] response in
                        guard let strongSelf = self else { return }
                        if let data = response as? Data {
                            let encoding = CFStringConvertEncodingToNSStringEncoding(UInt32(CFStringEncodings.GB_18030_2000.rawValue))
                            let text = String(data: data, encoding: String.Encoding(rawValue: encoding))
                            print("stockListResponse:\n\(text ?? "")")
                            if let components = text?.components(separatedBy: "\""),
                                !components.isEmpty,
                                let stockName = components[1].components(separatedBy: ",").first,
                                !stockName.isEmpty {
                                strongSelf.stockName = stockName
                                strongSelf.showStockImages(strongSelf.stockExchange + strongSelf.stockCode)
                                return
                            }
                        }
                        SRAlert.show(message: "Wrong stock code".localized, type: .error)
                })
        })
        alert.addButton("Reselect stock exchange".localized,
                        backgroundColor: "E066FF".color,
                        action:
            { [weak self] in
                self?.showStockExchangeAlert()
        })
        alert.show(.edit,
                   title: "Enter the stock code".localized,
                   message: String(format: "Current stock exchange is %@".localized,
                                   "sz" == stockExchange
                                    ? "Shenzhen Composite Index".localized
                                    : "Shanghai Composite Index".localized),
                   closeButtonTitle: "Cancel".localized)
    }
    
    func showStockImages(_ stockCode: String) {
        guard MutexTouch else { return }
        
        var urls = [] as [URL]
        if let url = URL(string: "http://image.sinajs.cn/newchart/min/n/\(stockCode).gif") {
            urls.append(url)
        }
        if let url = URL(string: "http://image.sinajs.cn/newchart/daily/n/\(stockCode).gif") {
            urls.append(url)
        }
        if let url = URL(string: "http://image.sinajs.cn/newchart/weekly/n/\(stockCode).gif") {
            urls.append(url)
        }
        if let url = URL(string: "http://image.sinajs.cn/newchart/monthly/n/\(stockCode).gif") {
            urls.append(url)
        }
        if !urls.isEmpty, let browser = IDMPhotoBrowser(photoURLs: urls) {
            browser.displayActionButton = false
            browser.displayArrowButton = !urls.isEmpty
            browser.displayCounterLabel = !urls.isEmpty
            browser.displayDoneButton = false
            browser.disableVerticalSwipe = true
            browser.dismissOnTouch = true
            navigationController?.present(browser, animated: true, completion: nil)
        }
    }
    
    //MARK: - Barrage
    
    func showBarrages() {
        if barrageView == nil {
            barrageView = UIView()
            barrageView.backgroundColor = C.maskBackgroundColor
            view.addSubview(barrageView)
            
            barrageRenderer = BarrageRenderer()
            barrageRenderer.canvasMargin =
                UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
            barrageRenderer.redisplay = true
            barrageView.addSubview(barrageRenderer.view)
            
            let filePath = C.resourceDirectory.appending(pathComponent: "json/debug/barrages.json")
            barrages = filePath.fileJsonObject as! AnyArray?
        }
        view.addSubview(barrageView)
        tableView.isScrollEnabled = false
        initBarrageFrame()
        startBarrages()
    }
    
    func hideBarrages() {
        stopBarrages()
        barrageView.removeFromSuperview()
        tableView.isScrollEnabled = true
    }
    
    var isShowingBarrages: Bool {
        return barrageView != nil && barrageView.superview != nil
    }
    
    func initBarrageFrame() {
        barrageView.frame = tableView.visibleContentRect
        barrageRenderer.view.frame = barrageView.bounds
    }
    
    func startBarrages() {
        barrageIndex = 0
        barrageCountUp()
        barrageTimer = Timer.scheduledTimer(timeInterval: 3.0,
                                            target: self,
                                            selector: #selector(barrageCountUp),
                                            userInfo: nil,
                                            repeats: true)
        barrageRenderer.start()
    }
    
    func stopBarrages() {
        barrageTimer?.invalidate()
        barrageTimer = nil
        barrageRenderer.stop()
    }
    
    //MARK: - 事件响应
    
    @IBAction func clickTableHeaderButton(_ sender: Any) {
        guard MutexTouch else { return }
        if ProfileManager.isLogin {
            srShow("ProfileViewController", storyboard: "Profile")
        } else {
            presentLoginVC()
        }
    }
    
    @objc func barrageCountUp() {
        if barrageIndex >= barrages.count {
            barrageTimer?.invalidate()
            barrageTimer = nil
            return
        }
        
        let array = NonNull.array(barrages[barrageIndex])
        array.filter { $0 is ParamDictionary }.forEach {
            let barrage = $0 as! ParamDictionary
            let descriptor = BarrageDescriptor()
            
            var value: Any?
            descriptor.params["text"] = NonNull.string(barrage["text"])
            if barrage.jsonValue("textColor", type: .string, outValue: &value) {
                descriptor.params["textColor"] = (value as! String).color
            } else {
                descriptor.params["textColor"] = UIColor.white
                //descriptor.params["shadowColor"] = UIColor.black
                //descriptor.params["shadowOffset"] = CGSize(0.5, 0.5)
            }
            if barrage.jsonValue("fontSize", type: .number, outValue: &value) {
                descriptor.params["fontSize"] = value
            }
            if barrage.jsonValue("speed", type: .number, outValue: &value) {
                descriptor.params["speed"] = value
            }
            if barrage.jsonValue("direction", type: .enumInt, outValue: &value) {
                descriptor.params["direction"] = value
            }
            if barrage.jsonValue("side", type: .enumInt, outValue: &value) {
                descriptor.params["side"] = value
            }
            
            descriptor.spriteName = NSStringFromClass(BarrageWalkTextSprite.self)
            if barrage.jsonValue("sprite", type: .string, outValue: &value) {
                if "floatText" == value as! String {
                    descriptor.spriteName = NSStringFromClass(BarrageFloatTextSprite.self)
                    if barrage.jsonValue("duration", type: .number, outValue: &value) {
                        descriptor.params["duration"] = value
                    }
                    if barrage.jsonValue("fadeInTime", type: .number, outValue: &value) {
                        descriptor.params["fadeInTime"] = value
                    }
                    if barrage.jsonValue("fadeOutTime", type: .number, outValue: &value) {
                        descriptor.params["fadeOutTime"] = value
                    }
                }
            }
            
            barrageRenderer.receive(descriptor)
        }
        
        barrageIndex += 1
    }
    
    override func contentSizeCategoryDidChange() {
        updateCellHeight()
        tableView.reloadData()
    }
}

/*
 //MARK: - MWPhotoBrowserDelegate
 
 extension MoreViewController: MWPhotoBrowserDelegate {
 func photoBrowser(_ photoBrowser: MWPhotoBrowser!, titleForPhotoAt index: UInt) -> String! {
 switch index {
 case 0:
 return stockName + "(" + "30 minutes candlestick chart") + ".localized"
 case 1:
 return stockName + "(" + "Daily candlestick chart") + ".localized"
 case 2:
 return stockName + "(" + "Weekly candlestick chart") + ".localized"
 case 3:
 return stockName + "(" + "Monthly candlestick chart") + ".localized"
 default:
 return ""
 }
 }
 */

//MARK: - UITextFieldDelegate

extension MoreViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        if !string.isEmpty {
            return string.regex(String.Regex.number) //Stock
        }
        return true
    }
}

//MARK: - UITableViewDelegate, UITableViewDataSource

extension MoreViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return indexPathSet.numberOfSections
    }
    
    func tableView(_ tableView: UITableView,
                   viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(0, 0, tableView.width, C.sectionHeaderHeight))
        view.backgroundColor = UIColor.groupTableViewBackground
        return view
    }
    
    func tableView(_ tableView: UITableView,
                   heightForFooterInSection section: Int) -> CGFloat {
        return C.sectionHeaderGroupNoHeight
    }
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return indexPathSet.items(headIndex: section).count
    }
    
    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Const.cellHeight
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let item = indexPathSet[indexPath] as? SRIndexPath.Table,
            let cell = item.cell {
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard MutexTouch else { return }
        
        let cell = tableView.cellForRow(at: indexPath)
        if cell === settingCell {
            srShow("SettingViewController", storyboard: "Profile")
            return
        }
        
        if !ProfileManager.isLogin {
            presentLoginVC()
            return
        }
        
        if cell === huangLiCell {
            showWebpage(URL(string: "http://sandbox.runjs.cn/show/ydp3it7b")!)
        } else if cell === qiuQianCell {
            showWebpage(URL(string: "http://sandbox.runjs.cn/show/yu9cs4i4")!)
        } else if cell === ceShiCell {
            showWebpage(URL(string: "http://gtest.sina.com.cn/astro/11707")!)
        } else if cell === guPiaoCell {
            if !isEmptyString(stockExchange) && !isEmptyString(stockCode) {
                showStockCodeAlert()
            } else {
                showStockExchangeAlert()
            }
        } else if cell === qiuYiCell {
            srShow("MapViewController", storyboard: "More")
        } else if cell === danMuCell {
            showBarrages()
        } else if cell === youXiCell {
            if !UIApplication.shared.statusBarOrientation.isPortrait {
                SRAlert.showToast("Please rotate screen to portrait!")
            } else {
                srShow("M2ViewController", storyboard: "More")
            }
        }
    }
}
