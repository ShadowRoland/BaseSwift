//
//  SRShareTool.swift
//  BaseSwift
//
//  Created by Gary on 2017/5/12.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit
import Cartography

public protocol SRShareToolDelegate: class {
    func shareTool(types shareTool: SRShareTool) -> [SRShareTool.CellType]?
    func shareTool(logo shareTool: SRShareTool, type: SRShareTool.CellType) -> UIImage?
    func shareTool(title shareTool: SRShareTool, type: SRShareTool.CellType) -> String?
    func shareTool(didSelect shareTool: SRShareTool, type: SRShareTool.CellType) -> Bool
}

extension SRShareToolDelegate {
    func shareTool(types shareTool: SRShareTool) -> [SRShareTool.CellType]? {
        return nil
    }
    
    func shareTool(logo shareTool: SRShareTool, type: SRShareTool.CellType) -> UIImage? {
        return nil
    }
    
    func shareTool(title shareTool: SRShareTool, type: SRShareTool.CellType) -> String? {
        return nil
    }
    
    func shareTool(didSelect shareTool: SRShareTool, type: SRShareTool.CellType) -> Bool {
        return false
    }
}

public class SRShareTool: UIViewController {
    public enum CellType {
        case tool(Tool)
        case share(Share)
        
        public enum Tool: UInt {
            case copyLink = 100, //复制链接
            openLinkInSafari, //在Safari中打开
            sms, //短信发送
            refresh //刷新（网页）
        }
        
        public enum Share: UInt {
            case wechatMoments = 200, //微信朋友圈
            wechat, //微信联系人
            qqZone, //QQ空间
            qq, //QQ联系人
            weibo, //微博
            facebook, //404-1
            twitter //404-2
        }
        
        static public func == (lhs: CellType, rhs: CellType?) -> Bool {
            return rhs != nil && lhs.rawValue == rhs!.rawValue
        }
        
        public var rawValue: UInt {
            switch self {
            case .tool(let value):
                return value.rawValue
            case .share(let value):
                return value.rawValue
            }
        }
        
        fileprivate var isTool: Bool {
            switch self {
            case .tool:
                return true
            default:
                return false
            }
        }
        
        fileprivate var isShare: Bool {
            switch self {
            case .share:
                return true
            default:
                return false
            }
        }
    }
    
    public static let defaultTypes: [SRShareTool.CellType] = [.tool(.copyLink),
                                                              .tool(.openLinkInSafari),
                                                              .tool(.sms),
                                                              .share(.wechatMoments),
                                                              .share(.wechat),
                                                              .share(.qqZone),
                                                              .share(.qq),
                                                              .share(.weibo)]
    
    public var option = SRShareOption()
    public weak var delegate: SRShareToolDelegate?
    
    public class var shared: SRShareTool {
        if sharedInstance == nil {
            sharedInstance = SRShareTool()
            sharedInstance?.initView()
        }
        return sharedInstance!
    }
    
    private static var sharedInstance: SRShareTool?
    
    private init() {
        super.init(nibName:nil, bundle:nil)
    }
    
    private override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName:nibNameOrNil, bundle:nibBundleOrNil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func show() {
        NotifyDefault.add(self,
                          selector: #selector(SRShareTool.deviceOrientationDidChange(_:) as (SRShareTool) -> (AnyObject?) -> ()),
                          name: .UIDeviceOrientationDidChange)
        UIApplication.shared.keyWindow!.addSubview(view)
        orientation = UIDevice.current.orientation
        reloadData()
        contentView.alpha = 0
        UIView.animate(withDuration: 0.25, animations: { [weak self] in
            self?.contentView.alpha = 1.0
        }) { [weak self] (finished) in
            self?.contentView.alpha = 1.0
        }
    }
    
    public func dismiss(_ animated: Bool = true) {
        NotifyDefault.remove(self)
        delegate = nil
        if animated {
            UIView.animate(withDuration: 0.25, animations: {
                self.contentView.alpha = 0
            }) { (finished) in
                self.contentView.alpha = 0
                self.view.removeFromSuperview()
            }
        } else {
            view.removeFromSuperview()
        }
    }
    
    public func reloadData() {
        reloadTypes()
        reloadCells()
        if orientation.isPortrait {
            view.frame = CGRect(0, 0, Const.screenWidth, Const.screenHeight)
        } else {
            view.frame = CGRect(0, 0, Const.screenHeight, Const.screenWidth)
        }
    }
    
    //MARK: - Private
    
    var defaultDelegate: SRShareToolDelegate = SRShareToolDefaultDelegate.shared
    private var orientation: UIDeviceOrientation = .unknown
    private var contentView = UIView()
    private var contentconstraintGroup = ConstraintGroup()
    private var toolScrollView = UIScrollView()
    private var shareScrollView = UIScrollView()
    private var shareSectionLabel = UILabel()
    private var cancelButton = UIButton()
    private var cells: [SRShareCellView] = []
    private var toolTypes: [SRShareTool.CellType] = []
    private var shareTypes: [SRShareTool.CellType] = []
    
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    //MARK: - Status Bar
    
