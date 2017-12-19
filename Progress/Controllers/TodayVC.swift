//
//  TodayVC.swift
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
import BEMCheckBox
import Realm
import RealmSwift
import DZNEmptyDataSet
import Crashlytics
import Instabug
import AudioToolbox
import Firebase

class TodayVC: UIViewController , TableViewReorderDelegate {

    
    @IBOutlet weak var tableView: UITableView!
    
    let color = FlatPurple()
    let bgColor = UIColor.white
    var currentlySelectedCell: TodayTaskCell?

    let realm = try! Realm()
    var tasksList: Results<SavedTask>?
    var token: NotificationToken?
    var firstOpening: Bool?
    let defaults = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Your Day"
        self.navigationController?.navigationBar.prefersLargeTitles = true
        
        Instabug.setIntroMessageEnabled(false)
  
        //table View Properties
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.separatorStyle = .none
        self.tableView.sectionHeaderHeight = 0
        
        //empty state data
        self.tableView.emptyDataSetSource = self;
        self.tableView.emptyDataSetDelegate = self;
        
        //table Cell Reordering
        self.tableView.reorder.delegate = self
        tableView.reorder.cellScale = 1.05
        tableView.reorder.shadowOpacity = 0.3
        tableView.reorder.shadowRadius = 20
    
        self.fetchObjects()
        
        token = self.tasksList?.observe {[weak self] (changes: RealmCollectionChange) in
            guard let tableView = self?.tableView else { return }
            
            switch changes {
            case .initial:
                tableView.reloadData()
                break
            case .update(let results, let deletions, let insertions, let modifications):
                
                tableView.beginUpdates()
                
                tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) },
                                     with: .left)
                tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) },
                                     with: .left)

                    for row in modifications {
                        let indexPath = IndexPath(row: row, section: 0)
                        let selectedTask = results[indexPath.row]
                        let cell = tableView.cellForRow(at: indexPath) as! TodayTaskCell
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
        let isTodayPredicate = NSPredicate(format: "isToday == %@",  Bool(booleanLiteral: true) as CVarArg)
        let isNotCompletedPredicate = NSPredicate(format: "isCompleted == %@",  Bool(booleanLiteral: false) as CVarArg)
        let andPredicate = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: [isTodayPredicate, isNotCompletedPredicate])
        let list = self.realm.objects(SavedTask.self).filter(andPredicate)
        self.tasksList = list.sorted(byKeyPath: "displayOrder", ascending: true)
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
}

extension TodayVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let spacer = tableView.reorder.spacerCell(for: indexPath) {
            return spacer
        }
        let selectedTask = tasksList![indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as! TodayTaskCell
        self.configure(cell: cell, with: selectedTask)
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = self.tableView.cellForRow(at: indexPath) as! TodayTaskCell
        if self.currentlySelectedCell != nil {
            self.currentlySelectedCell?.customDelegate?.cellDidEndEditing(editingCell: cell)
        }
        cell.customDelegate?.cellDidBeginEditing(editingCell: cell)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasksList!.count
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        return
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

}

extension TodayVC: CustomTodayTaskCellDelegate {
    func configure(cell: TodayTaskCell, with savedTask: SavedTask) {
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
        //let dotColors = [FlatPurple(),FlatBlue(),FlatGreen(),FlatYellow(),FlatOrange(),FlatRed()]
        //let colorIndex = ((width/indWidth)/(frameWidth/indWidth))%6
        //let dotColor = dotColors[colorIndex]
        
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
        let leftButton1 = MGSwipeButton(title: "Done for Today", backgroundColor: FlatGreen())
        leftButton1.titleLabel?.font = UIFont(name: "SF Pro Text Regular" , size: 12)
        cell.leftButtons = [leftButton1]
        cell.leftSwipeSettings.transition = .drag
        cell.leftExpansion.buttonIndex = 0
        cell.leftExpansion.fillOnTrigger = true
        cell.leftExpansion.threshold = 2
        let rightButton1 = MGSwipeButton(title: "Delete", backgroundColor: FlatRed())
        let rightButton2 = MGSwipeButton(title: "Remove from My Day", backgroundColor: UIColor.gray)
        rightButton1.titleLabel?.font = UIFont(name: "SF Pro Text Regular" , size: 12)
        rightButton2.titleLabel?.font = UIFont(name: "SF Pro Text Regular" , size: 12)
        cell.rightButtons = [rightButton1, rightButton2]
        cell.rightSwipeSettings.transition = .drag
        cell.rightExpansion.buttonIndex = 0
        cell.rightExpansion.fillOnTrigger = true
        cell.rightExpansion.threshold = 1
        
        //cell checkbox attributes
        if checked == true {
            cell.checkBox.on = true
            cell.alpha = CGFloat(0.3)
        } else {
            cell.checkBox.on = false
            cell.alpha = CGFloat(1.0)
        }
        cell.checkBox.onAnimationType = .fill
        cell.checkBox.onTintColor = color
        cell.checkBox.onFillColor = color
        cell.checkBox.onCheckColor = UIColor.white
    }
    
