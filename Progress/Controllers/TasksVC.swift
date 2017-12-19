
//
//  TasksVC.swift
//  Progress
//
//  Created by Aditya Gunda on 12/9/17.
//  Copyright © 2017 Aditya Gunda. All rights reserved.
//

import UIKit
import ChameleonFramework
import Floaty
import SwiftReorder
import DottedProgressBar
import MGSwipeTableCell
import Pulley
import Realm
import RealmSwift
import DZNEmptyDataSet
import AudioToolbox
import UserNotifications
import DispatchIntrospection
import Firebase

class TasksVC: UIViewController, FloatyDelegate  {
    
    
    @IBOutlet weak var tableView: UITableView!
    
    let color = FlatPurple()
    let bgColor = UIColor.white
    var currentlySelectedCell: TaskCell? = nil
    
    let realm = try! Realm()
    var tasksList: Results<SavedTask>?
    var token: NotificationToken?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "All Tasks"
        self.navigationController?.navigationBar.prefersLargeTitles = true
        
        //plus button attributes
        Floaty.global.button.buttonColor = color
        Floaty.global.button.plusColor = UIColor.white
        Floaty.global.button.hasShadow = true
        Floaty.global.button.fabDelegate = self
        Floaty.global.show()
        
        //Gripper View
        let gripperView = UIView(frame: CGRect(x: 0, y: 5, width: 36, height: 5))
        gripperView.backgroundColor = FlatWhiteDark()
        gripperView.layer.cornerRadius = 3
        self.navigationItem.titleView = gripperView
        
        //tableview attributes
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.separatorStyle = .none
        self.tableView.sectionHeaderHeight = 0
        
        //Table Cell Reordering
        self.tableView.reorder.delegate = self
        self.tableView.reorder.cellScale = 1.05
        self.tableView.reorder.shadowOpacity = 0.3
        self.tableView.reorder.shadowRadius = 20
        
        //empty state data
        self.tableView.emptyDataSetSource = self
        self.tableView.emptyDataSetDelegate = self
        
        self.fetchObjects()
        
        token = self.tasksList?.observe {[weak self] (changes: RealmCollectionChange) in
            guard let tableView = self?.tableView else { return }
            
            switch changes {
            case .initial:
                tableView.reloadData()
                break
            case .update(let results, let deletions, let insertions, let modifications):
                
                tableView.beginUpdates()
                
                //re-order cells when new pushes happen
                tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) },
                                     with: .left)
                tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) },
                                     with: .left)

                for row in modifications {
                    let indexPath = IndexPath(row: row, section: 0)
                    let selectedTask = results[indexPath.row]
                    let cell = tableView.cellForRow(at: indexPath) as! TaskCell
                    self?.configure(cell: cell, with: selectedTask)
                }
                
                tableView.endUpdates()
                break
            case .error(let error):
                //log crashlytics error
                Crashlytics.sharedInstance().recordError(error)
                print(error)
                break
            }
        }
    }
    
    func fetchObjects(){
        let isNotTodayPredicate = NSPredicate(format: "isToday == %@",  Bool(booleanLiteral: false) as CVarArg)
        let list = self.realm.objects(SavedTask.self).filter(isNotTodayPredicate)
        let sortProperties = [SortDescriptor(keyPath: "isNewTask", ascending: false), SortDescriptor(keyPath: "isCompleted", ascending: true), SortDescriptor(keyPath: "displayOrder", ascending: true)]
        self.tasksList = list.sorted(by: sortProperties)
        self.updateArrayDisplayOrder(self.tasksList!)
    }
    
    func updateArrayDisplayOrder(_ array: Results<SavedTask>){
        var i = 0
        for ro in array {
             i+=1
            try! self.realm.write {
                ro.displayOrder = i
            }
        }
    }
    
    //Plus button tapped to create new task
    func emptyFloatySelected(_ floaty: Floaty) {
        self.createNewTask()
    }
    
    //Creates a new task
    func createNewTask(){
        if let drawerVC = self.navigationController?.parent as? PulleyViewController {
            drawerVC.setDrawerPosition(position: .open, animated: true)
        }
        let newTask = SavedTask()
        newTask.isNewTask = true
        newTask.displayOrder = 0
        try! self.realm.write {
            self.realm.add(newTask)
        }
        //self.tableView.contentInset = UIEdgeInsetsMake(1, 0, 0, 0)
        let deadlineTime = DispatchTime.now() + .seconds(1)

        let visibleCells = self.tableView.indexPathsForVisibleRows
        if visibleCells?.contains(IndexPath(row: 0, section: 0)) == true {
            return
        }
        self.tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
    }
}

