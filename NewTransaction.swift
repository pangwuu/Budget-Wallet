//
//  NewTransaction.swift
//  Budget Prototype
//
//  Created by Johnny Wu on 17/1/2022.
//

import SwiftUI // Used to build literally everything
import Combine // Used to build something?
import Foundation // Makes time calculations much easier

extension Date {
    
    // From https://stackoverflow.com/questions/35771506/is-there-a-date-only-no-time-class-in-swift-or-foundation-classes/48941271. Used to make sure that we only store the date (not time) when calculating recurring transactions. This makes it possible to compare transactions from a particular day or week - because swift stores date objects to the nearest nanosecond (i think). An extension is a custom function that extends functionality of an existing or custom class/struct
    func stripTime() -> Date {
        // Break apart components
        let components = Calendar.current.dateComponents([.year, .month, .day], from: self)
        let date = Calendar.current.date(from: components)
        return date!
    }
    // From https://stackoverflow.com/questions/53356392/how-to-get-day-and-month-from-date-type-swift-4. This will get one componnent from a date, such as a date or a month, which is needed later
    func get(_ components: Calendar.Component..., calendar: Calendar = Calendar.current) -> DateComponents {
        return calendar.dateComponents(Set(components), from: self)
    }
    // This will get one componnent from a date, such as a date or a month, which is needed later
    func get(_ component: Calendar.Component, calendar: Calendar = Calendar.current) -> Int {
        return calendar.component(component, from: self)
    }
    
}

// Stolen from https://sanzaru84.medium.com/swiftui-how-to-add-a-clear-button-to-a-textfield-9323c48ba61c. This creates a little button on the right of a textfield which deletes all the user text within it. The reason I found this was necessary is because it is typically intuitive in most mobile apps and text forms - these little things matter significantly
struct TextFieldClearButton: ViewModifier {
    @Binding var text: String
    
    func body(content: Content) -> some View {
        HStack {
            // I think this is flexible
            content
            
            // only display if text is not empty
            if !text.isEmpty {
                Button (
                    // This will remove all text by replacing the entered text with an empty string
                    action: { self.text = "" },
                    label: {
                        // The displayed image is a system image
                        Image(systemName: "delete.left")
                            .foregroundColor(Color(UIColor.opaqueSeparator))
                    }
                )
            }
        }
    }
}

// Exactly the same but now it takes a category as input as a string
struct IconImageName : View {
    
    var category : String
    var type : String
    
    @Environment(\.colorScheme) var colorScheme
    
    // This function gets the name of the file given the transaction
    func getFileName() -> String {
        
        if type == "Income" {
            // I had to do this by cases because I don't have a seperate image for each type of income
            if category == "Social security" {
                return colorScheme == .light ? "Social_security_light" : "Social_security_dark"
            }
            else if category == "Capital gains" {
                return colorScheme == .light ? "Capital_gains_light" : "Capital_gains_dark"
            }
            else if category == "Rent" {
                return category + (colorScheme == .light ? "_light_income" : "_dark_income")
            }
            else if category == "Other" {
                return colorScheme == .light ? "Income_light": "Income_dark"
            }
            return category + (colorScheme == .light ? "_light" : "_dark")
        }
        
        else {
            if category == "Interest payments" {
                return colorScheme == .light ? "Interest_payments_light" : "Interest_payments_dark"
            }
            
            let name = category
            let theme = colorScheme == .light ? "_light" : "_dark"
            
            return name + theme
        }
    }
    
    var body: some View {
        // This is the actual image
        Image(getFileName()).resizable().scaledToFit().clipShape(Circle()).frame(width: 30, height: 30)
    }
}

struct NewTransaction : View {
    
    // Needed to obatain data from other views
    @Environment(\.presentationMode) var presentationMode
    @State private var showingDeleteAlert = false
    
    @EnvironmentObject var transactions : Transactions
    
    // Set up variables with defaults for date, future dates, name, amount and category
    @State var confirmation = false
    
    // This is just the date of which the transaction takes place - don't know why its so poorly names
    @State var newDueDate = Date.now.stripTime()
    // FutureDates is an array of dates which stores ALL dates of the transaction
    @State var futureDates = [Date]()
    
