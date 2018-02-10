//
//  TodayTaskCell.swift
//  Progress
//
//  Created by Aditya Gunda on 12/9/17.
//  Copyright © 2017 Aditya Gunda. All rights reserved.
//

import UIKit
import DottedProgressBar
import ChameleonFramework
import BEMCheckBox
import MGSwipeTableCell
import SwiftDate
import Floaty
import Pulley
import RMDateSelectionViewController

protocol CustomTaskCellDelegate {
    // Indicates that the edit process has begun for the given cell
    func cellDidBeginEditing(editingCell: TaskCell)
    // Indicates that the edit process has committed for the given cell
    func cellDidEndEditing(editingCell: TaskCell)
    
    // Indicates that the check box for the cell was clicked
    func cellCheckBoxTapped(editingCell: TaskCell, checked: Bool)
    //Indicates that the due date for the cell was changed
    func cellDueDateChanged(editingCell: TaskCell, date: Date?)
    
    //Indicates that user tried adding a deadline to empty cell
    func userTriedAddingDateToEmptyTask()
    
    //Indicates user selected date picker
    func cellPickerSelected(editingCell: TaskCell)
    
    //Indicates user is done with date picker
    func cellPickerDone(editingCell: TaskCell)
}


class TaskCell:  MGSwipeTableCell {
    @IBOutlet weak var taskTitleLabel: UITextField!
    @IBOutlet weak var progressBar: DottedProgressBar!
    @IBOutlet weak var checkBox: BEMCheckBox!
    @IBOutlet weak var dueDateBtn: UIButton!
    
    var dueDate: Date?
    var customDelegate: CustomTaskCellDelegate?
    var taskObj: SavedTask?
    var isBeingEdited = false
    var objectDeleted = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        taskTitleLabel.borderStyle = .none
        self.taskTitleLabel.delegate = self
        self.checkBox.delegate = self
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

extension TaskCell: UITextFieldDelegate {
    
    //calls custom delegate function to trigger action in TaskVC
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        //log firebase debug event
        DebugController.write(string: "textfield did end editing - \(self.taskTitleLabel.text!)")
        
        self.taskTitleLabel.text = textField.text!
        if self.customDelegate != nil  {
            self.customDelegate?.cellDidEndEditing(editingCell: self)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        //log firebase debug event
        DebugController.write(string: "textfield should return - \(self.taskTitleLabel.text!)")
        
        textField.resignFirstResponder()
        return false
    }
}

extension TaskCell: BEMCheckBoxDelegate {
    
    //Checkbox tapped - calls custom delegate function to trigger action in TaskVC
    func animationDidStop(for checkBox: BEMCheckBox) {
        if self.customDelegate != nil {
            if checkBox.on == true {
                self.customDelegate?.cellCheckBoxTapped(editingCell: self, checked: true)
            } else {
                self.customDelegate?.cellCheckBoxTapped(editingCell: self, checked: false)
            }
        }
    }
}

extension TaskCell {
    
    @IBAction func dueDateBtnSelected(_ sender: UIButton) {

        let newText = self.taskTitleLabel.text
        let trimmedText = newText?.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedText?.isEmpty == true {
            self.customDelegate?.userTriedAddingDateToEmptyTask()
            return
        }
        
        if self.isBeingEdited == true {
            self.taskTitleLabel.resignFirstResponder()
        }
        
        Floaty.global.button.isHidden = true

        let select: RMAction<UIDatePicker> = RMAction(title: "Done", style: .done)  { (controller) in
            
            //log firebase debug event
            DebugController.write(string: "Selected date in picker - \(self.taskTitleLabel.text!)")
            
            let date = controller.contentView.date
            self.customDelegate?.cellDueDateChanged(editingCell: self, date: date)
            self.customDelegate?.cellPickerDone(editingCell: self)
            Floaty.global.button.isHidden = false
            
            let delayTime = DispatchTime.now() +  .seconds(1)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                NotificationsController.requestPermission()//contextual ask for notification permissions
            }
            
            }!
       
        let clear: RMAction<UIDatePicker> = RMAction(title: "Remove", style: .destructive) { (controller) in
            
            //log firebase debug event
            DebugController.write(string: "removed date in picker - \(self.taskTitleLabel.text!)")
            
            self.customDelegate?.cellDueDateChanged(editingCell: self, date: nil)
            self.customDelegate?.cellPickerDone(editingCell: self)
            Floaty.global.button.isHidden = false 
            }!
        
        let title = (self.taskObj?.title)!
        
        self.customDelegate?.cellPickerSelected(editingCell: self)
        let picker = RMDateSelectionViewController(style: .sheetWhite, title: "Add Deadline", message: title, select: select, andCancel: clear)
        
        if dueDate != nil {
            picker?.datePicker.date = dueDate!
        }
        UIApplication.topViewController()?.present(picker!, animated: true, completion: nil)
    }
}

