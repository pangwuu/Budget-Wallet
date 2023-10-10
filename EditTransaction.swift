//
//  EditTransaction.swift
//  Budget Prototype
//
//  Created by Johnny Wu on 12/4/2022.
//

import SwiftUI
import Combine

// Heavily based off the newTransaction struct but it is used for editing a transaction instead of adding a new one - easier to make editing a dedicated page rather than on the transaction itself. This struct is specifically used to edit a transaction - even though it's more accurate to refer to it as a "delete and make new" transaction because that's its process.
struct EditTransaction : View {
    
    // Needed to obatain data from other views
    @EnvironmentObject var transactions : Transactions
    
    // Set up variables with defaults for date, future dates, name, amount and category
        
    // These should ALL be placed into the struct when accessing it.
    @State var editing : Transaction
    @State var confirmation = false
    @State var newDueDate : Date
    @State var futureDates = [Date]()
    @State var recurringType : String
    @State var newName : String
    @State var newAmount : String
    @State var endDate : Date
    @State var newCategory : String
    @State var type : String
    
    func getType() -> Bool {
        type == "Income"
    }
    
    // These are the various selections the user can make for their income, expenses and recurrence. I do this because handling user text is pain
    @State private var examples = ["Income", "Expense"]
    @State private var incomeCategories = ["Wages", "Salary", "Profits", "Capital gains", "Dividends", "Social security", "Rent", "Allowance", "Other"]
    @State private var expensesCategories = ["Rent", "Food", "Groceries", "Entertainment", "Subscriptions", "Transport", "Utilities", "Shopping", "Drinks", "Interest payments", "Savings", "Investments", "Insurance", "Education", "Pets", "Children", "Healthcare", "Other"]
    @State private var recurringTypes = ["Never", "Daily", "Weekly", "Fortnightly", "Monthly", "Yearly"]
    
    // Done to allow the app to know when the keyboard is opened up
    @FocusState private var keyboardFocus : Bool

    
    // Simplify code just a little bit using this
    func modifiedAddTime(startDate : Date, dateC : Calendar.Component, amount : Int) -> Date {
        Calendar.current.date(byAdding: dateC, value: amount , to: startDate)?.stripTime() ?? Date.now.stripTime()
    }
    
    
    // This function will generate an array of dates which will have the dates which a certain recurring transaction will have in the future
    func getFutureDates(startDate : Date, endDate : Date) -> [Date] {
        var startDate = startDate.stripTime()
        let calendar = Calendar.current
        var fDates : [Date] = [startDate]
        let startDateNumber = startDate.get(.day)
        
        // Only will calculate transactions up to the end date (and a bit) in the future. I don't want to caulculate for too long in case if that impacts performance
        
        func addTime(dateC : Calendar.Component, amount : Int) -> Date {
            calendar.date(byAdding: dateC, value: amount , to: startDate)?.stripTime() ?? Date.now.stripTime()
        }
        
        // This was going to fix it by hard setting the date in certain months
        func monthlyAddTime(dateC : Calendar.Component, amount : Int) -> Date {
            
            let checkDate = calendar.date(byAdding: dateC, value: amount , to: startDate)?.stripTime() ?? Date.now.stripTime()
            
            // Get which month we are currently working with
            let monthNumber = startDate.get(.month)
            
            // If the next month has more days, then we have to hard code the day component otherwise it will automatically just add the last day of this month
            if monthNumber == 2 || monthNumber == 4 || monthNumber == 6 || monthNumber == 9 || monthNumber == 11 {
                
                
                let forcedComponent = DateComponents(year: checkDate.get(.year), month : checkDate.get(.month), day: startDateNumber)
                return calendar.date(from: forcedComponent ) ?? Date.now
                
            }
            return checkDate
                        
        }
        
        // You have to add one unit of time to the first date so it doesn't duplicate the first date
        switch recurringType {
        case "Daily":
            startDate = addTime(dateC: .day, amount: 1)
            while startDate <= endDate {
                fDates.append(startDate)
                startDate = addTime(dateC: .day, amount: 1)
            }
        case "Weekly":
            startDate = addTime(dateC: .day, amount: 7)
            while startDate <= endDate {
                fDates.append(startDate)
                startDate = addTime(dateC: .day, amount: 7)
            }
        case "Fortnightly":
            startDate = addTime(dateC: .day, amount: 14)
            while startDate <= endDate {
                fDates.append(startDate)
                startDate = addTime(dateC: .day, amount: 14)
            }
        case "Monthly":
            startDate = addTime(dateC: .month, amount: 1)
            while startDate <= endDate {
                fDates.append(startDate)
                startDate = addTime(dateC: .month, amount: 1)
                
            }

        case "Yearly":
            startDate = addTime(dateC: .year, amount: 1)
            while startDate <= endDate {
                fDates.append(startDate)
                startDate = addTime(dateC: .year, amount: 1)
                
            }
        default :
            // Do nothing
            ()
        }
        return fDates
    }
    
    
    
