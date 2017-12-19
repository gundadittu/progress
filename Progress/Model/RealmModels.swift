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
    /*
 
 static var supportsSecureCoding: Bool {
 return true
 }
   required convenience init?(coder aDecoder: NSCoder) {
        self.init()
        let temp = SavedTask()
        temp.title =  aDecoder.decodeObject(forKey: "title") as! String
        let decodedDate = aDecoder.decodeObject(forKey: "deadline") as? Date
        temp.deadline = decodedDate
        temp.points =  aDecoder.decodeObject(forKey: "points") as! Int
         temp.isCompleted =  aDecoder.decodeObject(forKey: "isCompleted") as! Bool
         temp.isToday =  aDecoder.decodeObject(forKey: "isToday") as! Bool
         temp.displayOrder =  aDecoder.decodeObject(forKey: "displayOrder") as! Int
         temp.isNewTask =  aDecoder.decodeObject(forKey: "isNewTask") as! Bool
         temp.notificationIdentifier =  aDecoder.decodeObject(forKey: "notificationIdentifier") as! String
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.title, forKey: "title")
        aCoder.encode(self.deadline, forKey: "deadline")
        aCoder.encode(self.points, forKey: "points")
        aCoder.encode(self.isCompleted, forKey: "isCompleted")
        aCoder.encode(self.isToday, forKey: "isToday")
        aCoder.encode(self.displayOrder, forKey: "displayOrder")
        aCoder.encode(self.isNewTask, forKey: "isNewTask")
        aCoder.encode(self.notificationIdentifier, forKey: "notificationIdentifier")
    }
*/
}
