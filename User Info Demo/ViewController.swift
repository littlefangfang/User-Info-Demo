//
//  ViewController.swift
//  User Info Demo
//
//  Created by fy on 2019/8/8.
//  Copyright © 2019 founder. All rights reserved.
//

import UIKit
import Kingfisher

let oauthString = "client_id=beaf0fe9de3e4dbabdf3&client_secret=e0427617ad0a61ceda2a240bd6422bc8bfaf301b"

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    @IBOutlet var tableView: UITableView!
    var usersArray: [UserInfo]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    //MARK: - Helper
    
    /// 开始请求用户列表
    ///
    /// - Parameter text: 用来请求的用户名，用户输入的信息trim掉空格和换行
    func startRequest(text: String) {
        
        let urlString = "https://api.github.com/search/users?q=\(text)&\(oauthString)"
        
        HttpTool.request(url: urlString, success: { [unowned self] (data) in
            do {
                
                let users = try JSONDecoder().decode(Users.self, from: data)
                self.usersArray = users.items
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
            } catch {
                print("parse Users error: " + error.localizedDescription)
            }
        }) { (errInfo) in
            print(errInfo)
        }

    }
    
    /// 查找该用户用的最多的语言
    ///
    /// - Parameter data: 接口返回的data数据
    /// - Returns: 该用户用的最多的语言名字
    func findFavoriteLanguage(data: Data) -> String {
        do {
            let repoInfoArray = try JSONDecoder().decode([UserRepoInfo].self, from: data)
        
            var dict = [String: Int]() // 字典存放每种语言出现的次数
            for repoInfo in repoInfoArray {
                
                let languageName = repoInfo.language
                
                if languageName != nil {
                    if dict[languageName!] == nil {
                        dict[languageName!] = 1
                    } else {
                        dict[languageName!] = dict[languageName!]! + 1
                    }
                }
            }
            
            // 获取出现最多的语言名称
            if let languageObj = dict.max(by: { a, b in a.value < b.value }) {
                return languageObj.key
            }
            
            return "无"
        }catch{
            
            print("data parse error: " + error.localizedDescription)
            return "无"
        }
    }
    
    //MARK: - UISearchBarDelegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        URLSession.shared.cancelAllTasks()
        
        let formatedText = searchText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if formatedText.count != 0 {
            startRequest(text: formatedText)
        }else{
            usersArray?.removeAll()
            tableView.reloadData()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }
    
    //MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usersArray?.count ?? 0;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Search_Result_List_Cell", for: indexPath) as! SearchResultListCell
        
        var userInfo = usersArray![indexPath.row]
        
        // 设置用户名
        cell.nameLabel.text = userInfo.userName
        
        // 设置头像
        let url = URL(string: userInfo.avatarUrl)
        let processor = DownsamplingImageProcessor(size: cell.portraitImageView!.frame.size)
        cell.portraitImageView.kf.indicatorType = .activity
        cell.portraitImageView.kf.setImage(
            with: url,
            placeholder: UIImage(named: "placeholder_image"),
            options: [
                .processor(processor),
                .scaleFactor(UIScreen.main.scale),
                .transition(.fade(1)),
                .cacheOriginalImage
            ])
        {
            result in
            switch result {
            case .success(let value):
                print("download image success for: \(value.source.url?.absoluteString ?? "")")
            case .failure(let error):
                print("download image failed: \(error.localizedDescription)")
            }
        }
        
        // 设置用的最多的语言
        if userInfo.languageName != nil {
            cell.languageLabel.text = userInfo.languageName
        } else {
            HttpTool.request(url: "https://api.github.com/users/\(userInfo.userName)/repos?\(oauthString)", success: { [unowned self] (data) in
                let languageName = self.findFavoriteLanguage(data: data)
                userInfo.languageName = languageName
                self.usersArray?[indexPath.row] = userInfo
                
                DispatchQueue.main.async {
                    if self.tableView.indexPathsForVisibleRows!.contains(indexPath) {
                        cell.languageLabel.text = languageName
                    }
                }
            }) { (errInfo) in
                print("request language error: " + errInfo)
            }
        }
        
        return cell
    }
}

class SearchResultListCell: UITableViewCell {
    
    @IBOutlet var portraitImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var languageLabel: UILabel!
    
}


//MARK: - models

/// 用户列表
struct Users: Decodable {
    let items: [UserInfo]
}

/// 每个用户的详细信息
struct UserInfo: Decodable {
    let userName: String // 用户名
    let avatarUrl: String // 头像URL
    var languageName: String? // 所用语言（后期添加）
    
    private enum CodingKeys : String, CodingKey {
        case userName = "login"
        case avatarUrl = "avatar_url"
    }
}

/// 每个repo的详细信息
struct UserRepoInfo: Decodable {
    let language: String? // 语言名字
}

//MARK: - extensions
extension URLSession {
    func cancelAllTasks() {
        getAllTasks { (sessionTaskArray) in
            for task in sessionTaskArray {
                task.cancel()
            }
        }
    }
}

