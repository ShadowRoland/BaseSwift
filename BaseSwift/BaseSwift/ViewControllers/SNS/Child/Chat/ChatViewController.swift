//
//  ChatViewController.swift
//  BaseSwift
//
//  Created by Gary on 2017/4/24.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit

class ChatViewController: RCConversationViewController {
    var nickname: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        var setting = NavigartionBar.buttonFullSetting //获取带全属性的按钮字典
        setting[.style] = NavigartionBar.ButtonItemStyle.image //设置按钮的风格为纯图片
        setting[.image] = UIImage("page_back")
        navBarLeftButtonSettings = [setting]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let vc = navigationController as? SRNavigationController {
            vc.panEnable = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    public var navBarLeftButtonSettings: [[NavigartionBar.ButtonItemKey : Any]]? {
        didSet {
            guard let settings = navBarLeftButtonSettings, settings.count > 0 else {
                return
            }
            
            let items = (0 ..< settings.count).compactMap {
                BaseCommon.navigationBarButtonItem(settings[$0],
                                                   target: self,
                                                   action: #selector(pageBack),
                                                   tag: $0)
            }
            
            navigationItem.backBarButtonItem = nil
            if items.count == 0 {
                navigationItem.leftBarButtonItem = nil
                navigationItem.leftBarButtonItems = nil
            } else if items.count == 1 {
                navigationItem.leftBarButtonItem = items.first
            } else {
                navigationItem.leftBarButtonItems = items
            }
        }
    }
    
    @objc public func pageBack() {
        popBack()
    }
    
    //MARK: 3D Touch actions
    
    var previewedIndex = 0

    override var previewActionItems: [UIPreviewActionItem] {
        var actions = [] as [UIPreviewAction]
        let seeAction = UIPreviewAction(title: "See".localized, style: .default)
        { (action, previewViewController) in
            if let viewControllers = Common.rootVC?.navigationController?.viewControllers,
                let vc = viewControllers.reversed().first(where: { $0 is SNSViewController }) {
                vc.show(previewViewController, sender: vc)
            }
        }
        actions.append(seeAction)
        let deleteAction = UIPreviewAction(title: "Delete".localized, style: .destructive)
        { (action, previewViewController) in
            if let viewControllers = Common.rootVC?.navigationController?.viewControllers,
                let vc = viewControllers.reversed().first(where: { $0 is SNSViewController }),
                let chatVC = previewViewController as? ChatViewController {
                let chatListVC = (vc as! SNSViewController).chatListVC
                chatListVC.dataArray.remove(at: chatVC.previewedIndex)
                chatListVC.tableView.deleteRows(at: [IndexPath(row: chatVC.previewedIndex,
                                                               section: 0)],
                                                with: .automatic)
            }
        }
        actions.append(deleteAction)
        return actions
    }
}
