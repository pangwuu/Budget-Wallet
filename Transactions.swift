//
//  Transactions.swift
//  Budget Prototype
//
//  Created by Johnny Wu on 17/1/2022.
//


// What does this library do?
import SwiftUI
import AVFoundation

// This is used later - essentially if a function returns this specific
let globalCheckDate = Calendar.current.date(from: DateComponents(era : 1, year: 882, month: 2, day: 6, minute: 7, second: 23, nanosecond: 8374))

// These are three frameworks for the data type Transaction. The detailed view is a singular view showing all the details of the transaction, the Transaction itself is just the core data while the LittleTransactionView is placed in a list
// There are three frameworks used for UI/support for transactions. allTransactioDates allows the user to see all the transaction dates of their transaction, and IconImage is just a struct which takes a transaction as its input and displays the transaction's category as an image as output

// Codable and identifiable are needed to allow the transaction to be used in a picker AND for the transactions to be able to be converted to JSON -- needed to put them in coreData so it is actually stored when the user quits the app
struct Transaction : Identifiable, Codable, Equatable, Hashable {
    
    
    // Transactions have all these variables
    
    var name : String
    var amount : Double
    // Need to add functionality to recurring transactions - this shows how much it is recurring
    var recurring : String
    // This is the date of the initial transaction
    var dueDate : Date
    // This is the end date of the transaction - only really useful if it's recurring
    var endDate : Date
    // This is an array of dates, each of which is a date where the transaction will take place
    var futureDates : [Date]
    var category : String
    // true for inflow, false for outflow
    let type : Bool
    
    // Used to display the next transaction date in the littleTransactionView
    func getNextTransactionDate() -> Date {
        
        // Essentially if today's date is less than the end date of the transaction then return a check date, which signals that the recurring transaction will never recu again
        for date in futureDates {
            if date >= Date.now.stripTime() {
                return date
            }
        }
        return globalCheckDate ?? Date.now
    }
    
    // This obtains the index of a certain date.
    func nextTransactionDateIndex() -> Int {
        for i in 0...10000 {
            if self.futureDates[i] == self.getNextTransactionDate() {
                return i
            }
        }
        // If there are no more transactions after this one (aka this is the last transaction) then return -1
        return -1
    }
    
    
    // This is a unique identifier of type UUID() which allows each transaction to always be differentiated from another
    var id = UUID()
    
}


// Extremely simple view which takes a transaction as input and displays a list of all the transaction dates with any recurring transaction. It is NOT used for non-recurring transactions as it has no use then
struct AllTransactionDates : View {
    
    var transaction : Transaction
    
    var body: some View {
        Text("All transaction dates")
            .font(.headline)
            .bold()
        
        // A scrollView is a view that, you guessed it, you can scroll through
        ScrollView {
            // Using LazyVStack massively improves performance on large arrays - it will load in the contents of the entire array as the user is scrolling through it. More here https://www.hackingwithswift.com/quick-start/swiftui/how-to-lazy-load-views-using-lazyvstack-and-lazyhstack
            LazyVStack {
                ForEach(transaction.futureDates, id : \.self) {futureDate in
                    // Using the format parameter allows us to display dates cleanly
                    Text(futureDate, format: .dateTime.day().month().year())
                }
            }
        }
    }
}

// This new view puts JUST the image in a circular shape
struct IconImage : View {
    
    // This is the transaction which will be displayed
    var transaction : Transaction
    var width = 40.0
    var height = 40.0
    
    // This variable tracks whether the user is in light or dark mode. From https://betterprogramming.pub/how-to-detect-light-and-dark-modes-in-swiftui-eef21ba4d11d
    
    @Environment(\.colorScheme) var colorScheme
    
