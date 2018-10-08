//
//  SRVideoPlayer.swift
//  BaseSwift
//
//  Created by Gary on 2017/5/4.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer
import Cartography

@objc public protocol SRVideoPlayerDelegate {
    func player(didFailLoading player: SRVideoPlayer!, error: Error?)
    func player(isConnectingWwan player: SRVideoPlayer!) -> Bool
    func player(controlViewsDidShow player: SRVideoPlayer!)
    func player(controlViewsWillHide player: SRVideoPlayer!, animated: Bool)
}

public class SRVideoPlayer: NSObject,
    UIGestureRecognizerDelegate,
SRAssetResourceLoaderTaskDelegate {
    public weak var delegate: SRVideoPlayerDelegate?
    public var useCache = true //使用缓存
    public var autoPlay = true //自动播放
    public var autoFullScreen = false //是否自动全屏
    public var isAllowPlayingInWwan = false //是否允许在移动网络下播放视频
    
    var url: URL!
    
    var player: AVPlayer!
    var playerItem: AVPlayerItem?
    var resourceLoader: SRAssetResourceLoader?
    var playbackTimeObserver = NSObject()
    
    var playerView: SRPlayerView! //总视图
    var playerConstraintGroup = ConstraintGroup()
    var rotationAngle: CGFloat = 0
    var superview: UIView!
    var touchView = UIView() //点击/滑动的响应视图
    var bottomView = UIView()
    var playButton = UIButton() //播放/暂停按钮
    var screenButton = UIButton() //全屏/退出全屏按钮
    var currentTimeLabel = UILabel() //当前播放时间文字
    var totalTimeLabel = UILabel() //总播放时间文字
    var progressSlider = UISlider() //视频播放的控制条
    var loadedProgressView = UIProgressView(progressViewStyle: .default) //视频缓冲进度条
    
    var fastSeekView = UIView() //左右滑动而出发的快进或后退
    var fastSeekImageVIew = UIImageView()
    var fastSeekLabel = UILabel()
    
    var indicator = UIActivityIndicatorView() //加载视频时的旋转菊花
    var isIndicatorHidden: Bool {
        get {
            return indicator.isHidden
        }
        set {
            indicator.isHidden = newValue
            if newValue {
                indicator.stopAnimating()
            } else {
                indicator.startAnimating()
            }
        }
    }
    var repeatButton = UIButton() //重复播放按钮
    var brightnessView = SRBrightnessView() //亮度显示控件
    var volumeView = MPVolumeView() //音量控制控件
    var volumeSlider: UISlider! //音量控制控件辅助视图
    
    var alertView = UIView() //定制的提示框
    var alertContentView = UIView()
    var alertContentConstraintGroup = ConstraintGroup()
    var alertMessageLabel = UILabel()
    var alertMessageConstraintGroup = ConstraintGroup()
    var alertConfirmButton = UIButton()
    var alertConfirmConstraintGroup = ConstraintGroup()
    var alertCancelButton = UIButton()
    var alertCancelConstraintGroup = ConstraintGroup()
    var alertSeperatorLineView = UIView()
    
    var isPlaying = false //是否正在播放
    var isPlayingAppActive = false //应用在进入后台前的播放状态
    var isBuffering = false //是否在缓冲
    var isControlViewsHidden: Bool { return bottomView.isHidden }
    var isFullScreen: Bool { return playerView.superview != superview }
    var isPauseByUser = false //是否是用户主动暂停
    var isLocalVideo = true //是否是本地视频
    
    var currentDuration: Float = 0 //当前播放的时间
    var totalDuration: Float = 0 { //总的播放时间
        didSet {
            if Int(totalDuration) < 3600 {
                timeFormat = .minute
            } else {
                timeFormat = .hour
            }
            DispatchQueue.main.async {
                self.totalTimeLabel.text = self.text(playTime: self.totalDuration)
            }
        }
    }
    var timeFormat: PlayerTimeFormat = .hour
    
    var hiddenTimer: Timer? //控制上下菜单视图隐藏的timer
    var moveControlType: PlayerMoveControlType = .none //手势滑动的控制类型
    
    var touchBeginPoint: CGPoint! //触摸开始触碰到的点
    var touchBeginDuration: Float = 0 //触摸开始的播放时间
    var touchBeginBrightness: CGFloat = 0 //触摸开始的屏幕亮度
    var touchBeginVolume: CGFloat = 0 //触摸开始的音量
    
    override init() {
        super.init()
    }
    
    deinit {
        releasePlayer()
    }
    
    //MARK: - Public Interface
    
    public func play(_ url: URL!, inView: UIView!) {
        if player != nil, let playerItem = playerItem, playerItem.status == .readyToPlay {
            player.pause()
        }
        releasePlayer()
        
        self.url = url
        
        initView()
        superview = inView
        NotifyDefault.add(self,
                          selector: #selector(deviceOrientationDidChange(_:)),
                          name: .UIDeviceOrientationDidChange)
        NotifyDefault.add(self,
                          selector: #selector(didEnterBackground(_:)),
                          name: .UIApplicationDidEnterBackground)
        NotifyDefault.add(self,
                          selector: #selector(didBecomeActive(_:)),
                          name: .UIApplicationDidBecomeActive)
        if !autoFullScreen {
            show()
        } else {
            switch UIDevice.current.orientation {
            case .landscapeLeft:
                showFullScreen(orientation: .landscapeLeft)
                
            default:
                showFullScreen(orientation: .landscapeRight)
            }
        }
        currentTimeLabel.text = text(playTime: 0)
        
        initPlayer()
    }
    
    public func close() {
        pause()
        releasePlayer()
        bottomView.layer.removeAllAnimations()
        hiddenTimer?.invalidate()
        hiddenTimer = nil
        playerView.removeFromSuperview()
    }
    
    //通过外界更新连接到移动网络的情况
    public func connectWwan() {
        guard !isLocalVideo,
            !isAllowPlayingInWwan,
            let resourceLoader = resourceLoader,
            resourceLoader.isLoading else {
                return
        }
        
        
    }
    
    //MARK: - 视图初始化
    
    func initView() {
        guard playerView == nil else {
            return
        }
        
        playerView = SRPlayerView()
        playerView.backgroundColor = UIColor.black
        playerView.isUserInteractionEnabled = true
        
        bottomView.isUserInteractionEnabled = true
        playerView.addSubview(bottomView)
        constrain(bottomView) { (view) in
            view.bottom == view.superview!.bottom
            view.height == 44.0
            view.left == view.superview!.left
            view.right == view.superview!.right
        }
        
        playButton.image = UIImage(named: "player_play")
        playButton.contentEdgeInsets = UIEdgeInsetsMake(8.0, 8.0, 8.0, 8.0)
        playButton.clicked(self, action: #selector(clickPlayButton(_:)))
        bottomView.addSubview(playButton)
        constrain(playButton) { (view) in
            view.top == view.superview!.top
            view.left == view.superview!.left
            view.width == 44.0
            view.height == 44.0
        }
        
        screenButton.image = UIImage(named: "player_full_screen")
        screenButton.contentEdgeInsets = UIEdgeInsetsMake(8.0, 8.0, 8.0, 8.0)
        screenButton.clicked(self, action: #selector(clickScreenButton(_:)))
        bottomView.addSubview(screenButton)
        constrain(screenButton) { (view) in
            view.top == view.superview!.top
            view.right == view.superview!.right
            view.width == 44.0
            view.height == 44.0
        }
        
        currentTimeLabel.textColor = UIColor.white
        currentTimeLabel.font = UIFont.systemFont(ofSize: 11.0)
        currentTimeLabel.textAlignment = .center
        currentTimeLabel.adjustsFontSizeToFitWidth = true
        bottomView.addSubview(currentTimeLabel)
        constrain(currentTimeLabel, playButton) { (view1, view2) in
            view1.top == view1.superview!.top
            view1.left == view2.right
            view1.width == 55.0
            view1.height == 44.0
        }
        
        totalTimeLabel.textColor = UIColor.white
        totalTimeLabel.font = UIFont.systemFont(ofSize: 11.0)
        totalTimeLabel.textAlignment = .center
        totalTimeLabel.adjustsFontSizeToFitWidth = true
        bottomView.addSubview(totalTimeLabel)
        constrain(totalTimeLabel, screenButton) { (view1, view2) in
            view1.top == view1.superview!.top
            view1.right == view2.left
            view1.width == 55.0
            view1.height == 44.0
        }
        
        //progressSlider
        progressSlider.setThumbImage(UIImage(named: "player_progress"), for: .normal)
        progressSlider.minimumTrackTintColor = UIColor.white
        progressSlider.maximumTrackTintColor = UIColor.clear
        progressSlider.addTarget(self,
                                 action: #selector(progressSliderChanged(_:)),
                                 for: .valueChanged)
        progressSlider.addTarget(self,
                                 action: #selector(progressSliderChangEnd(_:)),
                                 for: .touchUpInside)
        progressSlider.addTarget(self,
                                 action: #selector(progressSliderChangEnd(_:)),
                                 for: .touchUpOutside)
        progressSlider.addTarget(self,
                                 action: #selector(progressSliderChangEnd(_:)),
                                 for: .touchCancel)
        var tapGR = UITapGestureRecognizer(target: self,
                                           action: #selector(handleProgressSliderTap(_:)))
        tapGR.numberOfTapsRequired = 1
        tapGR.numberOfTouchesRequired = 1
        tapGR.delegate = self
        progressSlider.addGestureRecognizer(tapGR)
        bottomView.addSubview(progressSlider)
        constrain(progressSlider, currentTimeLabel) { (view1, view2) in
            view1.top == view1.superview!.top
            view1.bottom == view1.superview!.bottom
            view1.left == view2.right
        }
        constrain(progressSlider, totalTimeLabel) { (view1, view2) in
            view1.right == view2.left
        }
        
        loadedProgressView.progressTintColor = UIColor(white: 1.0, alpha: 0.5)
        loadedProgressView.trackTintColor = UIColor.clear
        loadedProgressView.layer.cornerRadius = 0.5
        loadedProgressView.layer.masksToBounds = true
        loadedProgressView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        bottomView.insertSubview(loadedProgressView, belowSubview: progressSlider)
        constrain(loadedProgressView, progressSlider) { (view1, view2) in
            view1.centerY == view1.superview!.centerY
            view1.height == 2.0
            view1.left == view2.left
            view1.right == view2.right
        }
        
        //touchView
        tapGR = UITapGestureRecognizer(target: self, action: #selector(handleTouchViewTap(_:)))
        tapGR.numberOfTapsRequired = 1
        tapGR.numberOfTouchesRequired = 1
        tapGR.delegate = self
        touchView.addGestureRecognizer(tapGR)
        
        let panGR = UIPanGestureRecognizer(target: self, action: #selector(handleTouchViewPan(_:)))
        panGR.minimumNumberOfTouches = 1
        panGR.maximumNumberOfTouches = 1
        panGR.delegate = self
        touchView.addGestureRecognizer(panGR)
        
        playerView.addSubview(touchView)
        constrain(touchView) { (view) in
            view.top == view.superview!.top + 44.0
            view.bottom == view.superview!.bottom - 44.0
            view.left == view.superview!.left
            view.right == view.superview!.right
        }
        
        isIndicatorHidden = true
        playerView.addSubview(indicator)
        constrain(indicator) { (view) in
            view.centerX == view.superview!.centerX
            view.centerY == view.superview!.centerY
            view.width == 64.0
            view.height == 64.0
        }
        
        fastSeekView.layer.cornerRadius = 7.0
        fastSeekView.layer.masksToBounds = true
        fastSeekView.isHidden = true
        playerView.addSubview(fastSeekView)
        constrain(fastSeekView) { (view) in
            view.centerX == view.superview!.centerX
            view.centerY == view.superview!.centerY
            view.width == 150.0
            view.height == 60.0
        }
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        fastSeekView.addSubview(blurView)
        constrain(blurView) { (view) in
            view.top == view.superview!.top
            view.bottom == view.superview!.bottom
            view.left == view.superview!.left
            view.right == view.superview!.right
        }
        
        fastSeekView.addSubview(fastSeekImageVIew)
        constrain(fastSeekImageVIew) { (view) in
            view.top == view.superview!.top + 12.0
            view.centerX == view.superview!.centerX
            view.width == 29.0
            view.height == 20.0
        }
        
        fastSeekLabel.textColor = UIColor.white
        fastSeekLabel.font = UIFont.systemFont(ofSize: 12.0)
        fastSeekLabel.textAlignment = .center
        fastSeekView.addSubview(fastSeekLabel)
        constrain(fastSeekLabel, fastSeekImageVIew) { (view1, view2) in
            view1.top == view2.bottom + 5.0
            view1.bottom == view1.superview!.bottom - 8.0
            view1.left == view1.superview!.left + 5.0
            view1.right == view1.superview!.right - 5.0
        }
        
        repeatButton.image = UIImage(named: "player_repeat")
        repeatButton.contentEdgeInsets = UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0)
        repeatButton.clicked(self, action: #selector(clickRepeatButton(_:)))
        repeatButton.isHidden = true
        playerView.addSubview(repeatButton)
        constrain(repeatButton) { (view) in
            view.centerX == view.superview!.centerX
            view.centerY == view.superview!.centerY
            view.width == 64.0
            view.height == 64.0
        }
        
        brightnessView.isHidden = true
        playerView.addSubview(brightnessView)
        constrain(brightnessView) { (view) in
            view.centerX == view.superview!.centerX
            view.centerY == view.superview!.centerY
            view.width == SRBrightnessView.Const.width
            view.height == SRBrightnessView.Const.height
        }
        
        volumeView.showsRouteButton = false
        volumeView.showsVolumeSlider = false
        volumeSlider = volumeView.viewWithClass(NSClassFromString("MPVolumeSlider")!)! as? UISlider
        playerView.addSubview(volumeView)
        
        alertView.backgroundColor = UIColor(white: 0, alpha: 0.7)
        alertView.isHidden = true
        playerView.addSubview(alertView)
        constrain(alertView) { $0.edges == inset($0.superview!.edges, 0) }
        
        alertContentView.backgroundColor = UIColor.white
        alertContentView.layer.cornerRadius = 10.0
        alertContentView.layer.masksToBounds = true
        alertView.addSubview(alertContentView)
        
        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.black
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16.0)
        titleLabel.textAlignment = .center
        titleLabel.text = "Alert".localized
        alertContentView.addSubview(titleLabel)
        constrain(titleLabel) { (view) in
            view.top == view.superview!.top
            view.height == 44.0
            view.left == view.superview!.left
            view.right == view.superview!.right
        }
        
        alertMessageLabel.textColor = UIColor.darkGray
        alertMessageLabel.font = UIFont.systemFont(ofSize: 14.0)
        alertMessageLabel.textAlignment = .center
        alertContentView.addSubview(alertMessageLabel)
        
        alertConfirmButton.titleColor = UIColor.blue
        alertConfirmButton.titleFont = UIFont.systemFont(ofSize: 16.0)
        alertConfirmButton.clicked(self, action: #selector(clickAlertConfirmButton(_:)))
        alertContentView.addSubview(alertConfirmButton)
        
        var topLineView = UIView()
        topLineView.backgroundColor = UIColor.lightGray
        alertConfirmButton.addSubview(topLineView)
        constrain(topLineView) { (view) in
            view.top == view.superview!.top
            view.height == 0.5
            view.left == view.superview!.left
            view.right == view.superview!.right
        }
        
        alertCancelButton.title = "Cancel".localized
        alertCancelButton.titleColor = UIColor.black
        alertCancelButton.titleFont = UIFont.systemFont(ofSize: 16.0)
        alertCancelButton.clicked(self, action: #selector(clickAlertCancelButton(_:)))
        alertContentView.addSubview(alertCancelButton)
        
        topLineView = UIView()
        topLineView.backgroundColor = UIColor.lightGray
        alertCancelButton.addSubview(topLineView)
        constrain(topLineView) { (view) in
            view.top == view.superview!.top
            view.height == 0.5
            view.left == view.superview!.left
            view.right == view.superview!.right
        }
        
        alertSeperatorLineView.backgroundColor = UIColor.lightGray
        alertContentView.addSubview(alertSeperatorLineView)
        constrain(alertSeperatorLineView) { (view) in
            view.bottom == view.superview!.top
            view.centerX == view.superview!.centerX
            view.width == 0.5
            view.height == 44.0
        }
    }
    
    func initPlayer() {
        currentDuration = 0
        totalDuration = 0
        isLocalVideo = true
        
        var playURL = url
        if "http" == playURL?.scheme || "https" == playURL?.scheme {
            var isDirectory: ObjCBool = false
            let filePath = SRVideoPlayer.localVideoPath(url)
            if !FileManager.default.fileExists(atPath: filePath, isDirectory: &isDirectory)
                || isDirectory.boolValue {
                isLocalVideo = false
            } else {
                playURL = URL(fileURLWithPath: filePath)
            }
        }
        
        if !isLocalVideo {
            if useCache {
                resourceLoader = SRAssetResourceLoader(url: playURL)
                resourceLoader?.delegate = self
                var components = URLComponents(url: playURL!, resolvingAgainstBaseURL: false)!
                components.scheme = "streaming"
                playURL = components.url
                let videoURLAsset = AVURLAsset(url: playURL!)
                videoURLAsset.resourceLoader.setDelegate(resourceLoader, queue: DispatchQueue.main)
                playerItem = AVPlayerItem(asset: videoURLAsset)
            } else {
                playerItem = AVPlayerItem(asset: AVURLAsset(url: playURL!))
            }
        } else {
            playerItem = AVPlayerItem(asset: AVAsset(url: playURL!))
        }
        
        playerItem?.addObserver(self,
                                forKeyPath: Const.PlayerItemKeyPath.status,
                                options: .new,
                                context: nil)
        playerItem?.addObserver(self,
                                forKeyPath: Const.PlayerItemKeyPath.loadedTimeRanges,
                                options: .new,
                                context: nil)
        playerItem?.addObserver(self,
                                forKeyPath: Const.PlayerItemKeyPath.playbackBufferEmpty,
                                options: .new,
                                context: nil)
        playerItem?.addObserver(self,
                                forKeyPath: Const.PlayerItemKeyPath.presentationSize,
                                options: .new,
                                context: nil)
        NotifyDefault.add(self,
                          selector: #selector(playerItemDidPlayToEnd(_:)),
                          name: .AVPlayerItemDidPlayToEndTime,
                          object: playerItem!)
        NotifyDefault.add(self,
                          selector: #selector(playerItemPlaybackStalled(_:)),
                          name: .AVPlayerItemPlaybackStalled,
                          object: playerItem!)
        player = AVPlayer.init(playerItem: playerItem)
        (playerView.layer as! AVPlayerLayer).player = player
    }
    
    func releasePlayer() {
        guard player != nil, let playerItem = playerItem else {
            return
        }
        
        NotifyDefault.remove(self)
        playerItem.removeObserver(self, forKeyPath: Const.PlayerItemKeyPath.status)
        playerItem.removeObserver(self, forKeyPath: Const.PlayerItemKeyPath.loadedTimeRanges)
        playerItem.removeObserver(self, forKeyPath: Const.PlayerItemKeyPath.isPlaybackLikelyToKeepUp)
        playerItem.removeObserver(self, forKeyPath: Const.PlayerItemKeyPath.playbackBufferEmpty)
        playerItem.removeObserver(self, forKeyPath: Const.PlayerItemKeyPath.presentationSize)
        player.removeTimeObserver(playbackTimeObserver)
        self.playerItem = nil
        if let resourceLoader = self.resourceLoader {
            resourceLoader.cancel()
            self.resourceLoader = nil
        }
    }
    
    enum PlayerMoveControlType: Int {
        case none = 0,
        play,
        brightness,
        volume,
        unknown
    }
    
    enum PlayerTimeFormat: Int {
        case minute = 0,
        hour
    }
    
    struct Const  {
        struct PlayerItemKeyPath {
            static let status = "status"
            static let loadedTimeRanges = "loadedTimeRanges"
            static let isPlaybackLikelyToKeepUp = "isPlaybackLikelyToKeepUp"
            static let playbackBufferEmpty = "playbackBufferEmpty"
            static let presentationSize = "presentationSize"
        }
        
        static let moveMinOffset = 15.0 as CGFloat
        
        static let alertWidth = 200.0 as CGFloat
        static let alertMessageMaxHeight = 100.0 as CGFloat
        static let alertMessageMargin = 15.0 as CGFloat
    }
    
    //MARK: - 业务处理
    
    class func localVideoPath(_ url: URL!) -> String {
        SRVideoRequestTask.createFileItems()
        let fileName = url.absoluteString.md5() + ".mp4"
        return SRVideoRequestTask.videosDirectory.appending(pathComponent: fileName)
    }
    
    func text(playTime: Float) -> String {
        let seconds = lroundf(floorf(playTime))
        if timeFormat == .minute {
            return String(format: "%02d:%02d", seconds / 60, seconds % 60)
        } else {
            return String(format: "%02d:%02d:%02d",
                          seconds / 3600,
                          (seconds % 3600) / 60,
                          seconds % 60)
        }
    }
    
    func playTime(_ x: CGFloat) -> Float {
        let offset = 90.0 * (x - touchBeginPoint.x) / UIScreen.main.bounds.size.width
        let playTime = touchBeginDuration + Float(offset)
        return min(Float(totalDuration), max(0, playTime))
    }
    
    //MARK: Update views
    
    func updateFastSeekView(_ playTime: Float) {
        fastSeekImageVIew.image =
            UIImage(named: playTime < touchBeginDuration ? "player_rewind" : "player_fast_forward")
        fastSeekLabel.text = String(format: "%@/%@",
                                    text(playTime: playTime),
                                    text(playTime: totalDuration))
        if fastSeekView.isHidden {
            fastSeekView.isHidden = false
        }
    }
    
    func showControlViews() {
        bottomView.layer.removeAllAnimations()
        UIApplication.shared.isStatusBarHidden = isFullScreen
        bottomView.alpha = 1.0
        bottomView.isHidden = false
        bottomView.isUserInteractionEnabled = true
        delegate?.player(controlViewsDidShow: self)
    }
    
    func hideControlViews(_ animated: Bool) {
        delegate?.player(controlViewsWillHide: self, animated: animated)
        if !animated {
            bottomView.layer.removeAllAnimations()
            UIApplication.shared.isStatusBarHidden = isFullScreen
            bottomView.alpha = 1.0
            bottomView.isHidden = true
        } else {
            bottomView.isUserInteractionEnabled = false
            UIView.animate(withDuration: 0.5, animations: {
                UIApplication.shared.isStatusBarHidden = self.isFullScreen
                self.bottomView.alpha = 0
            }, completion: { (finished) in
                if finished {
                    self.bottomView.alpha = 0
                    self.bottomView.isHidden = true
                }
            })
        }
    }
    
    func startHiddenTimer() {
        hiddenTimer?.invalidate()
        hiddenTimer = nil
        hiddenTimer = Timer.scheduledTimer(timeInterval: 5.0,
                                           target: self,
                                           selector: #selector(stopHiddenTimer),
                                           userInfo: nil,
                                           repeats: false)
    }
    
    @objc func stopHiddenTimer() {
        hiddenTimer?.invalidate()
        hiddenTimer = nil
        hideControlViews(true)
    }
    
    //MARK: Player view
    
    func show() {
        guard playerView.superview != superview else {
            return
        }
        
        playerView.removeFromSuperview()
        superview.addSubview(playerView)
        playerConstraintGroup =
            constrain(playerView, replace: playerConstraintGroup) {
                $0.edges == inset($0.superview!.edges, 0)
        }
        if rotationAngle != 0 {
            UIView.animate(withDuration: 0.5, animations: {
                self.playerView.transform = CGAffineTransform.identity
            }, completion: { (finished) in
                if finished {
                    self.rotationAngle = 0
                }
            })
        }
    }
    
    func showFullScreen(orientation: UIInterfaceOrientation) {
        let window = UIApplication.shared.keyWindow!
        if playerView.superview != window {
            var width = UIScreen.main.bounds.size.width
            var height = UIScreen.main.bounds.size.height
            if width < height {
                width = width + height
                height = width - height
                width = width - height
            }
            playerView.removeFromSuperview()
            window.addSubview(playerView)
            playerConstraintGroup =
                constrain(playerView, replace: playerConstraintGroup) { (view) in
                    view.centerX == view.superview!.centerX
                    view.centerY == view.superview!.centerY
                    view.width == width
                    view.height == height
            }
        }
        let rotationAngle = self.rotationAngle
        updateRotationAngle(orientation: orientation)
        let transform = self.rotationAngle == 0
            ? CGAffineTransform.identity
            : CGAffineTransform(rotationAngle: self.rotationAngle)
        if rotationAngle != self.rotationAngle {
            UIView.animate(withDuration: 0.5, animations: {
                self.playerView.transform = transform
            }, completion: { (finished) in
                
            })
        } else {
            playerView.transform = transform
        }
    }
    
    func updateRotationAngle(orientation: UIInterfaceOrientation) {
        let statusBarOrientation = UIApplication.shared.statusBarOrientation
        if statusBarOrientation == orientation {
            rotationAngle = 0
        } else {
            //计算旋转的角度
            rotationAngle =
                angle(orientation: orientation) - angle(orientation: statusBarOrientation)
        }
    }
    
    //为每个方向设置一个角度
    func angle(orientation: UIInterfaceOrientation) -> CGFloat {
        switch orientation {
        case .portrait:
            return 0
            
        case .landscapeRight:
            return CGFloat.pi / 2
            
        case .portraitUpsideDown:
            return CGFloat.pi
            
        case .landscapeLeft:
            return -CGFloat.pi
            
        default:
            return 0
        }
    }
    
    //MARK: Player
    
    func play() {
        isPlaying = true
        playButton.image = UIImage(named: "player_pause")
        isIndicatorHidden = true
        player.play()
    }
    
    func pause() {
        isPlaying = false
        playButton.image = UIImage(named: "player_play")
        isIndicatorHidden = true
        player.pause()
    }
    
    func seek(_ playTime: Float) {
        guard let playerItem = playerItem, playerItem.status == .readyToPlay else {
            return
        }
        
        let seconds = Int64(min(totalDuration, max(0, playTime)))
        player.pause()
        playButton.image = UIImage(named: "player_pause")
        isIndicatorHidden = false
        player.seek(to: CMTimeMake(seconds, Int32(NSEC_PER_SEC))) { [weak self] (finished) in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.isIndicatorHidden = true
            
            if !finished {
                strongSelf.playButton.image = UIImage(named: "player_play")
                strongSelf.isPlaying = false
                return
            }
            
            strongSelf.isPauseByUser = false
            if !strongSelf.isPlaying {
                strongSelf.isPlaying = true
                strongSelf.playButton.image = UIImage(named: "player_pause")
            }
            strongSelf.repeatButton.isHidden = true
            strongSelf.player.play()
        }
    }
    
    func updateLoadedProgress() {
        guard let playerItem = playerItem else {
            return
        }
        
        let range = playerItem.loadedTimeRanges.first!.timeRangeValue
        let start = CMTimeGetSeconds(range.start)
        let duration = CMTimeGetSeconds(range.duration)
        let totalDuration = CMTimeGetSeconds(playerItem.duration)
        let progress = max((start + duration) / totalDuration, 1.0)
        loadedProgressView.setProgress(Float(progress), animated: true)
    }
    
    func buffering() {
        //反复监控到playbackBufferEmpty
        guard !isBuffering else {
            return
        }
        
        //需要先暂停一小会之后再播放，否则网络状况不好的时候时间在走，声音播放不出来
        isBuffering = true
        pause()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0,
                                      execute:
            { [weak self] in
                self?.isBuffering = false
                guard let strongSelf = self, !strongSelf.isPauseByUser else {  //如果此时用户已经暂停了，则不再需要开启播放
                    return
                }
                
                strongSelf.play()
                //如果执行了play还是没有播放则说明还没有缓存好，则再次缓存
                if let playerItem = strongSelf.playerItem, !playerItem.isPlaybackLikelyToKeepUp {
                    strongSelf.buffering()
                }
        })
    }
    
    //MARK: Alert
    
    func showAlert(_ message: String? = "Load fail".localized) {
        let height = alertMessageHeight(message!)
        alertMessageLabel.text = message!
        constrainAlertMessage(height)
        constrainAlertContent(height)
        alertConfirmConstraintGroup =
            constrain(alertConfirmButton) { (view) in
                view.bottom == view.superview!.bottom
                view.left == view.superview!.left
                view.right == view.superview!.right
                view.height == 44.0
        }
        alertConfirmButton.title = "OK".localized
        alertCancelButton.isHidden = true
        alertSeperatorLineView.isHidden = true
        alertView.isHidden = false
        playerView.bringSubview(toFront: alertView)
    }
    
    func showWwanAlert() {
        let message = "Connecting to the Internet via a Cellular Data Network".localized
        let height = alertMessageHeight(message)
        alertMessageLabel.text = message
        constrainAlertMessage(height)
        constrainAlertContent(height)
        alertConfirmConstraintGroup =
            constrain(alertConfirmButton) { (view) in
                view.bottom == view.superview!.bottom
                view.right == view.superview!.right
                view.width == Const.alertWidth / 2.0
                view.height == 44.0
        }
        alertConfirmButton.title = "Continue play".localized
        alertCancelButton.isHidden = false
        alertCancelConstraintGroup =
            constrain(alertCancelButton) { (view) in
                view.bottom == view.superview!.bottom
                view.left == view.superview!.left
                view.width == Const.alertWidth / 2.0
                view.height == 44.0
        }
        alertSeperatorLineView.isHidden = false
        alertView.isHidden = false
        playerView.bringSubview(toFront: alertView)
    }
    
    func hideAlert() {
        alertView.isHidden = true
    }
    
    func alertMessageHeight(_ message: String) -> CGFloat {
        let maxWidth = Const.alertWidth - 2.0 * Const.alertMessageMargin
        let size = Common.fitSize(message, font: alertMessageLabel.font, maxWidth: maxWidth)
        return min(Const.alertMessageMaxHeight, ceil(size.height))
    }
    
    func constrainAlertMessage(_ height: CGFloat) {
        alertMessageConstraintGroup =
            constrain(alertMessageLabel) { (view) in
                view.top == view.superview!.top + 44.0
                view.left == view.superview!.left + Const.alertMessageMargin
                view.right == view.superview!.right - Const.alertMessageMargin
                view.height == height
        }
    }
    
    func constrainAlertContent(_ height: CGFloat) {
        alertContentConstraintGroup =
            constrain(alertContentView) { (view) in
                view.centerX == view.superview!.centerX
                view.centerY == view.superview!.centerY
                view.width == Const.alertWidth
                view.height == 44.0 + height + 44.0 + 10.0
        }
    }
    
    //MARK: - 事件响应
    
    override public func observeValue(forKeyPath keyPath: String?,
                                      of object: Any?,
                                      change: [NSKeyValueChangeKey : Any]?,
                                      context: UnsafeMutableRawPointer?) {
        if Const.PlayerItemKeyPath.status == keyPath { //监听播放器的初始化状态
            isIndicatorHidden = true
            switch playerItem!.status {
            case .readyToPlay:
                totalDuration =
                    Float(playerItem!.duration.value) / Float(playerItem!.duration.timescale)
                progressSlider.minimumValue = 0
                progressSlider.maximumValue = totalDuration
                progressSlider.value = 0
                playbackTimeObserver = player.addPeriodicTimeObserver(forInterval: CMTimeMake(1, 1),
                                                                      queue: nil,
                                                                      using:
                    { [weak self] (time) in
                        guard let strongSelf = self, let playerItem = strongSelf.playerItem else {
                            return
                        }
                        
                        let currentDuration =
                            Float(playerItem.currentTime().value) / Float(playerItem.currentTime().timescale)
                        strongSelf.currentTimeLabel.text = strongSelf.text(playTime: currentDuration)
                        strongSelf.progressSlider.value = currentDuration
                        // 不相等的时候才更新，否则seek时会持续跳动
                        if strongSelf.currentDuration != currentDuration {
                            strongSelf.currentDuration = currentDuration
                            if strongSelf.totalDuration < strongSelf.currentDuration {
                                strongSelf.totalDuration = strongSelf.currentDuration
                            }
                        }
                }) as! NSObject
                if autoPlay {
                    seek(0)
                }
                
            case .failed:
                print("playerItem.error: \n\(playerItem!.error!)")
                DispatchQueue.main.async {
                    self.showAlert(self.playerItem?.error?.localizedDescription)
                }
                delegate?.player(didFailLoading: self, error: playerItem?.error)
                
            default:
                break
            }
        } else if Const.PlayerItemKeyPath.loadedTimeRanges == keyPath { //播放器的下载进度
            updateLoadedProgress()
        } else if Const.PlayerItemKeyPath.isPlaybackLikelyToKeepUp == keyPath { //播放器的缓冲成功
            isIndicatorHidden = true
        } else if Const.PlayerItemKeyPath.playbackBufferEmpty == keyPath { //播放器进入缓冲数据的状态
            isIndicatorHidden = false
            if playerItem!.isPlaybackBufferEmpty {
                buffering()
            }
        } else if Const.PlayerItemKeyPath.presentationSize == keyPath { //监听播放器的尺寸
            print("playerItem.presentationSize: \(playerItem!.presentationSize)")
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        }
    }
    
    @objc func deviceOrientationDidChange(_ notification: Notification) {
        let orientation = UIDevice.current.orientation
        switch orientation { //对应的播放器方向旋转
        case .portrait, .portraitUpsideDown:
            show()
            
        case .landscapeLeft:
            showFullScreen(orientation: .landscapeLeft)
            
        case .landscapeRight:
            showFullScreen(orientation: .landscapeRight)
            
        default:
            break
        }
    }
    
    @objc func clickPlayButton(_ sender: Any) {
        guard let playerItem = playerItem, playerItem.status == .readyToPlay else {
            return
        }
        
        if isPlaying {
            isPauseByUser = true
            pause()
        } else {
            isPauseByUser = false
            play()
        }
    }
    
    @objc func clickScreenButton(_ sender: Any) {
        if !isFullScreen {
            screenButton.image = UIImage(named: "player_full_screen")
            show()
        } else {
            screenButton.image = UIImage(named: "player_resize")
            var orientation: UIInterfaceOrientation = .landscapeRight
            let statusBarOrientation = UIApplication.shared.statusBarOrientation
            if UIInterfaceOrientationIsLandscape(orientation) { //若当前视图的方向为横向
                orientation = statusBarOrientation //全屏方向与视图方向保持一致
            }
            showFullScreen(orientation: orientation)
        }
    }
    
    @objc func clickRepeatButton(_ sender: Any) {
        initPlayer()
        seek(0)
    }
    
    @objc func clickAlertConfirmButton(_ sender: Any) {
        if "OK".localized == alertConfirmButton.title(for: .normal) {
            hideAlert()
        } else {
            hideAlert()
            isAllowPlayingInWwan = true
            resourceLoader?.resume()
            play()
        }
    }
    
    @objc func clickAlertCancelButton(_ sender: Any) {
        hideAlert()
    }
    
    @objc func progressSliderChanged(_ slider: UISlider) {
        currentTimeLabel.text = text(playTime: slider.value)
    }
    
    @objc func progressSliderChangEnd(_ slider: UISlider) {
        currentTimeLabel.text = text(playTime: slider.value)
        seek(slider.value)
    }
    
    @objc func handleProgressSliderTap(_ gr: UITapGestureRecognizer) {
        guard gr.numberOfTapsRequired == 1 else {
            return
        }
        
        let x = gr.location(in: progressSlider).x
        let value = Float(x / progressSlider.frame.size.width) * progressSlider.maximumValue
        progressSlider.value = value
        currentTimeLabel.text = text(playTime: value)
        seek(value)
    }
    
    @objc func handleTouchViewTap(_ gr: UITapGestureRecognizer) {
        if gr.numberOfTapsRequired == 1 {
            if isControlViewsHidden {
                startHiddenTimer()
                showControlViews()
            } else {
                stopHiddenTimer()
            }
        } else if gr.numberOfTapsRequired == 2 {
            if isPlaying {
                isPauseByUser = true
                pause()
            } else {
                isPauseByUser = false
                play()
            }
        }
    }
    
    @objc func handleTouchViewPan(_ gr: UIPanGestureRecognizer) {
        let point = gr.location(in: touchView)
        
        switch gr.state {
        case .began:
            moveControlType = .none
            touchBeginPoint = point
            touchBeginDuration = progressSlider.value
            touchBeginBrightness = UIScreen.main.brightness
            touchBeginVolume = CGFloat(volumeSlider.value)
            
        case .changed:
            //如果移动的距离过短, 判断为没有移动
            if fabs(point.x - touchBeginPoint.x) < Const.moveMinOffset
                && fabs(point.y - touchBeginPoint.y) < Const.moveMinOffset {
                return
            }
            
            if moveControlType == .none { //初次判断滑动的控制类型
                let tan = fabs(point.y - touchBeginPoint.y) / fabs(point.x - touchBeginPoint.x)
                if tan < 1.0 / sqrt(3.0) { //滑动角度小于30度的时候, 控制播放进度
                    moveControlType = .play
                    brightnessView.hide()
                } else if tan > sqrt(3.0) { //滑动角度大于60度的时候, 控制声音或亮度
                    //屏幕左侧控制亮度, 右侧控制音量
                    if point.x < touchView.frame.size.width / 2.0 {
                        moveControlType = .brightness
                    } else {
                        moveControlType = .volume
                        brightnessView.hide()
                    }
                } else {
                    moveControlType = .unknown
                }
            }
            
            switch moveControlType {
            case .play:
                updateFastSeekView(playTime(point.x))
                
            case .brightness:
                UIScreen.main.brightness = ((point.y - touchBeginPoint.y) / 10000.0)
                
            case .volume:
                //计算滑动后的音量
                var volume =
                    touchBeginVolume - ((point.y - touchBeginPoint.y) / touchView.frame.size.height)
                volume = max(1.0, min(0, volume))
                volumeSlider.value = Float(volume)
                
            case .unknown:
                if isControlViewsHidden {
                    startHiddenTimer()
                    showControlViews()
                } else {
                    stopHiddenTimer()
                }
                
            default:
                break
            }
            
        case .ended, .cancelled:
            if moveControlType == .play { //手势停止后跳转视频指定时间
                fastSeekView.isHidden = true
                seek(playTime(point.x))
            }
            moveControlType = .none
            
        default:
            break
        }
    }
    
    //MARKL: Application background && active
    
    @objc func didEnterBackground(_ notification: Notification) {
        isPlayingAppActive = isPlaying
        if isPlaying {
            pause()
        }
    }
    
    @objc func didBecomeActive(_ notification: Notification) {
        if isPlayingAppActive {
            play()
        }
    }
    
    //MARKL: PlayerItem status
    
    //播放结束
    @objc func playerItemDidPlayToEnd(_ notification: Notification) {
        showControlViews()
        repeatButton.isHidden = false
        isPlaying = false
        playButton.image = UIImage(named: "player_play")
    }
    
    //网络差的状态会调用，不做处理，会在playbackBufferEmpty里面缓存之后重新播放
    @objc func playerItemPlaybackStalled(_ notification: Notification) {
        print("buffing...")
    }
    
    //MARK: - UIGestureRecognizerDelegate
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldReceive touch: UITouch) -> Bool {
        return moveControlType == .none
    }
    
    //MARK: - SRAssetResourceLoaderTaskDelegate
    
    func resourceLoader(shouldLoad resourceLoader: SRAssetResourceLoader!) -> Bool {
        guard !isAllowPlayingInWwan else {
            return true
        }
        
        if let delegate = delegate, delegate.player(isConnectingWwan: self) {
            pause()
            resourceLoader.suspend()
            DispatchQueue.main.async {
                self.showWwanAlert()
            }
            return false
        }
        
        return true
    }
    
    func resourceLoader(didComplete resourceLoader: SRAssetResourceLoader!) {
        print("load completed")
    }
    
    func resourceLoader(didFail resourceLoader: SRAssetResourceLoader!, error: Error!) {
        DispatchQueue.main.async {
            self.showAlert(error.localizedDescription)
        }
    }
}
