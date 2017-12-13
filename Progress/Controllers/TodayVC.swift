//
//  TodayVC.swift
//  Progress
//
//  Created by Aditya Gunda on 12/9/17.
//  Copyright © 2017 Aditya Gunda. All rights reserved.
//

import UIKit
import SwiftReorder
import DottedProgressBar
import ChameleonFramework
import MGSwipeTableCell
import Pulley
import BEMCheckBox
import Floaty

class TodayVC: UIViewController, TableViewReorderDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    var cellSelectedToggle: Bool = false
    var currentlySelectedCell: TodayTaskCell?
    var taskList = [SavedTask]()
    let color = FlatPurple()
    let bgColor = UIColor.white
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.updateTaskList()
        
        self.title = "Today"
        self.navigationController?.navigationBar.prefersLargeTitles = true
        
        //table View Properties
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.separatorStyle = .none
        
        //table Cell Reordering
        self.tableView.reorder.delegate = self
        tableView.reorder.cellScale = 1.05
        tableView.reorder.shadowOpacity = 0.3
        tableView.reorder.shadowRadius = 20
    }
    
    func updateTaskList() {
        taskList = CoreDataHandler.fetchToday()!
        self.tableView.reloadData()
    }
    
}

extension TodayVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let spacer = tableView.reorder.spacerCell(for: indexPath) {
            return spacer
        }
        
        //update title, count, date, etc.  from core data
        let title = taskList[indexPath.row].title
        let count = taskList[indexPath.row].points
        let date = taskList[indexPath.row].deadline
        let progressDotRadius = CGFloat(3.0)
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as! TodayTaskCell
        
        //cell attributes
        cell.selectionStyle = .none
        cell.indexForCell = indexPath
        cell.delegate = self
        cell.customDelegate = self 
        cell.contentView.backgroundColor = bgColor
        //add cell date into button field - need to format it correctly into a string beforehand - handle nil date (set it to "Due Date")

        //cell progress bar attributes
        cell.progressBar.backgroundColor = bgColor
        cell.contentView.backgroundColor = bgColor
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
        
        //sliding options
        let leftButton1 = MGSwipeButton(title: "Done for Today", backgroundColor: FlatGreen())
        cell.leftButtons = [leftButton1]
        cell.leftSwipeSettings.transition = .drag
        cell.leftExpansion.buttonIndex = 0
        cell.leftExpansion.fillOnTrigger = true
        cell.leftExpansion.threshold = 2
        let rightButton1 = MGSwipeButton(title: "Delete", backgroundColor: FlatRed())
        let rightButton2 = MGSwipeButton(title: "Remove from Today",backgroundColor: FlatWhiteDark())
        cell.rightButtons = [ rightButton1, rightButton2]
        cell.rightSwipeSettings.transition = .drag
        cell.rightExpansion.buttonIndex = 0
        cell.rightExpansion.fillOnTrigger = true
        cell.rightExpansion.threshold = 1
        
        //cell checkbox attributes
        cell.checkBox.offAnimationType = .fill
        cell.checkBox.onAnimationType = .fill
        cell.checkBox.animationDuration = CGFloat(1)
        cell.checkBox.onTintColor = color
        cell.checkBox.onFillColor = color
        cell.checkBox.onCheckColor = UIColor.white
        
        return cell
    }
    
     func tableView(_ tableView: UITableView, reorderRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let temp = taskList[sourceIndexPath.row]
        taskList.remove(at: sourceIndexPath.row)
        taskList.insert(temp, at: destinationIndexPath.row)
        self.tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = self.tableView.cellForRow(at: indexPath) as! TodayTaskCell
        if cellSelectedToggle == false {
            cell.customDelegate?.cellDidBeginEditing(editingCell: cell)
            cellSelectedToggle = true
            currentlySelectedCell = cell
        } else{
            currentlySelectedCell?.customDelegate?.cellDidEndEditing(editingCell: cell)
            cellSelectedToggle = false
            currentlySelectedCell = nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taskList.count
    }
}

extension TodayVC: CustomTodayTaskCellDelegate {
    
