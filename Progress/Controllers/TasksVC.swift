
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
import CoreData

class TasksVC: UIViewController, FloatyDelegate  {
    
    
    @IBOutlet weak var tableView: UITableView!
    
    let color = FlatPurple()
    let bgColor = UIColor.white
    var currentlySelectedCell: TaskCell? = nil
    var changeIsUserDriven = false
    let managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var tasksArray = [SavedTask]()
    
    
    fileprivate lazy var fetchedResultsController: NSFetchedResultsController<SavedTask> = {
        let fetchRequest: NSFetchRequest<SavedTask> = SavedTask.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "isCompleted", ascending: true), NSSortDescriptor(key: "displayOrder", ascending: true)]
        //let isNotTodayPredicate = NSPredicate(format: "isToday == %@",  Bool(booleanLiteral: false) as CVarArg)
       // fetchRequest.predicate = isNotTodayPredicate
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "isCompleted", cacheName: "allCache")
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "All Tasks"
        
        self.fetchObjects()
        
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
        
        //Helps save context when application quits
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: Notification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    //Saves context when application quits
    @objc func applicationDidEnterBackground() {
        do {
            try self.managedObjectContext.save()
        } catch {
            print("Unable to save changes: \(error.localizedDescription).")
        }
      NSFetchedResultsController<SavedTask>.deleteCache(withName: "allCache")
    }
    
    func saveContext(_ selectedObject: NSManagedObject) {
        do {
            try selectedObject.managedObjectContext?.save()
            //fetchObjects()
        } catch {
            print("Unable to save changes: \(error.localizedDescription).")
        }
    }
    
    func saveContext() {
        do {
            try self.managedObjectContext.save()
        } catch {
            print("Unable to save changes: \(error.localizedDescription).")
        }
    }
    
    func fetchObjects() {
        do {
           try self.fetchedResultsController.performFetch()
            self.tasksArray = self.fetchedResultsController.fetchedObjects as! [SavedTask]
            self.updateTasksArrayOrder()
        } catch {
            let fetchError = error as NSError
            print("Unable to Perform FetchRequest: \(fetchError.localizedDescription)")
        }
    }
    
    //Plus button tapped to create new task
    func emptyFloatySelected(_ floaty: Floaty) {
        if currentlySelectedCell == nil {
            if let drawerVC = self.navigationController?.parent as? PulleyViewController {
                drawerVC.setDrawerPosition(position: .open, animated: true)
            }

            let altMessage = UIAlertController(title: "Create a New Task", message: nil, preferredStyle: UIAlertControllerStyle.alert)
            altMessage.addAction(UIAlertAction(title: "Create", style: UIAlertActionStyle.default, handler: { (action) in
                let textField = altMessage.textFields![0]
                let newTaskTitle = textField.text
                if newTaskTitle == "" {
                    return
                } else {
                    let entity = NSEntityDescription.entity(forEntityName: "SavedTask", in: self.managedObjectContext)
                    let newTask = NSManagedObject(entity: entity!, insertInto: self.managedObjectContext) as! SavedTask
                    newTask.setValue(newTaskTitle, forKey: "title")
                    newTask.setValue(0, forKey: "points")
                    newTask.setValue(false, forKey: "isCompleted")
                    newTask.setValue(false, forKey: "isToday")
                    //newTask.setValue(0, forKey: "displayOrder")
                    self.tasksArray.insert(newTask, at: 0)
                    self.updateTasksArrayOrder()
                    newTask.managedObjectContext?.insert(newTask)
                    //self.saveContext()
                    //self.fetchObjects()
                }
                
            }))
            altMessage.addTextField(configurationHandler: { (field) in return })
            self.present(altMessage, animated: true, completion: nil)
            
            //need to make textfield of this new task the first responder by calling did begin editing
        }
    }
    
    func updateTasksArrayOrder(){
        var i = 0
        for mo in tasksArray {
            i+=1
            mo.setValue(i, forKey: "displayOrder")
        }
    }
}

extension TasksVC: UITableViewDelegate, UITableViewDataSource, TableViewReorderDelegate {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let spacer = tableView.reorder.spacerCell(for: indexPath) {
            return spacer
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as! TaskCell
        self.configure(cell, at: indexPath)
        return cell
    }
    