    // These control the recurrence of the transaction. The user's selection is recorded in recurring type and it can be picked from any variable in recurringTypes
    @State var recurringType = "Never"
    @State private var recurringTypes = ["Never", "Daily", "Weekly", "Fortnightly", "Monthly", "Yearly"]

    @State var newName = ""
    @State var newAmount = ""
    @State var endDate = Date.now.addingTimeInterval(86400).stripTime()
    
    @State var newCategory = ""
    @State var type = ""
    
    // These are the various selections the user can make for their income, expenses and recurrence. I do this because handling user text is pain
    @State private var examples = ["Income", "Expense"]
    @State private var incomeCategories = ["Wages", "Salary", "Profits", "Capital gains", "Dividends", "Social security", "Rent", "Allowance", "Other"]
    @State private var expensesCategories = ["Rent", "Food", "Groceries", "Entertainment", "Subscriptions", "Transport", "Utilities", "Shopping", "Drinks", "Interest payments", "Savings", "Investments", "Insurance", "Education", "Pets", "Children", "Healthcare", "Other"]
    
    // Done to allow the app to know when the keyboard is opened up
    @FocusState private var keyboardFocus : Bool
    
    // Return a boolean value because it is stored as that
    func getType() -> Bool {
        type == "Income"
    }
    
