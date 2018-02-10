
//
//  AppDelegate.swift
//  Progress
//
//  Created by Aditya Gunda on 12/9/17.
//  Copyright © 2017 Aditya Gunda. All rights reserved.
//

import UIKit
import Firebase
import ChameleonFramework
import Floaty
import Realm
import RealmSwift
import UserNotifications

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    let defaults = UserDefaults.standard
    var notificationToken: NotificationToken?
    let realm = try! Realm()
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        NotificationCenter.default.post(name: Notification.Name("addTasksDueTodayToYourDay"), object: nil)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        
        if url.scheme == "openAppFromWidget"
        {
            
            //log firebase debug event
            DebugController.write(string: "recieved widget tap URL")
            
            //log firebase analytics event
            Analytics.logEvent(tappedWidgetEvent, parameters: [
                "name":"" as NSObject,
                "full_text": "" as NSObject
                ])
            NotificationCenter.default.post(name: Notification.Name("todayWidgetSelectedTask"), object: nil)
            return true
        }
        return false
    }
        
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure() //configure for Fireabase services
        if defaults.value(forKey: "transferredDataToSharedAppGroup") == nil {
            let realm = try! Realm()
            let objects = realm.objects(SavedTask.self)
            Migration.migrateDataToSharedAppGroup(allObjects: objects)
            defaults.setValue(true, forKey: "transferredDataToSharedAppGroup")
        }
        
        /*SyncUser.logIn(with: .usernamePassword(username: "gundadittu@gmail.com", password: "maroonppl123", register: false), server: URL(string: "http://40.78.107.52:9080")!) { user, error in
            guard let user = user else {
                fatalError(String(describing: error))
            }
            
            DispatchQueue.main.async(execute: {
                // Open Realm
                /*let configuration = Realm.Configuration(
                    syncConfiguration: SyncConfiguration(user: user, realmURL: URL(string: "realm://40.78.107.52:9080/~/progress")!)
                )*/
                
                let config = Realm.Configuration(
                    fileURL: FileManager
                        .default
                        .containerURL(forSecurityApplicationGroupIdentifier: "group.progress.tasks")!
                        .appendingPathComponent("db.realm"),
                    syncConfiguration: SyncConfiguration(user: user, realmURL: URL(string: "realm://40.78.107.52:9080/~/progress")!),
                    objectTypes: [SavedTask.self]
                )
                
                Realm.Configuration.defaultConfiguration = config
                
                
                //self.realm = try! Realm(configuration: configuration)
                
                // Set realm notification block
                self.notificationToken = self.realm.observe { notification , realm in 
                    NotificationCenter.default.post(name: Notification.Name("syncData"), object: nil)
                }
                
                /*addNotificationBlock{ _ in
                    NotificationCenter.default.post(name: Notification.Name("syncData"), object: nil)
                }*/
                
                NotificationCenter.default.post(name: Notification.Name("syncData"), object: nil)
            })
        }*/
        
       /* let config = Realm.Configuration(
            fileURL: FileManager
                .default
                .containerURL(forSecurityApplicationGroupIdentifier: "group.progress.tasks")!
                .appendingPathComponent("db.realm"),
            objectTypes: [SavedTask.self])
        Realm.Configuration.defaultConfiguration = config*/
        
        let sharedDirectory: URL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.progress.tasks")! as URL
        let sharedRealmURL = sharedDirectory.appendingPathComponent("db.realm")
        Realm.Configuration.defaultConfiguration = Realm.Configuration(fileURL: sharedRealmURL)
        
        UNUserNotificationCenter.current().delegate = self //Setting notification delegate
        
        NotificationsController.askForAppReview()
        
        let ydBadgeBool = defaults.value(forKey: "yourDayBadgeCount")
        if ydBadgeBool == nil {
            defaults.set(true, forKey: "yourDayBadgeCount")
        }
        
        let hapticBool = defaults.value(forKey: "hapticFeedback")
        if hapticBool == nil {
            defaults.set(true, forKey: "hapticFeedback")
        }
        
        let inAppBool = defaults.value(forKey: "inAppNotifications")
        if inAppBool == nil {
            defaults.set(true, forKey: "inAppNotifications")
        }
        
        //set daily motivational notification to 9 AM
        if defaults.value(forKey: "dailyNotificationTime") == nil {
            var components = DateComponents()
            components.hour = 9
            components.minute = 0
            let date = Calendar.current.date(from: components)
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            let string = formatter.string(from: date!)
            defaults.setValue(string, forKey: "dailyNotificationTime")
        }
        NotificationsController.scheduleMorningNotification() //Schedule anyways to change quote
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        let realm = try! Realm()

        /*let badgeBool = defaults.value(forKey: "yourDayBadgeCount") as! Bool
        let dueTodayBool = defaults.value(forKey: "dueTodayBadgeCount") as! Bool
        if badgeBool == true || dueTodayBool == true{
            var total = 0
            // Get the current calendar with local time zone
            var calendar = Calendar.current
            calendar.timeZone = NSTimeZone.local
            // Get today's beginning & end
            let dateFrom = calendar.startOfDay(for: Date()) // eg. 2016-10-10 00:00:00
            var components = calendar.dateComponents([.year, .month, .day, .hour, .minute],from: dateFrom)
            components.day! += 1
            let dateTo = calendar.date(from: components)! // eg. 2016-10-11 00:00:00
            // Note: Times are printed in UTC. Depending on where you live it won't print 00:00:00 but it will work with UTC times which can be converted to local time
            // Set predicate as date being today's date
            let datePredicate = NSPredicate(format: "(%@ <= deadline) AND (deadline < %@)", argumentArray: [dateFrom, dateTo])
            let isNotCompletedPredicate = NSPredicate(format: "isCompleted == %@",  Bool(booleanLiteral: false) as CVarArg)
            let isTodayPredicate = NSPredicate(format: "isToday == %@",  Bool(booleanLiteral: true) as CVarArg)
            
            if badgeBool == true {
                let andPredicate = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: [isNotCompletedPredicate, isTodayPredicate])
                let list = realm.objects(SavedTask.self).filter(andPredicate)
                total += list.count
            }
            if dueTodayBool == true {
                let andPredicate = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: [isNotCompletedPredicate, datePredicate])
                let list = realm.objects(SavedTask.self).filter(andPredicate)
                total += list.count
            }
            //remove duplicates
            if badgeBool == true && dueTodayBool == true {
                let andPredicate = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: [isNotCompletedPredicate, isTodayPredicate, datePredicate])
                let list = realm.objects(SavedTask.self).filter(andPredicate)
                total -= list.count
            }*/
        
        let badgeBool = defaults.value(forKey: "yourDayBadgeCount") as! Bool
        
        if badgeBool == true {
            var total = 0
            let isNotCompletedPredicate = NSPredicate(format: "isCompleted == %@",  Bool(booleanLiteral: false) as CVarArg)
            let isTodayPredicate = NSPredicate(format: "isToday == %@",  Bool(booleanLiteral: true) as CVarArg)
            let andPredicate = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: [isNotCompletedPredicate, isTodayPredicate])
            let list = realm.objects(SavedTask.self).filter(andPredicate)
            total += list.count
            application.applicationIconBadgeNumber = total > 0 ? 1 : 0
        } else {
             application.applicationIconBadgeNumber = 0
        }
        
        //to make sure all empty title tasks are deleted if app randomly closes 
        self.window?.endEditing(true)
    }
    
    //Handle incoming notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        switch response.actionIdentifier {
        case UNNotificationDismissActionIdentifier:
            //log firebase analytics event
            Analytics.logEvent(dismissedDeadlineNotificationEvent, parameters: [
                "name": "" as NSObject,
                "full_text": "" as NSObject
                ])
            completionHandler()
            break
        case UNNotificationDefaultActionIdentifier:
            
            //log firebase analytics event
            Analytics.logEvent(openedNotificationEvent, parameters: [
                "name": "" as NSObject,
                "full_text": "" as NSObject
                ])
            completionHandler()
            break
        case "deleteAction":
            //log firebase analytics event
            Analytics.logEvent(deleteTaskDeadlineNotificationEvent, parameters: [
                "name": "" as NSObject,
                "full_text": "" as NSObject
                ])
            let id = response.notification.request.identifier
            let realm = try! Realm()
            let idPredicate = NSPredicate(format: "notificationIdentifier == %@",  id)
            if let task = realm.objects(SavedTask.self).filter(idPredicate).first {
                try! realm.write {
                    realm.delete(task)
                }
            }
            completionHandler()
            break
        case "completeAction":
            //log firebase analytics event
            Analytics.logEvent(completeTaskDeadlineNotificationEvent, parameters: [
                "name": "" as NSObject,
                "full_text": "" as NSObject
                ])
            
            let id = response.notification.request.identifier
            let realm = try! Realm()
            let idPredicate = NSPredicate(format: "notificationIdentifier == %@",  id)
            if let task = realm.objects(SavedTask.self).filter(idPredicate).first {
                try! realm.write {
                    task.isCompleted = true
                    task.isToday = false
                }
            }
            completionHandler()
            break
        default:
            completionHandler()
            break
        }
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        let delayTime = DispatchTime.now() +  .seconds(1)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            if shortcutItem.type == "AG.Progress.Progress-Widget.createTask" {
                NotificationCenter.default.post(name: Notification.Name("shortcutCreateTask"), object: nil)
                
                //log firebase analytics event
                Analytics.logEvent("used_3D_touch_to_create_task", parameters: [
                    "name": "" as NSObject,
                    "full_text": "" as NSObject
                    ])
            }
        }
    }
}


