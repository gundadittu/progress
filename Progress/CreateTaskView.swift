//
//  createTask.swift
//  Progress
//
//  Created by Aditya Gunda on 12/10/17.
//  Copyright © 2017 Aditya Gunda. All rights reserved.
//

import UIKit
import BEMCheckBox
import PureLayout
import ChameleonFramework

class createTaskView: UIView {
    var shouldSetupConstraints = true
    var checkBox: BEMCheckBox!
    var textField: UITextField!

    override init(frame: CGRect) {
        super.init(frame: frame)
        checkBox = BEMCheckBox() 
        checkBox.autoSetDimension(.height, toSize: CGFloat(20))
        checkBox.autoSetDimension(.width, toSize: CGFloat(20))
        checkBox.offAnimationType = .fill
        checkBox.onTintColor = FlatPurple()
        checkBox.onFillColor = FlatPurple()
        checkBox.onCheckColor = UIColor.white
        textField = UITextField()
        textField.placeholder = "Create New Task"
        textField.borderStyle = .none
        textField.autoSetDimension(.height, toSize: 30)
        textField.autoSetDimension(.width, toSize: 100)
        self.addSubview(textField)
        self.addSubview(checkBox)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func updateConstraints() {
        if(shouldSetupConstraints) {
            checkBox.autoPinEdge(toSuperviewEdge: .left, withInset: 15)
            checkBox.autoPinEdge(toSuperviewEdge: .bottom, withInset: 10)
            //textField.autoPinEdge(toSuperviewEdge: .right, withInset: 15)
            //textField.autoPinEdge(.left, to: .right, of: checkBox, withOffset: 10)
            textField.autoPinEdge(.left, to: .right, of: checkBox)
            shouldSetupConstraints = false
        }
         super.updateConstraints()
    }
    
}
