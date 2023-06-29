//
//  AppDelegate.swift
//  Demo
//
//  Created by ZYP on 2022/12/21.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        
        UITableView.appearance().estimatedRowHeight = UITableView.automaticDimension
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .white
        let nvc = UINavigationController(rootViewController: ViewController())
        window?.rootViewController = nvc
        window?.makeKeyAndVisible()
        return true
    }


}

