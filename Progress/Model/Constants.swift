    //
//  File.swift
//  Progress
//
//  Created by Aditya Gunda on 12/19/17.
//  Copyright © 2017 Aditya Gunda. All rights reserved.
//

import Foundation
import ChameleonFramework
    
    let mainAppColor = FlatPurple()
    
    let tasksReorderedEvent = "tasks_reordered"
    let taskCheckedEvent = "task_checked"
    let taskUncheckedEvent = "task_unchecked"
    let deadlineChangedEvent = "changed_deadline"
    let taskDeletedEvent = "delete_task"
    let updatedTaskTitleEvent = "updated_task_title"
    let removeTaskFromTodayEvent = "remove_task_from_today"
    let taskDoneForTodayEvent = "task_done_for_today"
    let addTaskToYourDayEvent = "add_task_to_your_day"
    let createTaskEvent = "create_task"
    let dailyNotificationTimeChangedEvent = "daily_notification_time_changed"
    let dailyNotificationOffEvent = "daily_notification_off"
    let globalProgressDotRadius = CGFloat(4.0)
    let hapticFeedbackOnEvent = "haptic_feedback_on"
    let hapticFeedbackOffEvent = "haptic_feedback_off"
    let talkToUsEvent = "talk_to_us"
    let onboardingFromSettingsEvent = "onboarding_from_settings"
    let globalProgressDotsColorArr = [FlatPurple(),FlatBlue(),FlatGreen(),FlatYellow(),FlatOrange(),FlatRed()]
    let finishedWalkthroughEvent = "finished_walkthrough"
    let skippedWalkthroughEvent = "skipped_walkthrough"
    let notificationPermissionGrantedEvent = "notifications_permission_granted"
    let notificationPermissionDeniedEvent = "notifications_permission_denied"
    let dismissedDeadlineNotificationEvent = "dismissed_deadline_notification"
    let openedNotificationEvent = "opened_notification"
    let deleteTaskDeadlineNotificationEvent = "deleteTask_deadline_notification"
    let completeTaskDeadlineNotificationEvent = "completeTask_deadline_notification"
    let clickedHelpEvent = "clicked_help_in_settings"
    let clickedRateAppEvent = "clicked_rate_app_in_settings"
    let tappedWidgetEvent = "tapped_today_widget"
    //user defaults
    let UDyourDayBadgeCount = "yourDayBadgeCount"
