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
    private var _isToday: Bool
    private var _isCompleted: Bool
    
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
    
    var isToday: Bool {
        get {
            return _isToday
        }
        set(newIsToday) {
            _isToday = newIsToday
        }
    }
    
    var isCompleted: Bool {
        get {
            return _isCompleted
        }
        set(newIsCompleted) {
            _isCompleted = newIsCompleted
        }
    }
    
    init(title: String, count: Int, isToday: Bool, isCompleted: Bool) {
        self._title = title
        self._count = count
        self._isToday = isToday
        self._isCompleted = isCompleted
    }
}
