//
//  NotificationsManager.swift
//  Budget Prototype
//
//  Created by Johnny Wu on 27/4/2022.
//

import Foundation
import UserNotifications

class NotificationsManager : ObservableObject {
    
    // Array for all the notifications
    @Published private(set) var notifications : [UNNotificationRequest] = []
    // Array of all the notification times
    @Published var notificationTimes: [Date] = []
    
    // Variable which tracks whether the user has allowed notifications
    @Published private(set) var available : UNAuthorizationStatus?
    
    let center = UNUserNotificationCenter.current()
    
    // This will update the authorisation status (whether the user has allowed notifications)
    func reloadAuthorizationStatus() {
        // UNUserNotificationCenter is the object that controls most of the notifications and their settings when using the app
        center.getNotificationSettings(completionHandler: {settings in
            DispatchQueue.main.async {
                // This sets the authorisation status for notifications to be the notifications settings in settings
                self.available = settings.authorizationStatus
            }
        })
    }
    
    // This requests the user for authorisation for the app to present notifications - used at the beginning of the app
    func requestAuthorization() {
        
        center.requestAuthorization(options: [.alert, .sound, .badge], completionHandler: { granted, error in
            // DispatchQueue.main.async allows you to run this in the background without calling another function - it improves safety. More here : https://stackoverflow.com/questions/44324595/difference-between-dispatchqueue-main-async-and-dispatchqueue-main-sync
            DispatchQueue.main.async {
                // We reset the available variable depending on whether the user has allowed the app to use notifications
                self.available = granted ? .authorized : .denied
            }
        })
    }
    
    // This will reload the notifications manually, used when we add a notification
    func reloadLocalNotifications() {
        // This pulls the notifications from memory and stores it into the variable we have here in the notificationsmanager
        center.getPendingNotificationRequests(completionHandler: {notifications in
            DispatchQueue.main.async {
                self.notifications = notifications
            }
        })
    }
    
    // Fourth parameter is an optional error
    func createNotification(h : Int, m : Int, completion: @escaping (Error?) -> Void) {
        
        // Datecomponents makes it easy to work with dates. If no date is provided, this will recur daily, which is what is intended
        let dateComps = DateComponents(hour : h, minute : m)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComps, repeats: true)
        
        // For testing, I used this which schedules the notification trigger for 5 seconds after the notification is initialised -
        //let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        let differentNotificationTitles = ["Reminder!", "Did you remember?"]
        let differentNotificationMessages = ["Have you added your transactions today?", "Come add your transactions now!", "Track your spending by adding any new transactions!", "Did you buy anything today? Add it as a transaction!", "Are there any new goals you are aiming towards?"]
        
        // Select a random message from the different messages to show the user - but these will be the same for the notification as they b
        
        // Essentially creates an empty notification - we'll fill in this data later
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = differentNotificationTitles.randomElement() ?? "Reminder"
        notificationContent.body = differentNotificationMessages.randomElement() ?? "Hello?"
        
        // This is where the custom notification sound is used! Code partially from https://smashswift.com/create-custom-notification-sound/ - it essentially finds the sound file from the bundle and converts it into a special notificationsound type
        notificationContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "Notification.mp3"))
        // Create the request before it is added to the notification center
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: notificationContent, trigger: trigger)
        center.add(request)
    }
    
    
    // This allows the user to delete notifications. Surprisingly it is much more complex than a regular list you can delete from.
    func deleteLocalNotifications(identifiers: [String]) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
}
