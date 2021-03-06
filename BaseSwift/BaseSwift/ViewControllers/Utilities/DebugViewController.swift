//
//  DebugViewController.swift
//  BaseSwift
//
//  Created by Gary on 2017/5/26.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import SRKit

class DebugViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    lazy var safariCell: UITableViewCell =
        tableView.dequeueReusableCell(withIdentifier: "safariCell")!
    lazy var localNotificationCell: UITableViewCell =
        tableView.dequeueReusableCell(withIdentifier: "localNotificationCell")!
    private lazy var cells: [UITableViewCell] = [safariCell, localNotificationCell]
    
    var url: URL!
    var localDuration: TimeInterval!
    var localParams: ParamDictionary!

    override func viewDidLoad() {
        super.viewDidLoad()

        setDefaultNavigationBar()
        
        tableView.tableFooterView = UIView()
        //let filePath = C.resourceDirectory.appending(pathComponent: "html/debug_call_app.html")
        //url = URL(fileURLWithPath: filePath)
        url = URL(string: "http://127.0.0.1:9999/debug_call_app.html")
        safariCell.detailTextLabel?.text = url.absoluteString
        
        localDuration = 10.0
        localParams = [Param.Key.action : Event.Action.openWebpage.rawValue,
                       Param.Key.url : "http://baike.baidu.com/link?url=wg0mbCH5oS8BfaogPk70zgXJx-RAHYyyeZwhU2QPmx_FAxg9x4nwyf6KLxygH5EXJ_UvMkn6bOgCC84-JjGFqU7JeCzKwiBAsp4CeEGzThW",
                       Param.Key.message: "打开特定的网页"]
        localNotificationCell.detailTextLabel?.text =
            String(int: Int(localDuration)) + "秒后，参数：" + String(jsonObject: localParams).condense
   }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

//MARK: - UITableViewDelegate, UITableViewDataSource

extension DebugViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cells[indexPath.row]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard MutexTouch else { return }

        let cell = tableView.cellForRow(at: indexPath)!
        if safariCell === cell {
            srPopBack()
            UIApplication.shared.openURL(url)
        } else if localNotificationCell === cell {
            let notification = UILocalNotification()
            notification.fireDate = Date(timeIntervalSinceNow: localDuration)
            notification.userInfo = localParams
            notification.alertBody = localParams[Param.Key.message] as? String
            notification.repeatInterval = NSCalendar.Unit(rawValue: 0)
            notification.soundName = UILocalNotificationDefaultSoundName
            notification.applicationIconBadgeNumber = 1
            UIApplication.shared.scheduleLocalNotification(notification)
            srPopBack()
        }
    }
}
