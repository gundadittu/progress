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
    
    var indexForCell : IndexPath!
    var dueDate: Date?
    var customDelegate: CustomTodayTaskCellDelegate?
    var pickerSelected: Bool = false
    var didBeginEditing: Bool = false
    
 
    override func awakeFromNib() {
        super.awakeFromNib()
        taskTitleLabel.borderStyle = .none
        self.taskTitleLabel.delegate = self
        self.checkBox.delegate = self
        self.dueDateBtn.isHidden = true
    }
    
    //for progress bar
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

extension TodayTaskCell: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if self.customDelegate != nil {
            self.customDelegate!.cellDidBeginEditing(editingCell: self)
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.taskTitleLabel.text = textField.text!
        if self.customDelegate != nil && pickerSelected == false {
            self.customDelegate?.cellDidEndEditing(editingCell: self)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }

}

extension TodayTaskCell: BEMCheckBoxDelegate {
    
    func didTap(_ checkBox: BEMCheckBox) {
        if self.customDelegate != nil {
            if checkBox.on == true {
                self.customDelegate?.cellCheckBoxTapped(editingCell: self, checked: true)
            } else {
                self.customDelegate?.cellCheckBoxTapped(editingCell: self, checked: false)
            }
        }
    }
    
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
    
    @IBAction func dueDateBtnSelected(_ sender: UIButton) {
        pickerSelected = true
        if self.didBeginEditing == true {
            self.taskTitleLabel.resignFirstResponder()
        } else {
            self.customDelegate?.cellDidBeginEditing(editingCell: self)
        }
        
        var max: Date
        var selected: Date
        if let unwrappedDueDate = dueDate  {
            max = unwrappedDueDate.addingTimeInterval(60 * 60 * 24 * 100)
            selected = unwrappedDueDate
        } else {
            selected = Date()
            max = Date().addingTimeInterval(60 * 60 * 24 * 100)
        }
        
        let picker = DateTimePicker.show(selected: selected, maximumDate: max)
        picker.highlightColor = FlatPurple()
        picker.isDatePickerOnly = true
        picker.is12HourFormat = true
        picker.selectedDate = selected
        picker.doneBackgroundColor = FlatPurple()
        picker.includeMonth = true
        picker.cancelButtonTitle = "Clear"
        picker.doneButtonTitle = "Set Due Date"
        picker.delegate = self
        picker.completionHandler = { date in
            self.customDelegate?.cellDueDateChanged(editingCell: self, date: date)
            self.customDelegate?.cellDidEndEditing(editingCell: self)
            self.pickerSelected = false
        }
        picker.cancelHandler = {
            self.customDelegate?.cellDueDateChanged(editingCell: self, date: nil)
            self.customDelegate?.cellDidEndEditing(editingCell: self)
            self.pickerSelected = false
        }
        picker.dismissHandler = {
            self.customDelegate?.cellDidEndEditing(editingCell: self)
            self.pickerSelected = false
        }
    }
    
    func dateTimePicker(_ picker: DateTimePicker, didSelectDate: Date) {
        return
    }
}
