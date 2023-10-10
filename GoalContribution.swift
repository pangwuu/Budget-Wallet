//
//  GoalContribution.swift
//  Budget Prototype
//
//  Created by Johnny Wu on 17/1/2022.
//

import SwiftUI // Used to build literally everything
import Combine // Used to build
import Foundation // Makes time calculations much easier


// Highly based on the regular transactions view - but we have a few changes - most notably the fact that the goal numbers need to be modified. Indeed, goal contributions are a type of transaction
struct GoalContribution : View {
    
    // This is used to automatically make the user switch back to the view after they finish making the contribution
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var goals : Goals
    @EnvironmentObject var transactions : Transactions
    
    // This is the goal which the contribution is added to
    @State var goal : Goal

    
    // Set up variables with defaults for date, future dates, name, amount and category
    @State private var confirmation = false
    @State private var newDueDate = Date.now
    @State private var futureDates = [Date]()
    @State private var newAmount = ""
    
    // Done to allow the app to know when the keyboard is opened up - so it can present a button to remove the keyboard if needed
    @FocusState private var keyboardFocus : Bool
    
    @ViewBuilder
    var body: some View {
        
        VStack {
            // Title
            Text("Contribute to \(goal.name)").font(.largeTitle)
            
            Form {
                
                // Contribution amount with automatic user input checking
                Section {
                    Text("Amount to contribute").font(.headline)
                    HStack {
                        // The calculation for the amount is basically rounding to 2dp because swift doesn't have its own round function for some odd reason
                        Text("Amount needed to achieve goal:").font(.caption)
                        Spacer()
                        // Used to round to 2dp
                        Text(Int((goal.amount - goal.amountContributed)*100)/100,
                             format : .currency(code: Locale.current.currencyCode ?? "AUD")).font(.caption)
                    }
                    
                    // I did copy this but the general idea is that any user input is automatically checked when it is placed into the TextField (copy pasted data included) - and any value which isn't one of 0123456789. will not be able to be inputted.
                    TextField("Eg. $12", text : $newAmount).focused($keyboardFocus).keyboardType(.decimalPad).modifier(TextFieldClearButton(text: $newAmount)).onReceive(Just(newAmount)) { newValue in
                        let filtered = newValue.filter
                        { "0123456789.".contains($0) }
                        if filtered != newValue {
                            self.newAmount = filtered}
                    }
                }
                
                
                // Get transaction date - only display the date component in the datePicker not the time
                Section {
                    DatePicker("Date of contribution", selection: $newDueDate, displayedComponents: .date)
                }
                
                
                Section {
                    Button(action: {
                        
                        // Add to the array in the transactions class. Many of the attributes have automatically generated values
                        transactions.items.append( Transaction(
                            name: "Contribution to \(goal.name)", // Name is automatically set
                            amount: round( (Double(newAmount) ?? 0) * 100) / 100, // Used for rounding
                            recurring: "Never",
                            dueDate: newDueDate,
                            endDate: Date.now,
                            futureDates: [Date.now.stripTime()],
                            category : "Other",
                            type: false))
                        
                        // This will run the addContribution function which will add the amount to the goal - modifying the "amountContributed" attribute of the specific goal
                        goals.addContribution(goal: goal, amount: round( (Double(newAmount) ?? 0) * 100) / 100)
                        
                        // Show the alert
                        confirmation.toggle()
                        
                        SoundPlayer.instance.playSound(soundName: "Goal_contribution")
                        
                        // Disable the add transaction button if the name, category or amount is empty
                    }, label: {
                        Text("Add contribution")}
                           
                    ).disabled(newAmount.isEmpty).alert("Contribution added", isPresented: $confirmation, actions: {
                        Button("Ok") {
                            dismiss()
                        }
                    }
                                                                        
                    )
                }
                
            }

        }.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    keyboardFocus = false
                }
            }
            
        }
        
    }
}
