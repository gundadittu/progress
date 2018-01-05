//
//  TodayViewController.swift
//  Progress Widget
//
//  Created by Aditya Gunda on 1/3/18.
//  Copyright © 2018 Aditya Gunda. All rights reserved.
//

import UIKit
import NotificationCenter
import RealmSwift
import FirebaseAnalytics
import DottedProgressBar
import SwiftDate
import DZNEmptyDataSet

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


class TodayViewCell : UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
}

class TodayViewController: UIViewController, NCWidgetProviding, UITableViewDelegate, UITableViewDataSource {
        
    @IBOutlet weak var tableView: UITableView!
    var tasksList: Results<SavedTask>?
    var realm = try! Realm()
    let sharedDefaults = UserDefaults.init(suiteName: "group.progress.tasks")

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        let config = Realm.Configuration(
            fileURL: FileManager
                .default
                .containerURL(forSecurityApplicationGroupIdentifier: "group.progress.tasks")!
                .appendingPathComponent("db.realm"),
            objectTypes: [SavedTask.self])
         self.realm = try! Realm(configuration: config)
        
        self.tasksList = fetchObjects()
    }
    
    //fetches objects from database
    func fetchObjects() -> Results<SavedTask> {
        let isTodayPredicate = NSPredicate(format: "isToday == %@",  Bool(booleanLiteral: true) as CVarArg)
        let isNotCompletedPredicate = NSPredicate(format: "isCompleted == %@",  Bool(booleanLiteral: false) as CVarArg)
        
        //only fetches objects with isToday tasks and not completed
        let andPredicate = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: [isTodayPredicate, isNotCompletedPredicate])
        let list = self.realm.objects(SavedTask.self).filter(andPredicate)
        
        //sorts list by todayDisplayOrder attribute
        return list.sorted(byKeyPath: "todayDisplayOrder", ascending: true)
    }

    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.newData)
    }
    
    func widgetMarginInsets(forProposedMarginInsets defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = (tasksList?.count)!
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let selectedTask = tasksList![indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "todayviewcell", for: indexPath) as! TodayViewCell
        cell.titleLabel.text = selectedTask.title
        
        let date = selectedTask.deadline
        
        //due date btn
        if date != nil {
            cell.dateLabel.isHidden = false
            
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            let formattedDate = formatter.string(from: date!)
            
            if (date?.isYesterday)! == true {
                cell.dateLabel.text = "Yesterday"
            } else if (date?.isToday)! == true  {
                cell.dateLabel.text = "Today"
            } else if (date?.isTomorrow)! == true {
                  cell.dateLabel.text = "Tomorrow"
            } else {
                if (date?.isInPast)! == true {
                    let colloquialPhrase = (date?.colloquialSinceNow())!
                      cell.dateLabel.text = "\(colloquialPhrase)"
                } else {
                    //date is in future
                    let calendar = NSCalendar.current
                    let date1 = calendar.startOfDay(for: date!)
                    let date2 = calendar.startOfDay(for: Date())
                    let components = calendar.dateComponents([.day], from: date1, to: date2)
                    let difference = abs((components.day)!)
                    if difference < 15 {
                        cell.dateLabel.text = "in \(difference) days"
                    } else {
                        cell.dateLabel.text = "\(formattedDate)"
                    }
                }
            }
        } else {
            //if there is not deadline
            cell.dateLabel.text = "Add Deadline"
            cell.dateLabel.isHidden = true
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        sharedDefaults?.setValue(indexPath.row, forKey: "todayWidgetSelectedTask")
        extensionContext?.open(URL(string: "openAppFromWidget://")! , completionHandler: nil)
        return
    }
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        var numOfSections: Int = 0
        if (self.tasksList?.count)! > 0
        {
            tableView.separatorStyle = .singleLine
            numOfSections            = 1
            tableView.backgroundView = nil
        }
        else
        {
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(tappedEmptyWidget))
            self.tableView.backgroundView = UIView()
            self.tableView.backgroundView?.addGestureRecognizer(tap)
            
            let noDataLabel: UILabel     = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
            noDataLabel.text          = "No tasks left!"
            noDataLabel.font          =  UIFont(name: "Avenir-Light", size: 15)
            noDataLabel.textColor     = UIColor.black
            noDataLabel.textAlignment = .center
            tableView.backgroundView?.addSubview(noDataLabel)
            tableView.separatorStyle  = .none
        }
        return numOfSections
    }
    
    @objc func tappedEmptyWidget() {
        if (self.tasksList?.count)! == 0 {
            sharedDefaults?.setValue(nil, forKey: "todayWidgetSelectedTask")
            extensionContext?.open(URL(string: "openAppFromWidget://")! , completionHandler: nil)
        }
    }
}



 
