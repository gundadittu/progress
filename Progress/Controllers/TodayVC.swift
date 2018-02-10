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
import AudioToolbox
import Firebase
import Alamofire
import SwiftyJSON
import AlertOnboarding
import CFAlertViewController
import CFNotify
import BPStatusBarAlert

class TodayVC: UIViewController {

    
    @IBOutlet weak var tableView: UITableView!
    
    let color = mainAppColor
    let bgColor = UIColor.white
    var currentlySelectedCell: TodayTaskCell?

    var realm = try! Realm()
    var tasksList: Results<SavedTask>?
    var token: NotificationToken?
    let defaults = UserDefaults.standard
    let sharedDefaults = UserDefaults.init(suiteName: "group.progress.tasks")
    
    override func viewWillAppear(_ animated: Bool) {
        Floaty.global.button.isHidden = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Your Day"
        self.navigationController?.navigationBar.prefersLargeTitles = true
        
        //table View Properties
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.separatorStyle = .none
        self.tableView.sectionHeaderHeight = 0
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0,self.view.frame.height / 6, 0)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboardOnTap))
        self.tableView.backgroundView = UIView()
        self.tableView.backgroundView?.addGestureRecognizer(tap)
        
        //empty state data
        self.tableView.emptyDataSetSource = self
        self.tableView.emptyDataSetDelegate = self
        
        //table Cell Reordering
        self.tableView.reorder.delegate = self
        self.tableView.reorder.cellScale = 1.05
        self.tableView.reorder.shadowOpacity = 0.3
        self.tableView.reorder.shadowRadius = 20
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.showAlertToSwipeRight), name: Notification.Name("triggerTodayVCSwipeAlert"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.flashSelectedCell), name: Notification.Name("todayWidgetSelectedTask"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateObjects), name: Notification.Name("syncData"), object: nil)

        //Fetch data from database
        self.tasksList = self.fetchObjects()
        
        //Responds to changes in realm to rearrange tableview
        token = self.tasksList?.observe {[weak self] (changes: RealmCollectionChange) in
            guard let tableView = self?.tableView else { return }
            
            switch changes {
            case .initial:
                tableView.reloadData()
                break
            case .update(let results, let deletions, let insertions, let modifications):
                
                tableView.beginUpdates()
                
                tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) },
                                     with: .right)
                tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) },
                                     with: .left)

                    for row in modifications {
                        let indexPath = IndexPath(row: row, section: 0)
                        let selectedTask = results[indexPath.row]
                        if let uwcell = tableView.cellForRow(at: indexPath) {
                            let cell = uwcell as! TodayTaskCell
                            self?.configure(cell: cell, with: selectedTask)
                        }
                    }
                tableView.endUpdates()
                break
            case .error(let error):
                Crashlytics.sharedInstance().recordError(error) //log crashlytics error
                break
            }
        }
    }
    
    @objc func updateObjects() {
        self.tasksList = self.fetchObjects()
    }
    
    //fetches objects from database
     func fetchObjects() -> Results<SavedTask> {
        let isTodayPredicate = NSPredicate(format: "isToday == %@",  Bool(booleanLiteral: true) as CVarArg)
        let isNotCompletedPredicate = NSPredicate(format: "isCompleted == %@",  Bool(booleanLiteral: false) as CVarArg)
       
        //only fetches objects with isToday tasks and not completed
        let andPredicate = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: [isTodayPredicate, isNotCompletedPredicate])
        let list = self.realm.objects(SavedTask.self).filter(andPredicate)
        
        //sorts list by todayDisplayOrder attribute
        return list.sorted(byKeyPath: "todayDisplayOrder", ascending: true)
    }
    
    //used to update display orders after items are deleted + added
    func updateArrayDisplayOrder(_ array: Results<SavedTask>?){
        guard let uwArray = array else {
            return
        }
        var i = 0
        for ro in uwArray {
            try! self.realm.write {
                ro.todayDisplayOrder = i
            }
            i+=1
        }
    }
    

    @objc func dismissKeyboardOnTap() {
        if self.currentlySelectedCell != nil {
            //log firebase analytics event
            Analytics.logEvent("dismiss_keyboard_on_tap", parameters: ["name": "" as NSObject, "full_text": "" as NSObject])
            self.currentlySelectedCell?.taskTitleLabel.resignFirstResponder()
        }
    }
    
    @objc func flashSelectedCell() {
        
        if sharedDefaults?.value(forKey: "todayWidgetSelectedTask") == nil {
            if let drawerVC = self.navigationController?.parent as? PulleyViewController {
                drawerVC.setDrawerPosition(position: .open, animated: true)
            }
            
            //log firebase debug event
            DebugController.write(string: "recieved widget tap URL with nil selection")
            return
        }
        
        if let drawerVC = self.navigationController?.parent as? PulleyViewController {
            drawerVC.setDrawerPosition(position: .partiallyRevealed, animated: true)
        }
        
        if let uwRow = sharedDefaults?.value(forKey: "todayWidgetSelectedTask") {
            let row = uwRow as! Int
            let indexPath = IndexPath(row: row, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
            
            let cell = self.tableView.cellForRow(at: indexPath) as! TodayTaskCell
            
            let delayTime = DispatchTime.now() +  .microseconds(500000)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                cell.contentView.backgroundColor = UIColor.flatPurple.lighten(byPercentage: CGFloat(80))
               UIView.animate(withDuration: 2.0, animations: {
                    cell.contentView.backgroundColor = UIColor.white
                })
                
                //log firebase debug event
                DebugController.write(string: "recieved widget tap URL - flashed selected cell")
            }
        }
    }
    
    
    @IBAction func composeBtnClicked(_ sender: Any) {
        //log firebase analytics event
        Analytics.logEvent("feedback_button_clicked", parameters: ["name": "" as NSObject, "full_text": "" as NSObject])
        self.performSegue(withIdentifier: "toSettings", sender: nil)
        let delayTime = DispatchTime.now() +  .seconds(1)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            NotificationCenter.default.post(name: Notification.Name("triggerMailCompose"), object: nil)
        }
    }
}

