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
import Floaty

protocol CustomTodayTaskCellDelegate {
    // Indicates that the edit process has begun for the given cell
    func cellDidBeginEditing(editingCell: TodayTaskCell)
    // Indicates that the edit process has committed for the given cell
    func cellDidEndEditing(editingCell: TodayTaskCell)
    // Indicates that the check box for the cell was clicked
    func cellCheckBoxTapped(editingCell: TodayTaskCell, checked: Bool)
    //Indicates that the due date for the cell was changed
    func cellDueDateChanged(editingCell: TodayTaskCell, date: Date?)
}


class TodayTaskCell:  MGSwipeTableCell {
    
    @IBOutlet weak var dueDateBtn: UIButton!
    @IBOutlet weak var taskTitleLabel: UITextField!
    @IBOutlet weak var progressBar: DottedProgressBar!
    @IBOutlet weak var checkBox: BEMCheckBox!
    
    var dueDate: Date?
    var customDelegate: CustomTodayTaskCellDelegate?
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

extension TodayTaskCell: UITextFieldDelegate {
    
    //calls custom delegate function to trigger action in TodayVC
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.taskTitleLabel.text = textField.text!
        if   self.customDelegate != nil {
            self.customDelegate?.cellDidEndEditing(editingCell: self)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }

}

extension TodayTaskCell: BEMCheckBoxDelegate {
    
    //Checkbox tapped - calls custom delegate function to trigger action in TodayVC
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

extension TodayTaskCell: DateTimePickerDelegate {
    
    //calls custom delegate function to trigger action in TodayVC
    @IBAction func dueDateBtnSelected(_ sender: UIButton) {
        //does not trigger textfield become first responded under cellDidBeginEditing
        
        //Resings textfield so cellDidBeginEditing is triggered - saves task title text
        if self.isBeingEdited == true {
            self.taskTitleLabel.resignFirstResponder()
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
        
        let delayTime = DispatchTime.now() +  .microseconds(10000)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            self.pickerSelected = true
            
            //Resings textfield so cellDidBeginEditing is triggered - saves task title text
            if self.objectDeleted == true {
                return
            }
            
            self.dueDateBtn.isSelected = true //means user is editing deadline
            
            let picker = DateTimePicker.show(selected: selected, maximumDate: max)
            picker.becomeFirstResponder() //trigger method - does not make textfield first responded since self.pickerSelected = true
            
            self.customDelegate?.cellDidBeginEditing(editingCell: self)
            
            picker.highlightColor = mainAppColor
            picker.isDatePickerOnly = false
            picker.is12HourFormat = true
            picker.selectedDate = selected
            picker.doneBackgroundColor = mainAppColor
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
    }
    
    func dateTimePicker(_ picker: DateTimePicker, didSelectDate: Date) {
        return
    }
}
