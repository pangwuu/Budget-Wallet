//
//  GoalsOverview.swift
//  Budget Prototype
//
//  Created by Johnny Wu on 17/1/2022.
//

import SwiftUI

// Both these are used for videos and displaying videos
import AVFoundation
import AVKit

// This is the goals page. It is very very similar to the transactions page
struct GoalsOverview: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    // Take environmentObjects as these will ensure that data is shared across views
    @EnvironmentObject var goals : Goals
    @EnvironmentObject var transactions : Transactions
    
    // @State means that the variable is constantly looking for changes and will change instantly when its value changes. They are also private as it is only shared within this view
    @State private var helpPresented = false // This is the variable which detects whether the tutorial is being shown or not
    @State private var sortType = "None" // This is the variable which affects how the goals are sorted (it is picked from sortTypes)

    // All the different ways to sort the transaction. Each can be used
    var sortTypes = ["None", "Name: A to Z", "Name: Z to A", "Remaining: Low to high", "Remaining: High to low", "Total amount: Low to high", "Total amount: High to low", "Contributed: Low to high", "Contributed: High to low", "Date: closest to furthest", "Date: furthest to closest"]
    
    // From https://stackoverflow.com/questions/60555343/delete-item-from-a-section-list-on-swiftui. I also added the sound effect to play the deletion sound. Essentially this will just remove the item from the array BUT it actually won't work if it is unfiltered.
    // Essentially it removes a function at a particular index
    private func deleteItem(at indexSet: IndexSet) {
        self.goals.items.remove(atOffsets: indexSet)
        SoundPlayer.instance.playSound(soundName: "Scrunch")
    }
    
    @ViewBuilder
    var body: some View {
        
        VStack {
            
            // Display this if there is a goal to display - otherwise a button prompting the user to add the goal will appear
            if goals.items.count > 0 {
                VStack {
                    // Title
                    HStack {
                        Text("Your goals")
                            .font(.title)
                            .bold()
                            .frame(alignment: .leading)
                            .padding([.leading])
                        Spacer()
                    }
                    
                    // The list will stack everything within it on top of one another, while also making it appear as a menu with clickable buttons
                    List {
                        
                        // A picker is something which allows the user to change a variable from a certain selection. In this case, it will present the user with all the different ways to sort the goals, and will display a simple text view for each of them
                        Picker("Sort by", selection: $sortType, content: {
                            ForEach(sortTypes, id : \.self) {sortType in
                                Text(sortType)
                            }
                        }).font(.headline)
                            .dynamicTypeSize(.medium)
                        
                        // The first one is a sorted version while the second one is unsorted. The second one can also allow the user to delete goals
                        if sortType != "None" {
                            ForEach(goals.customSort(method: sortType.stringToSortMethod(), unsorted: goals.items), id : \.id) { goal in
                                NavigationLink(destination: GoalViewDetailed(goal: goal), label: {
                                    LittleGoalView(goal: goal)
                                }).dynamicTypeSize(.medium)
                            }
                        }
                        else {
                            ForEach(goals.items, id : \.id) { goal in
                                NavigationLink(destination: GoalViewDetailed(goal: goal), label: {
                                    LittleGoalView(goal: goal)
                                })
                            }.onDelete(perform: self.deleteItem)
                                .dynamicTypeSize(.medium) // Difference is on this line
                        }
                    }
                    
                    // Button to add a new goal (not in the list anymore). Made of a navigationLink which takes the user to the add goal page
                    NavigationLink(destination: {
                        NewGoal()
                    }, label: {
                        StyledText(text: "Add a goal", foreGroundColor: .blue)
                    }).font(.body)
                    
                    // This sheet triggers whether the tutorial is activated, and this is triggered by the value of helpPresented. The "$" symolises a binding variable - meaning that the sheet communicates with the view and vice versa to respond to changes
                }.sheet(isPresented: $helpPresented, content: {
                    Goals_tutorial()
                })
                
                // This places a button which looks like a question mark onto the right upper side of the screen. I don't know why it is placed here, it is really stupid but that's just how apple works I guess
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
            
            // This is the view if the user doesn't have any goals added. It has only one button and the tutorial (code for that is copied)
            else {
                NavigationLink(destination: NewGoal(), label: {
                    StyledText(text : "Add a goal to get started" , foreGroundColor: .blue)
                }).sheet(isPresented: $helpPresented, content: {
                    Goals_tutorial()
                })
                // This places a button which looks like a question mark onto the right upper side of the screen
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            // This boolean value controlls whether the tutorial is shown or not
                            helpPresented.toggle()
                        }, label: {
                            // Display a different image depending on whether the user is in light or dark mode
                            Image(colorScheme == .light ? "Help_light" : "Help_dark")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        })
                        
                    }
                }
                
            }
            
        }
    }
}


// Thia is a specific struct that manages playing video - including which video to play depending on whether user is in light/dark mode. It is used only in the various tutorials
struct TutorialVideo : View {
    
    @Environment(\.colorScheme) var colorScheme
    let screenSize: CGRect = UIScreen.main.bounds
    
    // This acts like a "Getfilename()" function from earlier - and returns different videos depending on the user is in light or dark mode
    func lightOrDarkVideo(nameOfVideo : String) -> String {
        // Return statement is implied when function has one line
        colorScheme == .light ? "\(name)_light" : "\(name)_dark"
    }
    