    // Simplify code just a little bit using this. Essentially this function will add a certain amount of time to a date - it will make more sense later
    func modifiedAddTime(startDate : Date, dateC : Calendar.Component, amount : Int) -> Date {
        Calendar.current.date(byAdding: dateC, value: amount , to: startDate)?.stripTime() ?? Date.now.stripTime()
    }
    
    
    // This function will generate an array of dates which will have the dates that a certain recurring transaction will have in the future
    func getFutureDates(startDate : Date, endDate : Date) -> [Date] {
        
        // Fist date
        var startDate = startDate.stripTime()
        let startDateReference = startDate.stripTime()
        // Used for monthly transactions
        let startDateNumber = startDateReference.stripTime().get(.day)
        
        let calendar = Calendar.current
        
        // this is the date where it will take place
        var fDates : [Date] = [startDate]
                
        // This is the modifiedAddTime function with amount set to 1 as transactions recurr every 1 set of something
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
                // Hardcoded date which is added
                let forcedComponent = DateComponents(year: checkDate.get(.year), month : checkDate.get(.month), day: startDateNumber)
                return calendar.date(from: forcedComponent ) ?? Date.now
                
            }
            return checkDate
                        
        }

        // You have to add one unit of time to the first date so it doesn't duplicate the first date
        switch recurringType {
        case "Daily":
            
            startDate = addTime(dateC: .day, amount: 1)
            // End at (or before) the end date
            while startDate <= endDate {
                // add the date to the array of future dates
                fDates.append(startDate)
                // add one date to the startDate
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
        // Use a different function when adding months to avoid the issue of the date being changed if the month after the first one has less days than the initial month.
        case "Monthly":
            startDate = monthlyAddTime(dateC: .month, amount: 1)
            while startDate <= endDate {
                fDates.append(startDate)
                startDate = monthlyAddTime(dateC: .month, amount: 1)
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
    
    // The actual view starts here
    @ViewBuilder
    var body: some View {
        
        VStack {
            // Title
            Text("Add a transaction").font(.largeTitle).bold()
            
            List {
                
                // Transaction name
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
                
                // Whether it is income or an expense. This takes the place of a regular picker (but with two options)
                Section {
                    Text("Type of transaction").font(.headline).bold()
                    Picker("Select the type of your transaction", selection : $type) {
                        ForEach(examples, id : \.self) { type in
                            Text(type)
                        }
                    }
                }.pickerStyle(.segmented) // This makes the picker appear as a series of horizontal radio buttons
                
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
                            .dynamicTypeSize(.medium)
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
                
                // Only appears if the transaction is recurring in some way. This allows the user to set when the goal will end (like car repayments for example)
                if recurringType != "Never" {
                    Section {
                        HStack {
                            Text("End date").font(.headline).bold()
                                .dynamicTypeSize(.medium)
                            Spacer()
                            
                            // For some ridiculous reason the regular VStack wouldn't work here, it would just make the entire row a very thin horizontal line. So I made it a LazyVstack instead
                            LazyVStack {
                                // Select end date
                                DatePicker("End date", selection: $endDate, in : (newDueDate.stripTime().addingTimeInterval(86400)...Date.distantFuture), displayedComponents: .date).labelsHidden()
                                    .dynamicTypeSize(.medium)
                                
                                Text("OR").font(.caption)
                                    .dynamicTypeSize(.medium)
                                
                                // This is the button to provide a "never ending" option to the user for any recurring transaction. It doesn't actually make it "never" because that will require a massive rework in the code (and may impact performance), but instead I decided to just add twelve years to the end date because its as good as forever... most people can't guarantee income for ten years so there's really not much use going any further than that)
                                // Like home loan repayments are the only thing that will last > 12 years.
                                Button(action: {
                                    endDate =  Calendar.current.date(byAdding: .year, value: 12 , to: endDate)?.stripTime() ?? Date.now.stripTime()
                                }) {
                                    Text("Never ending").foregroundColor(.blue).font(.headline).bold()
                                    // if endDate is too great (>12 years) it will be disabled
                                }.disabled(endDate >= Date.now.stripTime().addingTimeInterval(86400*365.25*12)).buttonStyle(PlainButtonStyle())
                                    .dynamicTypeSize(.medium)
                                
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
                    if newDueDate >= endDate {
                        Text("Transaction date needs to be before the end date").frame(alignment : .center).foregroundColor(.red).font(.headline)
                    }
                
                    // If the user places the end date too far it may cause performance issues. This alert is shown if they do this
                    if endDate >= Date.now.stripTime().addingTimeInterval(86400*365.25*121/10) {
                        Text("Date is too far in the future").frame(alignment : .center).foregroundColor(.red).font(.headline)
                    }
                    
                }

                
                    // Button to add transaction
                    Button (

                        action: {
                        // Add a new Transaction object to the transactions array in the stored class with all the information I just provided it
                        transactions.items.append(
                            Transaction(name: newName,
                                        amount: round( (Double(newAmount) ?? 0) * 100) / 100,
                                        recurring: recurringType, dueDate: newDueDate.stripTime(),
                                        endDate: endDate.stripTime(),
                                        futureDates: getFutureDates(startDate: newDueDate.stripTime(), // This is where we use the getFutureDates function is used - the future dates is computed when we run it here
                                        endDate: endDate.stripTime()),
                                        category : newCategory,
                                        type: getType()))
                        
                        // Show the alert
                        confirmation.toggle()
                        
                        // Play a sound using the Soundplayer class
                        SoundPlayer.instance.playSound(soundName: "AddTransactionOrGoal")
                        
                        // Disable the add transaction button if the name, category or amount is empty, or if the transaction type doesn't match with the catehory. This is ignored if the category is "rent" or "other" because they can be both income or expenses
                    }, label: {
                        Text("Add transaction").font(.headline)
                        
                        // The button is disabled IF
                    }).disabled(newName.isEmpty ||
                                newCategory.isEmpty ||
                                newAmount.isEmpty || // Any of these are empty OR
                                recurringType.isEmpty ||
                                endDate < newDueDate ||
                                (getType() == true && newCategory != "Other" && expensesCategories.contains(newCategory) && newCategory != "Rent") || // The type doesn't match the category OR
                                (getType() == false && newCategory != "Other" && newCategory != "Rent" && incomeCategories.contains(newCategory)) ||
                                endDate > Date.now.stripTime().addingTimeInterval(86400*365.25*121/10)) // The end date is set to far into the future
                        
                    .alert("Transaction added", isPresented: $confirmation, actions: {
                        // Two options - one cancels the adding and the other will accept it NOT DONE
                        Text("Done")
                        
                    }
                    )
                    
                
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



// From https://stackoverflow.com/questions/38084406/find-an-item-and-change-value-in-custom-object-array-swift - used to edit an object in an array. Works by just replacing the old one with the new one. The extension extends functionality of an existing struct, in this case any array which has equatable elements, and adds a new insance method
extension Array where Element: Equatable {
    @discardableResult
    
    // This is the added method - mutating gives it the ability to change the contents of the instance of any array. Two parameters, the old and new element
    public mutating func replace(_ element: Element, with new: Element) -> Bool {
        if let f = self.firstIndex(where: { $0 == element}) {
            // Replace the old method with the new one
            self[f] = new
            return true
        }
        return false
    }
}
