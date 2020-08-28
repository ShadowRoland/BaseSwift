//
//  ChatViewController.swift
//  BaseSwift
//
//  Created by Gary on 2017/4/24.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import SRKit
import Cartography

class ChatViewController: BaseViewController {
    var nickname: String?
    var previewedIndex = 0
    let conversation = RCConversationViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navBarLeftButtonOptions = [.image(UIImage("page_back")!)]
        addChild(conversation)
        srAddSubview(underTop: conversation.view)
    }
    
    //MARK: 3D Touch actions
    

    override var previewActionItems: [UIPreviewActionItem] {
        var actions = [] as [UIPreviewAction]
        let seeAction = UIPreviewAction(title: "See".localized, style: .default)
        { (action, previewViewController) in
            if let viewControllers = Common.rootVC?.navigationController?.viewControllers,
                let vc = viewControllers.last(where: { $0 is SNSViewController }) {
                vc.srShow(previewViewController)
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
