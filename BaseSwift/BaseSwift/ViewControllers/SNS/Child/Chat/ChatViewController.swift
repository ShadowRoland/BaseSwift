//
//  ChatViewController.swift
//  BaseSwift
//
//  Created by Gary on 2017/4/24.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import SRKit

class ChatViewController: RCConversationViewController {
    var nickname: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navBarLeftButtonOptions = [.image(UIImage("page_back")!)]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let vc = navigationController as? SRNavigationController {
            vc.isPageSwipeEnabled = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    open var navBarLeftButtonOptions: [NavigationBar.ButtonItemOption]? {
        didSet {
            guard let options = navBarLeftButtonOptions, !options.isEmpty else { //左边完全无按钮
                navigationItem.leftBarButtonItem =
                    UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
                return
            }
            
            //再添加新的按钮
            let items = (0 ..< options.count).compactMap {
                NavigationBar.buttonItem(options[$0],
                                         target: self,
                                         action: #selector(pageBack),
                                         tag: $0,
                                         useCustomView: navigationBarType != .system)
            }
            
            let type = navigationBarType
            if type == .system {
                if items.isEmpty {
                    navigationItem.leftBarButtonItem = nil
                    navigationItem.leftBarButtonItems = nil
                } else if items.count == 1 {
                    navigationItem.leftBarButtonItem = items.first
                } else {
                    navigationItem.leftBarButtonItems = items
                }
            } else if type == .sr {
                //srNavigationItem.leftBarButtonItems = items
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
                let vc = viewControllers.last(where: { $0 is SNSViewController }) {
                vc.show(previewViewController, sender: vc)
            }
        }
        actions.append(seeAction)
        let deleteAction = UIPreviewAction(title: "Delete".localized, style: .destructive)
        { (action, previewViewController) in
            if let viewControllers = Common.rootVC?.navigationController?.viewControllers,
                let vc = viewControllers.last(where: { $0 is SNSViewController }),
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