    // These are used to get the video from the bundle which is stored on the user's device
    var name : String
    var ext: String
    
    var body: some View {
        // the url variable is essentially a way to access a video, sort of like how you access files through a regular program, while the withExtension is used to find appropriate video. This is where the AVKit and AVFoundation libraries are used
        // The width and height are proportionate to the screen width, my attempt to improve compatibility for other devices. Furthermore, it includes the approximate dimensions for a video which looks well-proportioned when placed in a list
        VideoPlayer(player: AVPlayer(url:  Bundle.main.url(forResource: lightOrDarkVideo(nameOfVideo: name), withExtension: ext)!) ).frame(width: screenSize.width*0.81, height: screenSize.height*0.81)
        
    }
    
}

// Here is the contents of the tutorial. It is triggered when the sheet is activated
// The tutorial is made up of text and screen recordings that show how to use specific elements of the app
struct Goals_tutorial : View {
    
    // This environment variable takes whether the sheet is shown or not - it is used to disable it
    @Environment(\.presentationMode) var isPresented
    
    var body: some View {
        List {
            Section {
                Text("Goals help").font(.title)
            }
            
            // Text for goals
            Section {
                HStack {
                    Text("What are they?").font(.title2)
                    Spacer()
                }
                Text("Goals can be used to help you to achieve specific financial goals in the future, while comparing themselves with your cashflow to determine whether they are realistic")
            }
            
            Section {
                HStack {
                    Text("The menu").font(.title2)
                    Spacer()
                }
                Text("A goal in Budget Wallet allows you to see progress towards real life financial goals, such as a home or a holiday")
                Text("The menu also allows you to see your goals in a handy table. Get details or contribute to any particular goal by tapping on it")
                Text("Sort your goals by using the sort menu at the top of the list. You can sort or filter the goals by a variety of criteria, check out these features in the video below")
                // This shows a video which describes how to use the app - in this case, how to use the goals menu and how to filter/sort the user's goals
                // From https://www.hackingwithswift.com/quick-start/swiftui/how-to-play-movies-with-videoplayer, allows you to play video
                TutorialVideo(name: "Goals_menu", ext: "mov")
            }
            
            Section {
                HStack {
                    Text("Adding goals").font(.title2)
                    Spacer()
                }
                Text("Add a goal by tapping on the add goal button on the bottom of the menu")
                Text("Include information such as the due date of your goal and the amount required to achieve it. Use the slider to adjust and see the amount you have already contributed to this goal")
                Text("The achieveability rating estimates the estimated achieveability by comparing the amount needed to pay off the goal with your cashflows in the same time period of the goal. This will be adjusted to warn you against adding goals which may not be feasible in the time frame. To avoid this, you can extend the time frame of your goal")
                Text("Check out this process below")
                TutorialVideo(name: "Add_goal", ext: "mov")
            }
            
            Section {
                HStack {
                    Text("Goal contributions").font(.title2)
                    Spacer()
                }
                Text("There would be no use for goals if you can't actually achieve them through goal contributions")
                Text("Contribute to a goal by using the \"Contribute\" button on the bottom of any specific goal.")
                Text("Add the desired amount into the goal. This amount will then be subtracted from the remaining amount required to achieve the goal. When this amount reaches 0, the goal is achieved!")
                Text("Please note that any goal contributions will automatically add an expense transaction which corresponds to the contribution, which will also affect cashflow just like any other transaction")
                // Show video of contribution leading to an expense transaction
                TutorialVideo(name: "Goal_contribution", ext: "mov")
                
            }
            
            Section {
                HStack {
                    Text("Deleting goals").font(.title2)
                    Spacer()
                }
                
                Text("Like transactions, you can also edit and delete goals")
                Text("Delete any goal by first tapping the goal you want to delete from the menu, then pressing the delete button.")
                Text("Please note that deleting a goal will NOT delete any of its associated contributions that are listed in the transactions")
                TutorialVideo(name: "Delete_goal", ext: "mov")
                Text("Alternatively you can delete transactions by sliding on them, as long as they are unsorted")
                TutorialVideo(name : "Slide_delete_transaction", ext : "mov")
                
            }
            Section {
                HStack {
                    Text("Editing goals").font(.title2)
                    Spacer()
                }
                Text("Edit a goal by first tapping the goal you wish to edit and selecting the option to edit the goal")
                Text("Change the data in the text boxes or date pickers in order to change the data associated with the goal")
                Text("Once done, confirm your changes by selecting the button at the bottom")
                Text("Please do not use this method to add goal contributions, as it will provide a distorted view to your goal contributions")
                TutorialVideo(name: "Edit_goal", ext: "mov")
                Text("Please note that the data for the goal will only update AFTER you go back to the main menu.")
                
            }
            
            
            
            Section {
                Button(action: {
                    // This dismisses the button by utilising the environment variable which detects whether the sheet is presented. It will essentially make it "false" and hence remove the tutorial
                    isPresented.wrappedValue.dismiss()
                }, label: {
                    Text("Dismiss")
                }
                )
                
                
            }
            
            
        }
        
    }
}
