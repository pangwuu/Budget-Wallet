//
//  NewGoal.swift
//  Budget Prototype
//
//  Created by Johnny Wu on 25/1/2022.
//

import SwiftUI
import Combine

// This is used to show a little image in the picker where the user will pick the category of their new goal
struct GoalImageName : View {
    
    // Parameters for the height and width for the circular image
    var aHeight = 30.0
    var aWidth = 30.0
    @State var category : String
    
    @Environment(\.colorScheme) var colorScheme
    
    // This function gets the name of the file given the transaction
    func getFileName() -> String {
        let theme = colorScheme == .light ? "_light" : "_dark"
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

// Used for displaying each colour for the goal achievability index
struct GoalText : View {
    
    // Each instance of this is supplied with a three length array of a double between 0 and 1, this determines colour for red, green and blue
    let colourRGB : [Double]
    
    // Text which will be placed
    let text : String
    
    var body : some View {
        // Font adjusts the font,
        Text(text)
            .font(.headline)
            .fixedSize(horizontal: false, vertical: true) // Makes sure that the text won't have ... going after it - its a visual glitch
            .foregroundColor(Color(red: colourRGB[0], green: colourRGB[1], blue: colourRGB[2])) // A colour object takes in three parameters for red green and blue - we supply from outside
    }
}


struct NewGoal : View {
    
    // Need date, amount, name, category, etc
    
    // I'm working on this AFTER I have done most of the back end logic for transactions (which I suspect is more complex than goals anyway). Lots of code will be copied
    
    // Environment objects will share data with both the transactions class - all created from within the contentview struct
    @EnvironmentObject var goals : Goals
    
    // We need the transactions class to calculate the feasibility of the new goal. The app uses data from the transactions data store to calculate the cash flow in the time frame of the goal - this is also reflected in the level 1 and 2 DFDs
    @EnvironmentObject var transactions : Transactions
    
    
    // These are all variables for the new goal, and are automatically updates as a result of the @State property wrapper
    @State private var goalName = ""
    @State private var goalDate = Date.now.stripTime().addingTimeInterval(86400*30) // I made the default due date exactly one month after today's date (.striptime() will set the attributes of time to 12:00am so dates on the same day are treated in the same way
    @State private var goalAmount = ""
    @State private var contributedAmount = 0.0
    
    // This is used to allow the user to disable the keyboard, essentially it tracks whether the keyboard is up.
    @FocusState private var keyboardFocus : Bool
    
    // For the slider. These detect if the user is changing the slider
    @State private var isEditingSlider = false
    
    // This is used to display an alert when the user adds the goal
    @State private var alertShown = false
    
    var categories = ["House", "Car", "Education" ,"Holiday", "Savings", "Investments", "Emergency fund", "Other"]
    @State var category = ""
    
    // This is the function which calculates how achieveable a certain goal is. It is calculated using: total cash inflow / amount required in the goal and is meant to be a simple means to test whether a goal is feasiable or not within a certain time frame
    func calculateFeasibility() -> Double {
        // Exact same function used to display "custom balance" in the transaction menu
        let balance = transactions.getBalance(timePeriod: "Custom", startDate: Date.now.stripTime(), endDate: goalDate)
        // This is the initial amount remaining
        let g = (Double(goalAmount) ?? 0.0) - contributedAmount
        
        if balance < 0 {
            // This inverts the index if its negative, previously a small negative amount would mean a very low achievability index
            return round( ( 1 / ( balance / g ) ) * 100) / 100
        }
        
        return round( ( balance / g ) * 100 ) / 100
    }
    
    @ViewBuilder
    var body: some View {
        Form {
            
            Section {
                Text("Name")
                    .font(.headline)
                    .bold()
                // A textField is a text input which allows the user to enter in some text. the keyboardFocus is utilised in all of them, while the TextFieldClearButton creates a button which allows the user to clear the text. The text in textfield is the transparent gray text which is essentially a prompt.
                // As the text updates the new value is always stored into the goalName variable
                TextField("Eg. A house",  text : $goalName)
                    .focused($keyboardFocus)
                    .modifier(TextFieldClearButton(text: $goalName))
            }
            
            // Transaction amount with automatic user input checking
            Section {
                Text("Amount required").font(.headline)
                
                TextField("Eg. $600", text : $goalAmount)
                    .disabled( Double(goalAmount) ?? 0.0 > 99999999) // Too large of a number will break the whole app so I have to do this - it will disable the textbox if the number gets too big
                    .focused($keyboardFocus)
                    .modifier(TextFieldClearButton(text: $goalAmount))
                     // I did copy this but the general idea is that any user input is automatically checked when it is placed into the TextField (copy pasted data included) - and any value which isn't one of 0123456789. will not be able to be inputted - it will be filtered out automatically. This is also why the amount is a string and not a double
                    .keyboardType(.numberPad).onReceive(Just(goalAmount)) { newValue in
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
                    // A datepicker is a view which allows the user to change the value of a date. For example, the timer app uses datepickers
                    DatePicker(selection: $goalDate, // This is what the data is stored in
                               in : Date.now.stripTime()...Date.distantFuture, // This is the range of dates where the user can actually add something - from now until the year 4000 (that's what distant fututre means)
                               displayedComponents: [.date], // Only the date (no time) component will be shown
                               label: {
                        Text("Pick the date which this goal should be achieved")} )
                    .labelsHidden() // Hides labels but allows Voiceover (accessibility feature) to still act (sort of like alt text on a website)
                }
            }
            
            // Contributed amount using slider and a few stacks
            if goalAmount != "" {
                Section {
                    VStack {
                        HStack {
                            Text("Contributed amount").font(.headline)
                                .dynamicTypeSize(.medium)
                            Text(contributedAmount, format : .currency(code: Locale.current.currencyCode ?? "AUD"))
                                .font(.headline)
                                .padding()
                                .dynamicTypeSize(.medium)
                        }
                        HStack {
                            // Lower bound
                            Text(0, format : .currency(code: Locale.current.currencyCode ?? "AUD"))
                                .dynamicTypeSize(.medium)
                            // A slider is a view which allows the user to input a "continuous" set of data
                            Slider(value: $contributedAmount, // This is the variable that the slider changes
                                   // The lower bound is set to -1.0 because it breaks if the lower bound is set to 0 and the user's amount is also 0. On normally sized goals (>$100) this is unoticeable
                                   in: -1.0...(Double(goalAmount) ?? 1000.0), // Range which can be displayed, consisting of a lower and upper bound. If the program fails to obtain goalAmount it will be automatically set to 1000
                                   step : 1, // Minimum change of the slider - allows all numbers to be rounded to the nearest dollar
                                   onEditingChanged: {
                                isEditingSlider = $0 // Essentially this changes the value and signals to the program that the slider is being slided
                            } )
                            // Upper bound
                            Text(Double(goalAmount) ?? 1000.0, format : .currency(code: Locale.current.currencyCode ?? "AUD"))
                                .dynamicTypeSize(.medium)
                        }
                    }
                }
            }
            
            // Category using picker - it allows the user to pick the category of the goal
            Section {
                
                HStack {
                    
                    Text("Category").font(.headline)
                    Spacer()
                    
                    Picker("", selection: $category, content: {
                        Text("Categories").font(.headline)
                        ForEach(categories, id : \.self) { category in
                            HStack {
                                GoalImageName(category: category) // This displays the image to the left of the text
                                Text(category)
                            }
                        }
                    }).pickerStyle(.automatic) // Modifier which can modify the type of picker
                        .labelsHidden()
                }
            }
            
            
            
            // Display feasibility - have a colour gradient, essentially the more achievable it is the greener it is. It utilises the calculateFeasibility function
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
            
            // Display warning if proper input isn't there - essentially these can't be empty
            if goalName.isEmpty || goalAmount.isEmpty || category.isEmpty || goalDate == Date.now.stripTime() {
                Text("Goal needs a name, amount, category and due date").font(.headline)
                    .bold()
                    .foregroundColor(.red)
                    .padding(1)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Button to append to the list similarly to transactions
            Section {
                Button(action: {
                    // This is what is added to the items array within the goals class - a new goal object with the obtained data
                    goals.items.append(Goal(name: goalName,
                                            dueDate: goalDate.stripTime(),
                                            amount: Double(goalAmount) ?? 0.0,
                                            amountContributed: contributedAmount,
                                            feasibility : calculateFeasibility(),
                                            category : category))
                    
                    // Display alert - .toggle() will switch the value of the boolean variable
                    alertShown.toggle()
                    
                    // Play the sound which indicates the sound
                    SoundPlayer.instance.playSound(soundName: "AddTransactionOrGoal")
                    
                }, label: {
                    
                    Text("Add goal!").font(.headline).bold()
                    
                    // The button is disabled and cannot be used if any of the textfields are empty or if the goal has already been achieved
                }).disabled(goalName.isEmpty ||
                            goalDate == Date.now.stripTime() ||
                            goalAmount.isEmpty ||
                            category.isEmpty ||
                            contributedAmount == Double(goalAmount))
                    // This is the alert that is displyed when the goal is added - just some text
                    .alert("Goal added", isPresented: $alertShown, actions: {
                    Text("Done")
                })
            }
            
            
        }.navigationTitle("Add a goal")
            // What this does is that it places a "done" button on the keyboard which allows the user to get rid of the keyboard by flipping the value of keyboardFocus
            .toolbar {
                // Place it on the keyboard
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    keyboardFocus = false
                }
            }
        }
    }
}


