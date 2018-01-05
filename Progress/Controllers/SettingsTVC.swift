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
import UserNotifications
import RMDateSelectionViewController
import MessageUI
import SafariServices
import StoreKit

class SettingsTVC: UITableViewController, MFMailComposeViewControllerDelegate{

    @IBOutlet weak var dueTodayBadgeCount: UISwitch!
    @IBOutlet weak var badgeCountSwitch: UISwitch!
    @IBOutlet weak var dailyNotificationTimeBtn: UIButton!
    @IBOutlet weak var hapticFeedbackSwitch: UISwitch!
    @IBOutlet weak var inAppNotificationSwitch: UISwitch!
    let defaults = UserDefaults.standard
    let realm = try! Realm()
    var permissionAccess = false
    var canAskForAccess = false
    var goingForward = false
    
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
            DispatchQueue.main.async {
                if badgeBool == true && self.permissionAccess == true {
                    self.badgeCountSwitch.isOn = true
                } else {
                    self.badgeCountSwitch.isOn = false
                }
                
                if dtBadgeBool == true && self.permissionAccess == true {
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
                
                if let dailyNotificationsTime = self.defaults.value(forKey: "dailyNotificationTime")  {
                    let string = dailyNotificationsTime as! String
                    if string != "" && self.permissionAccess == true {
                        self.dailyNotificationTimeBtn.setTitle(string, for: .normal)
                    } else {
                        self.dailyNotificationTimeBtn.setTitle("Set", for: .normal)
                    }
                }
            }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        Floaty.global.hide()
        if let drawerVC = self.navigationController?.parent as? PulleyViewController {
            drawerVC.setDrawerPosition(position: .closed, animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if (self.goingForward == false) {
            Floaty.global.show()
            if let drawerVC = self.navigationController?.parent as? PulleyViewController {
                drawerVC.setDrawerPosition(position: .partiallyRevealed, animated: true)
            }
        } else {
            self.goingForward = false
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(60)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                //show help
                
                //log firebase debug event
                DebugController.write(string: "clicked help in settings")
                
                let svc = SFSafariViewController(url: URL(string:"https://www.makeprogressapp.com/help")!)
                svc.preferredControlTintColor = UIColor.flatPurpleDark
                
                self.goingForward = true
                self.present(svc, animated: true){return  }
                
                ///log firebase analytics event
                Analytics.logEvent(clickedHelpEvent, parameters: [
                    "name":"" as NSObject,
                    "full_text": "" as NSObject
                    ])
            }
            if indexPath.row == 1 {
                //trigger talk to us
                
                //log firebase debug event
                DebugController.write(string: "clicked talk to us in settings")
                
                if MFMailComposeViewController.canSendMail() {
                    
                    let composeVC = MFMailComposeViewController()
                    composeVC.mailComposeDelegate = self
                    
                    // Configure the fields of the interface.
                    composeVC.setToRecipients(["support@makeprogressapp.com"])
                   
                    self.goingForward = true
                    // Present the view controller modally.
                    self.present(composeVC, animated: true){ return }
                } else {
                    let alertController = CFAlertViewController(title: "Looks like you don't have the Mail app working on your phone.",
                                                                message: "Just shoot us an email at info@makeprogress.com to get in touch with us.",
                                                                textAlignment: .left,
                                                                preferredStyle: .alert,
                                                                didDismissAlertHandler: nil)
                    
                    
                    let gotAction = CFAlertAction(title: "Got It",
                                                  style: .Default,
                                                  alignment: .justified,
                                                  backgroundColor: FlatGreen(),
                                                  textColor: nil,
                                                  handler: { (action) in return })
                    
                    alertController.addAction(gotAction)
                    
                    self.goingForward = true
                    self.present(alertController, animated: true) {return }
                }
                
                ///log firebase analytics event
                Analytics.logEvent(talkToUsEvent, parameters: [
                    "name":"" as NSObject,
                    "full_text": "" as NSObject
                    ])
            }
            
            if indexPath.row == 2 {
                //load welcome guide
                
                //log firebase debug event
                DebugController.write(string: "clicked welcome guide in settings")
                
                let storyboard: UIStoryboard = UIStoryboard.init(name: "Main",bundle: nil)
                let vc: TodayVC = storyboard.instantiateViewController(withIdentifier: "PrimaryContentViewController") as! TodayVC
                vc.loadOnboarding()
                
                ///log firebase analytics event
                Analytics.logEvent(onboardingFromSettingsEvent, parameters: [
                    "name":"" as NSObject,
                    "full_text": "" as NSObject
                    ])
            }
            
            if indexPath.row == 3 {
                //review app
                
                //log firebase debug event
                DebugController.write(string: "clicked rate app in settings")
                
                SKStoreReviewController.requestReview()
                
                ///log firebase analytics event
                Analytics.logEvent(clickedRateAppEvent, parameters: [
                    "name":"" as NSObject,
                    "full_text": "" as NSObject
                    ])
            }
        }  else if indexPath.section == 2 {
            if indexPath.row == 0 {
                
                //log firebase debug event
                DebugController.write(string: "clicked clear completed tasks in settings")
                
                self.clearCompletedTasks()
            }
            if indexPath.row == 1 {
                
                //log firebase debug event
                DebugController.write(string: "clicked delete all tasks in settings")
                
                self.deleteAllTasks()
            }
        } else if indexPath.section == 3 {
             if indexPath.row == 0{
                //show website
                
                //log firebase debug event
                DebugController.write(string: "clicked website in settings")
                
                let svc = SFSafariViewController(url: URL(string:"https://www.makeprogressapp.com")!)
                svc.preferredControlTintColor = UIColor.flatPurpleDark
                
                self.goingForward = true
                self.present(svc, animated: true){ return }
            } else  if indexPath.row == 1 {
                //show credits
                
                //log firebase debug event
                DebugController.write(string: "clicked credits in settings")
                
                let svc = SFSafariViewController(url: URL(string:"https://www.makeprogressapp.com/credits")!)
                svc.preferredControlTintColor = UIColor.flatPurpleDark
                
                self.goingForward = true
                self.present(svc, animated: true){ return }
             }else  if indexPath.row == 2 {
                //show terms
                
                //log firebase debug event
                DebugController.write(string: "clicked terms in settings")
                
                let svc = SFSafariViewController(url: URL(string:"https://www.makeprogressapp.com/terms")!)
                svc.preferredControlTintColor = UIColor.flatPurpleDark
                
                self.goingForward = true
                self.present(svc, animated: true){ return }
             } else  if indexPath.row == 3 {
                //show privacy
                
                //log firebase debug event
                DebugController.write(string: "clicked privacy in settings")
                
                let svc = SFSafariViewController(url: URL(string:"https://www.makeprogressapp.com/privacy")!)
                svc.preferredControlTintColor = UIColor.flatPurpleDark
                self.goingForward = true
                self.present(svc, animated: true){ return }
            }
        }
    }

    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult, error: Error?) {
        // Dismiss the mail compose view controller.
        self.dismiss(animated: true, completion: nil)
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
        
        //log firebase debug event
        DebugController.write(string: "your day badge count switch toggled in settings")
        
        if badgeCountSwitch.isOn == true {
            Analytics.logEvent("your_day_count_badge_on", parameters: ["name":"" as NSObject, "full_text": "" as NSObject]) //log firebase analytics event
            defaults.set(true, forKey: "yourDayBadgeCount")
        } else {
            Analytics.logEvent("your_day_count_badge_off", parameters: [ "name":"" as NSObject, "full_text": "" as NSObject]) //log firebase analytics event
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
        
        DebugController.write(string: "due today badge count switch toggled in settings") //log firebase debug event
        
        if dueTodayBadgeCount.isOn == true {
            //log firebase analytics event
            Analytics.logEvent("due_today_count_badge_on", parameters: ["name":"" as NSObject, "full_text": "" as NSObject])
            
            defaults.set(true, forKey: "dueTodayBadgeCount")
        } else {
            //log firebase analytics event
            Analytics.logEvent("due_today_count_badge_off", parameters: ["name":"" as NSObject, "full_text": "" as NSObject])
            
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
        
        //log firebase debug event
        DebugController.write(string: "daily notification time clicked in settings")
        
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
        
        let select: RMAction<UIDatePicker> = RMAction(title: "Done", style: .done) { (controller) in
            
                //log firebase debug event
                DebugController.write(string: "daily notification time in settings - select action clicked")
            
                let date = controller.contentView.date
                let formattedDate = formatter.string(from: date)
            
                self.defaults.setValue(formattedDate, forKey: "dailyNotificationTime")
                self.dailyNotificationTimeBtn.setTitle(formattedDate, for: .normal)
            
                NotificationsController.scheduleMorningNotification()
            
                ///log firebase analytics event
                Analytics.logEvent(dailyNotificationTimeChangedEvent, parameters: ["name":"\(formattedDate)" as NSObject, "full_text": "" as NSObject])
            
            }!
        
        let clear: RMAction<UIDatePicker> = RMAction(title: "Remove", style: .destructive) { (controller) in
            
                //log firebase debug event
                DebugController.write(string: "daily notification time in settings - clear action clicked")
            
                self.dailyNotificationTimeBtn.setTitle("Set", for: .normal)
                self.defaults.setValue("", forKey: "dailyNotificationTime")
            
                NotificationsController.scheduleMorningNotification()
            
                if let drawerVC = self.navigationController?.parent as? PulleyViewController {
                    drawerVC.setDrawerPosition(position: .partiallyRevealed, animated: true)
                }
            
                ///log firebase analytics event
                Analytics.logEvent(dailyNotificationOffEvent, parameters: ["name":"" as NSObject, "full_text": "" as NSObject])
            }!
        
        let picker = RMDateSelectionViewController(style: .sheetWhite, title: "Set Time for Daily Motivational Notification", message: nil, select: select, andCancel: clear)
        picker?.datePicker.date = defaultDate
        picker?.contentView.datePickerMode = .time
        self.present(picker!, animated: true, completion: nil)
    }
  
    @IBAction func inAppNotificationSwitchToggled(_ sender: Any) {
        
        //log firebase debug event
        DebugController.write(string: "in app notification switch toggled in settings - select action clicked")
        
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
        //log firebase debug event
        DebugController.write(string: "haptic feedback switch toggled in settings - select action clicked")
        
        if hapticFeedbackSwitch.isOn {
            ///log firebase analytics event
            Analytics.logEvent(hapticFeedbackOnEvent, parameters: ["name":"" as NSObject, "full_text": "" as NSObject])
            defaults.set(true, forKey: "hapticFeedback")
        } else {
            ///log firebase analytics event
            Analytics.logEvent(hapticFeedbackOffEvent, parameters: ["name":"" as NSObject, "full_text": "" as NSObject])
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
                                         handler: { (action) in return })
        
        alertController.addAction(clearAction)
        alertController.addAction(cancelAction)
        self.goingForward = true
        self.present(alertController, animated: true) { return }
    }
    
    func deleteAllTasks() {
        self.goingForward = true
        
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
                                            Analytics.logEvent("delete_all_tasks", parameters: ["name":"" as NSObject, "full_text": "" as NSObject])
                                            
                                            try! self.realm.write {
                                                self.realm.deleteAll()
                                            }
        })
        
        let cancelAction = CFAlertAction(title: "Cancel",
                                         style: .Cancel,
                                         alignment: .justified,
                                         backgroundColor: FlatWhiteDark(),
                                         textColor: nil,
                                         handler:  { (action) in return })
        
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true) { return }
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
                                            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
                                                if granted == true {
                                                    //log firebase analytics event
                                                    Analytics.logEvent(notificationPermissionGrantedEvent, parameters: ["name":"" as NSObject, "full_text": "" as NSObject])
                                                    
                                                    self.permissionAccess = true
                                                    self.canAskForAccess = false
                                                    
                                                    DispatchQueue.main.async {
                                                        self.viewDidLoad()
                                                    }
                                                } else {
                                                    //log firebase analytics event
                                                    Analytics.logEvent(notificationPermissionDeniedEvent, parameters: ["name":"" as NSObject, "full_text": "" as NSObject])
                                                }
                                                
