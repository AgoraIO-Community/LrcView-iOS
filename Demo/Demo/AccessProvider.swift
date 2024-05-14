//
//  AccessProvider.swift
//  Demo
//
//  Created by ZYP on 2024/5/14.
//

import Foundation


class AccessProvider {
    typealias AccessBlock = (_ userId: String, _ token: String, _ errorMsg: String?) -> Void
    static var userId: String?
    static var token: String?
    
    static func fetchAccessData(completed: @escaping AccessBlock) {
        let url = ""
        let session = URLSession.shared
        let task = session.dataTask(with: URL(string: url)!) { (data, response, error) in
            
            if let e = error {
                completed("", "", e.localizedDescription)
                return
            }
            
            guard let data = data else {
                completed("", "", "data is nil")
                return
            }
            
            guard let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers), let dict = json as? [String: Any] else {
                completed("", "", "json error")
                return
            }
            
            guard let error = dict["error"] as? Int,
                  error == 0, let data = dict["data"] as? [String: Any], let userId = data["yinsuda_uid"] as? String, let token = data["token"] as? String else {
                completed("", "", "data error")
                return
            }
            AccessProvider.userId = userId
            AccessProvider.token = token
            completed(userId, token, nil)
        }
        task.resume()
    }
}
