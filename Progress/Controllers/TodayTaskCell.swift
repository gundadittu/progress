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
import Floaty
import DatePickerDialog

protocol CustomTodayTaskCellDelegate {
    // Indicates that the edit process has begun for the given cell
    func cellDidBeginEditing(editingCell: TodayTaskCell)
    // Indicates that the edit process has committed for the given cell
    func cellDidEndEditing(editingCell: TodayTaskCell)
    // Indicates that the check box for the cell was clicked
    func cellCheckBoxTapped(editingCell: TodayTaskCell, checked: Bool)
    //Indicates that the due date for the cell was changed
    func cellDueDateChanged(editingCell: TodayTaskCell, date: Date?)
    
    //Indicates that user tried adding a deadline to empty cell
    func userTriedAddingDateToEmptyTask()
    
    
    //Indicates user selected date picker
    func cellPickerSelected(editingCell: TodayTaskCell)
    
    //Indicates user is done with date picker
    func cellPickerDone(editingCell: TodayTaskCell)
}


class TodayTaskCell:  MGSwipeTableCell {
    
    @IBOutlet weak var dueDateBtn: UIButton!
    @IBOutlet weak var taskTitleLabel: UITextField!
    @IBOutlet weak var progressBar: DottedProgressBar!
    @IBOutlet weak var checkBox: BEMCheckBox!
    
    var dueDate: Date?
    var customDelegate: CustomTodayTaskCellDelegate?
   // var pickerSelected: Bool = false
    //var isBeingEdited: Bool = false
    var taskObj: SavedTask?
  //  var objectDeleted = false
 
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

extension TodayTaskCell {
    
    //calls custom delegate function to trigger action in TodayVC
    @IBAction func dueDateBtnSelected(_ sender: UIButton) {        
        
        let newText = self.taskTitleLabel.text
        let trimmedText = newText?.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedText?.isEmpty == true {
            self.customDelegate?.userTriedAddingDateToEmptyTask()
            return
        }
        
        let picker = DatePickerDialog(buttonColor: mainAppColor, font: UIFont(name: "HelveticaNeue-Bold", size: CGFloat(50))!)
        
        var defaultDate = Date()
        if self.dueDate != nil {
            defaultDate = self.dueDate!
        }
        
        self.customDelegate?.cellPickerSelected(editingCell: self)
        picker.show( "Set Deadline", doneButtonTitle: "Done", cancelButtonTitle: "Remove",defaultDate: defaultDate, datePickerMode: .dateAndTime) {
            (date) -> Void in
            if date != nil {
                self.customDelegate?.cellDueDateChanged(editingCell: self, date: date)
            } else {
                self.customDelegate?.cellDueDateChanged(editingCell: self, date: nil)
            }
            self.customDelegate?.cellPickerDone(editingCell: self)
        }
    }
}
