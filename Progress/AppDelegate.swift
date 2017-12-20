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

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    let defaults = UserDefaults.standard
        
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        Instabug.start(withToken: "14c94ce365f8079a4edad9fb61c9cf4a", invocationEvent: .shake)
        
        //Realm migration 
        let config = Realm.Configuration(
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: 0,
            migrationBlock: { migration, oldSchemaVersion in
                // We haven’t migrated anything yet, so oldSchemaVersion == 0
                if (oldSchemaVersion < 0) {
                    // Nothing to do! - Realm will automatically detect new properties and removed properties - And will update the schema on disk automatically
                }
        })
        
        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config
        
        //Setting notification delegate 
        UNUserNotificationCenter.current().delegate = self
        
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
        //Schedule anyways to change quote 
        NotificationsController.scheduleMorningNotification()

        if self.isAppAlreadyLaunchedOnce() == false {
            //load app introduction walkthrough if first time launching app
            self.loadOnboarding()
        }
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        let badgeBool = defaults.value(forKey: "yourDayBadgeCount") as! Bool
        let dueTodayBool = defaults.value(forKey: "dueTodayBadgeCount") as! Bool
        if badgeBool == true || dueTodayBool == true{
            var total = 0
            
            let realm = try! Realm()
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
    
    func loadOnboarding(){
        Floaty.global.button.isHidden = true
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let onboardVC = storyboard.instantiateViewController(withIdentifier: "onboarding")
        self.window?.makeKeyAndVisible()
        self.window?.rootViewController?.present(onboardVC, animated: true, completion: nil)
    }
    
    func isAppAlreadyLaunchedOnce()->Bool{
        if  defaults.string(forKey: "isAppAlreadyLaunchedBefore") == nil{
            defaults.set(true, forKey: "isAppAlreadyLaunchedBefore")
            return false
        }
        return true
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