    // This function gets the name of the file given the transaction. It works similarly to other ones from before
    func getFileName() -> String {
        if transaction.type == true {
            
            // I had to do this by cases because I don't have a seperate image for each type of income
            if transaction.category == "Social security" {
                return colorScheme == .light ? "Social_security_light" : "Social_security_dark"
            }
            else if transaction.category == "Capital gains" {
                return colorScheme == .light ? "Capital_gains_light" : "Capital_gains_dark"
            }
            else if transaction.category == "Rent" {
                return transaction.category + (colorScheme == .light ? "_light_income" : "_dark_income")
            }
            else if transaction.category == "Other" {
                return colorScheme == .light ? "Income_light": "Income_dark"
            }
            return transaction.category + (colorScheme == .light ? "_light" : "_dark")
        }
        
        else {
            if transaction.category == "Interest payments" {
                return colorScheme == .light ? "Interest_payments_light" : "Interest_payments_dark"
            }
            let name = transaction.category
            let theme = colorScheme == .light ? "_light" : "_dark"
            return name + theme
        }
    }
    
    var body: some View {
        Image(getFileName())
            .resizable()
            .scaledToFit()
            .clipShape(Circle())
            .frame(width: width, height: height)
        
    }
}


// This is the view which is found when you look for details on a particular transaction ie when you tap one on the transactions menu
struct TransactionViewDetailed : View {
    
    // This converts the type back into a string
    func typeBoolToString() -> String {
        if transaction.type == true {
            return "Income"
        }
        return "Expense"
    }
    
    @EnvironmentObject var transactions : Transactions
    var transaction : Transaction
    
    // For when the user deletes - see more below
    @State private var confirmationShown = false
    
    @ViewBuilder
    var body: some View {
        
        VStack {
            
            List {
                // Display the amount
                Section {
                    HStack {
                        Text("Amount").font(.title)
                            .bold()
                        Spacer()
                        // .currency(code: Locale.current.currencyCode ?? "AUD")).font(.title) will obtain the user's currency. If there is no currency it will default back into AUD
                        Text(transaction.amount, format : .currency(code: Locale.current.currencyCode ?? "AUD")).font(.title)
                    }
                    
                }
                
                // Display category with an image
                Section {
                    HStack {
                        VStack {
                            Text("CATEGORY")
                                .font(.caption)
                                .frame(alignment : .leading)
                            Text(transaction.category) // This is the category of the specific transaction that was inputted in the struct
                                .font(.title)
                                .bold()
                        }
                        Spacer()
                        VStack {
                            IconImage(transaction: transaction, width: 60, height: 60)
                            Text(transaction.type == true ? "INCOME" : "EXPENSE")
                                .font(.caption)
                                .frame(alignment : .leading)
                        }
                    }
                    
                    
                }
                
                // For the transaction date and next transaction
                Section {
                    HStack {
                        VStack {
                            Text("TRANSACTION DATE").font(.caption)
                            Text(transaction.dueDate, format : .dateTime.day().month().year())
                                .bold()
                                .font(.headline)
                        }
                        Spacer()
                        VStack {
                            // If there are no more transactions then display "Never"
                            Text("NEXT TRANSACTION").font(.caption)
                            if transaction.getNextTransactionDate() == globalCheckDate {
                                Text("Never").bold()
                                    .font(.headline)
                            }
                            // If there are then display the next date the transaction occurs
                            else {
                                Text(transaction.getNextTransactionDate(), format: .dateTime.day().month().year())
                                    .bold()
                                    .font(.headline)
                            }
                        }
                    }
                }
                
                // show whether the transaction is recurring
                Section {
                    if transaction.recurring != "Never" {
                        HStack {
                            Text("Repeating").font(.headline).bold()
                            Spacer()
                            // This is how often it repeats, such as "weekly", "Monthly" etc
                            Text("\(transaction.recurring.uppercased())")
                        }
                    }
                    else {
                        Text("Not repeating").font(.headline).bold()
                    }
                }
                
                // Only display this if the transaction is occuring in some way
                if transaction.recurring != "Never" {
                    Section {
                        HStack {
                            Text("Ending on").font(.headline)
                                .bold()
                            Spacer()
                            Text(transaction.endDate, format : .dateTime.day().month().year())
                        }
                    }
                    
                    // Button to see all the dates the transaction takes place
                    Section {
                        NavigationLink(destination : {
                            AllTransactionDates(transaction: transaction)
                        }, label : {
                            Text("See all transaction dates").font(.headline)
                        })
                    }
                }

                // This takes you to the edit button
                Section {
                    // The Edit transaction view takes in a bunch of variables - as they are by default filled in by data which is automatically filled in.
                    NavigationLink(destination : {
                        EditTransaction(editing: transaction,
                                        newDueDate: transaction.dueDate,
                                        futureDates: transaction.futureDates,
                                        recurringType: transaction.recurring,
                                        newName: transaction.name,
                                        newAmount: String(round( (Double(transaction.amount) * 100)) / 100 ),
                                        endDate: transaction.endDate,
                                        newCategory: transaction.category,
                                        type: typeBoolToString())
                    }, label : {
                        Text("Edit transaction")
                            .bold()
                            .foregroundColor(.blue)
                    })
                }
                
                // For deleting transactions
                Section {
                    // Buttons take an action and a label. The action is what happens when it is pressed and the label is what is displayed on screen
                    Button(role : .destructive, action: {
                        confirmationShown.toggle()
                    }, label: {
                        HStack {
                            Text("Delete transaction")
                                .font(.headline)
                                .foregroundColor(.red)
                                .bold()
                            Spacer()
                            Image(systemName: "trash")
                        }
                        
                        // Code for confirmation inspired from https://swiftwithmajid.com/2021/07/28/confirmation-dialogs-in-swiftui/ - we use something special called "confirmation dialog" to display something before the user delets something important.
                        // Using isPresented is the variable which declares whether the alert is presented or not.
                    }).confirmationDialog("Are you sure", isPresented: $confirmationShown, actions: {
                        
                        // Two buttons are presented, if user presses this one then the transaction is truly deleted. .destructive makes the button look as if it is of a destructive nature
                        Button(role: .destructive, action: {
                            // From https://stackoverflow.com/questions/24051633/how-to-remove-an-element-from-an-array-in-swift, good because it allows you to retain the original array after removing a certain element. It uses the filter function, where it loops through every element in transactions.items, and if its NOT the transaction it will be kept. ie the transaction will be deleted
                            transactions.items = transactions.items.filter( {$0 != transaction} )

                            AudioServicesPlayAlertSound(SystemSoundID(4095)) // Vibrates the phone
                            SoundPlayer.instance.playSound(soundName: "Scrunch") // Play the sound using SoundPlayer
                        }, label: {
                            Text("Delete")
                        })
                        
                        // If this is pressed then the thing is kept
                        Button(role: .cancel, action: {}, label: {
                            Text("Keep")
                        })
                    })
                    
                }
                
            }
            
        }.navigationTitle(transaction.name)
        
    }
}

