
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
    
    let color = mainAppColor
    let bgColor = UIColor.white
    var currentlySelectedCell: TaskCell? = nil
    
    let realm = try! Realm()
    var tasksList: Results<SavedTask>?
    var token: NotificationToken?
    let defaults = UserDefaults.standard

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
        
        //empty state data
        self.tableView.emptyDataSetSource = self
        self.tableView.emptyDataSetDelegate = self
        
        //Table Cell Reordering
        self.tableView.reorder.delegate = self
        self.tableView.reorder.cellScale = 1.05
        self.tableView.reorder.shadowOpacity = 0.3
        self.tableView.reorder.shadowRadius = 20
        
        //Fetch data from database
        self.fetchObjects()
        
        //Responds to changes in realm to rearrange tableview
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
                Crashlytics.sharedInstance().recordError(error) //log crashlytics error
                break
            }
        }
    }
    
    //fetches objects from realm
    func fetchObjects(){
        let isNotTodayPredicate = NSPredicate(format: "isToday == %@",  Bool(booleanLiteral: false) as CVarArg)
        let list = self.realm.objects(SavedTask.self).filter(isNotTodayPredicate)
        let sortProperties = [SortDescriptor(keyPath: "isNewTask", ascending: false), SortDescriptor(keyPath: "isCompleted", ascending: true), SortDescriptor(keyPath: "displayOrder", ascending: true)]
        self.tasksList = list.sorted(by: sortProperties)
        self.updateArrayDisplayOrder(self.tasksList!)
    }
    
    //assigns display order attribute to objects. Note: displayOrder attribute help save user defined order of tasks
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
        
        //Pull drawer up if task is being created
        if let drawerVC = self.navigationController?.parent as? PulleyViewController {
            drawerVC.setDrawerPosition(position: .open, animated: true)
        }
        
        let newTask = SavedTask()
        newTask.isNewTask = true
        newTask.displayOrder = 0
        try! self.realm.write {
            self.realm.add(newTask)
        }
        
        //if top of tableview is visible on screen, no need to execute code below that scrolls up
        let visibleCells = self.tableView.indexPathsForVisibleRows
        if visibleCells?.contains(IndexPath(row: 0, section: 0)) == true {
            return
        }
        
        //scrolls to top of tableview
        self.tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0) //inset so that the programattic scroll below doesn't hide the new task cell
        let delayTime = DispatchTime.now() + .seconds(1) //delay needed due to some bug
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true) //scrolls up to new task if top of table view is not visible when new task is created
        }
    }
}

extension TasksVC: UITableViewDelegate, UITableViewDataSource, TableViewReorderDelegate {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //spacer for reordering cells
        if let spacer = tableView.reorder.spacerCell(for: indexPath) {
            return spacer
        }
        
        let selectedTask = tasksList![indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as! TaskCell
        self.configure(cell: cell, with: selectedTask)
        
        //if it is new task created, automatically focuses on task to get user input on task title, etc.
        if selectedTask.isNewTask == true {
            cell.customDelegate?.cellDidBeginEditing(editingCell: cell)
        }
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
    
    //Handles user clicking on cell - triggers editing
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = self.tableView.cellForRow(at: indexPath) as! TaskCell
        //Ensures only one cell is being edited at a time
        if self.currentlySelectedCell != nil && self.currentlySelectedCell != cell {
            self.currentlySelectedCell?.customDelegate?.cellDidEndEditing(editingCell: cell)
        }
        if self.currentlySelectedCell == cell {
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
    
    //Ned these two to avoid some warnings
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        return
    }
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}

extension TasksVC: CustomTaskCellDelegate {
    
    //configures dequeued tableview cell
    func configure(cell: TaskCell, with savedTask: SavedTask) {
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
        //let dotColorsArr = [FlatPurple(),FlatBlue(),FlatGreen(),FlatYellow(),FlatOrange(),FlatRed()]
        //let colorIndex = ((width/indWidth)/(frameWidth/indWidth))%6
        let dotColor = color //dotColorsArr[colorIndex]
        
        //cell attributes
        cell.taskObj = cellTask
        cell.selectionStyle = .none //no highlighting of cell when clicked on
        cell.delegate = self //for MGSwiping
        cell.customDelegate = self //for custom functions to notify this VC of cell actions - protocol CustomTaskCellDelegate
        cell.contentView.backgroundColor = bgColor
        cell.taskTitleLabel.isEnabled = false //so that user clicking on textfield is not confused with clicking on cell
        cell.taskTitleLabel.text = title
        
        //due date btn
        cell.dueDateBtn.setTitleColor(UIColor.white, for: .selected)
        cell.dueDateBtn.tintColor = mainAppColor
        
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
            //if there is not deadline
            cell.dueDateBtn.setTitle("Add Deadline", for: .normal)
            cell.dueDateBtn.setTitleColor(FlatGray(), for: .normal)
            cell.dueDate = nil
            cell.dueDateBtn.isHidden = true
        }
        
