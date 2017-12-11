//
//  Task.swift
//  Progress
//
//  Created by Aditya Gunda on 12/9/17.
//  Copyright © 2017 Aditya Gunda. All rights reserved.
//

import Foundation

class Task {
    
    private var _title: String
    private var _count: Int
    
    var title: String {
        get {
            return _title
        }
        set(newTitle) {
            _title = newTitle
        }
    }
    
    var count: Int {
        get {
            return _count
        }
        set(newCount) {
            _count = newCount
        }
    }
    
    init(title: String, count: Int) {
        self._title = title
        self._count = count
    }
}
