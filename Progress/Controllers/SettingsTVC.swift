//
//  SettingsTVC.swift
//  Progress
//
//  Created by Aditya Gunda on 12/19/17.
//  Copyright © 2017 Aditya Gunda. All rights reserved.
//

import UIKit
import ChameleonFramework
import CFAlertViewController
import Floaty
import Realm
import RealmSwift
import Pulley
import Firebase
import DatePickerDialog
import UserNotifications

class SettingsTVC: UITableViewController {

    @IBOutlet weak var dueTodayBadgeCount: UISwitch!
    @IBOutlet weak var badgeCountSwitch: UISwitch!
    @IBOutlet weak var dailyNotificationTimeBtn: UIButton!
    @IBOutlet weak var hapticFeedbackSwitch: UISwitch!
    @IBOutlet weak var inAppNotificationSwitch: UISwitch!
    let defaults = UserDefaults.standard
    let realm = try! Realm()
    var permissionAccess = false
    var canAskForAccess = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Settings"
        self.tableView.separatorStyle = .singleLine
        self.navigationController?.navigationBar.tintColor = mainAppColor
        
        let badgeBool = defaults.value(forKey: UDyourDayBadgeCount) as! Bool
        let dtBadgeBool = defaults.value(forKey: "dueTodayBadgeCount") as! Bool
        let hapticBool = defaults.value(forKey: "hapticFeedback") as! Bool
        let inAppBool = defaults.value(forKey: "inAppNotifications") as! Bool
        
        UNUserNotificationCenter.current().getNotificationSettings (completionHandler: { (settings) in
            let status = settings.authorizationStatus
            if status == .authorized {
               self.permissionAccess = true
            }
            if status == .notDetermined {
                self.canAskForAccess = true
            } else {
                self.canAskForAccess = false
            }
        })
        
        if badgeBool == true && permissionAccess == true {
            self.badgeCountSwitch.isOn = true
        } else {
            self.badgeCountSwitch.isOn = false 
        }
        
        if dtBadgeBool == true && permissionAccess == true {
            self.dueTodayBadgeCount.isOn = true
        } else {
            self.dueTodayBadgeCount.isOn = false
        }
        
        if hapticBool == true {
            self.hapticFeedbackSwitch.isOn = true
        } else {
            self.hapticFeedbackSwitch.isOn = false
        }
        
        if inAppBool == true {
            self.inAppNotificationSwitch.isOn = true
        } else {
            self.inAppNotificationSwitch.isOn = false
        }
        
