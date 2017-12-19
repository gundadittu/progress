//
//  SettingsVC.swift
//  Progress
//
//  Created by Aditya Gunda on 12/16/17.
//  Copyright © 2017 Aditya Gunda. All rights reserved.
//

import UIKit
import Instabug
import ChameleonFramework

class SettingsVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    let items = ["Share App", "FAQs", "Walkthrough", "Talk to Us", "Notifications","Erase all Data","Website", "Credits", "Privacy Policy", "Terms & Conditions", ]
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Settings"
        self.tableView.separatorStyle = .none
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.navigationController?.navigationBar.tintColor = FlatPurple()
     }
}

extension SettingsVC: UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = indexPath.row
        switch index {
        case 0:
            break
        case 1:
            break
        case 2:
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.loadOnboarding()
            break
        case 3:
            Instabug.invoke()
            break
        case 4:
            break
        case 5:
            break
        case 6:
            break
        case 7:
            break
        case 8:
            break
        default:
            return
        }
        
        if items[indexPath.row] == "Talk to Us" {
            Instabug.invoke()
        }
        return
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
}

extension SettingsVC: UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath) as! SettingsCell
        cell.label.text = items[indexPath.row]
        return cell 
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
}
