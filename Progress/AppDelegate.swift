//
//  AppDelegate.swift
//  Progress
//
//  Created by Aditya Gunda on 12/9/17.
//  Copyright © 2017 Aditya Gunda. All rights reserved.
//

import UIKit
import Firebase
import Instabug
import ChameleonFramework
import Floaty
import paper_onboarding
import Realm
import RealmSwift
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
        
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        Instabug.start(withToken: "14c94ce365f8079a4edad9fb61c9cf4a", invocationEvent: .shake)
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            if error != nil {
                return
            }
        }
        
        if self.isAppAlreadyLaunchedOnce() == false {
            Floaty.global.button.isHidden = true
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let onboardVC = storyboard.instantiateViewController(withIdentifier: "onboarding")
            self.window?.makeKeyAndVisible()
            self.window?.rootViewController?.present(onboardVC, animated: true, completion: nil)
        }
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        let realm = try! Realm()
        let isTodayPredicate = NSPredicate(format: "isToday == %@",  Bool(booleanLiteral: true) as CVarArg)
        let isNotCompletedPredicate = NSPredicate(format: "isCompleted == %@",  Bool(booleanLiteral: false) as CVarArg)
        let andPredicate = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: [isNotCompletedPredicate, isTodayPredicate])
        let list = realm.objects(SavedTask.self).filter(andPredicate)
        application.applicationIconBadgeNumber = list.count
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
    }
    
    func isAppAlreadyLaunchedOnce()->Bool{
        let defaults = UserDefaults.standard
        if  defaults.string(forKey: "isAppAlreadyLaunchedOnce") == nil{
            defaults.set(true, forKey: "isAppAlreadyLaunchedOnce")
            return false
        }
        return true
    }
}

