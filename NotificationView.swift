//
//  NotificationView.swift
//  Budget Prototype
//
//  Created by Johnny Wu on 27/4/2022.
//

import SwiftUI
import AVKit

// This is the front end of the notifications menu, it shows the user what time their notifications are, where they are
struct NotificationView: View {
    
    // This is used to obtain the data for the notifications for persistence
    @EnvironmentObject var notificationsManager : NotificationsManager
    
    // Time of the notification
    @State private var notificationTime = Date()
    
    // Controls whether the addNotification sheet is shown
    @State private var isShowingSheet = false
    
    // Controls whether the tutorial is shown
    @State private var helpPresented = false
    @Environment(\.colorScheme) var colorScheme
    
    // This will convert the time of a notification object to a string. I don't know too much about it other than that
    func timeDisplayText(notification : UNNotificationRequest) -> String {
        
        // This will attempt to obtain the notification trigger, which in our case, is what activates the notification. Since our notifications are activated by a specific time, it will try to obtain the time of when the notification will be triggered.
        guard let nextTriggerDate = (notification.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate()
        else {return ""}
        
        // This converts the date object into a string so it can be displayed in a text view
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: nextTriggerDate)
    }
    
    @ViewBuilder
    var body: some View {
        
        VStack {
            
            // Tell the user whether the app is able to use notifications
            if notificationsManager.available == UNAuthorizationStatus.authorized {
                StyledText(text: "Reminders are currently allowed", foreGroundColor: .green).font(.title2).padding().frame(alignment: .center)
                // Place the data about notifications here and how to change time of daily reminders
            }
            
            // If the user has denied permissions the table will not load (as there are no notifications) and the usr will be prompted to add a notification
            else if notificationsManager.available == UNAuthorizationStatus.denied {
                
                VStack {
                    Text("Please enable reminders by using the button below").foregroundColor(.red).font(.headline).bold().padding().background(.ultraThickMaterial).clipShape(Capsule())
                    Button(action: {
                        // First line obtains the url needed for the system to go to the settings app to open the specific page with the budget wallet app
                        // Third line uses said url to actually open that page in settings
                        if let url = URL(string: UIApplication.openSettingsURLString),
                           UIApplication.shared.canOpenURL(url)
                        {
                            UIApplication.shared
                                .open(url, options: [:], completionHandler: nil)
                        }
                        
                    }, label: {
                        StyledText(text: "Enable reminders", foreGroundColor: .blue)
                    }).padding([.trailing, .bottom])
                }
            }
            
            // Text on why reminders are used in the app
            HStack {
                Text("Why do we use reminders?").font(.title3).bold().padding([.leading])
                Spacer()
            }
            Text("Reminders are used to remind you to add any new transactions everyday. You can add reminders to remind yourself to add transactions multiple times daily, or remove them by sliding to the left on the list of reminders if you wish").padding().dynamicTypeSize(.medium)
            
            // Title to introduce the times the user has set notifications for
            Text("Daily reminder times").font(.title2).bold().frame(alignment : .leading).padding()
            
            Form {
                
                // If it's denied then prompt the user to allow notirifactions
                if notificationsManager.available == UNAuthorizationStatus.denied {
                    Text("Please enable notifications for daily reminders for you to add new transactions")
                }
                // Otherwise then just display the times of every notification
                else {
                    if notificationsManager.notifications.count != 0 {
                        ForEach(notificationsManager.notifications, id : \.self, content : {
                            notification in
                            Text(timeDisplayText(notification: notification) // The timeDisplayText function is used to convert the trigger time to a text
                            )
                            // The deleting function is here (allows user to delete by sliding)
                        }).onDelete(perform: delete).onChange(of: notificationsManager.notifications, perform: { _ in
                            notificationsManager.reloadLocalNotifications()
                        })
                    }
                    else {
                        Text("None yet!")
                    }
                }
                
            }
            
            // Button to allow the user to add notifications - only shown if user allowed notifications
            if notificationsManager.available == UNAuthorizationStatus.authorized {
                Button(action: {
                    isShowingSheet.toggle()
                }, label: {
                    StyledText(text: "Add reminder", foreGroundColor: .blue)
                    // Disable button if the user didn't enable notifications
                }).disabled(notificationsManager.available == UNAuthorizationStatus.denied)
            }
            
            // Run if the user removes notifications and come back to the app, it won't be reflected in the app and it wont prompt the user to enable notifications- so this line allows it to detect updates
            
            // This sheet encompasses the entire process of adding a new notifications. It consists of some text, a datepicker and a button.
        }.sheet(isPresented: $isShowingSheet, onDismiss: {
            notificationsManager.reloadLocalNotifications() // When the sheet is dismissed we need to manually reload the notifications
        }, content: {
                VStack {
                    List {
                        
                        // Let user pick time of their new reminder
                        Text("Add a new reminder").bold().font(.title).frame(alignment : .leading).padding()
                        DatePicker("Time of reminder", selection: $notificationTime, displayedComponents: [.hourAndMinute]).font(.title2)
                    }
                    HStack {
                        
                        Button(action: {
                            
                            let dateComponents = Calendar.current.dateComponents([.hour,.minute], from: notificationTime)
                            let hour = dateComponents.hour ?? 19
                            let minute = dateComponents.minute ?? 0
                            
                            // This will add a notification with time of hour and minute. The completion function is used to detect errors but it's ok to have it like this because this is simple
                            notificationsManager.createNotification(h: hour, m: minute, completion: { error in
                                if error != nil {
                                    fatalError()
                                }
                            }
                            )
                            
                            // Play the sound and dismiss the sheet
                            SoundPlayer.instance.playSound(soundName: "AddTransactionOrGoal")
                            isShowingSheet.toggle()
                            
                        }, label: {
                            // This is the button displayed on the bottom
                            StyledText(text: "Add reminder", foreGroundColor: .blue).font(.title3).frame(alignment : .center)
                        })
                        
                        // This one will just disable the sheet without adding a notification
                        Button(action: {
                            isShowingSheet.toggle()
                        }, label: {
                            StyledText(text: "Exit", foreGroundColor: .red)
                        })
                        
                    }
                }
                
            })
        
        // Whenever the notification status for the app (ie if the user has allowed notifications), it will reload the authorisation status, allowing the screen to update
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification), perform: { _ in
            notificationsManager.reloadAuthorizationStatus()
        }).onAppear(perform: notificationsManager.reloadAuthorizationStatus).onChange(of: notificationsManager.available, perform: {available in
            switch available {
                
            case .notDetermined:
                // Ask for permission here - this is when the user first opens the app. This displays an alert which prompts the user to allow notifications
                notificationsManager.requestAuthorization()
            case .authorized:
                notificationsManager.reloadLocalNotifications()
            default:
                // Do nothing
                break
                
            }
        }).navigationTitle("Reminders").sheet(isPresented: $helpPresented, content: {
            NotificationTutorial()
        })
        // This places a button which looks like a question mark onto the right upper side of the screen
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    // This boolean value controlls whether the tutorial is shown or not
                    helpPresented.toggle()
                }, label: {
                    // Display a different image depending on whether the user is in light or dark mode
                    Image(colorScheme == .light ? "Help_light" : "Help_dark").resizable().scaledToFit().frame(width: 40, height: 40).clipShape(Circle())
                })
                
            }
        }
        
    }
}

