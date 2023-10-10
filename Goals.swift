//
//  Goals.swift
//  Budget Prototype
//
//  Created by Johnny Wu on 17/1/2022.
//

import SwiftUI
import AVFoundation

// A goal is made up of all of these things. A LOT OF THIS IS COPIED FROM THE TRANSACTION STRUCT
struct Goal : Identifiable, Codable, Equatable {
    
    var name : String
    var dueDate : Date
    var amount : Double
    var amountContributed : Double
    var id = UUID()
    // This is a number that shows the user how easy it is to actually pay off their goal
    var feasibility : Double
    var category : String
    
}

// Exactly the same but now it takes a category as input as a string and has variable height and length to accomodate two different locations
struct GoalImage : View {
    
    var aHeight = 40.0
    var aWidth = 40.0
    var goal : Goal
    @Environment(\.colorScheme) var colorScheme
    
    // This function gets the name of the file given from goal
    func getFileName() -> String {
        let theme = colorScheme == .light ? "_light" : "_dark"
        let category = goal.category
        if category == "Emergency fund" {
            return "Emergency_fund_goal" + theme
        }
        return category + "_goal" + theme
        
    }
    
    var body: some View {
        // This is the actual image
        Image(getFileName())
            .resizable()
            .scaledToFit()
            .clipShape(Circle())
            .frame(width: aWidth, height: aHeight)
    }
}

// Like the detailed view for transactions
struct GoalViewDetailed : View {
    
    var goal : Goal
    
    // For when user deletes - identical to Transactions view
    @State private var confirmationShown = false
    
    @EnvironmentObject var goals : Goals
    @EnvironmentObject var transactions : Transactions
    
    // Calculates the "achievability index" of the specific goal by extracting the user's cash flow between "now" and the time where it is due. It is calculated by cashflow/Balance over the time period
    func calculateFeasibility() -> Double {
        let balance = transactions.getBalance(timePeriod: "Custom", startDate: Date.now.stripTime(), endDate: goal.dueDate.stripTime())
        let g = goal.amount - goal.amountContributed
        return round( (balance/g) * 100 )/100
    }
    
