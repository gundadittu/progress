//
//  CoreDataHandler.swift
//  Progress
//
//  Created by Aditya Gunda on 12/11/17.
//  Copyright © 2017 Aditya Gunda. All rights reserved.
//

import UIKit
import CoreData

class CoreDataHandler: NSObject {
    
    private class func getContext() -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    class func saveNewTask(title: String, points: Int, dueDate: Date?, isToday: Bool, isCompleted: Bool) -> Bool {
        let context = getContext()
        let entity = NSEntityDescription.entity(forEntityName: "SavedTask", in: context)
        let managedObject = NSManagedObject(entity: entity!, insertInto: context)
        managedObject.setValue(title, forKey: "title")
        managedObject.setValue(points, forKey: "points")
        managedObject.setValue(isToday, forKey: "isToday")
        managedObject.setValue(isCompleted, forKey: "isCompleted")
        if dueDate != nil {
            managedObject.setValue(dueDate!, forKey: "deadline")
        }
        
        do {
            try context.save()
            return true
        } catch {
            return false
        }
    }
    
    class func updateTitle(savedTask: SavedTask, newValue: String) -> Bool {
        let context = getContext()
        savedTask.title = newValue
        do {
            try context.save()
            return true
        } catch {
            return false
        }
    }
    
    class func updatePoints(savedTask: SavedTask, newValue: Int) -> Bool {
        let context = getContext()
        savedTask.points = Int16(newValue)
        do {
            try context.save()
            return true
        } catch {
            return false
        }
    }

    class func updateIsToday(savedTask: SavedTask, newValue: Bool) -> Bool {
        let context = getContext()
        savedTask.isToday = newValue
        do {
            try context.save()
            return true
        } catch {
            return false
        }
    }
    
    class func updateIsCompleted(savedTask: SavedTask, newValue: Bool) -> Bool {
        let context = getContext()
        savedTask.isCompleted = newValue
        do {
            try context.save()
            return true
        } catch {
            return false
        }
    }
    
    class func updateDate(savedTask: SavedTask, newValue: Date) -> Bool {
        let context = getContext()
        savedTask.deadline = newValue
        do {
            try context.save()
            return true
        } catch {
            return false
        }
    }
    
    class func fetchAll() -> [SavedTask]? {
        let context = getContext()
        var savedTasks: [SavedTask]? = nil
        do {
            savedTasks = try context.fetch(SavedTask.fetchRequest())
            return savedTasks
        } catch {
            return savedTasks
        }
    }
    
    class func fetchToday() -> [SavedTask]? {
        let context = getContext()
        var savedTasks: [SavedTask]? = nil
        let isTodayPredicate = NSPredicate(format: "isToday == %@", Bool(booleanLiteral: true) as CVarArg)
        let isNotCompletedPredicate = NSPredicate(format: "isCompleted == %@",  Bool(booleanLiteral: false) as CVarArg)
        let andPredicate = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: [isTodayPredicate, isNotCompletedPredicate])
        let fetchRequest: NSFetchRequest<SavedTask> = SavedTask.fetchRequest()
        fetchRequest.predicate = andPredicate
        do {
            savedTasks = try context.fetch(fetchRequest)
            return savedTasks
        } catch {
            return savedTasks
        }
    }
    
    class func fetchAllTasks() -> [SavedTask]? {
        let context = getContext()
        var savedTasks: [SavedTask]? = nil
        let isNotTodayPredicate = NSPredicate(format: "isToday == %@",  Bool(booleanLiteral: false) as CVarArg)
        let isNotCompletedPredicate = NSPredicate(format: "isCompleted == %@",  Bool(booleanLiteral: false) as CVarArg)
        let andPredicate = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: [isNotTodayPredicate, isNotCompletedPredicate])
        let fetchRequest: NSFetchRequest<SavedTask> = SavedTask.fetchRequest()
        fetchRequest.predicate = andPredicate
        do {
            savedTasks = try context.fetch(fetchRequest)
            return savedTasks
        } catch {
            return savedTasks
        }
    }
    
    class func delete(_ savedTask: SavedTask) -> Bool {
        let context = getContext()
        context.delete(savedTask)
        
        do {
            try context.save()
            return true
        } catch {
            return false
        }
    }
}