        if checked == true {
            cell.dueDateBtn.isEnabled = false //prevents user from messing with deadling of completed tasks 
        } else {
            cell.dueDateBtn.isEnabled = true
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
        let leftButton1 = MGSwipeButton(title: "Add to Your Day", backgroundColor: FlatGreen())
        cell.leftButtons = [leftButton1]
        cell.leftSwipeSettings.transition = .drag
        cell.leftExpansion.buttonIndex = 0
        cell.leftExpansion.fillOnTrigger = true
        cell.leftExpansion.threshold = 2
        let rightButton1 = MGSwipeButton(title: "Delete", backgroundColor: FlatRed())
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
        
        //play vibration if user allows
        let hapticBool = self.defaults.value(forKey: "hapticFeedback") as! Bool
        if hapticBool == true {
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
        let selectedTask = editingCell.taskObj!
        
        if checked == true {
            //log firebase analytics event
            Analytics.logEvent(taskCheckedEvent, parameters: [
                "name": selectedTask.title as NSObject,
                "full_text": "" as NSObject
                ])
            
            if selectedTask.deadline != nil {
                NotificationsController.removeNotifications(task: selectedTask)
            }
        } else {
            //log firebase analytics event
            Analytics.logEvent(taskUncheckedEvent, parameters: [
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
        
        if date != nil { //contextual prompt of asking user for permissions to add badges
            NotificationsController.requestPermission()
        }
        
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
            } else {
                selectedTask.deadline = nil
            }
        }
        
        //Schedules notification if there is a new deadline
         NotificationsController.scheduleNotification(task: selectedTask)
    }
    
    //delete task
    func deleteTask(editingCell: TaskCell) {
        let selectedTask = (editingCell.taskObj)!
        
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
    }
    
    //update new task title
    func updateTaskTitle(editingCell: TaskCell, newTitle: String) {
        let selectedTask = (editingCell.taskObj)!
        
        //log firebase analytics event
        Analytics.logEvent(updatedTaskTitleEvent, parameters: [
            "name": selectedTask.title as NSObject,
            "full_text": "" as NSObject
            ])
        
        try! self.realm.write {
            selectedTask.title = newTitle
        }
    }
    
    //add task to today
    func addTasktoToday(editingCell: TaskCell) {
        
        //plays vibration if user allows 
        let hapticBool = self.defaults.value(forKey: "hapticFeedback") as! Bool
        if hapticBool == true {
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
        
        let selectedTask = (editingCell.taskObj)!
        
        //log firebase analytics event
        Analytics.logEvent(addTaskToYourDayEvent, parameters: [
            "name": selectedTask.title as NSObject,
            "full_text": "" as NSObject
            ])
        
        //writes changes to database
        try! self.realm.write {
            selectedTask.isToday = true
            //in case user tries to add completed task to today
            selectedTask.isCompleted = false
        }
    }
    
    func cellDidBeginEditing(editingCell: TaskCell) {
        
        //Makes sure you cannot edit cell if it is completed or mid-swipe
        if editingCell.taskObj?.isCompleted == true || editingCell.swipeOffset > 0 {
            return
        }
        
        //Updates currently being edited information
        editingCell.isBeingEdited = true
        self.currentlySelectedCell = editingCell
        
        //Brings drawer up if it is not already up
        //Makes sure user can not move drawer while editing.
        if let drawerVC = self.navigationController?.parent as? PulleyViewController {
            drawerVC.setDrawerPosition(position: .open, animated: true)
            drawerVC.allowsUserDrawerPositionChange = false
        }
        
        //makes due date button visible so user can choose deadline
        editingCell.dueDateBtn.isHidden = false
        
     
        editingCell.taskTitleLabel.isEnabled = true//to allow user input
        
        if editingCell.pickerSelected == false {
            //triggers keyboard if picker is not the first responder
            editingCell.taskTitleLabel.becomeFirstResponder()
        } else {
            Floaty.global.button.isHidden = true //So that the button does to overlap with datepicker
        }
        
        //animate cells up
        let editingOffset = self.tableView.contentOffset.y - editingCell.frame.origin.y as CGFloat
        let visibleCells = self.tableView.visibleCells as! [TaskCell]
        for cell in visibleCells {
            //animate cells up so that edited cell is at top of tableview
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                cell.transform = CGAffineTransform(translationX: 0, y: editingOffset)
                if cell != editingCell {
                    cell.dueDateBtn.isEnabled = false //so user can not trigger date picker of another cell
                    cell.alpha = 0.1 //gray out any cells that aren't being edited
                }
            })
        }
    }
    
    func cellDidEndEditing(editingCell: TaskCell) {
        
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0) //readjusts insets, because they are changed when new task is created


        //Updates isNewTask attribute
        if editingCell.taskObj?.isNewTask == true {
            try! self.realm.write {
                editingCell.taskObj?.isNewTask = false
            }
            
            //log firebase analytics event for creating new task
            Analytics.logEvent(createTaskEvent, parameters: [ "name": (editingCell.taskObj?.title)! as NSObject, "full_text": "" as NSObject ])
        }
        
        //Allows user to now more drawer again
        if let drawerVC = self.navigationController?.parent as? PulleyViewController {
            drawerVC.allowsUserDrawerPositionChange = true 
        }

        //Updates currently editing info
        //doesnt change isbeingedited if picker is selected because cell is still being edited (case applies when user selects date picker while keyboard is active)
        
        editingCell.isBeingEdited = false

        //self.currentlySelectedCell might be another cell that the user clicked on, which caused this cell to resign and end editing
        if self.currentlySelectedCell == editingCell{
            self.currentlySelectedCell = nil
        }
        
        //hides due date btn if there is no assigned deadline
        if editingCell.dueDate == nil {
            editingCell.dueDateBtn.isHidden = true
        }
        
        Floaty.global.button.isHidden = false //Shows floaty button because it is hidden when date picker is selected
        
        editingCell.dueDateBtn.isSelected = false //means user is not editing deadline
        
        editingCell.taskTitleLabel.isEnabled = false //Disables textfield again, so that selecting cell is not confused with selecting textfield

        
        //save updated task title, delete if new title is empty
        let newText = editingCell.taskTitleLabel.text
        let trimmedText = editingCell.taskTitleLabel.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedText.isEmpty == false {
            self.updateTaskTitle(editingCell: editingCell, newTitle: newText!)
        } else {
            //delete new task if user did not give it title or deletes existing task if user removed its title
            editingCell.objectDeleted = true
            editingCell.pickerSelected = false //important for edge case where user clicks on add deadline when creating new task, but task title is empty 
            self.deleteTask(editingCell: editingCell)
        }
        
        //animates cells back down
        let visibleCells = tableView.visibleCells as! [TaskCell]
        for cell: TaskCell in visibleCells {
            UIView.animate(withDuration: 0.2, animations: { () -> Void in
                cell.transform = CGAffineTransform.identity
                if cell != editingCell {
                    cell.dueDateBtn.isEnabled = true //diabled before so user can not trigger date picker of another cell
                    cell.alpha = 1.0
                }
            }, completion: { (Finished: Bool) -> Void in return })
        }
    }
}

extension TasksVC: MGSwipeTableCellDelegate {
    
    //Prevents swiping if a cell is being edited
    func swipeTableCell(_ cell: MGSwipeTableCell, canSwipe direction: MGSwipeDirection, from point: CGPoint) -> Bool {
        if self.currentlySelectedCell != nil {
            return false
        }
        return true
    }
    
    //Handles user swipe inputs 
    func swipeTableCell(_ cell: MGSwipeTableCell, tappedButtonAt index: Int, direction: MGSwipeDirection, fromExpansion: Bool) -> Bool {
        let modifiedCell = cell as! TaskCell
        
        if direction == .rightToLeft {
            if index == 0 {
                //if user swipes to delete cell
                self.deleteTask(editingCell: modifiedCell)
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

//tableview empty state data 
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