extension TodayVC: UITableViewDelegate, UITableViewDataSource, TableViewReorderDelegate {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
        //spacer for reordering cells
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
        Analytics.logEvent("tasks_reordered", parameters: [ "name":"" as NSObject, "full_text": "" as NSObject ])
        
        //adjusts displayOrder attributes for all cells without notifying Realm so that tableview is not updated again (user's actions already updated it)
        self.realm.beginWrite()
        let sourceObject = tasksList![sourceIndexPath.row]
        let destinationObject = tasksList![destinationIndexPath.row]
        
        //log firebase debug event
        DebugController.write(string: "Reordered tasks: moved \(sourceObject.title) to \(destinationObject.title)")
      
        let destinationObjectOrder = destinationObject.todayDisplayOrder
        if sourceIndexPath.row < destinationIndexPath.row {
            for index in (sourceIndexPath.row...destinationIndexPath.row) {
                let object = tasksList![index]
                object.todayDisplayOrder -= 1
            }
        } else {
            for index in (destinationIndexPath.row..<sourceIndexPath.row).reversed() {
                let object = tasksList![index]
                object.todayDisplayOrder += 1
            }
        }
        sourceObject.todayDisplayOrder = destinationObjectOrder
        try! self.realm.commitWrite(withoutNotifying: [self.token!])
    }
    
    //Handles user clicking on cell - triggers editing
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let uwcell = self.tableView.cellForRow(at: indexPath) else  {
            return
        }
        
        let cell = uwcell as! TodayTaskCell
       
        //handles edge case where user selects cell immedately after clicking delete
        if  cell.swipeState != .none {
            return
        }
        
        //log firebase analytics event
        Analytics.logEvent("selected_task", parameters: ["name": "" as NSObject, "full_text": "" as NSObject])
        
        if let title = cell.taskObj?.title {
            //log firebase debug event
            DebugController.write(string: "Selected task - task title: \(title)")
        } else {
            //log firebase debug event
            DebugController.write(string: "Selected task - not title")
        }
        
        //Ensures only one cell is being edited at a time
        if self.currentlySelectedCell != nil && self.currentlySelectedCell != cell {
            self.currentlySelectedCell?.taskTitleLabel.resignFirstResponder()
            return
        }
        
        if self.currentlySelectedCell != nil && self.currentlySelectedCell == cell {
            return
        }
        cell.customDelegate?.cellDidBeginEditing(editingCell: cell)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasksList!.count
    }
    
    //Need these two to silence warnings
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        return
    }
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}