    //mark task as completed when checked
    func cellCheckBoxTapped(editingCell: TodayTaskCell, checked: Bool) {
        let hapticBool = self.defaults.value(forKey: "hapticFeedback") as! Bool
        if hapticBool == true {
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
        
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
            selectedTask.isToday = false
        }
    }
    
    //update changed deadline
    func cellDueDateChanged(editingCell: TodayTaskCell, date: Date?) {
        
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
    
    //delete task
    func deleteTask(editingCell: TodayTaskCell) {
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
    func updateTaskTitle(editingCell: TodayTaskCell, newTitle: String) {
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
    
    func removeTaskfromToday(editingCell: TodayTaskCell){
        let selectedTask = (editingCell.taskObj)!
        
        //log firebase analytics event
        Analytics.logEvent("remove_task_from_today", parameters: [
            "name": selectedTask.title as NSObject,
            "full_text": "" as NSObject
            ])
        
        try! self.realm.write {
            selectedTask.isToday = false
        }
    }
    
    func incrementTaskPoint(editingCell: TodayTaskCell){
         let selectedTask = (editingCell.taskObj)!
         let currentPoints = selectedTask.points
         try! self.realm.write {
             selectedTask.points = currentPoints + 1
        }
    }
    
    func taskDoneForToday(editingCell: TodayTaskCell) {
        let hapticBool = self.defaults.value(forKey: "hapticFeedback") as! Bool
        if hapticBool == true {
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
        
        let selectedTask = (editingCell.taskObj)!
        
        Analytics.logEvent("task_done_for_today", parameters: [
            "name": selectedTask.title as NSObject,
            "full_text": "" as NSObject
            ])
        
        try! self.realm.write {
            selectedTask.isToday = false
        }        
    }

    func cellDidBeginEditing(editingCell: TodayTaskCell) {
        
        if editingCell.taskObj?.isCompleted == true || editingCell.swipeOffset > 0 {
            return
        }
    
        editingCell.isBeingEdited = true
        
        self.currentlySelectedCell = editingCell
        
        //makes due date button visible
        editingCell.dueDateBtn.isHidden = false
        
        editingCell.taskTitleLabel.isEnabled = true
        if editingCell.pickerSelected == false {
            //triggers keyboard if picker is not the first responder
            editingCell.taskTitleLabel.becomeFirstResponder()
        } else {
            Floaty.global.button.isHidden = true
        }
        
        let editingOffset = self.tableView.contentOffset.y - editingCell.frame.origin.y as CGFloat
        let visibleCells = self.tableView.visibleCells as! [TodayTaskCell]
        for cell in visibleCells {
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                cell.transform = CGAffineTransform(translationX: 0, y: editingOffset)
                if cell != editingCell {
                    cell.alpha = 0.3
                }
            })
        }
    }
    
    func cellDidEndEditing(editingCell: TodayTaskCell) {
        editingCell.isBeingEdited = false
        
        if self.currentlySelectedCell == editingCell{
            self.currentlySelectedCell = nil
        }
        
        //hides due date btn
        if editingCell.dueDate == nil {
            editingCell.dueDateBtn.isHidden = true
        }
        
       //show Floaty again
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
        
        let visibleCells = tableView.visibleCells as! [TodayTaskCell]
        for cell: TodayTaskCell in visibleCells {
            UIView.animate(withDuration: 0.2, animations: { () -> Void in
                cell.transform = CGAffineTransform.identity
                if cell != editingCell {
                    cell.alpha = 1.0
                }
            }, completion: { (Finished: Bool) -> Void in
            })
        }
    }
}

extension TodayVC: MGSwipeTableCellDelegate {
    
    func swipeTableCellWillBeginSwiping(_ cell: MGSwipeTableCell) {
        let uwCell = cell as! TodayTaskCell
        if uwCell.isBeingEdited == true {
            uwCell.endEditing(false)
        }
    }
    
    func swipeTableCell(_ cell: MGSwipeTableCell, tappedButtonAt index: Int, direction: MGSwipeDirection, fromExpansion: Bool) -> Bool {
        
        let modifiedCell = cell as! TodayTaskCell
        if modifiedCell.isBeingEdited == true {
            modifiedCell.taskTitleLabel.resignFirstResponder()
        }
        
        if direction == .rightToLeft {
            if index == 0 {
                //if user swipes to delete cell
                if modifiedCell.taskObj?.title != "" || (modifiedCell.isBeingEdited == false && modifiedCell.taskObj?.title == "") {
                    self.deleteTask(editingCell: modifiedCell)
                }
            } else if index == 1 {
                //if user swipes to remove cell from today
                self.removeTaskfromToday(editingCell: modifiedCell)
            }
            
        } else {
            if index == 0 {
                //if user swipes to mark cell as done for today
                self.incrementTaskPoint(editingCell: modifiedCell)
                self.taskDoneForToday(editingCell: modifiedCell)
            }
        }        
        return true
    }
}

extension TodayVC: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return  UIImage(named: "sunbed" )
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "Hallelujah!"
        let attrs = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let str = "You have no tasks left for today."
        let attrs = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return -((self.navigationController?.navigationBar.frame.size.height)!/2.0)
    }
}