    @ViewBuilder
    var body: some View {
        
        VStack {
            // Title
            Text("Edit a transaction").font(.largeTitle).bold()
            
            List {
                                
                Section {
                    Text("Name").font(.headline).bold()
                    TextField("Eg. Bananas",  text : $newName).focused($keyboardFocus).modifier(TextFieldClearButton(text: $newName))
                }
                
                // Transaction amount with automatic user input checking
                Section {
                    Text("Amount").font(.headline).bold()
                    
                    // I did copy this but the general idea is that any user input is automatically checked when it is placed into the TextField (copy pasted data included) - and any value which isn't one of 0123456789. will not be able to be inputted.
                    TextField("Eg. $12", text : $newAmount).focused($keyboardFocus).keyboardType(.decimalPad).modifier(TextFieldClearButton(text: $newAmount)).onReceive(Just(newAmount)) { newValue in
                        let filtered = newValue.filter
                        { "0123456789.".contains($0) }
                        if filtered != newValue {
                            self.newAmount = filtered}
                    }
                }
                
                // Whether it is income or an expense
                Section {
                    Text("Type of transaction").font(.headline).bold()
                    Picker("Select the type of your transaction", selection : $type) {
                        ForEach(examples, id : \.self) { type in
                            Text(type)
                        }
                    }
                }.pickerStyle(.segmented)
                
                Section {
                    
                    // Modify the view which is shown based on whether the user has income or expenses selected
                    if type == "Income" {
                        
                        HStack {
                            Text("Category").font(.headline).bold()
                            Spacer()
                            Picker("", selection: $newCategory) {
                                Text("Income").font(.headline)
                                ForEach(incomeCategories, id : \.self) { category in
                                    HStack {
                                        IconImageName(category: category, type: type)
                                        Text(category)
                                    }
                                }
                            }.labelsHidden()
                        }
                    }
                    else {
                        HStack {
                            Text("Category").font(.headline).bold()
                            Spacer()
                            Picker("", selection: $newCategory) {
                                Text("Expenses").font(.headline)
                                ForEach(expensesCategories, id : \.self) { category in
                                    HStack {
                                        IconImageName(category: category, type: type)
                                        Text(category)
                                    }
                                }.labelsHidden()
                            }
                        }
                    }
                }
                
                // Get transaction date - only display the date component in the datePicker not the time
                Section {
                    HStack {
                        // This is a standard form which allows two pieces of text to placed on the same line
                        Text("Transaction date").font(.headline).bold()
                        Spacer()
                        DatePicker("Transaction date", selection: $newDueDate, displayedComponents: .date).labelsHidden()
                    }
                }
                
                // Get how this transaction is recurring (if it is recurring)
                Section {
                    
                    HStack {
                        Text("Recurring type").font(.headline).bold()
                        Spacer()
                        Picker("", selection : $recurringType) {
                            ForEach(recurringTypes, id : \.self) {
                                Text($0)
                            }
                        }.labelsHidden()
                    }
                    
                }
                
                if recurringType != "Never" {
                    Section {
                        HStack {
                            // Need an option for "Never ending"
                            Text("End date").font(.headline).bold().dynamicTypeSize(.medium)
                            Spacer()
                            // For some ridiculous reason the regular VStack wouldn't work here, it would just make the entire row a very thin horizontal line. So I made it a LazyVstack instead
                            LazyVStack {
                                DatePicker("End date", selection: $endDate, in : newDueDate.stripTime().addingTimeInterval(86400)...Date.now.stripTime().addingTimeInterval(86400*365.25*12), displayedComponents: .date).labelsHidden().dynamicTypeSize(.medium)
                                Text("OR").font(.caption).dynamicTypeSize(.medium)
                                // This is the button to provide a "never ending" option to the user for any recurring transaction. It doesn't actually make it "never" because that will require a massive rework in the code (and may impact performance), but instead I decided to just add twelve years to the end date because its as good as forever... most people can't guarantee income for ten years so there's really not much use going any further than that)
                                // Like home loan repayments are the only thing that will last > 12 years.
                                Button(action: {
                                    endDate =  Calendar.current.date(byAdding: .year, value: 12 , to: endDate)?.stripTime() ?? Date.now.stripTime()
                                }) {
                                    Text("Never ending").foregroundColor(.blue).font(.headline).bold()
                                }.disabled(endDate >= Date.now.stripTime().addingTimeInterval(86400*365.25*12)).buttonStyle(PlainButtonStyle()).dynamicTypeSize(.medium)
                                // offset is needed because it will shift the LazyVStack to the right (a regular VStack won't need it)
                            }.offset(x : 73)
                        }
                    }
                }
                
                // This section is made up of a bunch of conditional alerts could be displayed
                Section {
                    // Display this alert if any of the required categories is empty
                    if newName.isEmpty || newCategory.isEmpty || newAmount.isEmpty || recurringType.isEmpty {
                        Text("Transaction needs a name, category, amount and recurring type").frame(alignment : .center).foregroundColor(.red).font(.headline).fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Display this alert if the transacion type doesn't match with category, ie if the user selected "income" as the type but "food" as the category it won't be able to add it. If this is displayed the button to add a transaction is also disabled
                    // But this alert is disabled if the category is "rent" or "other" because these two are part of both income and expenses
                    if getType() == true && (newCategory != "Other" && newCategory != "Rent") {
                        if expensesCategories.contains(newCategory) {
                            Text("Transaction type doesn't match with category!").frame(alignment : .center).foregroundColor(.red).font(.headline)
                        }
                    }
                    if getType() == false && (newCategory != "Other" && newCategory != "Rent") {
                        if incomeCategories.contains(newCategory) {
                            Text("Transaction type doesn't match with category!").frame(alignment : .center).foregroundColor(.red).font(.headline)
                        }
                    }
                    
                    // If user places the date before the end date show an error
                    if newDueDate >= endDate && recurringType != "Never" {
                        Text("Transaction date needs to be before the end date").frame(alignment : .center).foregroundColor(.red).font(.headline)
                    }
                
                    // If the user places the end date too far it may cause performance issues. This alert is shown if they do this
                    if endDate >= Date.now.stripTime().addingTimeInterval(86400*365.25*121/10) {
                        Text("Date is too far in the future").frame(alignment : .center).foregroundColor(.red).font(.headline)
                    }
                    
                }
                

                
                Section {
                    Button(action: {
                        
                        // Play a sound
                        SoundPlayer.instance.playSound(soundName: "AddTransactionOrGoal")

                        
                        // Replace a new Transaction object to the transactions array in the stored class with all the information I just provided it. So essentially the add transaction but instead of adding we are replacing
                        if recurringType != "Never" {
                            transactions.items.replace(editing, with: Transaction(name: newName, amount: round((Double(newAmount) ?? 0)), recurring: recurringType, dueDate: newDueDate.stripTime(), endDate: endDate.stripTime(), futureDates: getFutureDates(startDate: newDueDate.stripTime(), endDate: endDate.stripTime()), category : newCategory, type: getType()))
                        }
                        // Used to fix a bug which occurs if user tries to change a date on a non recurring transaction
                        else {
                            transactions.items.replace(editing, with: Transaction(name: newName, amount: round((Double(newAmount) ?? 0)), recurring: recurringType, dueDate: newDueDate.stripTime(), endDate: newDueDate.stripTime().addingTimeInterval(86400), futureDates: getFutureDates(startDate: newDueDate.stripTime(), endDate: endDate.stripTime()), category : newCategory, type: getType()))
                        }
                        
                        // Show the alert
                        confirmation.toggle()
                        
                        // This phrase is only intended to be used when editing a transaction - it will delete the OLD transaction from the items by using the filter function

                        // Disable the add transaction button if the name, category or amount is empty
                    }, label: {
                        Text("Confirm edits").font(.headline)}
                    ).disabled(newName.isEmpty
                               || newCategory.isEmpty
                               || newAmount.isEmpty
                               || recurringType.isEmpty
                               || (getType() == true && expensesCategories.contains(newCategory))
                               || (getType() == false && incomeCategories.contains(newCategory)
                               || endDate > Date.now.stripTime().addingTimeInterval(86400*365.25*121/10) ) ).alert("Done", isPresented: $confirmation, actions: {
                        
                        // Two options - one cancels the adding and the other will accept it NOT DONE
                        
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

