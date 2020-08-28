//
//  SingleContactViewController.swift
//  BaseSwift
//
//  Created by Shadow on 2016/12/9.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import SRKit

class SingleContactViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    var needLoadData = true
    var letters: [[UserModel]] = []
    var letterTitles: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorInset =
            UIEdgeInsets(top: 0, left: ContactCell.headPortraitMargin, bottom: 0, right: 0)
        tableView.contentInset = UIEdgeInsets(0, 0, C.tabBarHeight(), 0)
        tableView.tableFooterView = UIView()
        ContactCell.updateCellHeight()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if needLoadData {
            needLoadData = false
            loadData()
            tableView.reloadData()
        }
    }
    
    deinit {
        LogDebug("\(NSStringFromClass(type(of: self))).\(#function)")
        NotifyDefault.remove(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - 业务处理
    
    func loadData() {
        var contacts = ProfileManager.getContacts(.single)
        //先排序
        contacts.sort { (model1, model2) -> Bool in
            if isEmptyString(model1.letter) {
                return true
            }
            
            if isEmptyString(model2.letter) {
                return false
            }
            
            if model2.letter == "#" {
                return true
            } else if model1.letter == "#" {
                return false
            }
            
            let letter1 = model1.letter!.substring(to: 1)
            let letter2 = model2.letter!.substring(to: 1)
            return UnicodeScalar(letter1.uppercased())!.value
                <= UnicodeScalar(letter2.uppercased())!.value
        }
        
        //相同首字母的放在一起
        var letters = [] as [[UserModel]]
        var letterTitles = [] as [String]
        for contact in contacts {
            var array: [UserModel]?
            var index = -1
            for models in letters {
                index += 1
                if contact.letter?.uppercased() == models[0].letter?.uppercased() {
                    array = models
                    break
                }
            }
            if array != nil {
                array?.append(contact)
                letters[index] = array!
            } else {
                letters.append([contact])
                letterTitles.append((contact.letter?.uppercased())!)
            }
        }
        self.letters = letters
        self.letterTitles = letterTitles
        
        //startLoginTimer()
    }
    
    /*
     * Debug 在IM中注册新用户
     *
     static var timer: Timer?
     static var letterIndex: NSInteger = 0
     static var modelIndex: NSInteger = 0
     
     func startLoginTimer() {
     SingleContactViewController.letterIndex = 0
     SingleContactViewController.modelIndex = 0
     SingleContactViewController.timer = Timer.scheduledTimer(timeInterval: 5.0,
     target: self,
     selector: #selector(loginUser),
     userInfo: nil,
     repeats: true)
     }
     
     func loginUser() {
     let letterIndex = SingleContactViewController.letterIndex
     let modelIndex = SingleContactViewController.modelIndex
     guard letterIndex < letters.count else {
     SingleContactViewController.timer?.invalidate()
     SingleContactViewController.timer = nil
     return
     }
     
     if letterIndex == letters.count - 1 && modelIndex >= letters[letterIndex].count {
     SingleContactViewController.timer?.invalidate()
     SingleContactViewController.timer = nil
     return
     }
     
     let model = letters[letterIndex][modelIndex]
     if modelIndex < letters[letterIndex].count - 1 {
     SingleContactViewController.modelIndex += 1
     } else if letterIndex == letters.count - 1 {
     SingleContactViewController.modelIndex += 1
     } else {
     SingleContactViewController.letterIndex += 1
     }
     
     //调试，注册新用户
     let userparams =
     [Param.Key.userId : NonNull.string(model.userId),
     Param.Key.name : NonNull.string(model.nickname),
     Param.Key.portraitUri : NonNull.string(model.headPortrait)]
     BF.callBusiness(BF.businessId(.im, Manager.IM.funcId(.login)), userParam)
     }
     */
    
    //MARK: - 事件响应
    
    override func contentSizeCategoryDidChange() {
        ContactCell.updateCellHeight()
        tableView.reloadData()
    }
}

//MARK: - UITableViewDelegate, UITableViewDataSource

extension SingleContactViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return letters.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return letterTitles[section]
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return letterTitles
    }
    
    func tableView(_ tableView: UITableView,
                   sectionForSectionIndexTitle title: String,
                   at index: Int) -> Int {
        tableView.scrollToRow(at: IndexPath(row: 0, section: index),
                              at: .top,
                              animated: true)
        return index;
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return ContactCell.height(.single)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return letters[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell =
            tableView.dequeueReusableCell(withIdentifier: C.reuseIdentifier) as? ContactCell
        if cell == nil {
            cell = ContactCell(style: .default, reuseIdentifier: C.reuseIdentifier)
            cell?.contactType = .single
            cell?.initView()
        }
        cell?.update(letters[indexPath.section][indexPath.row])
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard MutexTouch else { return }
        
        let vc = ChatViewController()
        vc.nickname = letters[indexPath.section][indexPath.row].nickname
        vc.conversation.targetId = letters[indexPath.section][indexPath.row].userId
        vc.conversation.conversationType = .ConversationType_PRIVATE
        srShow(vc)
    }
}
