//
//  HttpTool.swift
//  User Info Demo
//
//  Created by fy on 2019/8/8.
//  Copyright © 2019 founder. All rights reserved.
//

import UIKit

class HttpTool: NSObject {
    class func request(url: String, success: @escaping (Data) -> Void, failure: @escaping (String) -> Void) {
        
        let session = URLSession.shared
        
        session.dataTask(with: URL(string: url)!) { (data, resp, err) in
            
            guard err == nil else {
                failure("request error: " + err!.localizedDescription)
                return
            }
            
            guard data != nil else {
                failure("data is null")
                return
            }
            
            success(data!)
            
            }.resume();
    }
}
