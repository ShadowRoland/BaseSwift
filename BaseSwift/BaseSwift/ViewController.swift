//
//  ViewController.swift
//  BaseSwift
//
//  Created by Shadow on 2016/11/13.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import SRKit

class ViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the vivar typically from a nib.
        defaultNavigationBar("Root")
        navigationBarBackgroundAlpha = NavigationBar.backgroundBlurAlpha
        navigationBarTintColor = NavigationBar.tintColor
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
            stateMachine.append(option: .showAdvertisingGuard)
        }
        
        //启动程序检查并执行可以执行的option
        if let option = Event.option(Common.currentActionParams?[Param.Key.action]),
            .openWebpage == option {
            stateMachine.append(option: option)
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
        guard let option = Event.Option(rawValue: event) else {
            return
        }
        
        switch option {
        case .showAdvertisingGuard:
            publicBusinessComponent.showAdvertisingGuard()
            
        case .showAdvertising:
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
            cell?.selectionStyle = .default
            cell?.accessoryType = .disclosureIndicator
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
        guard MutexTouch else { return }
        
        switch indexPath.row {
        case 0:
            Configs.entrance = .simple
            show("SimpleViewController", storyboard: "Simple")
            
        case 1:
            Configs.entrance = .sns
            show("LoginViewController", storyboard: "Profile")
            
        case 2:
            Configs.entrance = .news
            show("NewsViewController", storyboard: "News")
            
        case 3:
            /*
             Entrance = .aggregation
             let mainMenuVC = UIViewController.viewController("MainMenuViewController", "Aggregation")
             let leftMenuVC = UIViewController.viewController("LeftMenuViewController", "Aggregation")
             let navigationVC = SRNavigationController(rootViewController: mainMenuVC)
             let aggregationVC = AggregationViewController(mainViewController: navigationVC,
             leftMenuViewController: leftMenuVC)
             present(aggregationVC, animated: true, completion: {
             
             })
             */
            
            let alert = SRAlert()
            alert.addButton("OK".localized,
                            backgroundColor: NavigationBar.backgroundColor,
                            action:
                {
                    UserStandard[USKey.enterAggregationEntrance] = true
                    UserStandard.synchronize()
                    exit(0)
            })
            alert.show(.notice,
                       title: "",
                       message: "Reopen the program to enter Aggregation mode".localized,
                       closeButtonTitle: "Cancel".localized)
            
        default:
            break
        }
    }
}
