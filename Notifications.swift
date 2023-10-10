//
//  Notifications.swift
//  Budget Prototype
//
//  Created by Johnny Wu on 24/4/2022.
//

import Foundation
import UserNotifications

// The notifications that I will be using are called notifications, essentially triggered by the passing of time. The user will also have the option to adjust some notification settings - much of this is taken from https://www.youtube.com/watch?v=iRjyk1S0nvo


//let content = UNMutableNotificationContent()
//
//content.title = "Weekly Staff Meeting"
//content.body = "Every Tuesday at 2pm"
//
//// Configure the recurring date.
//var dateComponents = DateComponents()
//dateComponents.calendar = Calendar.current
//
//dateComponents.weekday = 3  // Tuesday
//dateComponents.hour = 14    // 14:00 hours
//
//// Create the trigger as a repeating event.
//let trigger = UNCalendarNotificationTrigger(
//         dateMatching: dateComponents, repeats: true)
//
//// Create the request
//let uuidString = UUID().uuidString
//let request = UNNotificationRequest(identifier: uuidString,
//            content: content, trigger: trigger)
//
//// Schedule the request with the system.
//let notificationCenter = UNUserNotificationCenter.current()
//notificationCenter.add(request) { (error) in
//   if error != nil {
//      // Handle any errors.
//   }
//}
