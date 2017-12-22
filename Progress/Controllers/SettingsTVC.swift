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

class SettingsTVC: UITableViewController {

    @IBOutlet weak var dueTodayBadgeCount: UISwitch!
    @IBOutlet weak var badgeCountSwitch: UISwitch!
    @IBOutlet weak var dailyNotificationTimeBtn: UIButton!
    @IBOutlet weak var hapticFeedbackSwitch: UISwitch!
    let defaults = UserDefaults.standard
    let realm = try! Realm()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Settings"
        self.tableView.separatorStyle = .singleLine
        self.navigationController?.navigationBar.tintColor = mainAppColor
        
        let badgeBool = defaults.value(forKey: "yourDayBadgeCount") as! Bool
        if badgeBool == true {
            self.badgeCountSwitch.isOn = true
        } else {
            self.badgeCountSwitch.isOn = false 
        }
        
        let dtBadgeBool = defaults.value(forKey: "dueTodayBadgeCount") as! Bool
        if dtBadgeBool == true {
            self.dueTodayBadgeCount.isOn = true
        } else {
            self.dueTodayBadgeCount.isOn = false
        }
        
        let hapticBool = defaults.value(forKey: "hapticFeedback") as! Bool
        if hapticBool == true {
            self.hapticFeedbackSwitch.isOn = true
        } else {
            self.hapticFeedbackSwitch.isOn = false
        }
        
        if let dailyNotificationsTime = defaults.value(forKey: "dailyNotificationTime"){
            let string = dailyNotificationsTime as! String
            if string != "" {
                self.dailyNotificationTimeBtn.setTitle(string, for: .normal)
            } else {
                self.dailyNotificationTimeBtn.setTitle("Set", for: .normal)
            }
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        Floaty.global.button.isHidden = true
        if let drawerVC = self.navigationController?.parent as? PulleyViewController {
            drawerVC.setDrawerPosition(position: .closed, animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        Floaty.global.button.isHidden = false
        if let drawerVC = self.navigationController?.parent as? PulleyViewController {
            drawerVC.setDrawerPosition(position: .collapsed, animated: true)
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
            if let drawerVC = self.navigationController?.parent as? PulleyViewController {
                drawerVC.setDrawerPosition(position: .closed, animated: true)
            }
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
            if let drawerVC = self.navigationController?.parent as? PulleyViewController {
                drawerVC.setDrawerPosition(position: .closed, animated: true)
            }
        }
    }

    @IBAction func badgeCountSwitchToggled(_ sender: Any) {
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
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(60)
    }
}