extension TodayVC: CustomTodayTaskCellDelegate {
    
    //configures dequeued tableview cell
    func configure(cell: TodayTaskCell, with savedTask: SavedTask) {
        
        let cellTask = savedTask
        let title = cellTask.title
        let count = cellTask.points
        let date = cellTask.deadline
        let checked = cellTask.isCompleted
        let progressDotRadius = globalProgressDotRadius
        let indWidth = (10+(2*Int(progressDotRadius)))
        let width = indWidth * count
        let frameWidth = Int(cell.progressBar.frame.width)
        var modifiedCount = count
        let dotColor = mainAppColor
        
        //cell attributes
        cell.taskObj = cellTask
        cell.selectionStyle = .none //no highlighting of cell when clicked on
        cell.delegate = self //for MGSwiping
        cell.customDelegate = self //for custom functions to notify this VC of cell actions - protocol CustomTodayTaskCellDelegate
        cell.contentView.backgroundColor = bgColor
        cell.taskTitleLabel.isEnabled = false
        cell.taskTitleLabel.text = title
        
        //due date btn
        if date != nil {
            cell.dueDate = date //cell attribute
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
                    cell.dueDateBtn.setTitleColor(FlatRed(), for: .normal)
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
            //if there is not deadline
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
                dotRadius: globalProgressDotRadius,
                dotsColor: dotColor,
                dotsProgressColor: dotColor,
                backColor: UIColor.clear
            )
            
            //checks if # of dots is greater than what can fit on screen size - displays remainder instead
            if width > frameWidth {
                let remainder = (width/indWidth)%(frameWidth/indWidth)
                modifiedCount = remainder
            }
            cell.progressBar.setNumberOfDots(modifiedCount, animated: false)
        }
        
            //sliding options
            let leftButton1 = MGSwipeButton(title: "Made Progress", backgroundColor: FlatPurple())
            cell.leftButtons = [leftButton1]
            cell.leftSwipeSettings.transition = .drag
            cell.leftExpansion.buttonIndex = 0
            cell.leftExpansion.fillOnTrigger = true
            cell.leftExpansion.threshold = 1
            let rightButton1 = MGSwipeButton(title: "Delete", backgroundColor: FlatRed())
            let rightButton2 = MGSwipeButton(title: "Remove", backgroundColor: UIColor.gray)
    
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
        
        if editingCell.isBeingEdited == true {
            let newText = editingCell.taskTitleLabel.text
            let trimmedText = newText?.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedText?.isEmpty == true {
                editingCell.taskTitleLabel.resignFirstResponder()
                return
            }
            editingCell.taskTitleLabel.resignFirstResponder()
        }
        
        //play vibration if user allows
        if NotificationsController.checkHapticPermissions() == true {
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
        
        let selectedTask = editingCell.taskObj!
        
        //log firebase debug event
        DebugController.write(string: "tapped checkbox for state: \(checked); task title: \(selectedTask.title)")
        
        if NotificationsController.checkInAppNotificationPermissions() == true {
            BPStatusBarAlert(duration: 0.3, delay: 2, position: .statusBar)
                .message(message: "You completed a task.")
                .messageColor(color: .white)
                .bgColor(color: .flatGreen)
                .show()
        }
        
        //log firebase analytics event
        Analytics.logEvent(taskCheckedEvent, parameters: [
            "name": selectedTask.title as NSObject,
            "full_text": "" as NSObject
            ])
        
        //removes scheduled notification if there is a deadline
        if selectedTask.deadline != nil {
            NotificationsController.removeNotifications(task: selectedTask)
        }
        
        //updates database
        try! self.realm.write {
            selectedTask.isCompleted = checked
            selectedTask.isToday = false
        }
        
        self.updateArrayDisplayOrder(self.tasksList)
    }
    
