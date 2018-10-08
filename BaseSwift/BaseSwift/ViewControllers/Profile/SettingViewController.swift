//
//  SettingViewController.swift
//  BaseSwift
//
//  Created by Gary on 2017/1/12.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit
import LocalAuthentication
import SDWebImage

class SettingViewController: BaseViewController {
    var indexPathSet: SRIndexPathSet!
    var lastSection = IntegerInvalid
    var lastSectionWillAdd = IntegerInvalid
    var lastRow = IntegerInvalid
    
    @IBOutlet weak var tableView: UITableView!
    lazy var lockScreenCell: UITableViewCell = {
        let cell = tableCell("lockScreenCell")
        lockScreenSwitch = cell.contentView.viewWithTag(Const.switchTag) as? UISwitch
        lockScreenSwitch.addTarget(self,
                                   action: #selector(lockScreenSwitchValueChanged(_:)),
                                   for: .valueChanged)
        return cell
    }()
    weak var lockScreenSwitch: UISwitch!
    
    lazy var wifiLoadImagesCell: UITableViewCell = {
        let cell = tableCell("wifiLoadImagesCell")
        wifiLoadImagesSwitch = cell.contentView.viewWithTag(Const.switchTag) as? UISwitch
        wifiLoadImagesSwitch.addTarget(self,
                                       action: #selector(wifiLoadImagesSwitchValueChanged(_:)),
                                       for: .valueChanged)
        return cell
    }()
    weak var wifiLoadImagesSwitch: UISwitch!
    
    lazy var authenticateCell: UITableViewCell = {
        let cell = tableCell("wifiLoadImagesCell")
        authenticateSwitch = cell.contentView.viewWithTag(Const.switchTag) as? UISwitch
        authenticateSwitch.addTarget(self,
                                     action: #selector(authenticateSwitchValueChanged(_:)),
                                     for: .valueChanged)
        return cell
    }()
    weak var authenticateSwitch: UISwitch!
    
    lazy var nightModeCell: UITableViewCell = tableCell("nightModeCell")
    lazy var fontCell: UITableViewCell = tableCell("fontCell")
    lazy var fontSizeCell: UITableViewCell = tableCell("fontSizeCell")
    lazy var pushCell: UITableViewCell = tableCell("pushCell")
    
    lazy var clearCacheCell: UITableViewCell = {
        let cell = tableCell("clearCacheCell")
        cacheLabel = cell.contentView.viewWithTag(Const.detailLabelTag) as? UILabel
        return cell
    }()
    weak var cacheLabel: UILabel!
    
    lazy var helpCell: UITableViewCell = tableCell("helpCell")
    
    lazy var aboutCell: UITableViewCell = {
        let cell = tableCell("aboutCell")
        versionLabel = cell.contentView.viewWithTag(Const.detailLabelTag) as? UILabel
        return cell
    }()
    weak var versionLabel: UILabel!
    
