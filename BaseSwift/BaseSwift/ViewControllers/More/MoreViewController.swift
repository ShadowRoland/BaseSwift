//
//  MoreViewController.swift
//  BaseSwift
//
//  Created by Shadow on 2016/12/9.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import UIKit
import MJRefresh
//import MWPhotoBrowser
import BarrageRenderer

class MoreViewController: BaseViewController {
    lazy var indexPathSet: SRIndexPathSet = SRIndexPathSet()
    var lastSection = IntegerInvalid
    var lastSectionWillAdd = IntegerInvalid
    var lastRow = IntegerInvalid
    
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
    var stockExchange = EmptyString
    var stockCode = EmptyString
    var stockName = EmptyString
    //weak var photoBrowser: MWPhotoBrowser?
    //var photos: [MWPhoto] = []
    var photoIndexes: [UInt] = [] //已经被置成白色背景的图片序号
    
    //MARK: Barrage
    var barrageView: UIView!
    var barrageRenderer: BarrageRenderer!
    var barrageTimer: Timer?
    var barrageIndex = 0
    var barrages: [Any]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotifyDefault.add(self,
                          selector: #selector(getProfile),
                          name: Notification.Name.This.refreshProfile)
        NotifyDefault.add(self,
                          selector: #selector(reloadProfile),
                          name: Notification.Name.This.reloadProfile)
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
        static var cellHeight = TableCellHeight
    }
    
    func initView() {
        let freshHeader = SRMJRefreshHeader(refreshingBlock: { [weak self] in
            if Common.isLogin() {
                self?.getProfile()
            } else {
                self?.tableView.mj_header.endRefreshing()
                self?.presentLoginVC()
            }
        })
        freshHeader.stateLabel.isHidden = true
        freshHeader.lastUpdatedTimeLabel.isHidden = true
        tableView.mj_header = freshHeader
        tableView.tableFooterView = UIView()
        initSections()
        reloadProfile()
        deviceOrientationDidChange()
        tableView.reloadData()
    }
    
    func initSections() {
        indexPathSet.removeAll()
        lastSection = IntegerInvalid
        initSection1()
        initSection2()
        initSection3()
    }
    
    func initSection1() {
        lastSection = lastSectionWillAdd
        lastRow = IntegerInvalid
        
        item(huangLiCell)
        item(qiuQianCell)
        item(ceShiCell)
        item(guPiaoCell)
        item(qiuYiCell)
    }
    
    func initSection2() {
        lastSection = lastSectionWillAdd
        lastRow = IntegerInvalid
        
        item(danMuCell)
        item(youXiCell)
    }
    
    func initSection3() {
        lastSection = lastSectionWillAdd
        lastRow = IntegerInvalid
        
        item(settingCell)
    }
    
    @discardableResult
    func item(_ cell: UITableViewCell) -> SRIndexPathTable? {
        let item = SRIndexPathTable()
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
        httpRequest(.get(.profile), success: { response in
            self.tableView.mj_header.endRefreshing()
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
        if let profile = Common.currentProfile(), profile.isLogin {
            headPortraitImageView.sd_setImage(with: URL(string: NonNull.string(profile.headPortrait)),
                                              placeholderImage: Resource.defaultHeadPortrait(.normal))
            nameLabel.text = profile.name?.fullName
            userNameLabel.text = profile.userName
        } else {
            headPortraitImageView.image = Resource.defaultHeadPortrait(.normal)
            nameLabel.text = "Click Login".localized
            userNameLabel.text = "More money, more power".localized
        }
    }
    
    func updateCellHeight() {
        Const.textFont = UIFont.Preferred.body
        Const.detailFont = UIFont.Preferred.subheadline
        Const.cellHeight = max(TableCellHeight,
                               Const.textFont.lineHeight + 2.0 * Const.textLabelMarginVertical)
    }
    
    func presentLoginVC(_ params: ParamDictionary? = nil) {
        let vc =
            Common.viewController("LoginViewController", storyboard: "Profile") as! LoginViewController
        if let params = params {
            vc.params = params
        }
        present(SRModalViewController.standard(vc), animated: true, completion: nil)
    }
    
    //MARK: Stock
    
    func showStockExchangeAlert() {
        let alert = SRAlert()
        alert.addButton("Shanghai Composite Index".localized,
                        backgroundColor: NavigartionBar.backgroundColor,
                        action:
            { [weak self] in
                self?.stockExchange = "sh"
                self?.showStockCodeAlert()
        })
        alert.addButton("Shenzhen Composite Index".localized,
                        backgroundColor: NavigartionBar.backgroundColor,
                        action:
            { [weak self] in
                self?.stockExchange = "sz"
                self?.showStockCodeAlert()
        })
        alert.show(.info,
                   title: "Select stock exchange".localized,
                   message: EmptyString,
                   closeButtonTitle: "Cancel".localized)
    }
    
    func showStockCodeAlert() {
        let alert = SRAlert()
        let textField = alert.addTextField()
        textField.keyboardType = .numberPad
        textField.delegate = self
        textField.text = stockCode
        
        alert.addButton("OK".localized,
                        backgroundColor: NavigartionBar.backgroundColor,
                        action:
            { [weak self] in
                guard self != nil, let text = textField.text?.condense,
                    !Common.isEmptyString(textField.text) else {
                        return
                }
                
                self?.stockCode = text
                self?.httpRequest(.get(.sinaStockList),
                                  url: String(format: "http://hq.sinajs.cn/list=%@", (self?.stockExchange)! + text), //获取股票信息的api
                                  success:
                    { response in
                        if let data = response as? Data {
                            let encoding = CFStringConvertEncodingToNSStringEncoding(UInt32(CFStringEncodings.GB_18030_2000.rawValue))
                            let text = String(data: data, encoding: String.Encoding(rawValue: encoding))
                            print("stockListResponse:\n\(text ?? EmptyString)")
                            if let components = text?.components(separatedBy: "\""),
                                components.count > 0,
                                let stockName = components[1].components(separatedBy: ",").first,
                                !stockName.isEmpty {
                                self?.stockName = stockName
                                self?.showStockImages((self?.stockExchange)! + (self?.stockCode)!)
                                return
                            }
                        }
                        Common.showAlert(message: "Wrong stock code".localized, type: .error)
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
        /*
         let photoBrowser: MWPhotoBrowser = MWPhotoBrowser(delegate: self)
         photoBrowser.displayActionButton = false
         photoBrowser.displayNavArrows = false
         photoBrowser.displaySelectionButtons = false
         photoBrowser.alwaysShowControls = false
         photoBrowser.zoomPhotosToFill = true
         photoBrowser.enableGrid = false
         photoBrowser.startOnGrid = false
         photoBrowser.enableSwipeToDismiss = true
         photos.removeAll()
         photos.append(MWPhoto(url: URL(string: String(format: "http://image.sinajs.cn/newchart/min/n/%@.gif", stockCode))))
         photos.append(MWPhoto(url: URL(string: String(format: "http://image.sinajs.cn/newchart/daily/n/%@.gif", stockCode))))
         photos.append(MWPhoto(url: URL(string: String(format: "http://image.sinajs.cn/newchart/weekly/n/%@.gif", stockCode))))
         photos.append(MWPhoto(url: URL(string: String(format: "http://image.sinajs.cn/newchart/monthly/n/%@.gif", stockCode))))
         self.photoBrowser = photoBrowser
         photoIndexes.removeAll()
         present(SRModalViewController.standard(photoBrowser), animated: true, completion:nil)
         */
    }
    
    //MARK: - Barrage
    
    func showBarrages() {
        if barrageView == nil {
            barrageView = UIView()
            barrageView.backgroundColor = MaskBackgroundColor
            view.addSubview(barrageView)
            
            barrageRenderer = BarrageRenderer()
            barrageRenderer.canvasMargin =
                UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
            barrageRenderer.redisplay = true
            barrageView.addSubview(barrageRenderer.view)
            
            let filePath = ResourceDirectory.appending(pathComponent: "json/debug/barrages.json")
            barrages = Common.readJsonFile(filePath) as! [Any]?
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
        guard Common.mutexTouch() else { return }
        if Common.isLogin() {
            show("ProfileViewController", storyboard: "Profile")
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
                descriptor.params["textColor"] = UIColor(hex: value as! String)
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
 return EmptyString
 }
 }
 
 func numberOfPhotos(in photoBrowser: MWPhotoBrowser!) -> UInt {
 return UInt(photos.count)
 }
 
 func photoBrowser(_ photoBrowser: MWPhotoBrowser!, photoAt index: UInt) -> MWPhotoProtocol! {
 if Int(index) < photos.count {
 return photos[Int(index)]
 }
 return nil
 }
 
 func photoBrowser(_ photoBrowser: MWPhotoBrowser!, didDisplayPhotoAt index: UInt) {
 guard !photoIndexes.contains(index) else {
 return
 }
 
 photoIndexes.append(index)
 if let scrollView = photoBrowser.view.viewWithClass(UIScrollView.self) {
 scrollView.subviews.forEach {
 print($0)
 if let imageView = $0.viewWithClass(UIImageView.self) {
 imageView.backgroundColor = UIColor.white
 }
 }
 }
 }
 }
 */

//MARK: - UITextFieldDelegate

extension MoreViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        if string.length > 0 {
            return string.regex(Regex.number) //Stock
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
        let view = UIView(frame: CGRect(0, 0, tableView.width, SectionHeaderHeight))
        view.backgroundColor = UIColor.groupTableViewBackground
        return view
    }
    
    func tableView(_ tableView: UITableView,
                   heightForFooterInSection section: Int) -> CGFloat {
        return SectionHeaderGroupNoHeight
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
        if let item = indexPathSet[indexPath] as? SRIndexPathTable,
            let cell = item.cell {
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard Common.mutexTouch() else { return }
        
        let cell = tableView.cellForRow(at: indexPath)
        if cell === settingCell {
            show("SettingViewController", storyboard: "Profile")
            return
        }
        
        if !Common.isLogin() {
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
            if !Common.isEmptyString(stockExchange) && !Common.isEmptyString(stockCode) {
                showStockCodeAlert()
            } else {
                showStockExchangeAlert()
            }
        } else if cell === qiuYiCell {
            show("MapViewController", storyboard: "More")
        } else if cell === danMuCell {
            showBarrages()
        } else if cell === youXiCell {
            if !UIApplication.shared.statusBarOrientation.isPortrait {
                Common.showToast("Please rotate screen to portrait!")
            } else {
                show("M2ViewController", storyboard: "More")
            }
        }
    }
}