extension TasksVC: UITableViewDelegate, UITableViewDataSource, TableViewReorderDelegate {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let spacer = tableView.reorder.spacerCell(for: indexPath) {
            return spacer
        }
        let selectedTask = tasksList![indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as! TaskCell
        self.configure(cell: cell, with: selectedTask)
        
        if selectedTask.isNewTask == true {
            cell.customDelegate?.cellDidBeginEditing(editingCell: cell)
        }
        return cell
    }
    
    //when user reorders table cells
    func tableView(_ tableView: UITableView, reorderRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        //log firebase analytics event
        Analytics.logEvent("tasks_reordered", parameters: [
            "name":"" as NSObject,
            "full_text": "" as NSObject
            ])
        
        self.realm.beginWrite()
        
        let sourceObject = tasksList![sourceIndexPath.row]
        let destinationObject = tasksList![destinationIndexPath.row]
        
        let sourceStatus = sourceObject.isCompleted
        let destinationStatus = destinationObject.isCompleted
        
        if sourceStatus != destinationStatus {
            sourceObject.isCompleted = destinationStatus
        }
        
        let destinationObjectOrder = destinationObject.displayOrder
        
        if sourceIndexPath.row < destinationIndexPath.row {
            for index in sourceIndexPath.row...destinationIndexPath.row {
                let object = tasksList![index]
                object.displayOrder -= 1
            }
        } else {
            for index in (destinationIndexPath.row..<sourceIndexPath.row).reversed() {
                let object = tasksList![index]
                object.displayOrder += 1
            }
        }
        sourceObject.displayOrder = destinationObjectOrder
        
        try! self.realm.commitWrite(withoutNotifying: [self.token!])
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        return
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    //when user taps on cell to edit it
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = self.tableView.cellForRow(at: indexPath) as! TaskCell
        cell.customDelegate?.cellDidBeginEditing(editingCell: cell)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasksList!.count
    }
}

extension TasksVC: CustomTaskCellDelegate {
    
