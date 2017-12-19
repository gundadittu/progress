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
import DateTimePicker
import SwiftDate

protocol CustomTaskCellDelegate {
    // Indicates that the edit process has begun for the given cell
    func cellDidBeginEditing(editingCell: TaskCell)
    // Indicates that the edit process has committed for the given cell
    func cellDidEndEditing(editingCell: TaskCell)
    
    // Indicates that the check box for the cell was clicked
    func cellCheckBoxTapped(editingCell: TaskCell, checked: Bool)
    //Indicates that the due date for the cell was changed
    func cellDueDateChanged(editingCell: TaskCell, date: Date?)
}


class TaskCell:  MGSwipeTableCell {
    @IBOutlet weak var taskTitleLabel: UITextField!
    @IBOutlet weak var progressBar: DottedProgressBar!
    @IBOutlet weak var checkBox: BEMCheckBox!
    @IBOutlet weak var dueDateBtn: UIButton!
    
    var dueDate: Date?
    var customDelegate: CustomTaskCellDelegate?
    var pickerSelected: Bool = false
    var isBeingEdited: Bool = false
    var taskObj: SavedTask?
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
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        return
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.taskTitleLabel.text = textField.text!
        if self.customDelegate != nil {
            self.customDelegate?.cellDidEndEditing(editingCell: self)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}

extension TaskCell: BEMCheckBoxDelegate {
    
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

extension TaskCell: DateTimePickerDelegate {
    
    @IBAction func dueDateBtnSelected(_ sender: UIButton) {
        
        //does not trigger textfield become first responded under cellDidBeginEditing
        self.pickerSelected = true
        
        //Resings textfield so cellDidBeginEditing is triggered - saves task title text
        if self.isBeingEdited == true {
            self.taskTitleLabel.resignFirstResponder()
        }
        
        //if taskk title is empty/ has been, do not want to trigger further action
        if self.objectDeleted == true {
            return 
        }
        
        var max: Date
        var selected: Date
        if self.dueDate != nil {
            max = (self.dueDate?.addingTimeInterval(60 * 60 * 24 * 100))!
            selected = self.dueDate!
        } else {
            max = Date().addingTimeInterval(60 * 60 * 24 * 100)
            selected = Date()
        }
        
        let picker = DateTimePicker.show(selected: selected, maximumDate: max)
        picker.becomeFirstResponder()
        //trigger method - does not make textfield first responded since self.pickerSelected = true
        self.customDelegate?.cellDidBeginEditing(editingCell: self)
        
        picker.highlightColor = FlatPurple()
        picker.isDatePickerOnly = false
        picker.is12HourFormat = true
        picker.selectedDate = selected
        picker.doneBackgroundColor = FlatPurple()
        picker.includeMonth = true
        picker.cancelButtonTitle = "Clear"
        picker.doneButtonTitle = "Set Deadline"
        picker.delegate = self
        picker.completionHandler = { date in
            self.pickerSelected = false
            self.customDelegate?.cellDueDateChanged(editingCell: self, date: date)
            self.customDelegate?.cellDidEndEditing(editingCell: self)
        }
        picker.cancelHandler = {
            self.pickerSelected = false
            self.customDelegate?.cellDueDateChanged(editingCell: self, date: nil)
            self.customDelegate?.cellDidEndEditing(editingCell: self)
        }
        picker.dismissHandler = {
            self.pickerSelected = false
            self.customDelegate?.cellDidEndEditing(editingCell: self)
        }
    }
    
    func dateTimePicker(_ picker: DateTimePicker, didSelectDate: Date) {
        return
    }
}
    