    //when user reorders table cells
    func tableView(_ tableView: UITableView, reorderRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        self.changeIsUserDriven = true
        let movedObj = tasksArray.remove(at: sourceIndexPath.row)
        tasksArray.insert(movedObj, at: destinationIndexPath.row)
        self.updateTasksArrayOrder()
        self.saveContext()
       // self.fetchObjects()
        self.changeIsUserDriven = false
    }
    
    //when user taps on cell to edit it
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = self.tableView.cellForRow(at: indexPath) as! TaskCell
        if self.currentlySelectedCell != nil {
            self.currentlySelectedCell?.customDelegate?.cellDidEndEditing(editingCell: cell)
        }
        cell.customDelegate?.cellDidBeginEditing(editingCell: cell)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionInfo = self.fetchedResultsController.sections?[section] else { fatalError("Unexpected Section")}
        return sectionInfo.numberOfObjects
    }
    
     func numberOfSections(in tableView: UITableView) -> Int {
         guard let sections = self.fetchedResultsController.sections else { return 0 }
         return sections.count
     }

     func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionInfo = self.fetchedResultsController.sections?[section] else { fatalError("Unexpected Section")}
        return sectionInfo.name
       // return ""
     }
}

extension TasksVC: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch(type) {
        case NSFetchedResultsChangeType.insert:
            if let uwIndexPath = newIndexPath {
                self.tableView.insertRows(at: [uwIndexPath], with: UITableViewRowAnimation.fade)
            }
            break
        case NSFetchedResultsChangeType.delete:
            if let uwIndexPath = newIndexPath {
                self.tableView.deleteRows(at: [uwIndexPath], with: .fade)
            }
            break
        case NSFetchedResultsChangeType.update:
            if let unwrappedIndexPath = indexPath, let cell = self.tableView.cellForRow(at: unwrappedIndexPath) as? TaskCell{
                self.configure(cell, at: unwrappedIndexPath)
            }
            break
        case NSFetchedResultsChangeType.move:
            if self.changeIsUserDriven == false {
                if let uwIndexPath = indexPath {
                    self.tableView.deleteRows(at: [uwIndexPath], with: .fade)
                }
                if let uwNewIndexPath = newIndexPath {
                    self.tableView.insertRows(at: [uwNewIndexPath], with: .fade)
                }
            }
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
        self.tableView.reloadData()
    }
}

extension TasksVC: CustomTaskCellDelegate {
    
    func configure(_ cell: TaskCell, at indexPath: IndexPath) {
        //update title, count, date, etc. from core data
        let cellTask = self.tasksArray[indexPath.row]//self.fetchedResultsController.object(at: indexPath)
        let title = cellTask.title
        let count = cellTask.points
        let date = cellTask.deadline
        let checked = cellTask.isCompleted
        let progressDotRadius = CGFloat(3.0)
        
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
            print("\(title!): \(formattedDate)")
            
            
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
            cell.taskTitleLabel.text = title
            cell.progressBar.progressAppearance = DottedProgressBar.DottedProgressAppearance (
                dotRadius: progressDotRadius,
                dotsColor: UIColor.gray.withAlphaComponent(0.5),
                dotsProgressColor: color,
                backColor: UIColor.clear
            )
            cell.progressBar.setNumberOfDots(Int(count), animated: true)
            cell.progressBar.setProgress(Int(count))
        }
        
