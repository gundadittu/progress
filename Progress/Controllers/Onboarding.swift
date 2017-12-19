//
//  OnboardingVC.swift
//  Progress
//
//  Created by Aditya Gunda on 9/13/17.
//  Copyright © 2017 Aditya Gunda. All rights reserved.
//

import UIKit
import paper_onboarding
import ChameleonFramework
import Floaty
import Instabug
import Firebase

class OnboardingVC: UIViewController, PaperOnboardingDataSource, PaperOnboardingDelegate {
    
    @IBOutlet var paperView: PaperOnboarding!
    @IBOutlet weak var getStartedBtn: UIButton!
    @IBOutlet weak var skipBtn: UIButton!
    var titleSize = 20
    
    let items: [OnboardingItemInfo] = [
    (imageName: UIImage(named: "logo")!, title: "Swipe left to get started.", description: "", iconName: UIImage(named: "logo")!, color: UIColor.clear, titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont:  UIFont(name: "HelveticaNeue-Medium", size: CGFloat(20))! ,descriptionFont: UIFont(name: "HelveticaNeue", size: CGFloat(20))!),
      (imageName: UIImage(named: "1")!, title: "To create a new task,", description: "look for the purple plus button.", iconName: UIImage(named: "1")!, color: UIColor.clear, titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: UIFont(name: "HelveticaNeue-Medium", size: CGFloat(20))!,descriptionFont: UIFont(name: "HelveticaNeue", size: CGFloat(20))!),
       (imageName: UIImage(named: "2")!, title: "Your tasks are under All Tasks.", description: "You can add tasks to Your Day by swiping right.", iconName: UIImage(named: "2")!, color: UIColor.clear, titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: UIFont(name: "HelveticaNeue-Medium", size: CGFloat(20))!,descriptionFont: UIFont(name: "HelveticaNeue", size: CGFloat(20))!),
    (imageName: UIImage(named: "3")!, title: "Your Day holds today's tasks.", description: "When you're done with a task for today, just swipe right.", iconName: UIImage(named: "3")!, color: UIColor.clear, titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: UIFont(name: "HelveticaNeue-Medium", size: CGFloat(20))!,descriptionFont: UIFont(name: "HelveticaNeue", size: CGFloat(20))!),
    (imageName: UIImage(named: "4")!, title: "When you finish a task for the day,", description: "a dot is added under the task to mark your progress.", iconName: UIImage(named: "4")!, color: UIColor.clear, titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont:  UIFont(name: "HelveticaNeue-Medium", size: CGFloat(20))! ,descriptionFont: UIFont(name: "HelveticaNeue", size: CGFloat(20))!),
    (imageName: UIImage(named: "5")!, title: "Whenever you complete a task,", description: "just tap the checkbox and watch it fade away.", iconName: UIImage(named: "5")!, color: UIColor.clear, titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: UIFont(name: "HelveticaNeue-Medium", size: CGFloat(20))!,descriptionFont: UIFont(name: "HelveticaNeue", size: CGFloat(20))!)
    ]
    
    override func viewWillAppear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        paperView.dataSource = self
        paperView.delegate = self
        self.getStartedBtn.layer.cornerRadius = CGFloat(10)
    }

    func onboardingItemAtIndex(_ index: Int) -> OnboardingItemInfo {
        return self.items[index]
    }
    
    func onboardingItemsCount() -> Int {
        return self.items.count
    }
    
    func onboardingDidTransitonToIndex(_ index: Int) {
        return
    }
    
    func onboardingWillTransitonToIndex(_ index: Int) {
        if index == (self.items.count - 1) {
            self.skipBtn.isHidden = true
            self.getStartedBtn.isHidden = false
        } else {
            self.skipBtn.isHidden = false
            self.getStartedBtn.isHidden = true
        }
    }
    
    func onboardingConfigurationItem(_ item: OnboardingContentViewItem, index: Int) {
        let screenSize: CGRect = UIScreen.main.bounds
        item.imageView?.frame = CGRect(x: 0, y: 0, width: 150, height: screenSize.height * 0.4)
    }
    
    @IBAction func getStartedBtnHandler(_ sender: Any) {
        
        //log firebase analytics event
        Analytics.logEvent("finished_walkthrough", parameters: [
            "name":"" as NSObject,
            "full_text": "" as NSObject
            ])
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func skipBtnHandler(_ sender: Any) {
        
        //log firebase analytics event
        Analytics.logEvent("skipped_walkthrough", parameters: [
            "name":"" as NSObject,
            "full_text": "" as NSObject
            ])
        
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .default
        Floaty.global.button.isHidden = false
        Instabug.showIntroMessage()
    }
}