        if let dailyNotificationsTime = defaults.value(forKey: "dailyNotificationTime")  {
            let string = dailyNotificationsTime as! String
            if string != "" && permissionAccess == true {
                self.dailyNotificationTimeBtn.setTitle(string, for: .normal)
            } else {
                self.dailyNotificationTimeBtn.setTitle("Set", for: .normal)
            }
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        Floaty.global.button.isHidden = false
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(60)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 2 {
                ///log firebase analytics event
                Analytics.logEvent(talkToUsEvent, parameters: [
                    "name":"" as NSObject,
                    "full_text": "" as NSObject
                    ])
            }
            if indexPath.row == 3 {
                ///log firebase analytics event
                Analytics.logEvent(onboardingFromSettingsEvent, parameters: [
                    "name":"" as NSObject,
                    "full_text": "" as NSObject
                    ])
                
                let storyboard: UIStoryboard = UIStoryboard.init(name: "Main",bundle: nil)
                let vc: TodayVC = storyboard.instantiateViewController(withIdentifier: "PrimaryContentViewController") as! TodayVC
                vc.loadOnboarding()
            }
        } else if indexPath.section == 3 {
            if indexPath.row == 0 {
                self.clearCompletedTasks()
            }
            if indexPath.row == 1 {
                self.deleteAllTasks()
            }
        }
    }


    @IBAction func badgeCountSwitchToggled(_ sender: Any) {
        
        if self.permissionAccess == false {
            badgeCountSwitch.isOn = false
            if self.canAskForAccess == true {
                  self.requestPermission() //display alert saying they need to give us permission
                return
            }
            self.deniedAlert() //display alert saying they need to go their phone's settings
            return
        }
        
        if badgeCountSwitch.isOn == true {
           
            //log firebase analytics event
            Analytics.logEvent("your_day_count_badge_on", parameters: [
                "name":"" as NSObject,
                "full_text": "" as NSObject
                ])
            
            defaults.set(true, forKey: "yourDayBadgeCount")
        } else {
            //log firebase analytics event
            Analytics.logEvent("your_day_count_badge_off", parameters: [
                "name":"" as NSObject,
                "full_text": "" as NSObject
                ])
            
             defaults.set(false, forKey: "yourDayBadgeCount")
        }
    }
    @IBAction func dueTodayBadgeCountSwitchToggled(_ sender: Any) {

        if self.permissionAccess == false {
            dueTodayBadgeCount.isOn = false
            if self.canAskForAccess == true {
                 self.requestPermission() //display alert saying they need to give us permission
                return
            }
            self.deniedAlert() //display alert saying they need to go their phone's settings
            return
        }
        
        if dueTodayBadgeCount.isOn == true {
            //log firebase analytics event
            Analytics.logEvent("due_today_count_badge_on", parameters: [
                "name":"" as NSObject,
                "full_text": "" as NSObject
                ])
            defaults.set(true, forKey: "dueTodayBadgeCount")
        } else {
            Analytics.logEvent("due_today_count_badge_off", parameters: [
                "name":"" as NSObject,
                "full_text": "" as NSObject
                ])
            defaults.set(false, forKey: "dueTodayBadgeCount")
        }
    }
    
    @IBAction func dailyNotificationTimeBtnTapped(_ sender: Any) {
        
        if self.permissionAccess == false {
            if self.canAskForAccess == true {
                self.requestPermission() //display alert saying they need to give us permission
                return
            }
            self.deniedAlert() //display alert saying they need to go their phone's settings
            return
        }
        
        var defaultDate = Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        if let dailyNotificationsTime = defaults.value(forKey: "dailyNotificationTime"){
            let string = dailyNotificationsTime as! String
            if string != "" {
                defaultDate = (formatter.date(from: string))!
            }
        }
        let picker = DatePickerDialog(buttonColor: mainAppColor, font: UIFont(name: "HelveticaNeue-Medium", size: CGFloat(50))!)
        picker.show("Daily Notification Time", doneButtonTitle: "Done", cancelButtonTitle: "Remove", defaultDate: defaultDate, datePickerMode: .time) {
            (date) -> Void in
            if date != nil {
                
                let formattedDate = formatter.string(from: date!)
                
                
                self.defaults.setValue(formattedDate, forKey: "dailyNotificationTime")
                self.dailyNotificationTimeBtn.setTitle(formattedDate, for: .normal)
                
                NotificationsController.scheduleMorningNotification()
                
                ///log firebase analytics event
                Analytics.logEvent(dailyNotificationTimeChangedEvent, parameters: [
                    "name":"\(formattedDate)" as NSObject,
                    "full_text": "" as NSObject
                    ])
            } else {
                self.dailyNotificationTimeBtn.setTitle("Set", for: .normal)
                self.defaults.setValue("", forKey: "dailyNotificationTime")
                
                NotificationsController.scheduleMorningNotification()
                
                ///log firebase analytics event
                Analytics.logEvent(dailyNotificationOffEvent, parameters: [
                    "name":"" as NSObject,
                    "full_text": "" as NSObject
                    ])
            }
        }
    }
  
    @IBAction func inAppNotificationSwitchToggled(_ sender: Any) {
        if inAppNotificationSwitch.isOn == true {
            //log firebase analytics event
            Analytics.logEvent("in_app_notifications_on", parameters: [
                "name":"" as NSObject,
                "full_text": "" as NSObject
                ])
            defaults.set(true, forKey: "inAppNotifications")
        } else {
            Analytics.logEvent("in_app_notifications_off", parameters: [
                "name":"" as NSObject,
                "full_text": "" as NSObject
                ])
            defaults.set(false, forKey: "inAppNotifications")
        }
        return
    }
    
    
    @IBAction func hapticFeedbackSwitchToggled(_ sender: Any) {
        if hapticFeedbackSwitch.isOn {
            ///log firebase analytics event
            Analytics.logEvent(hapticFeedbackOnEvent, parameters: [
                "name":"" as NSObject,
                "full_text": "" as NSObject
                ])
            defaults.set(true, forKey: "hapticFeedback")
        } else {
            ///log firebase analytics event
            Analytics.logEvent(hapticFeedbackOffEvent, parameters: [
                "name":"" as NSObject,
                "full_text": "" as NSObject
                ])
            defaults.set(false, forKey: "hapticFeedback")
        }
    }
    
    func clearCompletedTasks() {
        let alertController = CFAlertViewController(title: "Are you sure you want to clear all your completed tasks?",
                                                    message: "",
                                                    textAlignment: .left,
                                                    preferredStyle: .alert,
                                                    didDismissAlertHandler: nil)
        let clearAction = CFAlertAction(title: "Clear Completed Tasks",
                                        style: .Destructive,
                                        alignment: .justified,
                                        backgroundColor: FlatRed(),
                                        textColor: nil,
                                        handler: { (action) in
                                            
                                            //log firebase analytics event
                                            Analytics.logEvent("clear_completed_tasks", parameters: [
                                                "name":"" as NSObject,
                                                "full_text": "" as NSObject
                                                ])
                                            
                                            let isCompletedPredicate = NSPredicate(format: "isCompleted == %@",  Bool(booleanLiteral: true) as CVarArg)
                                            let clearObjects = self.realm.objects(SavedTask.self).filter(isCompletedPredicate)
                                            try! self.realm.write {
                                                self.realm.delete(clearObjects)
                                            }
        })
        
        let cancelAction = CFAlertAction(title: "Cancel",
                                         style: .Cancel,
                                         alignment: .justified,
                                         backgroundColor: FlatWhiteDark(),
                                         textColor: nil,
                                         handler: nil)
        
        alertController.addAction(clearAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true) {
            //Causes view to disappear and thus makes both show, need to courteract this
            Floaty.global.button.isHidden = true
        }
    }
    
    func deleteAllTasks() {
        let alertController = CFAlertViewController(title: "⚠️ WARNING: YOU ARE DELETING ALL YOUR TASKS! ",
                                                    message: "This will delete all your tasks. Once all your tasks are deleted, there is no way to get them back.",
                                                    textAlignment: .left,
                                                    preferredStyle: .alert,
                                                    didDismissAlertHandler: nil)
        let deleteAction = CFAlertAction(title: "Delete All My Tasks",
                                         style: .Destructive,
                                         alignment: .justified,
                                         backgroundColor: FlatRed(),
                                         textColor: nil,
                                         handler: { (action) in
                                            
                                            //log firebase analytics event
                                            Analytics.logEvent("delete_all_tasks", parameters: [
                                                "name":"" as NSObject,
                                                "full_text": "" as NSObject
                                                ])
                                            
                                            try! self.realm.write {
                                                self.realm.deleteAll()
                                            }
        })
        
        let cancelAction = CFAlertAction(title: "Cancel",
                                         style: .Cancel,
                                         alignment: .justified,
                                         backgroundColor: FlatWhiteDark(),
                                         textColor: nil,
                                         handler: nil)
        
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true) {
            //Causes view to disappear and thus makes both show, need to courteract this
            Floaty.global.button.isHidden = true
        }
    }
    
    func requestPermission() {
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
                                            Floaty.global.button.isHidden = false
                                            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
                                                if granted == true {
                                                    //log firebase analytics event
                                                    Analytics.logEvent(notificationPermissionGrantedEvent, parameters: [
                                                        "name":"" as NSObject,
                                                        "full_text": "" as NSObject
                                                        ])
                                                    
                                                    self.permissionAccess = true
                                                    self.canAskForAccess = false
                                                    
                                                    DispatchQueue.main.async {
                                                        self.viewDidLoad()
                                                    }
                                                    
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
        
        self.present(alertController, animated: true) {
            //Causes view to disappear and thus makes both show, need to courteract this
            Floaty.global.button.isHidden = true
        }
    }
    
    func deniedAlert() {
        let alertController = CFAlertViewController(title: " You didn't give us permission to send you notifications! 😞",
                                                    message: "Unfortunately, you need to give us permission to send notifications in order to access this feature. You can manage these permissions in your phone's settings.",
                                                    textAlignment: .left,
                                                    preferredStyle: .alert,
                                                    didDismissAlertHandler: nil)
        
        let settingsAction = CFAlertAction(title: "Settings",
                                        style: .Default,
                                        alignment: .justified,
                                        backgroundColor: FlatGreen(),
                                        textColor: nil,
                                        handler: { (action) in UIApplication.shared.open(URL(string:UIApplicationOpenSettingsURLString)!) })
        
        alertController.addAction(settingsAction)
        
        self.present(alertController, animated: true) {
            //Causes view to disappear and thus makes both show, need to courteract this
            Floaty.global.button.isHidden = true
        }
    }
}
