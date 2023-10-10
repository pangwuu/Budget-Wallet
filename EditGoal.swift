//
//  EditGoal.swift
//  Budget Prototype
//
//  Created by Johnny Wu on 12/4/2022.
//

import SwiftUI
import Combine

// This is basically the same as the NewGoal transaction except that it takes in existing values instead of just empty ones
struct EditGoal : View {
        
    // Environment objects will share data with both the transactions class - all created from within the contentview struct
    @EnvironmentObject var goals : Goals
    @EnvironmentObject var transactions : Transactions
    
    // This is the goal which will be replaced
    @State var editing : Goal
    
    @State var goalName : String
    @State var goalDate : Date
    @State var goalAmount : String
    @State var contributedAmount : Double
    
    @FocusState private var keyboardFocus : Bool
    
    // For the slider
    @State private var isEditingSlider = false
    @State private var alertShown = false
    
    var categories = ["House", "Car", "Education" ,"Holiday", "Savings", "Investments", "Emergency fund", "Other"]
    
    @State var category : String
    
    // This is the function which calculates how achieveable a certain goal is. It is calculated using total cash inflow / amount required in the goal and is meant to be a simple means to test whether a goal is feasiable or not
    func calculateFeasibility() -> Double {
        let balance = transactions.getBalance(timePeriod: "Custom", startDate: Date.now.stripTime(), endDate: goalDate)
        let g = (Double(goalAmount) ?? 0.0) - contributedAmount
        return round( (balance/g) * 100 )/100
    }
    
    @ViewBuilder
    var body: some View {
        Form {
            
            Section {
                Text("Name").font(.headline).bold()
                TextField("Eg. An avocado",  text : $goalName).focused($keyboardFocus).modifier(TextFieldClearButton(text: $goalName))
            }
            
            // Transaction amount with automatic user input checking
            Section {
                Text("Amount required").font(.headline)
                
                // I did copy this but the general idea is that any user input is automatically checked when it is placed into the TextField (copy pasted data included) - and any value which isn't one of 0123456789. will not be able to be inputted - it will be filtered out
                TextField("Eg. $600", text : $goalAmount)
                    .focused($keyboardFocus)
                    .modifier(TextFieldClearButton(text: $goalAmount))
                    .keyboardType(.numberPad)
                    .disabled( Double(goalAmount) ?? 0.0 > 99999999)
                    .onReceive(Just(goalAmount)) { newValue in
                    let filtered = newValue.filter
                    { "0123456789".contains($0) }
                    if filtered != newValue {
                        self.goalAmount = filtered}
                }
            }
            
            // Get due date - restricted to dates AFTER today
            Section {
                HStack {
                    Text("Due date of goal").font(.headline)
                    Spacer()
                    DatePicker(selection: $goalDate, in : Date.now.stripTime()...Date.distantFuture, displayedComponents: [.date], label: {
                        Text("Pick the date which this goal should be achieved")} ).labelsHidden()
                }
            }
            
            // Contributed amount using slider and a few stacks
            if goalAmount != "" {
                Section {
                    VStack {
                        HStack {
                            Text("Contributed amount").font(.headline)
                            Text(contributedAmount, format : .currency(code: Locale.current.currencyCode ?? "AUD")).font(.headline).padding()
                        }
                        HStack {
                            Text(0, format : .currency(code: Locale.current.currencyCode ?? "AUD"))
                            Slider(value: $contributedAmount, in: -1.0...(Double(goalAmount) ?? 1000), step : 1, onEditingChanged: {
                                isEditingSlider = $0
                            } )
                            Text(Double(goalAmount) ?? 1000.0, format : .currency(code: Locale.current.currencyCode ?? "AUD"))
                        }
                    }
                }
            }
            
            // Category using picker
            Section {
                
                HStack {
                    Text("Category").font(.headline)
                    Spacer()
                    Picker("", selection: $category, content: {
                        Text("Categories").font(.headline)
                        ForEach(categories, id : \.self) { category in
                            HStack {
                                GoalImageName(category: category)
                                Text(category)
                            }
                        }
                    }).pickerStyle(.automatic).labelsHidden()
                }
            }
            

            
            // Display feasibility - have a colour gradient
            if goalAmount != "" {
                Section {
                    HStack {
                        Text("Achievability rating").bold()
                        Spacer()
                        Text(calculateFeasibility(), format: .number)
                    }
                    if calculateFeasibility() > 10 {
                        GoalText(colourRGB: [0.0,0.8,0.0], text: "This goal is extremely achievable")
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
                        GoalText(colourRGB: [0.8,0.0,0.0], text: "Try to achieve a positive balance in this timeframe before you set goals")
                    }
                }
            }
            
            // Display alert if proper input isn't there
            if goalName.isEmpty || goalAmount.isEmpty || category.isEmpty || goalDate == Date.now.stripTime() {
                Section {
                    Text("Goal needs a name, amount, category and due date").font(.headline).bold().foregroundColor(.red).padding(1)
                }
            }
            
            // Button to append to the list similarly to transactions
            Section {
                Button(action: {
                    // Instead of appending a goal it will replace it instead, which will
                    goals.items.replace(editing, // This is the variable which will be replaced
                                        with : Goal(
                                            name: goalName,
                                            dueDate: goalDate.stripTime(),
                                            amount: Double(goalAmount) ?? 0.0,
                                            amountContributed: contributedAmount,
                                            feasibility : calculateFeasibility(),
                                            category : category)
                    )
                    
                    // Play the sound
                    SoundPlayer.instance.playSound(soundName: "AddTransactionOrGoal")
                    alertShown.toggle()
                }, label: {
                    Text("Add goal!").font(.headline).bold()
                }).disabled(goalName.isEmpty ||
                            goalDate == Date.now.stripTime() ||
                            goalAmount.isEmpty ||
                            category.isEmpty ||
                            contributedAmount == Double(goalAmount)).alert("Goal edited", isPresented: $alertShown, actions: {
                    Text("Done")
                })
            }
            
            
        }.navigationTitle("Edit a goal").toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    keyboardFocus = false
                }
            }
            
        }
    }
}
