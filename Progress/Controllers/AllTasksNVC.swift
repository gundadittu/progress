//
//  AllTasksNVC.swift
//  Progress
//
//  Created by Aditya Gunda on 1/1/18.
//  Copyright © 2018 Aditya Gunda. All rights reserved.
//

import UIKit
import Pulley
import FirebaseAnalytics

class AllTasksNVC: UINavigationController,  PulleyDrawerViewControllerDelegate{

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    func collapsedDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return CGFloat(400)
    }
    
    func partialRevealDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        let height = self.view.frame.height / 6
         return CGFloat(height)
    }
    
    func supportedDrawerPositions() -> [PulleyPosition] {
        return [.closed, .partiallyRevealed, .open]
    }
    
    func drawerPositionDidChange(drawer: PulleyViewController, bottomSafeArea: CGFloat) {
        if drawer.drawerPosition == .open {
            NotificationCenter.default.post(name: Notification.Name("triggerTaskVCSwipeAlert"), object: nil)
        }
        Analytics.logEvent("drawer_position_did_change", parameters: [ "name":"" as NSObject, "full_text": "" as NSObject ])
    }
}
