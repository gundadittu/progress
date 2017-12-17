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

class OnboardingVC: UIViewController, PaperOnboardingDataSource, PaperOnboardingDelegate {
    
    @IBOutlet var paperView: PaperOnboarding!
    @IBOutlet weak var getStartedBtn: UIButton!
    @IBOutlet weak var skipBtn: UIButton!
    var titleSize = 20
    
    let items: [OnboardingItemInfo] = [
    (imageName: UIImage(named: "logo")!, title: "Swipe left to learn more.", description: "", iconName: UIImage(named: "logo")!, color: UIColor.clear, titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont:  UIFont(name: "HelveticaNeue-Medium", size: CGFloat(20))! ,descriptionFont: UIFont(name: "HelveticaNeue", size: CGFloat(20))!),
      (imageName: UIImage(named: "1")!, title: "To create a new task,", description: "click on the big purple plus button.", iconName: UIImage(named: "1")!, color: UIColor.clear, titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: UIFont(name: "HelveticaNeue-Medium", size: CGFloat(20))!,descriptionFont: UIFont(name: "HelveticaNeue", size: CGFloat(20))!),
       (imageName: UIImage(named: "2")!, title: "Your new task will appear under All Tasks.", description: "You can add tasks to work on today by  swiping right.", iconName: UIImage(named: "2")!, color: UIColor.clear, titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: UIFont(name: "HelveticaNeue-Medium", size: CGFloat(20))!,descriptionFont: UIFont(name: "HelveticaNeue", size: CGFloat(20))!),
    (imageName: UIImage(named: "3")!, title: "Your Day holds your tasks for the day.", description: "When you're done with a task for the day, just swipe right.", iconName: UIImage(named: "3")!, color: UIColor.clear, titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: UIFont(name: "HelveticaNeue-Medium", size: CGFloat(20))!,descriptionFont: UIFont(name: "HelveticaNeue", size: CGFloat(20))!),
    (imageName: UIImage(named: "4")!, title: "Everytime you finish a task for the day,", description: "a purple dot is added under the task to mark your progress.", iconName: UIImage(named: "4")!, color: UIColor.clear, titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont:  UIFont(name: "HelveticaNeue-Medium", size: CGFloat(20))! ,descriptionFont: UIFont(name: "HelveticaNeue", size: CGFloat(20))!),
    (imageName: UIImage(named: "5")!, title: "Whenever you finally complete a task,", description: "just tap the checkbox and watch it fade away.", iconName: UIImage(named: "5")!, color: UIColor.clear, titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: UIFont(name: "HelveticaNeue-Medium", size: CGFloat(20))!,descriptionFont: UIFont(name: "HelveticaNeue", size: CGFloat(20))!)
    ]

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
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func skipBtnHandler(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        Floaty.global.button.isHidden = false 
    }
}