    //update changed deadline
    func cellDueDateChanged(editingCell: TodayTaskCell, date: Date?) {
        
        
        let selectedTask = editingCell.taskObj!
        
        //log firebase analytics event
        Analytics.logEvent(deadlineChangedEvent, parameters: [
            "name": selectedTask.title as NSObject,
            "full_text": "" as NSObject
            ])
        
        //clears scheduled notification identifier
        if selectedTask.notificationIdentifier != "" {
            NotificationsController.removeNotifications(task: selectedTask)
        }
        
        //updates database
        try! self.realm.write {
            if let unwrappedDate = date {
                selectedTask.deadline = unwrappedDate
                
                //log firebase debug event
                DebugController.write(string: "changed deadline for \(selectedTask.title) to \(unwrappedDate)")
            } else {
                selectedTask.deadline = nil
                
                //log firebase debug event
                DebugController.write(string: "changed deadline for \(selectedTask.title) to none")
            }
        }
        
        //Schedules notification if there is a new deadline
        NotificationsController.scheduleNotification(task: selectedTask)
    }

    func userTriedAddingDateToEmptyTask() {
        
        //log firebase analytics event
        Analytics.logEvent("tried_adding_deadline_to_empty_task", parameters: ["name": "" as NSObject, "full_text": "" as NSObject])
        
        //log firebase debug event
        DebugController.write(string: "tried adding deadline to empty task")
        
        BPStatusBarAlert(duration: 0.3, delay: 2, position: .statusBar)
            .message(message: "Give your task a name to add a deadline.")
            .messageColor(color: .white)
            .bgColor(color: .flatRed)
            .show()
    }
    
    //delete task
    func deleteTask(editingCell: TodayTaskCell) {
        
        editingCell.objectDeleted = true 
        let selectedTask = (editingCell.taskObj)!
        
        //log firebase debug event
        DebugController.write(string: "deleted task - task title: \(selectedTask.title)")
        
        //log firebase analytics event
        Analytics.logEvent(taskDeletedEvent, parameters: [
            "name": selectedTask.title as NSObject,
            "full_text": "" as NSObject
            ])
        
        ///Removes scheduled notification since task is being deleted
        if selectedTask.notificationIdentifier != "" {
            NotificationsController.removeNotifications(task: selectedTask)
        }
        
        //update database
        try! self.realm.write {
            self.realm.delete(selectedTask)
        }
        self.updateArrayDisplayOrder(self.tasksList)
    }
    
    //update new task title
    func updateTaskTitle(editingCell: TodayTaskCell, newTitle: String) {
        
        let selectedTask = (editingCell.taskObj)!
        
        //log firebase debug event
        DebugController.write(string: "updated task title to \(newTitle) - prev task title: \(selectedTask.title)")
        
        //log firebase analytics event
        Analytics.logEvent(updatedTaskTitleEvent, parameters: [
            "name": selectedTask.title as NSObject,
            "full_text": "" as NSObject
            ])
        
        //update database
        try! self.realm.write {
            selectedTask.title = newTitle
        }
    }
    
    func removeTaskfromToday(editingCell: TodayTaskCell){
        
        let selectedTask = (editingCell.taskObj)!
        
        //log firebase debug event
        DebugController.write(string: "removed task from today - task title: \(selectedTask.title)")
        
        //place at top of all tasks
        let storyboard: UIStoryboard = UIStoryboard.init(name: "Main",bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "DrawerContentViewController") as! TasksVC
        let list = vc.fetchObjects()
        let index = list.count
        
        //update database
        try! self.realm.write {
            selectedTask.displayOrder = index
            selectedTask.isToday = false
        }
        self.updateArrayDisplayOrder(self.tasksList)
        
        //log firebase analytics event
        Analytics.logEvent(removeTaskFromTodayEvent, parameters: [
            "name": selectedTask.title as NSObject,
            "full_text": "" as NSObject
            ])
        
    }
    
    func incrementTaskPoint(editingCell: TodayTaskCell){
        
         let selectedTask = (editingCell.taskObj)!
         let currentPoints = selectedTask.points
        
        //update database
         try! self.realm.write {
             selectedTask.points = currentPoints + 1
        }
    }
    