        //sliding options
        let leftButton1 = MGSwipeButton(title: "Add to Today", backgroundColor: FlatGreen())
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
            cell.alpha = CGFloat(0.3)
        } else {
            cell.checkBox.on = false
            cell.alpha = CGFloat(1.0)
        }
        cell.checkBox.onAnimationType = .fill
        // cell.checkBox.offAnimationType = .fill
        //cell.checkBox.animationDuration = CGFloat(1)
        cell.checkBox.onTintColor = color
        cell.checkBox.onFillColor = color
        cell.checkBox.onCheckColor = UIColor.white
    }
    
    //mark task as completed when checked - core data
    func cellCheckBoxTapped(editingCell: TaskCell, checked: Bool) {
        let selectedTask = editingCell.taskObj!
        //selectedTask.isCompleted = checked
        selectedTask.setValue(checked, forKey: "isCompleted")
        self.saveContext()
        self.fetchObjects()
    }
    
    //update changed deadline - core data
    func cellDueDateChanged(editingCell: TaskCell, date: Date?) {
        let selectedTask = editingCell.taskObj!
        if let unwrappedDate = date {
            //selectedTask.deadline = unwrappedDate
            selectedTask.setValue(unwrappedDate, forKey: "deadline")
        } else {
            //selectedTask.deadline = nil
            selectedTask.setValue(nil, forKey: "deadline")
        }
        self.saveContext(selectedTask)
    }
    
    //delete task - core data
    func deleteTask(editingCell: TaskCell) {
        let selectedTask = editingCell.taskObj!
        selectedTask.managedObjectContext?.delete(selectedTask)
    }
    
    //update new task title
    func updateTaskTitle(editingCell: TaskCell, newTitle: String) {
        let selectedTask = editingCell.taskObj!
        //selectedTask.title = newTitle
        selectedTask.setValue(newTitle, forKey: "title")
        self.saveContext(selectedTask)
    }
    
    //add task to today
    func addTasktoToday(editingCell: TaskCell) {
        let selectedTask = editingCell.taskObj!
        // selectedTask.isToday = true
        selectedTask.setValue(true, forKey: "isToday")
        self.saveContext(selectedTask)
    }
    
    func cellDidBeginEditing(editingCell: TaskCell) {
        
        editingCell.isBeingEdited = true
        
        self.currentlySelectedCell = editingCell
        
        //makes due date button visible
        editingCell.dueDateBtn.isHidden = false
        
        //Hide plus button
        Floaty.global.button.isHidden = true
        
        editingCell.taskTitleLabel.isEnabled = true
        // print(editingCell.pickerSelected)
        if editingCell.pickerSelected == false {
            //triggers keyboard if picker is not the first responder
            editingCell.taskTitleLabel.becomeFirstResponder()
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
        
        editingCell.isBeingEdited = false
        
        if self.currentlySelectedCell == editingCell{
            self.currentlySelectedCell = nil
        }
        
        //hides due date btn
        if editingCell.dueDate == nil {
            editingCell.dueDateBtn.isHidden = true
        }
        
        //Show plus button
        Floaty.global.button.isHidden = false
        
        
        editingCell.taskTitleLabel.isEnabled = false
        editingCell.taskTitleLabel.isEnabled = false
        
        //mark new name in coredata
        let newText = editingCell.taskTitleLabel.text!
        if newText != "" {
            self.updateTaskTitle(editingCell: editingCell, newTitle: newText)
        } else {
            //delete new task if user did not give it title
            //deletes existing task if user removed its title
            self.deleteTask(editingCell: editingCell)
        }
        
        let visibleCells = tableView.visibleCells as! [TaskCell]
        let lastView = visibleCells[visibleCells.count - 1]
        let editingOffset = self.tableView.contentOffset.y - editingCell.frame.origin.y as CGFloat
        for cell: TaskCell in visibleCells {
            UIView.animate(withDuration: 0.2, animations: { () -> Void in
                cell.transform = CGAffineTransform.identity
                if cell != editingCell {
                    cell.alpha = 1.0
                }
            }, completion: { (Finished: Bool) -> Void in
                if cell == lastView {
                    self.tableView.reloadData()
                }
            })
        }
    }
}

extension TasksVC: MGSwipeTableCellDelegate {
    
    func swipeTableCell(_ cell: MGSwipeTableCell, tappedButtonAt index: Int, direction: MGSwipeDirection, fromExpansion: Bool) -> Bool {
        let modifiedCell = cell as! TaskCell
        //let cellIndex = self.tableView.indexPath(for: modifiedCell)!
        //let savedTask = self.fetchedResultsController.object(at: cellIndex)
        
        if direction == .rightToLeft {
            if index == 0 {
                //if user swipes to delete cell
                self.deleteTask(editingCell: modifiedCell)
            }
        } else {
            if index == 0 {
                self.addTasktoToday(editingCell: modifiedCell)
            }
        }
        return true
    }
}

extension TasksVC: PulleyDrawerViewControllerDelegate {
    
    func collapsedDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return CGFloat(200)
    }
    
    func partialRevealDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return CGFloat(500)
    }
    
    func supportedDrawerPositions() -> [PulleyPosition] {
        return PulleyPosition.all
    }
    
    func drawerDisplayModeDidChange(drawer: PulleyViewController) {
        self.saveContext()
        self.fetchObjects()
    }

}

