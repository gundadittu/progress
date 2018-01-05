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
    @objc dynamic var todayDisplayOrder = 0
    @objc dynamic var isNewTask = false
    @objc dynamic var notificationIdentifier = ""
}

class RealmConfig {
    class func config() -> Realm.Configuration {
        let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.progress.tasks")
        let realmURL = container!.appendingPathComponent("default.realm")
        let config = Realm.Configuration(fileURL: realmURL, objectTypes: [SavedTask.self])
        return config
    }
}

class Migration {
    
    /*class func checkSchema(){
        //let sharedR = try! Realm(configuration: RealmConfig.config())
       let config = Realm.Configuration(
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: 2,
            
            // Set the block which will be called automatically when opening a Realm with
            // a schema version lower than the one set above
            migrationBlock: { migration, oldSchemaVersion in
                // We haven’t migrated anything yet, so oldSchemaVersion == 0
               // let objects = try! Realm().objects(SavedTask.self)
                let objects = try! Realm().objects(SavedTask.self)
                switch oldSchemaVersion {
                case 1:
                    self.migrateDataToSharedAppGroup(allObjects: objects)
                    break
                case 2:
                    break
                default:
                    self.migrateDataToSharedAppGroup(allObjects: objects)
                    return
                }
        })
        Realm.Configuration.defaultConfiguration = config
        try! Realm.performMigration()
    }*/
    
    class func migrateDataToSharedAppGroup(allObjects: Results<SavedTask>) {
        
        let config = Realm.Configuration(
            fileURL: FileManager
                .default
                .containerURL(forSecurityApplicationGroupIdentifier: "group.progress.tasks")!
                .appendingPathComponent("db.realm"),
            objectTypes: [SavedTask.self])
       let sharedR =  try! Realm(configuration: config)
        
        try! sharedR.write {
            sharedR.deleteAll()

            for obj in allObjects {
                let title = obj.title
                let points = obj.points
                let isCompleted = obj.isCompleted
                let isToday = obj.isToday
                let displayOrder = obj.displayOrder
                let todayDisplayOrder = obj.todayDisplayOrder
                let isNewTask = obj.isNewTask
                let notID = obj.notificationIdentifier
                var deadline: Date? = nil
                if let date = obj.deadline {
                    deadline = date
                }
                
                let task = SavedTask()
                task.title = title 
                task.points = points
                task.isCompleted = isCompleted
                task.isToday = isToday
                task.displayOrder = displayOrder
                task.todayDisplayOrder = todayDisplayOrder
                task.isNewTask = isNewTask
                task.notificationIdentifier = notID
                task.deadline = deadline
                sharedR.add(task)
            }
        }
    }
}