// This is half of the function which allows the user to delete notifications - using the .map modififer to perform an action to every thing in the array of notifications
extension NotificationView {
    
    func delete(_ indexSet: IndexSet) {
        notificationsManager.deleteLocalNotifications(
            // Some information from https://www.hackingwithswift.com/example-code/language/how-to-use-map-to-transform-an-array and https://developer.apple.com/documentation/swift/array/3017522-map which was useful in allowing us to transform the original array and getting identifiers by running the closure there
            
            identifiers: indexSet.map { notificationsManager.notifications[$0].identifier }
        )
        // Update notifications afterwards
        notificationsManager.reloadLocalNotifications()
        SoundPlayer.instance.playSound(soundName: "Scrunch")
    }
}

// This is the tutorial for the notifications

struct NotificationTutorial : View {
    @Environment(\.presentationMode) var isPresented
    
    var body: some View {
        
        List {
            Section {
                Text("Notifications help").font(.title)
            }
            
            Section {
                Text("Allowing notifications").font(.title2)
                Text("When first using notifications, you will be prompted to allow Budget Wallet to send through local notifications, which are used to remind you to add your transactions daily. However, if you choose to remove access to sending notifications, this will be reflected in the app")
                Text("You may also choose these notifications to be a part of the daily summary, which means that the time of your daily summary will determine when the notifications will be set through, not the app")
                Text("To turn notifications back on, just press the button above the status of notifications which will redirect you to settings")
                TutorialVideo(name: "Modify_notifications_settings", ext: "mov")
                
            }
            
            Section {
                Text("Adding notifications").font(.title2)
                Text("Add a reminder by pressing the button at the bottom of the reminder screen. These are always daily reminders at the specified time, so be careful of how many you add")
                TutorialVideo(name: "Add_notification", ext: "mov")
                
            }
            
            Section {
                Text("Deleting notifications").font(.title2)
                Text("To delete notifications, merely swipe left on the specific time you want to remove")
                TutorialVideo(name: "Delete_notification", ext: "mov")
            }
            
            Button(action: {
                isPresented.wrappedValue.dismiss()
            }, label: {
                Text("Dismiss")
            })
        }
    }
}