    func taskDoneForToday(editingCell: TodayTaskCell) {
        
         CFNotify.hideAll()
        
        //plays vibration if user has allowed it
        if NotificationsController.checkHapticPermissions() == true {
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
        
        let selectedTask = (editingCell.taskObj)!
        
        //log firebase debug event
        DebugController.write(string: "done with task for today - task title: \(selectedTask.title)")
        
        let storyboard: UIStoryboard = UIStoryboard.init(name: "Main",bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "DrawerContentViewController") as! TasksVC
        let list = vc.fetchObjects()
        
        try! self.realm.write {
            //move recently unchecked task to bottom of pending - make selected task displayOrder = 0 + move all other up 1
            /*for task in list {
                if task != selectedTask && task.isCompleted == false {
                    let original = task.displayOrder
                    task.displayOrder = original + 1
                }
            }*/
            
            //selectedTask.displayOrder = 0
            selectedTask.displayOrder = list.count
            selectedTask.isToday = false
        }
        self.updateArrayDisplayOrder(self.tasksList)
        
        if NotificationsController.checkInAppNotificationPermissions() == true &&  defaults.string(forKey: "showAlertAfterFirstSwipeRightInTodayVC") != nil{
    
            BPStatusBarAlert(duration: 0.3, delay: 2, position: .statusBar)
                .message(message: "You made progress on a task.")
                .messageColor(color: .white)
                .bgColor(color: .flatPurple)
                .show()
        }
        
        self.showAlertAfterFirstSwipeRight()
        
        //log firebase analytics event
        Analytics.logEvent(taskDoneForTodayEvent, parameters: [
            "name": selectedTask.title as NSObject,
            "full_text": "" as NSObject
            ])
    }

    func cellDidBeginEditing(editingCell: TodayTaskCell) {
        
        //log firebase debug event
        DebugController.write(string: "cell did begin editing - task title: \(String(describing: editingCell.taskObj?.title))")
        
        ///Stop editing if task is completed or is mid-swipe
        if editingCell.taskObj?.isCompleted == true || editingCell.swipeOffset > 0 {
            return
        }
        
        editingCell.isBeingEdited = true
        
        self.tableView.reorder.isEnabled = false
        self.tableView.isScrollEnabled = false

        //update attributes
        self.currentlySelectedCell = editingCell
        
        editingCell.dueDateBtn.isHidden = false //makes due date button visible so user can select deadline
        
        editingCell.taskTitleLabel.isEnabled = true //Enable textfield again for user inout
        editingCell.taskTitleLabel.becomeFirstResponder() //triggers keyboard if picker is not the first responder
     
        //animate cells up
        let editingOffset = self.tableView.contentOffset.y - editingCell.frame.origin.y as CGFloat
        let visibleCells = self.tableView.visibleCells as! [TodayTaskCell]
        for cell in visibleCells {
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                cell.transform = CGAffineTransform(translationX: 0, y: editingOffset)
                if cell != editingCell {
                    cell.checkBox.isEnabled = false
                    cell.dueDateBtn.isEnabled = false //so user can not trigger date picker of another cell
                    cell.alpha = 0.3
                }
            })
        }
        return
    }
    
    func cellDidEndEditing(editingCell: TodayTaskCell) {
        
        //log firebase debug event
        DebugController.write(string: "cell did end editing - task title: \(String(describing: editingCell.taskObj?.title))")

        editingCell.isBeingEdited = false
        
        self.tableView.reorder.isEnabled = true 
        self.tableView.isScrollEnabled = true 

        //self.currentlySelectedCell might be another cell that the user clicked on, which caused this cell to resign and end editing
        if self.currentlySelectedCell == editingCell{
            self.currentlySelectedCell = nil
        }
        
        //hides due date btn if there is no assigned deadline
        if editingCell.dueDate == nil {
            editingCell.dueDateBtn.isHidden = true
        }
        
        editingCell.taskTitleLabel.isEnabled = false //Disables textfield again, so that selecting cell is not confused with selecting textfield
        
        //save updated task title, delete if new title is empty
        let newText = editingCell.taskTitleLabel.text
        let trimmedText = editingCell.taskTitleLabel.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedText.isEmpty == false {
            self.updateTaskTitle(editingCell: editingCell, newTitle: newText!)
        } else {
            
            BPStatusBarAlert(duration: 0.3, delay: 2, position: .statusBar)
                .message(message: "Your task was deleted because it had no name.")
                .messageColor(color: .white)
                .bgColor(color: .flatRed)
                .show()
            
            //delete new task if user did not give it title or deletes existing task if user removed its title
            self.deleteTask(editingCell: editingCell)
        }
        
        //animates cells back down
        let visibleCells = self.tableView.visibleCells as! [TodayTaskCell]
        for cell: TodayTaskCell in visibleCells {
            UIView.animate(withDuration: 0.2, animations: { () -> Void in
                cell.transform = CGAffineTransform.identity
                if cell != editingCell {
                    cell.checkBox.isEnabled = true
                    cell.dueDateBtn.isEnabled = true //disabled before so user can not trigger date picker of another cell
                    cell.alpha = 1.0
                }
            }, completion: { (Finished: Bool) -> Void in return })
        }
        return
    }
    
    func cellPickerSelected(editingCell: TodayTaskCell) {
        
        //log firebase debug event
        DebugController.write(string: "selected date picker - task title: \(String(describing: editingCell.taskObj?.title))")
        
        //Makes sure you cannot edit cell if it is completed or mid-swipe
        if editingCell.taskObj?.isCompleted == true || editingCell.swipeOffset > 0 {
            return
        }
        
        Analytics.logEvent("selected_date_picker", parameters: ["name": "" as NSObject, "full_text": "" as NSObject])
        
        Floaty.global.button.isHidden = true
        
        //Updates currently being edited information
        self.currentlySelectedCell = editingCell
        
        //Brings drawer up if it is not already up + Makes sure user can not move drawer while editing.
        if let drawerVC = self.navigationController?.parent as? PulleyViewController {
            drawerVC.setDrawerPosition(position: .partiallyRevealed, animated: true)
            drawerVC.allowsUserDrawerPositionChange = false
        }
        
        //makes due date button visible so user can choose deadline
        editingCell.dueDateBtn.isHidden = false

    }
    
    func cellPickerDone(editingCell: TodayTaskCell) {
        
        //log firebase debug event
        DebugController.write(string: "done with date picker - task title: \(String(describing: editingCell.taskObj?.title))")
        
        //Allows user to now more drawer again
        if let drawerVC = self.navigationController?.parent as? PulleyViewController {
            drawerVC.allowsUserDrawerPositionChange = true
        }
        
        //self.currentlySelectedCell might be another cell that the user clicked on, which caused this cell to resign and end editing
        if self.currentlySelectedCell == editingCell{
            self.currentlySelectedCell = nil
        }
        
        Floaty.global.button.isHidden = false
        
        //hides due date btn if there is no assigned deadline
        if editingCell.dueDate == nil {
            editingCell.dueDateBtn.isHidden = true
        }
    }
}