    //设置为false后横屏状态下将默认显示状态栏，前提是info.plist设置View controller-based status bar appearance为YES
    //在某些不需要横屏状态下显示状态栏的页面，重写该方法，返回true
    override public var prefersStatusBarHidden: Bool { return false }
    
    //务必将Info.plist中的View controller-based status bar appearance设置为NO
    override public var preferredStatusBarStyle: UIStatusBarStyle { return .default }
    
    //MARK: - Autorotate Orientation
    
    override public var shouldAutorotate: Bool { return ShouldAutorotate }
    
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return SupportedInterfaceOrientations
    }
    
    override public var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return PreferredInterfaceOrientationForPresentation
    }
    
    @objc func deviceOrientationDidChange(_ sender: AnyObject? = nil) {
        guard guardDeviceOrientationDidChange(sender) else {
            self.orientation = UIDevice.current.orientation
            return
        }
        
        let orientation = UIDevice.current.orientation
        if (orientation.isPortrait && self.orientation.isPortrait)
            || (orientation.isLandscape && self.orientation.isLandscape) { //和原先同为横屏或者同为竖屏
            self.orientation = orientation
            return
        }
        
        if sender != nil {
            self.orientation = orientation
            reloadData()
        }
    }
    
    struct Const {
        static let maxColumn = 4 //在竖屏下最多显示的列数
        static let sectionTitleHeight = 25.0 as CGFloat //标题高度
        static let subviewMargin = 10.0 as CGFloat //标题高度
        static let cellMarginPortrait = 20.0 as CGFloat
        static var cellMarginLandscape = 0.0 as CGFloat
        static let cellTitleHeight = 36.0 as CGFloat
        static var screenWidth = 0 as CGFloat
        static var screenHeight = 0 as CGFloat
        static var cellWidth = 0 as CGFloat
        static var cellHeight = 0 as CGFloat
        static var cancelButtonHeight = 44.0 as CGFloat
    }
    
    func initConstVariable() {
        guard Const.screenWidth == 0 else {
            return
        }
        
        //Calculate & initialize const variable
        let size: CGSize = (UIScreen.main.currentMode?.size)!
        if size.width < size.height {
            Const.screenWidth = size.width / 2.0
            Const.screenHeight = size.height / 2.0
        } else {
            Const.screenWidth = size.height / 2.0
            Const.screenHeight = size.width / 2.0
        }
        let marginSum =
            2.0 * Const.subviewMargin + CGFloat(Const.maxColumn - 1) * Const.cellMarginPortrait
        Const.cellWidth = (Const.screenWidth - marginSum) / CGFloat(Const.maxColumn)
        Const.cellHeight =
            Const.cellWidth + SRShareCellView.Const.labelMarginTop + Const.cellTitleHeight
        //cellWidth * column + cellMarginLandscape * (column - 1) + 2 * subviewMargin = screenHeight
        //column = (screenHeight - 2 * subviewMargin + cellMarginLandscape) / (cellWidth + cellMarginLandscape)
        //cellMarginLandscape >= cellMarginPortrait
        let columnFloat = (Const.screenHeight - 2.0 * Const.subviewMargin)
            / (Const.cellWidth + Const.cellMarginPortrait)
        let column = lroundf(Float(columnFloat))
        Const.cellMarginLandscape =
            (Const.screenHeight - 2.0 * Const.subviewMargin - CGFloat(column) * Const.cellWidth)
            / CGFloat(column - 1)
    }
    
    func initView() {
        initConstVariable()
        
        view.autoresizingMask =
            [UIViewAutoresizing.flexibleHeight, UIViewAutoresizing.flexibleWidth]
        view.backgroundColor = MaskBackgroundColor
        
        contentView.backgroundColor = UIColor(white: 1.0, alpha: 0.8)
        contentView.isUserInteractionEnabled = true
        view.addSubview(contentView)
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        contentView.addSubview(blurView)
        constrain(blurView) { $0.edges == inset($0.superview!.edges, 0) }
        
        cancelButton.titleFont = UIFont.system(14.0)
        cancelButton.titleColor = UIColor.darkGray
        cancelButton.title = "Cancel".localized
        cancelButton.clicked(self, action: #selector(clickCancelButton(_:)))
        contentView.addSubview(cancelButton)
        constrain(cancelButton) { (view) in
            view.bottom == view.superview!.bottom
            view.height == Const.cancelButtonHeight
            view.left == view.superview!.left
            view.right == view.superview!.right
        }
        
        toolScrollView.showsHorizontalScrollIndicator = false
        toolScrollView.showsVerticalScrollIndicator = false
        toolScrollView.alwaysBounceVertical = false
        toolScrollView.contentInset =
            UIEdgeInsets(top: 0, left: Const.subviewMargin, bottom: 0, right: Const.subviewMargin)
        
        shareScrollView.showsHorizontalScrollIndicator = false
        shareScrollView.showsVerticalScrollIndicator = false
        shareScrollView.alwaysBounceVertical = false
        shareScrollView.contentInset =
            UIEdgeInsets(top: 0, left: Const.subviewMargin, bottom: 0, right: Const.subviewMargin)
        
        shareSectionLabel.font = UIFont.system(13.0)
        shareSectionLabel.text = "Share to".localized
    }
    
    //MARK: - Reload
    
    func reloadTypes() {
        var types: [SRShareTool.CellType]!
        if let delegate = delegate,
            let delegateTypes = delegate.shareTool(types: self),
            delegateTypes.count > 0 {
            types = delegateTypes
        } else {
            types = defaultDelegate.shareTool(types: self)!
        }
        
        //去重
        var distinctTypes = [] as [SRShareTool.CellType]
        types.forEach { type in
            if !distinctTypes.contains { $0 == type } {
                distinctTypes.append(type)
            }
        }
        toolTypes = distinctTypes.filter { $0.isTool }
        shareTypes = distinctTypes.filter { $0.isShare }
    }
    
    func reloadCells() {
        let toolCells = cells(types: toolTypes)
        let shareCells = cells(types: shareTypes)
        
        let isPortrait = UIInterfaceOrientationIsPortrait(UIApplication.shared.statusBarOrientation)
        let screenWidth = isPortrait ? Const.screenWidth : Const.screenHeight
        let screenHeight = isPortrait ? Const.screenHeight : Const.screenWidth
        let cellMargin = isPortrait ? Const.cellMarginPortrait : Const.cellMarginLandscape
        
        var originY = Const.subviewMargin
        var subviews = toolScrollView.subviews
        subviews.forEach{ $0.removeFromSuperview() }
        if toolCells.count > 0 {
            toolScrollView.frame = CGRect(0, originY, screenWidth, Const.cellHeight)
            contentView.addSubview(toolScrollView)
            layout(scrollView: toolScrollView, cells: cells, cellMargin: cellMargin)
            originY += Const.cellHeight
        } else {
            toolScrollView.removeFromSuperview()
        }
        
        subviews = shareScrollView.subviews
        subviews.forEach{ $0.removeFromSuperview() }
        if shareCells.count > 0 {
            shareSectionLabel.frame = CGRect(Const.subviewMargin,
                                             originY,
                                             screenWidth - 2.0 * Const.subviewMargin,
                                             Const.sectionTitleHeight)
            contentView.addSubview(shareSectionLabel)
            originY += Const.sectionTitleHeight
            
            shareScrollView.frame = CGRect(0, originY, screenWidth, Const.cellHeight)
            contentView.addSubview(shareScrollView)
            layout(scrollView: shareScrollView, cells: cells, cellMargin: cellMargin)
            originY += Const.cellHeight
        } else {
            shareSectionLabel.removeFromSuperview()
            shareScrollView.removeFromSuperview()
        }
        
        let height = originY + Const.cancelButtonHeight
        contentView.frame = CGRect(0, screenHeight - height, screenWidth, height)
    }
    
     func cells(types: [SRShareTool.CellType]) -> [SRShareCellView] {
        return types.map { type in
            if let cell = self.cells.first(where: { $0.type == type }) {
                return cell
            } else {
                let cell = SRShareCellView(type: type)
                cell.button.clicked(self, action: #selector(clickCellButton(_:)))
                return cell
            }
        }
    }
    
    func layout(scrollView: UIScrollView!, cells: [SRShareCellView]!, cellMargin: CGFloat!) {
        for i in 0 ..< cells.count {
            let cell = cells[i]
            let type = cell.type!
            var image: UIImage!
            var string: String!
            if let delegate = delegate,
                let logo = delegate.shareTool(logo: self, type: type) {
                image = logo
            } else {
                image = defaultDelegate.shareTool(logo: self, type: type)
            }
            
            if let delegate = delegate,
                let title = delegate.shareTool(title: self, type: type) {
                string = title
            } else {
                string = defaultDelegate.shareTool(title: self, type: type)
            }
            cell.layout(frame: CGRect(CGFloat(i) * (cellMargin + Const.cellWidth),
                                      0,
                                      Const.cellWidth,
                                      Const.cellHeight),
                        image: image, title: string)
            scrollView.addSubview(cell)
        }
        scrollView.contentSize =
            CGSize((Const.cellWidth + cellMargin) * CGFloat(cells.count) - cellMargin ,
                   Const.cellHeight)
    }
    
    @objc func clickCellButton(_ sender: Any) {
        guard Common.mutexTouch() else { return }
        
        DispatchQueue.main.async {
            self.dismiss()
        }
        
        let button = sender as! UIButton
        let cell = button.superview as! SRShareCellView
        if let delegate = delegate,
            !delegate.shareTool(didSelect: self, type: cell.type) {
            let _ = defaultDelegate.shareTool(didSelect: self, type: cell.type)
        } else {
            let _ = defaultDelegate.shareTool(didSelect: self, type: cell.type)
        }
    }
    
    @objc func clickCancelButton(_ sender: Any) {
        guard Common.mutexTouch() else { return }
        
        DispatchQueue.main.async {
            self.dismiss()
        }
    }
}