    // Copied it returns a string form of a short date (ie Date month and year only)
    func getShortDate(d : Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: d)
    }
    
    @ViewBuilder
    var body: some View {
        
        VStack {
            
            List {
                // For the category - this is slightly more complex as it requires some spacing of the different elements - first the two texts are arranged vertically - then that group is arranged horizontally to the image
                
                // For cetagory
                Section {
                    HStack {
                        VStack {
                            Text("CATEGORY").font(.caption).frame(alignment : .leading)
                            Text(goal.category).font(.title).bold()
                        }
                        Spacer()
                        GoalImage(aHeight: 60, aWidth: 60, goal: goal)
                    }
                }
                
                // For the goal's end date
                Section {
                    HStack {
                        Text("Due date").font(.headline)
                        Spacer()
                        Text(goal.dueDate, format : .dateTime.day().month().year())
                    }
                }
                                
                // This is displayed if the goal has not been achieved YET
                if goal.amount > goal.amountContributed {
                    
                    Section {
                        HStack {
                            Text("Remaining").font(.title).bold()
                            Spacer()
                            Text(goal.amount - goal.amountContributed, format : .currency(code: Locale.current.currencyCode ?? "AUD"))
                        }
                    }
                    
                    // This is the amount required
                    Section {
                        HStack {
                            Text("Total amount required").font(.headline)
                            Spacer()
                            Text(goal.amount,  format : .currency(code: Locale.current.currencyCode ?? "AUD"))
                        }
                        // Amount the user has put into the goal
                        HStack {
                            Text("Amount contributed").font(.headline)
                            Spacer()
                            Text(goal.amountContributed, format : .currency(code: Locale.current.currencyCode ?? "AUD"))
                        }
                    }
                    
                    // I would use a switch but that only works with discrete cases not ranges of continuous data - essentially this creates text which has a different colour depending on the colour of the text. The more feasible the goal is the greener it is
                    // This shows the achieveability rating of the goal
                    Section {
                        HStack {
                            Text("Achievability rating").bold()
                            Spacer()
                            Text(calculateFeasibility(), format: .number)
                        }
                        if calculateFeasibility() > 10 {
                            // GoalText is a custom struct which takes in a 3 length array for colour and then makes a piece of text with that colour
                            GoalText(colourRGB: [0.0,1.0,0.0], text: "This goal is extremely achievable")
                        }
                        else if calculateFeasibility() > 5 && calculateFeasibility() <= 10 {
                            GoalText(colourRGB: [0.48,0.8,0.35], text: "This goal is very achievable")
                        }
                        else if calculateFeasibility() > 3 && calculateFeasibility() <= 5 {
                            GoalText(colourRGB: [0.6, 0.69, 0.35], text: "This goal is quite achievable")
                        }
                        else if calculateFeasibility() > 1.5 && calculateFeasibility() <= 3 {
                            GoalText(colourRGB: [0.77, 0.54, 0.3], text: "This goal is achievable")
                        }
                        else if calculateFeasibility() >= 1 && calculateFeasibility() <= 1.5 {
                            GoalText(colourRGB: [0.9, 0.43, 0.25], text: "This goal is achievable provided you contribute the majority of your savings to it")
                        }
                        else if calculateFeasibility() >= 0.5 && calculateFeasibility() < 1 {
                            GoalText(colourRGB: [0.92, 0.33, 0.22], text: "This goal may be difficult to achieve if you don't change your spending habits")
                        }
                        else if calculateFeasibility() > 0 && calculateFeasibility() < 0.5 {
                            GoalText(colourRGB: [0.95, 0.25, 0.18], text: "This may be an unrealistic goal for you to set. Consider changing your spending habits or increasing the timeframe available to achieve this goal")
                        }
                        else {
                            GoalText(colourRGB: [1.0,0.0,0.0], text: "Try to achieve a positive balance in this timeframe before you set goals")
                        }
                    }
                    
                    // For deleting - system is identical to the transactions delete
                    Section {
                        // role : .destructive makes the button look like it will delete something.
                        Button(role : .destructive, action : {
                            // When the user wants to delete then display the special alert confirmation, whether it is displayed or not is controlled by this variable
                            confirmationShown = true
                        }, label: {
                            HStack {
                                Text("Delete goal").bold()
                                Spacer()
                                Image(systemName: "trash")
                            }
                        }).confirmationDialog("Are you sure", isPresented: $confirmationShown, actions: {
                            
                            // If user presses this one then the transaction is truly deleted
                            Button(role: .destructive, action: {
                                // From https://stackoverflow.com/questions/24051633/how-to-remove-an-element-from-an-array-in-swift, good because it allows you to retain the original array after removing a certain element.
                                AudioServicesPlayAlertSound(SystemSoundID(4095))
                                SoundPlayer.instance.playSound(soundName: "Scrunch")
                                goals.items = goals.items.filter( {$0 != goal} )
                                confirmationShown = false
                                
                            }, label: {
                                Text("Delete")
                            })
                            
                            // If user presses this one they go back
                            Button(role: .cancel, action: {confirmationShown = false}, label: {
                                Text("Keep")
                            })
                            
                        })
                    }
                    
                    // Basically the same as transactions
                    Section {
                        NavigationLink(destination: {
                            EditGoal(editing: goal,
                                     goalName: goal.name,
                                     goalDate: goal.dueDate,
                                     goalAmount: String(goal.amount),
                                     contributedAmount: goal.amountContributed,
                                     category: goal.category)}
                                       , label: {
                            Text("Edit goal").bold().foregroundColor(.blue)})
                    }
                    
                }
                
                // If the goal has been achieved show this
                else {
                    // Tell the user that it has been achieved
                    Section {
                        Text("This goal has been achieved!").font(.title2)
                    }
                    // Option to delete
                    Section {
                        Button(role : .destructive, action : {
                            confirmationShown = true
                            
                        }, label: {
                            HStack {
                                Text("Delete goal")
                                Spacer()
                                Image(systemName: "trash")
                            }
                        }).confirmationDialog("Are you sure", isPresented: $confirmationShown, actions: {
                            
                            // If user presses this one then the transaction is truly deleted
                            Button(role: .destructive, action: {
                                // From https://stackoverflow.com/questions/24051633/how-to-remove-an-element-from-an-array-in-swift, good because it allows you to retain the original array after removing a certain element.
                                goals.items = goals.items.filter( {$0 != goal} )
                                confirmationShown = false
                                
                                // Play deleting sound effect when it is deleted
                                AudioServicesPlayAlertSound(SystemSoundID(4095))
                                SoundPlayer.instance.playSound(soundName: "Scrunch")
                                
                                
                            }, label: {
                                Text("Delete")
                            })
                            
                            // If user presses this one they go back
                            Button(role: .cancel, action: {confirmationShown = false}, label: {Text("Keep")
                            })
                            
                        })
                        
                    }.navigationTitle(goal.name)
                    
                }
            }
            
            
        }
        
        // Allow the user to contribute to their goal only if there is still anything to contribute to - this contribution will be recorded as a special type of transaction.
        if goal.amount - goal.amountContributed > 0 {
            Section {
                // This button takes the user to the contribution screen
                NavigationLink(destination: GoalContribution(goal: goal), label: {
                    StyledText(text: "Contribute", foreGroundColor: .blue).padding()
                })
            }.navigationTitle(goal.name)
        }
        
    }
}

// Same as little transactions view but less complex cuz we don't deal with recurrence
struct LittleGoalView: View {
    var goal : Goal
    
    var body: some View {
        HStack {
            GoalImage(goal : goal)
            
            VStack(alignment: .leading) {
                Text(goal.name).font(.headline)
                HStack {
                    Text("Date:")
                    Text(goal.dueDate, format: .dateTime.day().month().year())
                }
            }
            Spacer()
            
            if (goal.amount - goal.amountContributed) > 0 {
                Text(goal.amount - goal.amountContributed, format : .currency(code: Locale.current.currencyCode ?? "AUD"))
            }
            else {
                Text("Achieved!")
            }
        }
    }
}


