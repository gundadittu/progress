
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
        
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure() //configure for Fireabase services
        
        UNUserNotificationCenter.current().delegate = self //Setting notification delegate
        
        NotificationsController.scheduleMorningNotification() //Schedule anyways to change quote
        
        let ydBadgeBool = defaults.value(forKey: "yourDayBadgeCount")
        if ydBadgeBool == nil {
            defaults.set(true, forKey: "yourDayBadgeCount")
        }
        
        let hapticBool = defaults.value(forKey: "hapticFeedback")
        if hapticBool == nil {
            defaults.set(true, forKey: "hapticFeedback")
        }
        
        let dtBadgeBool = defaults.value(forKey: "dueTodayBadgeCount")
        if dtBadgeBool == nil {
            defaults.set(true, forKey: "dueTodayBadgeCount")
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
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        let realm = try! Realm()

        let badgeBool = defaults.value(forKey: "yourDayBadgeCount") as! Bool
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
            }
            application.applicationIconBadgeNumber = total
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
    
}


