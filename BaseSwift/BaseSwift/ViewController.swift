//
//  ViewController.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/13.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import UIKit

class ViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the vivar typically from a nib.
        self.title = "Root"
        navigationBarBackgroundAlpha = NavigartionBar.backgroundBlurAlpha
        navigationBarTintColor = NavigartionBar.tintColor
        initNavigationBar()
        navBarLeftButtonSettings = nil
        tableView.backgroundColor = UIColor.groupTableViewBackground
        tableView.tableFooterView = UIView()
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        }
        Common.rootVC = self
        
        if UserStandard[USKey.showAdvertisingGuide] != nil {
            UserStandard[USKey.showAdvertisingGuide] = nil
            stateMachine.append(Event.showAdvertisingGuard)
        }
        
        //启动程序检查并执行可以执行的option
        if let action = Common.currentActionParams()?[ParamKey.action] {
            if Action.openWebpage == String(describing: action) {
                stateMachine.append(option: Event.option(Action.openWebpage)!)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        pageBackGestureStyle = .none
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - SRStateMachineDelegate
    
    override func stateMachine(_ stateMachine: SRStateMachine, didFire event: Int) {
        switch event {
        case Event.showAdvertisingGuard:
            publicBusinessComponent.showAdvertisingGuard()
            
        case Event.showAdvertising:
            publicBusinessComponent.showAdvertising()
            
        default:
            super.stateMachine(stateMachine, didFire: event)
        }
    }
}

//MARK: - UITableViewDelegate, UITableViewDataSource

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: ReuseIdentifier)
            cell?.selectionStyle = UITableViewCellSelectionStyle.default
            cell?.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
        }
        
        switch indexPath.row {
        case 0:
            cell?.textLabel?.text = "Simple".localized
            
        case 1:
            cell?.textLabel?.text = "SNS".localized
            
        case 2:
            cell?.textLabel?.text = "News".localized
            
        case 3:
            cell?.textLabel?.text = "Aggregation".localized
            
        default:
            break
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard Common.mutexTouch() else { return }
        
        switch indexPath.row {
        case 0:
            Entrance = .simple
            show("SimpleViewController", storyboard: "Simple")
            
        case 1:
            Entrance = .sns
            show("LoginViewController", storyboard: "Profile")
            
        case 2:
            Entrance = .news
            show("NewsViewController", storyboard: "News")
            
        case 3:
            /*
             Entrance = .aggregation
             let mainMenuVC = Common.viewController("MainMenuViewController", "Aggregation")
             let leftMenuVC = Common.viewController("LeftMenuViewController", "Aggregation")
             let navigationVC = SRNavigationController(rootViewController: mainMenuVC)
             let aggregationVC = AggregationViewController(mainViewController: navigationVC,
             leftMenuViewController: leftMenuVC)
             present(aggregationVC, animated: true, completion: {
             
             })
             */
            
            let alert = SRAlert()
            alert.addButton("OK".localized,
                            backgroundColor: NavigartionBar.backgroundColor,
                            action:
                {
                    UserStandard[USKey.enterAggregationEntrance] = true
                    UserStandard.synchronize()
                    exit(0)
            })
            alert.show(.notice,
                       title: EmptyString,
                       message: "Reopen the program to enter Aggregation mode".localized,
                       closeButtonTitle: "Cancel".localized)
            
        default:
            break
        }
    }
}
