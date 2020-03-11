//
//  SelectCountryCodeViewController.swift
//  BaseSwift
//
//  Created by Gary on 2017/3/17.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import SRKit

class SelectCountryCodeViewController: BaseViewController {
    var didSelectBlock: ((CountryCodeModel) -> Void)?

    @IBOutlet weak var tableView: UITableView!
    var letters: [Array<CountryCodeModel>] = []
    var letterTitles: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        setDefaultNavigationBar("Select country or region".localized)
        initView()
        loadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - 视图初始化
    
    func initView() {
        tableView.tableFooterView = UIView()
    }
    
    //MARK: - 业务处理
    
    func loadData() {
        let filePath = C.resourceDirectory.appending(pathComponent: "json/country_codes.json")
        var countryCodes =
            (filePath.fileJsonObject as! [ParamDictionary]).compactMap { CountryCodeModel(JSON: $0) }
        //先排序
        countryCodes.sort { (model1, model2) -> Bool in
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
        var letters = [] as [Array<CountryCodeModel>]
        var letterTitles = [] as [String]
        for model in countryCodes {
            var array: [CountryCodeModel]?
            var index = -1
            for models in letters {
                index += 1
                if model.letter?.uppercased() == models[0].letter?.uppercased() {
                    array = models
                    break
                }
            }
            if array != nil {
                array?.append(model)
                letters[index] = array!
            } else {
                letters.append([model])
                letterTitles.append((model.letter?.uppercased())!)
            }
        }
        self.letters = letters
        self.letterTitles = letterTitles
    }
    
    //MARK: - 事件响应
    
    override func contentSizeCategoryDidChange() {
        tableView.reloadData()
    }
}
    
//MARK: - UITableViewDelegate, UITableViewDataSource

extension SelectCountryCodeViewController: UITableViewDelegate, UITableViewDataSource {
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return letters[section].count
    }
    
    func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: C.reuseIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .value1, reuseIdentifier: C.reuseIdentifier)
            cell?.detailTextLabel?.textColor = UIColor.darkGray
        }
        cell?.textLabel?.font = UIFont.preferred.body
        cell?.detailTextLabel?.font = UIFont.preferred.footnote
        
        let model = letters[indexPath.section][indexPath.row]
        cell?.textLabel?.text = model.name
        let code = NonNull.string(model.code)
        cell?.detailTextLabel?.text = code.hasPrefix("+") ? code : "+" + code
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard MutexTouch else { return }
        
        if let didSelectBlock = didSelectBlock {
            didSelectBlock(letters[indexPath.section][indexPath.row])
        }
        popBack()
    }
}