                                                if error != nil {
                                                    Crashlytics.sharedInstance().recordError(error!)  //log crashlytics error
                                                    return
                                                }
                                            }
                                            
        })
        
        let laterAction = CFAlertAction(title: "Decide Later",
                                        style: .Cancel,
                                        alignment: .justified,
                                        backgroundColor: FlatWhiteDark(),
                                        textColor: nil,
                                        handler: { (action) in return})
    
        alertController.addAction(grantedAction)
        alertController.addAction(laterAction)
        
        alertController.shouldDismissOnBackgroundTap = false
        
        self.goingForward = true
        self.present(alertController, animated: true) { return }
    }
    
    func deniedAlert() {
        let alertController = CFAlertViewController(title: "You didn't give us permission to send you notifications! 😞",
                                                    message: "Unfortunately, you need to give us permission to send notifications in order to access this feature. You can manage these permissions in your phone's settings.",
                                                    textAlignment: .left,
                                                    preferredStyle: .alert,
                                                    didDismissAlertHandler: nil)
        
        let settingsAction = CFAlertAction(title: "Settings",
                                        style: .Default,
                                        alignment: .justified,
                                        backgroundColor: FlatGreen(),
                                        textColor: nil,
                                        handler: { (action) in
                                            UIApplication.shared.open(URL(string:UIApplicationOpenSettingsURLString)!) })
        
        alertController.addAction(settingsAction)
        
        self.goingForward = true
        self.present(alertController, animated: true) { return }
    }
}