// This is the view which is in the AtAGlance page, featuring conditional colours (wow!). The transactions menu is made up of a list of these
struct LittleTransactionView: View {
    
    // Get user colourscheme - light or dark mode
    @Environment(\.colorScheme) var colorScheme
    
    var transaction : Transaction
    
    // Allows us to create conditional views
    @ViewBuilder
    var body: some View {
        
        HStack {
            
            HStack {
                
                // Show the image which will take a transaction and spit out the image which is of the category of the transaction
                IconImage(transaction: transaction)
                
                VStack(alignment: .leading) {
                    
                    Text(transaction.name).bold()
                    HStack {
                        
                        // This is all used to customise which text is shown based on certain conditions - whether the transaction is recurring or not, and if its recurring, whether the end recurring date is before the beginning.
                        if transaction.recurring != "Never" {
                            Text("Next:")
                            if transaction.getNextTransactionDate() == globalCheckDate {
                                Text("Never")
                            }
                            
                            else {
                                if transaction.getNextTransactionDate() == Date.now.stripTime() {
                                    Text("Today")
                                }
                                else {
                                    Text(transaction.getNextTransactionDate(), format: .dateTime.day().month())
                                }
                            }
                        }
                        
                        else {
                            Text("Date:")
                            Text(transaction.dueDate, format: .dateTime.day().month())
                        }
                        
                    }
                }
                
                if transaction.recurring != "Never" {
                    Image(systemName: "repeat")
                }
                
            }
            
            Spacer()
            Text(transaction.amount, format : .currency(code: Locale.current.currencyCode ?? "AUD"))
            
        }.foregroundColor(transaction.type == true ? .green : .red) // This shows the conditional coloruing of the view. If it is an income type then make it green, otherwise make it red
    }
}

