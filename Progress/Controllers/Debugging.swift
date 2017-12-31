//
//  Debugging.swift
//  Progress
//
//  Created by Aditya Gunda on 12/31/17.
//  Copyright © 2017 Aditya Gunda. All rights reserved.
//

import Foundation
import Crashlytics

class DebugController {
    
    class func write(string: String) {
        CLSLogv("%@", getVaList([string]))
    }
}
