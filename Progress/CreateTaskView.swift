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

class createTaskView: UIView {
    var shouldSetupConstraints = true
    var checkBox: BEMCheckBox!
    var textField: UITextField!

    override init(frame: CGRect) {
        super.init(frame: frame)
        checkBox.autoSetDimension(.height, toSize: CGFloat(20))
        checkBox.autoSetDimension(.width, toSize: CGFloat(20))
        self.addSubview(checkBox)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func updateConstraints() {
        if(shouldSetupConstraints) {
            checkBox.autoPinEdge(toSuperviewEdge: .left, withInset: 10)
            checkBox.autoPinEdge(toSuperviewEdge: .bottom, withInset: 10)
            shouldSetupConstraints = false
        }
         super.updateConstraints()
    }
    
}
