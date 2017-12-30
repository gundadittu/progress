//
//  Notifications.swift
//  Progress
//
//  Created by Aditya Gunda on 12/18/17.
//  Copyright © 2017 Aditya Gunda. All rights reserved.
//

import Foundation
import UserNotifications
import Realm
import RealmSwift
import Firebase
import CFAlertViewController
import ChameleonFramework
import Floaty
import Alamofire
import SwiftyJSON
import StoreKit

class NotificationsController  {
    
    static let center = UNUserNotificationCenter.current()
    static let defaults = UserDefaults.standard
    static let quotesAPIURL = "http://api.forismatic.com/api/1.0/"
    
    class func scheduleNotification(task: SavedTask) {
        
        if task.deadline == nil {
            return
        }
        
        let title = ""
        let body = task.title
        let categoryID = "deadline"
        let date = task.deadline!
        
        
        let completeAction = UNNotificationAction(identifier: "completeAction",
                                                  title: "Mark as Completed", options: [])
        let deleteAction = UNNotificationAction(identifier: "deleteAction",
                                                title: "Delete", options: [.destructive])
        let category = UNNotificationCategory(identifier: categoryID,
                                              actions: [completeAction, deleteAction],
                                              intentIdentifiers: [], options: [])
        self.center.setNotificationCategories([category])
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default()
        content.categoryIdentifier = categoryID
        
        var dateComponents = DateComponents()
        dateComponents.month = NSCalendar.current.component(.month, from: date)
        dateComponents.year = NSCalendar.current.component(.year, from: date)
        dateComponents.hour = NSCalendar.current.component(.hour, from: date)
        dateComponents.minute = NSCalendar.current.component(.minute, from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let uniqueIdentifier = UUID().uuidString
        let request = UNNotificationRequest(identifier: uniqueIdentifier, content: content, trigger: trigger)
        center.add(request)
        
        let realm = try! Realm()
        try! realm.write {
            task.notificationIdentifier = uniqueIdentifier
        }
    }
    
    class func removeNotifications(task: SavedTask) {
        let identifier = task.notificationIdentifier
        self.center.removePendingNotificationRequests(withIdentifiers: [identifier])
        let realm = try! Realm()
        try! realm.write {
            task.notificationIdentifier = ""
        }
    }
    
    class func requestPermission(_ override: Bool = false){
        
        if override != true {
            if defaults.value(forKey: "notificationRequestCount") == nil {
                    defaults.setValue(0, forKey: "notificationRequestCount")
                    return
            } else {
                let count = defaults.value(forKey: "notificationRequestCount") as! Int
                let newCount = count + 1
                defaults.setValue(newCount, forKey: "notificationRequestCount")
                if newCount%3 != 2  || newCount < 4{
                    return
                }
            }
        }
        
        self.center.getNotificationSettings(completionHandler: { (settings) in
            let status = settings.authorizationStatus
            if status == .notDetermined {
                DispatchQueue.main.async {
                    
                    let alertController = CFAlertViewController(title: "👋 We need your permission to send you notifications! ",
                                                                message: "Nothing annoying. Just so we can place a badge count, and remind you to plan your day and of deadlines. \n \n Even after you give us permission, you have control over which notification we can send you in settings.",
                                                                textAlignment: .left,
                                                                preferredStyle: .alert,
                                                                didDismissAlertHandler: nil)
                    
                    let grantedAction = CFAlertAction(title: "Ask me Now",
                                                      style: .Default,
                                                      alignment: .justified,
                                                      backgroundColor: FlatGreen(),
                                                      textColor: nil,
                                                      handler: { (action) in
                                                        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
                                                            if granted == true {
                                                                //log firebase analytics event
                                                                Analytics.logEvent(notificationPermissionGrantedEvent, parameters: [
                                                                    "name":"" as NSObject,
                                                                    "full_text": "" as NSObject
                                                                    ])
                                                            } else {
                                                                //log firebase analytics event
                                                                Analytics.logEvent(notificationPermissionDeniedEvent, parameters: [
                                                                    "name":"" as NSObject,
                                                                    "full_text": "" as NSObject
                                                                    ])
                                                            }
                                                            
                                                            if error != nil {
                                                                //log crashlytics error
                                                                Crashlytics.sharedInstance().recordError(error!)
                                                                return
                                                            }
                                                        }
                                                        
                    })
                    
                    let laterAction = CFAlertAction(title: "Decide Later",
                                                    style: .Cancel,
                                                    alignment: .justified,
                                                    backgroundColor: FlatWhiteDark(),
                                                    textColor: nil,
                                                    handler: nil)
                    alertController.addAction(grantedAction)
                    alertController.addAction(laterAction)
                    
                    alertController.shouldDismissOnBackgroundTap = false
                    
                    Floaty.global.button.isHidden = true
                    let vc = UIApplication.topViewController()
                    vc?.present(alertController, animated: true, completion: nil)
                }
            }
        })
    }
    
    class func scheduleMorningNotification(){
        let title = "What do you want to work on today?"
        var body = "A good plan today is better than a perfect plan tomorrow. - Anonymous"
        let category = "morningNotification"
    
        self.center.removePendingNotificationRequests(withIdentifiers: [category])
        
        guard let dailyNotificationsTime = self.defaults.value(forKey: "dailyNotificationTime") else { return }
        
        randomQuote { quote in
            if quote != nil {
                body = quote!
            }
            
            let string = dailyNotificationsTime as! String
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            let date = formatter.date(from: string)
            
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.categoryIdentifier = category
            content.sound = UNNotificationSound.default()
            
            var dateComponents = DateComponents()
            dateComponents.hour = date?.hour
            dateComponents.minute = date?.minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let n = UNNotificationRequest(identifier: category, content: content, trigger: trigger)
            
            self.center.add(n)
            
        }
    }
    
    static func randomQuote(completion: @escaping (String?) -> Void) {
        let parameters: [String : Any] = ["method": "getQuote", "format" : "json", "key" : 4, "lang" : "en"]
        Alamofire.request(quotesAPIURL, parameters: parameters).responseJSON { (response) in
            switch response.result {
            case .success(let value):
                let json = JSON(value).dictionaryObject!
                let quote = json["quoteText"] as! String
                let author = json["quoteAuthor"] as! String
                var body = "\(String(describing: quote))"
                if author != "" {
                    body += "- \(String(describing: author))"
                }
                completion(body)
                break
            case .failure(let error):
                print(error.localizedDescription)
                Crashlytics.sharedInstance().recordError(error) //log crashlytics error
                completion(nil)
                break
            }
        }
    }
    
    static func checkHapticPermissions() -> Bool {
        let hapticBool = self.defaults.value(forKey: "hapticFeedback") as! Bool
        return hapticBool
    }
    
    static func checkInAppNotificationPermissions() -> Bool {
        let inAppBool = self.defaults.value(forKey: "inAppNotifications") as! Bool
        return inAppBool
    }
    
    static func askForAppReview() {
        let val = self.defaults.value(forKey: "reviewsCount")
        if val == nil {
            self.defaults.setValue(1, forKey: "reviewsCount")
            return
        }
        let count = val as! Int
        if count%7 == 0 {
            SKStoreReviewController.requestReview()
        }
        self.defaults.setValue(count+1, forKey: "reviewsCount")
    }
}

extension UIApplication {
    class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}
