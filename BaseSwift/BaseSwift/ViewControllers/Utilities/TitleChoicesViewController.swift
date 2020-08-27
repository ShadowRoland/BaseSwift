//
//  TitleChoicesViewController.swift
//  BaseSwift
//
//  Created by Gary on 2017/4/2.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import SRKit

class TitleChoicesViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    
    //可配置项
    var titleChoices: [TitleChoiceModel] = []  //全部的选项，包括了是否已选择的项
    var isMultiple = false //是否可以多选
    var isShowSelectAll = true //在可多选的情况下是否显示全选的选项，全选的id为"-1“
    var isEditable = true //是否可编辑
    var didSelectBlock: (([TitleChoiceModel]?) -> Void)?
    
    private var isSelectedAll = false //在可多选的情况下，是否已经选择了全部
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        setDefaultNavigationBar()
        navBarLeftButtonOptions =
            isEditable && isMultiple ? [.text([.title(("OK").localized)])] : nil
        tableView.tableFooterView = UIView()
        initChoices()
        initSelectedAll()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - 视图初始化
    
    func initChoices() {
        guard isMultiple, isShowSelectAll else { return }
        
        let model = TitleChoiceModel()
        model.id = String(int: -1)
        model.title = "Select all".localized
        titleChoices.insert(model, at: 0)
    }
    
    func initSelectedAll() {
        guard isMultiple else { return}
        
        let count = titleChoices.count
        for i in 0 ..< count {
            if isShowSelectAll && i == 0 { //第一个"全选"不用判断
                continue
            }
            if !titleChoices[i].isSelected {
                isSelectedAll = false
                return
            }
        }
        
        isSelectedAll = true
    }
    
    //MARK: - 业务处理
    
    func confirmSelectedChoices() {
        if let didSelectBlock = didSelectBlock {
            didSelectBlock(titleChoices.filter {
                $0.id != String(int: -1) && $0.isSelected
            })
        }
        srPopBack()
    }
    
    //MARK: - 事件响应
    
    override func clickNavigationBarRightButton(_ button: UIButton) {
        guard MutexTouch else { return }
        confirmSelectedChoices()
    }
}

//MARK: - UITableViewDelegate, UITableViewDataSource

extension TitleChoicesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titleChoices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: C.reuseIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: C.reuseIdentifier)
            cell?.accessoryType = .checkmark
            cell?.selectionStyle = .default
            cell?.textLabel?.numberOfLines = 0
            cell?.textLabel?.textColor = UIColor.darkGray
        }
        
        cell?.textLabel?.font = UIFont.preferred.body
        
        let model = titleChoices[indexPath.row]
        cell?.textLabel?.text = model.title
        
        //判断是否已选中
        if isMultiple { //多选
            if isSelectedAll { //已全选的情况下
                if isShowSelectAll { //只需第一行“全选”标记即可
                    cell?.accessoryType = indexPath.row == 0 ? .checkmark : .none
                } else { //每一行都选中
                    cell?.accessoryType = .checkmark
                }
            } else {
                if isShowSelectAll && indexPath.row == 0 {
                    cell?.accessoryType = .none
                } else {
                    cell?.accessoryType = model.isSelected ? .checkmark : .none
                }
            }
        } else { //单选
            cell?.accessoryType = model.isSelected ? .checkmark : .none
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard isEditable else {
            return
        }
        
        let model = titleChoices[indexPath.row]
        let currentSelected = model.isSelected
        
        if isMultiple { //多选
            if isShowSelectAll && indexPath.row == 0 { //选中第一行"全选"
                if !isSelectedAll { //原先并不是全选，进行全部选中
                    titleChoices.forEach({ $0.isSelected = true })
                } else { //由全选中变为全不选中
                    titleChoices.forEach({ $0.isSelected = false })
                }
            } else {
                model.isSelected = !currentSelected //toggle
            }
        } else { //单选
            if !currentSelected { //由不选中变为选中
                model.isSelected = true
                
                //将其他已选中的变为不选中
                titleChoices.forEach({
                    if $0.isSelected  && $0.id! != model.id {
                        $0.isSelected = false
                    }
                })
                
                view.isUserInteractionEnabled = false
                DispatchQueue.main.async { [weak self] in
                    self?.confirmSelectedChoices()
                }
            } else {
                return
            }
        }
        initSelectedAll()
        tableView.reloadData()
    }
}

