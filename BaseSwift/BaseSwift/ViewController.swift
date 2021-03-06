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
        srDefaultNavigationBarType = .sr
        srNavigationBarType = .sr
        setDefaultNavigationBar("Root")
        navBarLeftButtonOptions = []
        tableView.removeFromSuperview()
        srAddSubview(underTop: tableView)
        tableView.backgroundColor = UIColor.groupTableViewBackground
        tableView.tableFooterView = UIView()
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        }
        Common.rootVC = self
        
        if UserStandard[UDKey.showAdvertisingGuide] != nil {
            UserStandard[UDKey.showAdvertisingGuide] = nil
            srStateMachine.append(Event(.showAdvertisingGuard))
        }
        
        //启动程序检查并执行可以执行的option
        if let event = Common.events.first(where: { $0.option == .openWebpage }) {
            DispatchQueue.main.async { [weak self] in
                self?.srStateMachine.append(event)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        srPageBackGestureStyle = .none
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - SRStateMachineDelegate
    
    override func stateMachine(_ stateMachine: SRStateMachine, didFire event: Event) {
        switch event.option {
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
        var cell = tableView.dequeueReusableCell(withIdentifier: C.reuseIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: C.reuseIdentifier)
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
            Config.entrance = .simple
            srShow("SimpleViewController", storyboard: "Simple")
            
        case 1:
            Config.entrance = .sns
            srShow("LoginViewController", storyboard: "Profile")
            
        case 2:
            Config.entrance = .news
            srShow("NewsViewController", storyboard: "News")
            
        case 3:
            /*
             Entrance = .aggregation
             let mainMenuVC = UIViewController.srViewController("MainMenuViewController", "Aggregation")
             let leftMenuVC = UIViewController.srViewController("LeftMenuViewController", "Aggregation")
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
                    UserStandard[UDKey.enterAggregationEntrance] = true
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