extension TodayVC: MGSwipeTableCellDelegate {
    
    //Prevents all swiping if a cell is being edited
    func swipeTableCell(_ cell: MGSwipeTableCell, canSwipe direction: MGSwipeDirection, from point: CGPoint) -> Bool {
        let editingCell = cell as! TodayTaskCell
        if self.currentlySelectedCell != nil {
            if self.currentlySelectedCell == editingCell {
                Analytics.logEvent("swiped_on_currently_editing_cell", parameters: ["name": "" as NSObject, "full_text": "" as NSObject])

                let newText = editingCell.taskTitleLabel.text
                let trimmedText = newText?.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedText?.isEmpty == true {
                    return false
                } else {
                    editingCell.customDelegate?.cellDidEndEditing(editingCell: editingCell)
                    return true
                }
            } else {
                return false
            }
        }
        return true
    }
    
    //Handles swipe actions
    func swipeTableCell(_ cell: MGSwipeTableCell, tappedButtonAt index: Int, direction: MGSwipeDirection, fromExpansion: Bool) -> Bool {
        
        let modifiedCell = cell as! TodayTaskCell
        if direction == .rightToLeft {
            if index == 0 {
                //user swipes left to delete
                
                //log firebase debug event
                DebugController.write(string: "swiped to delete - task title: \(String(describing: modifiedCell.taskObj?.title))")
                
                self.deleteTask(editingCell: modifiedCell)
                
            } else if index == 1 {
                //if user swipes to remove cell from today
                self.removeTaskfromToday(editingCell: modifiedCell)
                
                //log firebase debug event
                DebugController.write(string: "swiped to remove from today - task title: \(String(describing: modifiedCell.taskObj?.title))")
            }
            
        } else {
            if index == 0 {
                //if user swipes to mark cell as done for today
                self.incrementTaskPoint(editingCell: modifiedCell)
                self.taskDoneForToday(editingCell: modifiedCell)
                
                //log firebase debug event
                DebugController.write(string: "swiped to mark as done for today - task title: \(String(describing: modifiedCell.taskObj?.title))")
            }
        }        
        return true
    }
}