    func configure(cell: TaskCell, with savedTask: SavedTask) {
        let cellTask = savedTask
        let title = cellTask.title
        let count = cellTask.points
        let date = cellTask.deadline
        let checked = cellTask.isCompleted
        let progressDotRadius = CGFloat(4.0)
        let indWidth = (10+(2*Int(progressDotRadius)))
        let width = indWidth * count
        let frameWidth = Int(cell.progressBar.frame.width)
        var modifiedCount = count
        //let dotColorsArr = [FlatPurple(),FlatBlue(),FlatGreen(),FlatYellow(),FlatOrange(),FlatRed()]
        //let colorIndex = ((width/indWidth)/(frameWidth/indWidth))%6
        //let dotColor = dotColorsArr[colorIndex]
        
        //cell attributes
        cell.taskObj = cellTask
        cell.selectionStyle = .none
        cell.delegate = self
        cell.customDelegate = self
        cell.contentView.backgroundColor = bgColor
        cell.taskTitleLabel.isEnabled = false
        cell.taskTitleLabel.text = title
        
        //due date button
        cell.dueDateBtn.setTitle("Choose Deadline", for: .highlighted)
        cell.dueDateBtn.setTitleColor(FlatPurple(), for: .highlighted)

        if date != nil {
            cell.dueDate = date
            cell.dueDateBtn.isHidden = false
            
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            let formattedDate = formatter.string(from: date!)
            
            if (date?.isYesterday)! == true {
                cell.dueDateBtn.setTitle("Yesterday", for: .normal)
                cell.dueDateBtn.setTitleColor(FlatRed(), for: .normal)
            } else if (date?.isToday)! == true  {
                cell.dueDateBtn.setTitle("Today", for: .normal)
                cell.dueDateBtn.setTitleColor(FlatGreen(), for: .normal)
            } else if (date?.isTomorrow)! == true {
                cell.dueDateBtn.setTitle("Tomorrow", for: .normal)
                cell.dueDateBtn.setTitleColor(FlatGrayDark(), for: .normal)
            } else {
                if (date?.isInPast)! == true {
                    let colloquialPhrase = (date?.colloquialSinceNow())!
                    cell.dueDateBtn.setTitle("\(colloquialPhrase)", for: .normal)
                    cell.dueDateBtn.setTitleColor(FlatGrayDark(), for: .normal)
                } else {
                    //date is in future
                    let calendar = NSCalendar.current
                    let date1 = calendar.startOfDay(for: date!)
                    let date2 = calendar.startOfDay(for: Date())
                    let components = calendar.dateComponents([.day], from: date1, to: date2)
                    let difference = abs((components.day)!)
                    if difference < 15 {
                        cell.dueDateBtn.setTitle("in \(difference) days", for: .normal)
                        cell.dueDateBtn.setTitleColor(FlatGrayDark(), for: .normal)
                    } else {
                        cell.dueDateBtn.setTitle("\(formattedDate)", for: .normal)
                        cell.dueDateBtn.setTitleColor(FlatGrayDark(), for: .normal)
                    }
                }
            }
        } else {
            cell.dueDateBtn.setTitle("Add Deadline", for: .normal)
            cell.dueDateBtn.setTitleColor(FlatGray(), for: .normal)
            cell.dueDate = nil
            cell.dueDateBtn.isHidden = true
        }
        
        //cell progress bar attributes
        if count == 0 {
            cell.progressBar.isHidden = true
        } else {
            cell.progressBar.isHidden = false
            cell.progressBar.backgroundColor = bgColor
            cell.progressBar.progressAppearance = DottedProgressBar.DottedProgressAppearance (
                dotRadius: progressDotRadius,
                dotsColor: color,
                dotsProgressColor: color,
                backColor: UIColor.clear
            )
            if width > frameWidth {
                let remainder = (width/indWidth)%(frameWidth/indWidth)
                modifiedCount = remainder
            }
            cell.progressBar.setNumberOfDots(modifiedCount, animated: false)
        }
        
        //sliding options
        let leftButton1 = MGSwipeButton(title: "Add to My Day", backgroundColor: FlatGreen())
        leftButton1.titleLabel?.font = UIFont(name: "SF Pro Text Regular" , size: 12)
        cell.leftButtons = [leftButton1]
        cell.leftSwipeSettings.transition = .drag
        cell.leftExpansion.buttonIndex = 0
        cell.leftExpansion.fillOnTrigger = true
        cell.leftExpansion.threshold = 2
        let rightButton1 = MGSwipeButton(title: "Delete", backgroundColor: FlatRed())
        rightButton1.titleLabel?.font = UIFont(name: "SF Pro Text Regular" , size: 12)
        cell.rightButtons = [ rightButton1]
        cell.rightSwipeSettings.transition = .drag
        cell.rightExpansion.buttonIndex = 0
        cell.rightExpansion.fillOnTrigger = true
        cell.rightExpansion.threshold = 1
        
        //cell checkbox attributes
        if checked == true {
            cell.checkBox.on = true
            cell.contentView.alpha = CGFloat(0.2)
        } else {
            cell.checkBox.on = false
            cell.contentView.alpha = CGFloat(1.0)
        }
        cell.checkBox.onAnimationType = .fill
        cell.checkBox.onTintColor = color
        cell.checkBox.onFillColor = color
        cell.checkBox.onCheckColor = UIColor.white
    }
    
    //mark task as completed when checked
    func cellCheckBoxTapped(editingCell: TaskCell, checked: Bool) {
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        let selectedTask = editingCell.taskObj!
        
        if checked == true {
            //log firebase analytics event
            Analytics.logEvent("task_completed", parameters: [
                "name": selectedTask.title as NSObject,
                "full_text": "" as NSObject
                ])
            
            if selectedTask.deadline != nil {
                NotificationsController.removeNotifications(task: selectedTask)
            }
        } else {
            //log firebase analytics event
            Analytics.logEvent("task_uncompleted", parameters: [
                "name": selectedTask.title as NSObject,
                "full_text": "" as NSObject
                ])
            
            if selectedTask.deadline != nil {
                NotificationsController.scheduleNotification(task: selectedTask)
            }
        }
        
        try! self.realm.write {
            selectedTask.isCompleted = checked
        }
    }
    
