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

class SettingsTVC: UITableViewController {

    @IBOutlet weak var badgeCountSwitch: UISwitch!
    @IBOutlet weak var dailyNotificationTimeBtn: UIButton!
    @IBOutlet weak var hapticFeedbackSwitch: UISwitch!
    let defaults = UserDefaults.standard
    let realm = try! Realm()

    override func viewDidLoad() {
        super.viewDidLoad()
        Floaty.global.button.isHidden = true
        
        self.title = "Settings"
        self.tableView.separatorStyle = .singleLine
        self.navigationController?.navigationBar.tintColor = FlatPurple()
        
        let badgeBool = defaults.value(forKey: "yourDayBadgeCount") as! Bool
        if badgeBool == true {
            self.badgeCountSwitch.isOn = true
        } else {
            self.badgeCountSwitch.isOn = false 
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
                self.dailyNotificationTimeBtn.setTitle("Choose Time", for: .normal)
            }
        }
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        Floaty.global.button.isHidden = false
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
        let alertController = CFAlertViewController(title: "⚠️ WARNING: YOU ARE DELETING ALL YOUR TASKS! ⚠️",
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
            defaults.set(true, forKey: "yourDayBadgeCount")
        } else {
             defaults.set(false, forKey: "yourDayBadgeCount")
        }
    }
    
    @IBAction func dailyNotificationTimeBtnTapped(_ sender: Any) {
        
        let picker = DateTimePicker.show(selected: nil, maximumDate: nil)
        picker.becomeFirstResponder()
        picker.todayButtonTitle = ""
        picker.highlightColor = FlatPurple()
        picker.isTimePickerOnly = true
        picker.is12HourFormat = true
        picker.doneBackgroundColor = FlatPurple()
        picker.cancelButtonTitle = "Remove"
        picker.doneButtonTitle = "Set Time"
        picker.completionHandler = { date in
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            let formattedDate = formatter.string(from: date)
            self.defaults.setValue(formattedDate, forKey: "dailyNotificationTime")
            self.dailyNotificationTimeBtn.setTitle(formattedDate, for: .normal)
            NotificationsController.scheduleMorningNotification()
        }
        picker.cancelHandler = {
             self.dailyNotificationTimeBtn.setTitle("Choose time", for: .normal)
            self.defaults.setValue("", forKey: "dailyNotificationTime")
            NotificationsController.scheduleMorningNotification()
        }
        picker.dismissHandler = {
            return
        }
    }

    @IBAction func hapticFeedbackSwitchToggled(_ sender: Any) {
        if hapticFeedbackSwitch.isOn {
            defaults.set(true, forKey: "hapticFeedback")
        } else {
            defaults.set(false, forKey: "hapticFeedback")
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 2 {
                Instabug.invoke()
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
