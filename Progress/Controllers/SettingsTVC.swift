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
import DateTimePicker
import Floaty
import Realm
import RealmSwift
import Instabug
import Pulley
import Firebase

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
    
    func clearCompletedTasks() {
        let alertController = CFAlertViewController(title: "Are you sure you want to clear all your completed tasks?",
                                                    message: "",
                                                    textAlignment: .left,
                                                    preferredStyle: .alert,
                                                    didDismissAlertHandler: nil)
        let clearAction = CFAlertAction(title: "Clear Completed Tasks",
                                        style: .Destructive,
                                        alignment: .justified,
                                        backgroundColor: FlatGreen(),
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
        self.present(alertController, animated: true, completion: nil)
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
                                         handler: { (action) in return })
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
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
        
        let picker = DateTimePicker.show(selected: nil, minimumDate: Date()-1, maximumDate: nil)
        picker.becomeFirstResponder()
        picker.todayButtonTitle = ""
        picker.highlightColor = mainAppColor
        picker.isTimePickerOnly = true
        picker.is12HourFormat = true
        picker.doneBackgroundColor = mainAppColor
        picker.cancelButtonTitle = "Clear"
        picker.doneButtonTitle = "Set Time"
        picker.completionHandler = { date in
            
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            let formattedDate = formatter.string(from: date)
            self.defaults.setValue(formattedDate, forKey: "dailyNotificationTime")
            self.dailyNotificationTimeBtn.setTitle(formattedDate, for: .normal)
            NotificationsController.scheduleMorningNotification()
            
            ///log firebase analytics event
            Analytics.logEvent(dailyNotificationTimeChangedEvent, parameters: [
                "name":"\(formattedDate)" as NSObject,
                "full_text": "" as NSObject
                ])
        }
        
        picker.cancelHandler = {
            ///log firebase analytics event
            Analytics.logEvent(dailyNotificationOffEvent, parameters: [
                "name":"" as NSObject,
                "full_text": "" as NSObject
                ])
            
            self.dailyNotificationTimeBtn.setTitle("Set", for: .normal)
            self.defaults.setValue("", forKey: "dailyNotificationTime")
            
            NotificationsController.scheduleMorningNotification()
        }
        
        picker.dismissHandler = {
            return
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
                Instabug.invoke()
            }
            if indexPath.row == 3 {
                ///log firebase analytics event
                Analytics.logEvent(onboardingFromSettingsEvent, parameters: [
                    "name":"" as NSObject,
                    "full_text": "" as NSObject
                    ])
                
                let appD = UIApplication.shared.delegate as! AppDelegate
                appD.loadOnboarding()
            }
        } else if indexPath.section == 2 {
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