    func tableCell(_ identifier: String) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: identifier)!
    }
    
    @IBOutlet var tableFooterView: UIView!
    @IBOutlet var submitButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        defaultNavigationBar("Setting".localized)
        initView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if baseBusinessComponent.isViewDidAppear {
            initSections()
            tableView.reloadData()
            DispatchQueue.main.async {
                self.updateCacheSize()
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    struct Const {
        static let textLabelTag = 100
        static var textFont: UIFont!
        static let switchTag = 101
        static let detailLabelTag = 101
        static var detailFont: UIFont!
        static let textLabelMarginVertical = 5.0 as CGFloat
        static var cellHeight = TableCellHeight
    }
    
    //MARK: - 视图初始化
    
    func initView() {
        updateCellHeight()
        initSections()
        initTableFooterView()
        initSwitches()
        updateCacheSize()
        submitButton.backgroundColor = UIColor.clear
        submitButton.backgroundImage = UIImage.rect(NavigartionBar.backgroundColor,
                                                    size: submitButton.bounds.size)
    }
    
    func initSections() {
        indexPathSet = SRIndexPathSet()
        lastSection = IntegerInvalid
        lastSectionWillAdd = lastSection
        
        //Section 0
        lastRow = IntegerZero
        
        item(lockScreenCell)
        item(wifiLoadImagesCell)
        item(authenticateCell)
        
        //Section 1
        lastSection = lastSectionWillAdd
        lastSectionWillAdd = lastSection
        lastRow = IntegerInvalid
        
        item(nightModeCell)
        item(fontCell)
        item(fontSizeCell)
        item(pushCell)
        
        //Section 2
        lastSection = lastSectionWillAdd
        lastSectionWillAdd = lastSection
        lastRow = IntegerInvalid
        
        item(clearCacheCell)
        item(helpCell)
        item(aboutCell)
    }
    
    @discardableResult
    func item(_ cell: UITableViewCell) -> SRIndexPathTable? {
        lastSectionWillAdd = lastSection + 1 //确保section会自增
        lastRow += 1
        let item = SRIndexPathTable(cell: cell)
        indexPathSet[IndexPath(row: lastRow, section: lastSectionWillAdd)] = item
        return item
    }
    
    func initTableFooterView() {
        if !Common.isLogin() {
            tableView.tableFooterView = UIView()
        }
    }
    
    func initSwitches() {
        lockScreenSwitch.isOn = UserStandard[USKey.isFreeInterfaceOrientations] == nil
        wifiLoadImagesSwitch.isOn = isOnlyShowImageInWLAN
        if canAuthenticate {
            authenticateSwitch.isOn = UserStandard[USKey.forbidAuthenticateToLogin] == nil
        }
    }
    
    //MARK: - 业务处理
    
    override func performViewDidLoad() {
        //FIXME: FOR DEBUG，广播“触发状态机的完成事件”的通知
        if let sender = params[ParamKey.sender] as? String,
            let event = params[ParamKey.event] as? Int {
            LogDebug(NSStringFromClass(type(of: self)) + ".\(#function), sender: \(sender), event: \(event)")
            NotifyDefault.post(name: Notification.Name.Base.didEndStateMachineEvent,
                               object: params)
        }
    }
    
    func updateCellHeight() {
        Const.textFont = UIFont.Preferred.body
        Const.detailFont = UIFont.Preferred.subheadline
        Const.cellHeight = max(TableCellHeight,
                               Const.textFont.lineHeight + 2.0 * Const.textLabelMarginVertical)
    }
    
    //MARK: LocalAuthentication
    
    var canAuthenticate: Bool {
        return checkAuthenticateDevice() && checkAuthenticateBusiness()
    }
    
    //查看硬件和系统是否支持
    func checkAuthenticateDevice() -> Bool {
        let context = LAContext()
        var error: NSError?
        let isSupport = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                                  error: &error)
        if !isSupport && error?.code == Int(kLAErrorTouchIDNotAvailable) {
            return false
        }
        return true
    }
    
    //查看业务上是否支持
    func checkAuthenticateBusiness() -> Bool {
        return Common.isLogin()
    }
    
    func checkAuthenticateSetting() -> Bool {
        let context = LAContext()
        var error: NSError?
        let isSupport = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                                  error: &error)
        if !isSupport {
            Common.showAlert(message: "Authenticate not setup".localized, type: .warning)
            return false
        }
        return true
    }
    
    func authenticate() {
        let context = LAContext()
        context.localizedFallbackTitle = EmptyString
        navigationController?.view.isUserInteractionEnabled = false //在弹出指纹验证的弹窗时禁止屏幕移动和按钮
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                               localizedReason: "Authenticate localized reason for login".localized)
        { (success, error) in
            if success {
                DispatchQueue.main.async {
                    UserStandard[USKey.forbidAuthenticateToLogin] = nil
                }
            } else {
                DispatchQueue.main.async {
                    self.authenticateSwitch.setOn(false, animated: true)
                }
            }
            DispatchQueue.main.async {
                self.navigationController?.view.isUserInteractionEnabled = true
            }
        }
    }
    
    //MARK: - Cache
    
    func updateCacheSize() {
        var size = UInt64(SDWebImageManager.shared().imageCache?.getSize() ?? 0)
        size += Common.fileSize(VideosDirectory)
        size += Common.fileSize(VideosCacheDirectory)
        if size == 0 {
            cacheLabel.text = "0M"
        } else if size >= 1000 * 1000 * 1000 {
            cacheLabel.text =
                String(format: "%.2fG", Double(size) / Double(1000 * 1000 * 1000))
        } else if size >= 1000 * 1000 {
            cacheLabel.text =
                String(format: "%.2fM", Double(size) / Double(1000 * 1000))
        } else {
            cacheLabel.text = String(format: "%.2fK", Double(size) / Double(1000))
        }
    }
    
    func clearCache() {
        DispatchQueue.global(qos: .default).async {
            let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory,
                                                                .userDomainMask,
                                                                true)[0]
            if let files = FileManager.default.subpaths(atPath: cachePath) {
                for filesPath in files {
                    if filesPath.regex("^Logs.*$") { //不能删除日志文件
                        continue
                    }
                    
                    let path = cachePath.appending(pathComponent: filesPath)
                    if !FileManager.default.fileExists(atPath: path) {
                        continue
                    }
                    
                    do {
                        try FileManager.default.removeItem(atPath: path)
                    } catch {
                        DispatchQueue.main.async {
                            LogError("Remove cache files failed: \(error.localizedDescription)")
                        }
                    }
                }
            }
            
            SDWebImageManager.shared().cancelAll()
            SDWebImageManager.shared().imageCache?.clearMemory()
            SDWebImageManager.shared().imageCache?.clearDisk(onCompletion: {
                DispatchQueue.main.async { [weak self] in
                    self?.updateCacheSize()
                    Common.showToast("Clear the cache successfully!".localized)
                }
            })
            
            do {
                try FileManager.default.removeItem(atPath: VideosDirectory)
                try FileManager.default.removeItem(atPath: VideosCacheDirectory)
            } catch {
                DispatchQueue.main.async {
                    LogError("Remove video files failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    //MARK: - 事件响应
    
    @objc func lockScreenSwitchValueChanged(_ sender: Any) {
        if lockScreenSwitch.isOn {
            ShouldAutorotate = false
            SupportedInterfaceOrientations = .portrait
            UserStandard[USKey.isFreeInterfaceOrientations] = nil
        } else {
            ShouldAutorotate = true
            SupportedInterfaceOrientations = .allButUpsideDown
            UserStandard[USKey.isFreeInterfaceOrientations] = true
        }
    }
    
    @objc func wifiLoadImagesSwitchValueChanged(_ sender: Any) {
        UserStandard[USKey.isAllowShowImageInWLAN] = wifiLoadImagesSwitch.isOn ? nil : true
        isOnlyShowImageInWLAN = UserStandard[USKey.isAllowShowImageInWLAN] == nil
    }
    
    @objc func authenticateSwitchValueChanged(_ sender: Any) {
        if authenticateSwitch.isOn {
            if checkAuthenticateSetting() {
                authenticate()
            }
        } else {
            UserStandard[USKey.forbidAuthenticateToLogin] = true
        }
    }
    
    @IBAction func clickSubmitButton(_ sender: Any) {
        Keyboard.hide {
            let alert = SRAlert()
            alert.addButton("Logout".localized,
                            backgroundColor: NavigartionBar.backgroundColor,
                            action:
                {
                    BF.callBusiness(BF.businessId(.profile, Manager.Profile.funcId(.logout)))
                    if Entrance == .sns {
                        Common.clearForLogin()
                    } else if Entrance == .news || Entrance == .aggregation {
                        self.initSections()
                        self.initTableFooterView()
                        self.tableView.reloadData()
                        //NotifyDefault.post(Notification.Name.This.reloadProfile)
                    }
            })
            alert.show(.notice,
                       title: "Are you sure?".localized,
                       message: EmptyString,
                       closeButtonTitle: "Cancel".localized)
        }
    }
    
    override func contentSizeCategoryDidChange() {
        updateCellHeight()
        tableView.reloadData()
    }
}

//MARK: - UITableViewDelegate, UITableViewDataSource

extension SettingViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return lastSection + 1;
    }
    
    func tableView(_ tableView: UITableView,
                   heightForFooterInSection section: Int) -> CGFloat {
        return section == 2 ? SectionHeaderGroupNoHeight : SectionHeaderHeight / 2.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return indexPathSet.items(headIndex: section).count
    }
    
    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Const.cellHeight
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let item = indexPathSet[indexPath] as? SRIndexPathTable, let cell = item.cell {
            if let label = cell.contentView.viewWithTag(Const.textLabelTag) as? UILabel {
                label.adjustsFontSizeToFitWidth = true
                label.font = Const.textFont
            }
            if let detailLabel = cell.contentView.viewWithTag(Const.detailLabelTag) as? UILabel {
                detailLabel.adjustsFontSizeToFitWidth = true
                detailLabel.font = Const.detailFont
            }
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard Common.mutexTouch() else { return }
        
        if clearCacheCell == tableView.cellForRow(at: indexPath) {
            clearCache()
        } else if helpCell == tableView.cellForRow(at: indexPath) {
            let filePath = ResourceDirectory.appending(pathComponent: "html/help.html")
            showWebpage(URL(fileURLWithPath: filePath))
        } else if aboutCell == tableView.cellForRow(at: indexPath) {
            let filePath = ResourceDirectory.appending(pathComponent: "html/about.html")
            showWebpage(URL(fileURLWithPath: filePath))
        }
    }
}