//returns Data for empty state of table view
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
        let returnString = "Looks like you have no tasks to work on or due today."
        let attrs = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
        return NSAttributedString(string: returnString, attributes: attrs)
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return -((self.navigationController?.navigationBar.frame.size.height)!/2.0)
    }
}

extension TodayVC : AlertOnboardingDelegate {
    
    override func viewDidAppear(_ animated: Bool) {
        if self.isAppAlreadyLaunchedOnce() == false {
            Floaty.global.button.isHidden = true
            self.loadOnboarding() //load app introduction walkthrough if first time launching app
        }
    }
    
    func loadOnboarding(){
        //First, declare datas
        let arrayOfImage = ["purpleBox","layers","progress","meditation"]
        let arrayOfTitle = ["Welcome to Progress", "SPLIT UP TASKS", "TRACK YOUR PROGRESS", "STAY FOCUSED"]
        let arrayOfDescription = ["A simple to-do list that encourages you to reach your goals gradually. \n \n Swipe left to learn more",
                                  "Most to-do lists only reward you for finishing a task in one shot. With Progress, you decide how many shots you need.","With bold dots under each task, you can easily track your progress on a task and feel accomplished every step of the way.",
                                  "Progress leaves out all the unnecessary features that usually make to-do list apps intimidating and distracting."]
        //Simply call AlertOnboarding...
        let alertView = AlertOnboarding(arrayOfImage: arrayOfImage, arrayOfTitle: arrayOfTitle, arrayOfDescription: arrayOfDescription)
        
        //Modify background color of AlertOnboarding
        alertView.colorForAlertViewBackground = UIColor.white 
        
        //Modify colors of AlertOnboarding's button
        alertView.colorButtonText = UIColor.white
        alertView.colorButtonBottomBackground = FlatPurple()
        //alertView.colorTitleLabel.
        
        //Modify colors of labels
        alertView.colorTitleLabel = UIColor.black
        alertView.colorDescriptionLabel = UIColor.black
        
        //Modify colors of page indicator
        alertView.colorPageIndicator = FlatWhiteDark()
        alertView.colorCurrentPageIndicator = FlatPurple()
        
        //Modify size of alertview (Percentage of screen height and width)
        alertView.percentageRatioHeight = 0.9
        alertView.percentageRatioWidth = 0.9
        
        //Modify labels
        alertView.titleSkipButton = "SKIP"
        alertView.titleGotItButton = "GET STARTED"
        
        //Set delegate
        alertView.delegate = self
        
        Floaty.global.button.isHidden = true
        //... and show it !
        alertView.show()
    }
    
    func isAppAlreadyLaunchedOnce()->Bool{
        if  defaults.string(forKey: "isAppAlreadyLaunchedBefore") == nil{
            defaults.set(true, forKey: "isAppAlreadyLaunchedBefore")
            return false
        }
        return true
    }
    
    func alertOnboardingSkipped(_ currentStep: Int, maxStep: Int) {
        
        self.introducingYourDayAlert()
        
        //log firebase debug event
        DebugController.write(string: "skipped onboarding")
                
        //log firebase analytics event
        Analytics.logEvent(skippedWalkthroughEvent, parameters: [
            "name":"" as NSObject,
            "full_text": "" as NSObject
            ])
    }
    
