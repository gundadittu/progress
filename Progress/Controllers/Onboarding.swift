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
    
    
    let items: [OnboardingItemInfo]  = [
        (imageName: UIImage(named: "logo")!, title: "", description: "Swipe through to learn more.", iconName: UIImage(named: "logo")!, color: UIColor.clear, titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont:  UIFont(name: "HelveticaNeue-Medium", size: CGFloat(20))! ,descriptionFont: UIFont(name: "HelveticaNeue", size: CGFloat(20))!),
        (imageName: UIImage(named: "1")!, title: "", description: "Under Today, you'll find all the tasks you've planned to work on today. When you're done with the task for the day, just swipe right.", iconName: UIImage(named: "1")!, color: UIColor.clear, titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: UIFont(name: "HelveticaNeue-Medium", size: CGFloat(20))!,descriptionFont: UIFont(name: "HelveticaNeue", size: CGFloat(20))!),
         (imageName: UIImage(named: "2")!, title: "", description: "Everytime you finish a task for the day, a purple dot appears to show your progress.", iconName: UIImage(named: "logo")!, color: UIColor.clear, titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont:  UIFont(name: "HelveticaNeue-Medium", size: CGFloat(20))! ,descriptionFont: UIFont(name: "HelveticaNeue", size: CGFloat(20))!),
        (imageName: UIImage(named: "3")!, title: "", description: "Slide up to go to all your tasks. Here you can add tasks to Today by swiping right.", iconName: UIImage(named: "2")!, color: UIColor.clear, titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: UIFont(name: "HelveticaNeue-Medium", size: CGFloat(20))!,descriptionFont: UIFont(name: "HelveticaNeue", size: CGFloat(20))!),
        (imageName: UIImage(named: "4")!, title: "", description: "Whenever you complete a task, just tap the checkbox and watch it fade away.", iconName: UIImage(named: "3")!, color: UIColor.clear, titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: UIFont(name: "HelveticaNeue-Medium", size: CGFloat(20))!,descriptionFont: UIFont(name: "HelveticaNeue", size: CGFloat(20))!),
        (imageName: UIImage(named: "5")!, title: "", description: "To report any issues, just shake your phone at anytime. Give it a shot now.", iconName: UIImage(named: "4")!, color: UIColor.clear, titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: UIFont(name: "HelveticaNeue-Medium", size: CGFloat(20))!,descriptionFont: UIFont(name: "HelveticaNeue", size: CGFloat(20))!)]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        paperView.dataSource = self
        paperView.delegate = self
        self.getStartedBtn.layer.cornerRadius = CGFloat(10)
    }

    func onboardingItemAtIndex(_ index: Int) -> OnboardingItemInfo {
        return items[index] 
    }
    
    func onboardingItemsCount() -> Int {
        return items.count
    }
    
    func onboardingDidTransitonToIndex(_ index: Int) {
        return
    }
    
    func onboardingWillTransitonToIndex(_ index: Int) {
        if index == (items.count - 1) {
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