    //mark task as completed when checked - core data
    func cellCheckBoxTapped(editingCell: TodayTaskCell, checked: Bool) {
        let index = editingCell.indexForCell.row
        let savedTask = taskList[index]
        let update = CoreDataHandler.updateIsCompleted(savedTask: savedTask, newValue: true)
        self.updateTaskList()
    }
    
    //update changed deadline - core data
    func cellDueDateChanged(editingCell: TodayTaskCell, date: Date?) {
        let index = editingCell.indexForCell.row
        let savedTask = taskList[index]
        let update = CoreDataHandler.updateDate(savedTask: savedTask, newValue: date!)
        self.updateTaskList()
    }
    
    //delete task - core data
    func deleteTask(_ savedTask: SavedTask) {
        let update = CoreDataHandler.delete(savedTask)
        self.updateTaskList()
    }
    
    //update new task title
    func updateTaskTitle(savedTask: SavedTask, newTitle: String) {
        let update = CoreDataHandler.updateTitle(savedTask: savedTask, newValue: newTitle)
        self.updateTaskList()
    }
    
    func removeTaskfromToday(_ savedTask: SavedTask){
        let update = CoreDataHandler.updateIsToday(savedTask: savedTask, newValue: false)
        self.updateTaskList()
    }
    
    func taskDoneForToday(_ savedTask: SavedTask) {
        let oldPoints = savedTask.points
        let newPoints = Int(oldPoints + 1)
        let update1 = CoreDataHandler.updatePoints(savedTask: savedTask, newValue: newPoints)
        let update2 = CoreDataHandler.updateIsToday(savedTask: savedTask, newValue: false)
        self.updateTaskList()
    }

    func cellDidBeginEditing(editingCell: TodayTaskCell) {
        //makes due date button visible
        editingCell.dueDateBtn.isHidden = false
        
        //marks bool as true
        editingCell.didBeginEditing = true
        
        //Hide plus button
        Floaty.global.button.isHidden = true
        
        if editingCell.pickerSelected == false {
            //triggers keyboard if picker is not the first responder
            editingCell.taskTitleLabel.becomeFirstResponder()
        }
        
        let editingOffset = tableView.contentOffset.y - editingCell.frame.origin.y as CGFloat
        let visibleCells = tableView.visibleCells as! [TodayTaskCell]
        for cell in visibleCells {
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                cell.transform = CGAffineTransform(translationX: 0, y: editingOffset)
                if cell != editingCell {
                    cell.alpha = 0.1
                }
            })
        }
    }
    
    func cellDidEndEditing(editingCell: TodayTaskCell) {
        //hides due date btn
        editingCell.dueDateBtn.isHidden = true
        
        //resigns keyboard
        editingCell.taskTitleLabel.resignFirstResponder()
        
        //marks bool as false
        editingCell.didBeginEditing = false
        
        //Show plus button
        Floaty.global.button.isHidden = false 

        //mark new name in coredata
        let newText = editingCell.taskTitleLabel.text!
        let updatedTask = taskList[editingCell.indexForCell.row]
        self.updateTaskTitle(savedTask: updatedTask, newTitle: newText)
        
        let visibleCells = tableView.visibleCells as! [TodayTaskCell]
        let lastView = visibleCells[visibleCells.count - 1] as TodayTaskCell
        for cell: TodayTaskCell in visibleCells {
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
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

extension TodayVC: MGSwipeTableCellDelegate {
    
    func swipeTableCell(_ cell: MGSwipeTableCell, tappedButtonAt index: Int, direction: MGSwipeDirection, fromExpansion: Bool) -> Bool {
        let modifiedCell = cell as! TodayTaskCell
        let index = modifiedCell.indexForCell.row
        let savedTask = taskList[index]
        
        if direction == .rightToLeft {
            if index == 0 {
                //if user swipes to delete cell
                self.deleteTask(savedTask)
            } else if index == 1 {
                //if user swipes to remove cell from today
                self.removeTaskfromToday(savedTask)
            }
            
        } else {
            if index == 0 {
                //if user swipes to mark cell as done for today
                self.taskDoneForToday(savedTask)
            }
        }
        self.updateTaskList()
        self.tableView.reloadData()
        return true
    }
}

