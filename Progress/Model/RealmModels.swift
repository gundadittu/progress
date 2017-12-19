//
//  RealmModels.swift
//  Progress
//
//  Created by Aditya Gunda on 12/14/17.
//  Copyright © 2017 Aditya Gunda. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

class SavedTask: Object {
    
    @objc dynamic var title = ""
    @objc dynamic var deadline: Date? = nil
    @objc dynamic var points = 0
    @objc dynamic var isCompleted = false
    @objc dynamic var isToday = false
    @objc dynamic var displayOrder = 0
    @objc dynamic var isNewTask = false
    @objc dynamic var notificationIdentifier = ""
}