    func alertOnboardingCompleted() {
        
        self.introducingYourDayAlert()
        
        //log firebase debug event
        DebugController.write(string: "finished onboarding")
        
        //log firebase analytics event
        Analytics.logEvent(finishedWalkthroughEvent, parameters: [
            "name":"" as NSObject,
            "full_text": "" as NSObject
            ])
    }
    
    func alertOnboardingNext(_ nextStep: Int) {
        return
    }
   
}

extension TodayVC {
    
    func introducingYourDayAlert(){
        let bool = defaults.value(forKey: "alreadyIntroducedYourDay")
        if bool == nil {
            defaults.setValue(true, forKey: "alreadyIntroducedYourDay")
        } else {
            return
        }
        
        Floaty.global.button.isHidden = false
        
        CFNotify.hideAll()
        
        var classicViewConfig = CFNotify.Config()
        classicViewConfig.appearPosition = .center //the view will appear at the top of screen
        classicViewConfig.hideTime = .never //the view will never automatically hide
        
        let classicView = CFNotifyView.toastWith(text:  "Welcome to Your Day.\n \n Here you'll find all the tasks you want to work and that are due today. \n \n Swipe up to check out All Tasks",
        textFont: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline),
        textColor: UIColor.white,
        backgroundColor: UIColor.flatPurple)
        CFNotify.present(config: classicViewConfig, view: classicView)
    }
    
    @objc func showAlertToSwipeRight() {
        if  defaults.string(forKey: "showAlertToSwipeRightinTodayVC") != nil{
            return
        }
        defaults.set(true, forKey: "showAlertToSwipeRightinTodayVC")
        
        var classicViewConfig = CFNotify.Config()
        classicViewConfig.appearPosition = .bottom //the view will appear at the top of screen
        classicViewConfig.hideTime = .never //the view will never automatically hide
        
        let classicView = CFNotifyView.toastWith(text: "Your Day Hint: Swipe right (-->) on a task if you've made progress, or tap the checkbox if you've completed it.",
                                                 textFont: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline),
                                                 textColor: UIColor.white,
                                                 backgroundColor: UIColor.flatPurple)
        CFNotify.present(config: classicViewConfig, view: classicView)
    }
    
    func showAlertAfterFirstSwipeRight() {
        
        if  defaults.string(forKey: "showAlertAfterFirstSwipeRightInTodayVC") != nil{
            return
        }
        defaults.set(true, forKey: "showAlertAfterFirstSwipeRightInTodayVC")
        
        let alertController = CFAlertViewController(title: "You just made progress on a task!",
                                                    message: "Your task just disappeared back into All Tasks. \n",
                                                    textAlignment: .center,
                                                    preferredStyle: .alert,
                                                    didDismissAlertHandler: nil)
        
        let gotoAction = CFAlertAction(title: "Go to All Tasks",
                                       style: .Default,
                                       alignment: .center,
                                       backgroundColor: FlatGreen(),
                                       textColor: nil,
                                       handler: { (action) in
                                        
                                        //log firebase debug event
                                        DebugController.write(string: "selected action for alert after first swipe right in today")
                                        
                                        if let drawerVC = self.navigationController?.parent as? PulleyViewController {
                                            drawerVC.setDrawerPosition(position: .open, animated: true)
                                        }
            
                                        let delayTime = DispatchTime.now() +  .seconds(1)
                                        DispatchQueue.main.asyncAfter(deadline: delayTime) {
                                            self.showDotAlert()
                                        }
        })
        
        alertController.addAction(gotoAction)
        alertController.shouldDismissOnBackgroundTap = false
        self.present(alertController, animated: true) {
            Floaty.global.button.isHidden = true
        }
    }
    
    func showDotAlert() {
        
        CFNotify.hideAll()
        
        var classicViewConfig = CFNotify.Config()
        classicViewConfig.appearPosition = .bottom //the view will appear at the top of screen
        classicViewConfig.hideTime = .never //the view will never automatically hide
        
        let classicView = CFNotifyView.toastWith(text: "What's that dot underneath your task? \n \n Each dot represents a time you've worked on it, allowing you to track your progress.",
                                                 textFont: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline),
                                                 textColor: UIColor.white,
                                                 backgroundColor: UIColor.flatPurple)
        CFNotify.present(config: classicViewConfig, view: classicView)
    }
}