    //update changed deadline
    func cellDueDateChanged(editingCell: TaskCell, date: Date?) {
        
        //contextual prompt of asking user for permissions to add badges
        NotificationsController.requestPermission()
        
        let selectedTask = editingCell.taskObj!
        
        //log firebase analytics event
        Analytics.logEvent("changed_deadline", parameters: [
            "name": selectedTask.title as NSObject,
            "full_text": "" as NSObject
            ])
        
        if selectedTask.notificationIdentifier != "" {
            NotificationsController.removeNotifications(task: selectedTask)
        }
        
        try! self.realm.write {
            if let unwrappedDate = date {
                selectedTask.deadline = unwrappedDate
            } else {
                selectedTask.deadline = nil
            }
        }
        
         NotificationsController.scheduleNotification(task: selectedTask)
    }
    
    //delete task - core data
    func deleteTask(editingCell: TaskCell) {
        let selectedTask = (editingCell.taskObj)!
        
        //log firebase analytics event
        Analytics.logEvent("delete_task", parameters: [
            "name": selectedTask.title as NSObject,
            "full_text": "" as NSObject
            ])
        
        if selectedTask.notificationIdentifier != "" {
            NotificationsController.removeNotifications(task: selectedTask)
        }
        
        try! self.realm.write {
            self.realm.delete(selectedTask)
        }
    }
    
    //update new task title
    func updateTaskTitle(editingCell: TaskCell, newTitle: String) {
        let selectedTask = (editingCell.taskObj)!
        
        //log firebase analytics event
        Analytics.logEvent("updated_task_title", parameters: [
            "name": selectedTask.title as NSObject,
            "full_text": "" as NSObject
            ])
        
        try! self.realm.write {
            selectedTask.title = newTitle
        }
    }
    
    //add task to today
    func addTasktoToday(editingCell: TaskCell) {
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        let selectedTask = (editingCell.taskObj)!
        
        //log firebase analytics event
        Analytics.logEvent("add_task_to_your_day", parameters: [
            "name": selectedTask.title as NSObject,
            "full_text": "" as NSObject
            ])
        
        try! self.realm.write {
            selectedTask.isCompleted = false
            selectedTask.isToday = true
        }
    }
    
    func cellDidBeginEditing(editingCell: TaskCell) {
        
        if editingCell.taskObj?.isCompleted == true || editingCell.swipeOffset > 0 {
            return
        }
        
        if let drawerVC = self.navigationController?.parent as? PulleyViewController {
            drawerVC.setDrawerPosition(position: .open, animated: true)
            drawerVC.allowsUserDrawerPositionChange = false
        }
        
        editingCell.isBeingEdited = true
        self.currentlySelectedCell = editingCell
        
        //makes due date button visible
        editingCell.dueDateBtn.isHidden = false
        
        //Hide Button if datepicker is selected
        ///Show keyboard if datepicker is not selected
        editingCell.taskTitleLabel.isEnabled = true
        if editingCell.pickerSelected == false {
            //triggers keyboard if picker is not the first responder
            editingCell.taskTitleLabel.becomeFirstResponder()
        } else {
            Floaty.global.button.isHidden = true
        }
        
        let editingOffset = self.tableView.contentOffset.y - editingCell.frame.origin.y as CGFloat
       let visibleCells = self.tableView.visibleCells as! [TaskCell]
       for cell in visibleCells {
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                cell.transform = CGAffineTransform(translationX: 0, y: editingOffset)
                if cell != editingCell {
                    cell.alpha = 0.1
                }
            })
        }
    }
    
    func cellDidEndEditing(editingCell: TaskCell) {
        
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)

        if editingCell.taskObj?.isNewTask == true {
            try! self.realm.write {
                editingCell.taskObj?.isNewTask = false
            }
            
            //log firebase analytics event for creating new task
            Analytics.logEvent("create_task", parameters: [
                "name": (editingCell.taskObj?.title)! as NSObject,
                "full_text": "" as NSObject
                ])
        }
        
        if let drawerVC = self.navigationController?.parent as? PulleyViewController {
            drawerVC.allowsUserDrawerPositionChange = true 
        }

        editingCell.isBeingEdited = false
        
        if self.currentlySelectedCell == editingCell{
            self.currentlySelectedCell = nil
        }
        
        //hides due date btn
        if editingCell.dueDate == nil {
            editingCell.dueDateBtn.isHidden = true
        }
        
        if editingCell.pickerSelected == true {
            Floaty.global.button.isHidden = false 
        }
        
        
        editingCell.taskTitleLabel.isEnabled = false
        editingCell.taskTitleLabel.isEnabled = false
        
        //mark new name in coredata
        let newText = editingCell.taskTitleLabel.text
        let trimmedText = editingCell.taskTitleLabel.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedText.isEmpty == false {
            self.updateTaskTitle(editingCell: editingCell, newTitle: newText!)
        } else {
            //delete new task if user did not give it title
            //deletes existing task if user removed its title
            editingCell.objectDeleted = true 
            self.deleteTask(editingCell: editingCell)
        }
        
        let visibleCells = tableView.visibleCells as! [TaskCell]
        for cell: TaskCell in visibleCells {
            UIView.animate(withDuration: 0.2, animations: { () -> Void in
                cell.transform = CGAffineTransform.identity
                if cell != editingCell {
                    cell.alpha = 0.3
                }
            }, completion: { (Finished: Bool) -> Void in
            })
        }
        
    }
    
}

extension TasksVC: MGSwipeTableCellDelegate {
    
    func swipeTableCellWillBeginSwiping(_ cell: MGSwipeTableCell) {
        let uwCell = cell as! TaskCell
        if uwCell.isBeingEdited == true {
            uwCell.endEditing(false)
        }
    }
    
    func swipeTableCell(_ cell: MGSwipeTableCell, tappedButtonAt index: Int, direction: MGSwipeDirection, fromExpansion: Bool) -> Bool {
       
        let modifiedCell = cell as! TaskCell
        
        if direction == .rightToLeft {
            if index == 0 {
                //if user swipes to delete cell
                if modifiedCell.taskObj?.title != "" || (modifiedCell.isBeingEdited == false && modifiedCell.taskObj?.title == "") {
                    self.deleteTask(editingCell: modifiedCell)
                }
            }
        } else {
            if index == 0 {
                //if user swipes to add task to today
                self.addTasktoToday(editingCell: modifiedCell)
                
                //contextual prompt of asking user for permissions to add badges
                NotificationsController.requestPermission()
            }
        }
        
        if modifiedCell.isBeingEdited == true {
            modifiedCell.taskTitleLabel.resignFirstResponder()
        }
        
        return true
    }
}

extension TasksVC: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "confused" )
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "What to do?"
       let attrs = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "You have no pending tasks."
        let attrs = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return -((self.navigationController?.navigationBar.frame.size.height)!/2.0)
    }
}

/*
extension TasksVC: UNUserNotificationCenterDelegate  {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        switch response.actionIdentifier {
        case UNNotificationDismissActionIdentifier:
            //log firebase analytics event
            Analytics.logEvent("dismissed_deadline_notification", parameters: [
                "name": "" as NSObject,
                "full_text": "" as NSObject
                ])
            completionHandler()
            break
        case UNNotificationDefaultActionIdentifier:
            //log firebase analytics event
            Analytics.logEvent("opened_deadline_notification", parameters: [
                "name": "" as NSObject,
                "full_text": "" as NSObject
                ])
            completionHandler()
            break
        /*case "deleteAction":
            /*let userInfo = response.notification.request.content.userInfo
            let task = userInfo["task"] as! SavedTask
            let realm = try! Realm()
            try! realm.write {
                realm.delete(task)
            }*/
            break
        case "completeAction":
            /*let userInfo = response.notification.request.content.userInfo
            let task = userInfo["task"] as! SavedTask
            let realm = try! Realm()
            try! realm.write {
                task.isCompleted = true
                task.isToday = false
            }*/
            break*/
        default:
            completionHandler()
            break
        }
    }
}
 */

