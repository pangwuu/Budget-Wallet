//
//  AtAGlance.swift
//  Budget Prototype
//
//  Created by Johnny Wu on 17/1/2022.
//

import SwiftUI

// Convert the various strings (which are from pickers) to enumerations (which is what are used by the functions in storedData) - probably makes the code safer but I still think this is quite risky and could result in errors if I can't spell
extension String {
    
    // The waysToSort cases are what is used by the code
    func stringToSortMethod() -> WaysToSort {
        
        switch self {
            
        case "None":
            return .unsorted
        case "Name: A to Z":
            return .alphabetical
        case "Name: Z to A":
            return .reverseAlphabetical
        case "Amount: Low to high":
            return .amountAscending
        case "Total amount: Low to high":
            return .amountAscending
        case "Amount: High to low":
            return .amountDescending
        case "Total amount: High to low":
            return .amountDescending
        case "Date: closest to furthest":
            return .dateAscending
        case "Date: furthest to closest":
            return .dateDescending
        case "Income":
            return .income
        case "Expenses":
            return .expenses
        case "Recurring":
            return .recurring
        case "Non recurring":
            return .notRecurring
        case "Contributed: Low to high":
            return .amountContributed
        case  "Contributed: High to low":
            return .amountContributedReversed
        case "Remaining: Low to high":
            return .amountRemaining
        case "Remaining: High to low":
            return .amountRemainingReversed
        default:
            // Default case cannot be empty
            return .dateAscending
        }
    }
}

// This should be more accurately named TransactionsMenu, but it's too late now. It is the memu of transactions which are displayed
struct AtAGlance: View {
    let screenSize: CGRect = UIScreen.main.bounds
    
    // This gets whether the user is in light or dark mode
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var transactions : Transactions

    @State private var balanceType = "Daily"
    var balanceTypes = ["Daily", "Weekly", "Monthly", "Yearly", "Custom"]
    var sortTypes = ["None" ,"Name: A to Z", "Name: Z to A", "Amount: Low to high", "Amount: High to low", "Date: closest to furthest", "Date: furthest to closest", "Income", "Expenses", "Recurring", "Non recurring"]
    
    @State private var sortType : String = "None"
    
    // These are the dates for the "custom" cashflow type which are controlled using two seperate datePickers
    @State private var customDateOne = Date.now
    @State private var customDateTwo = Date.now
    
    @State private var alertIsPresented = false
    @State private var helpPresented = false
    
    // Used for formatting - convert a date into a string
    func getShortDate(d : Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: d)
    }
    
    // Same as goals function except will delete from a different place
    private func deleteItem(at indexSet: IndexSet) {
        self.transactions.items.remove(atOffsets: indexSet)
        SoundPlayer.instance.playSound(soundName: "Scrunch")
    }
    
    @ViewBuilder
    var body: some View {
        
        // If there is 1 or more transactions display this part
        if transactions.items.count > 0 {
            
            VStack {
                HStack {
                    Text("Your transactions").font(.title).bold().offset(y : -15 ).frame(alignment: .leading).padding([.leading])
                    Spacer()
                }
                
                VStack {
                    
                    // This is the part where the user can see their own cashflow. the mode is detemined by the variable "BalanceType"
                    Section {
                        VStack {
                            // Title
                            Text("CASHFLOW TYPE").font(.caption).frame(alignment : .leading)
                                .offset(y : 6) // This will shift the title up 6 units
                            
                            // this allows the user to pick what timeframe they want to see their goal in
                            Picker("CASHFLOW TYPE", selection : $balanceType, content: {
                                ForEach(balanceTypes, id : \.self) {
                                    Text($0)
                                }
                            }).pickerStyle(.segmented) // This makes the picker appear as a series of horizontal radio buttons
                                .padding([.leading, .bottom, .trailing], 10) // This means that padding of 10px is applied on the left, bottom and right parts but not the top
                            
                            if balanceType == "Custom" {
                                HStack {
                                    // DatePickers to find the upper and lower bounds of the custom balanace
                                    VStack {
                                        Text("Start date").bold()
                                        DatePicker("Start date", selection: $customDateOne, displayedComponents: .date).padding([.bottom], 10).labelsHidden()
                                    }
                                    // This one is restricted
                                    VStack {
                                        Text("End date").bold()
                                        DatePicker("End date", selection: $customDateTwo, in: customDateOne...Date.distantFuture,displayedComponents: .date).padding([.bottom], 10).labelsHidden()
                                    }
                                }
                            }
                        }
                        
                    }.background(Material.thick)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding([.leading, .trailing], 20)
                    
                    VStack {
                        
                        Section {
                            
                            // Display alert if the dates are improper - won't form a proper dateRange
                            if customDateTwo < customDateOne && balanceType == "Custom" {
                                Text("Start date must be before end date!")
                                    .foregroundColor(.red)
                                    .bold()
                                    .font(.title)
                            }
                            
                            else if balanceType == "Custom" {
                                HStack {
                                    // Conditional colour - if the Cashflow over said time period is >= 0 then make it green, otherwise it should be red
                                    // (transactions.getBalance(timePeriod: balanceType, startDate: customDateOne, endDate: customDateTwo) is the custom balance over the required time frame
                                    Text("Custom cashflow").foregroundColor(transactions.getBalance(timePeriod: balanceType, startDate: customDateOne, endDate: customDateTwo) >= 0 ? .green : .red).font(.title2).bold().padding()
                                    Spacer()
                                    Text(transactions.getBalance(timePeriod: balanceType, startDate: customDateOne, endDate: customDateTwo), format: .currency(code: Locale.current.currencyCode ?? "AUD"))
                                    // the colour is conditional on whether the cashflow is positive or negative in a given time frame
                                        .foregroundColor(transactions.getBalance(timePeriod: balanceType, startDate: customDateOne, endDate: customDateTwo) >= 0 ? .green : .red).font(.title2).bold().padding()
                                
                                }
                            }
                            else {
                                HStack {
                                    // This is any other type of cashflow (daily, weekly, monthly etc)
                                    Text("\(balanceType) cashflow").foregroundColor(transactions.getBalance(timePeriod: balanceType) >= 0 ? .green : .red)
                                        .font(.title2)
                                        .bold()
                                        .padding()
                                    Spacer()
                                    Text(transactions.getBalance(timePeriod: balanceType, startDate: customDateOne, endDate: customDateTwo), format: .currency(code: Locale.current.currencyCode ?? "AUD"))
                                        .foregroundColor(transactions.getBalance(timePeriod: balanceType, startDate: customDateOne, endDate: customDateTwo) >= 0 ? .green : .red).font(.title2).bold().padding()
                                }
                            }
                        }
                    }.frame(maxWidth: .infinity)
                        .background(Material.thick) // Make a hazy effect on screen
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding([.leading, .trailing], 20)
                    
                }
                
                
                
                
                List {
                    // Sorting method
                    Picker("Sort by", selection: $sortType, content : {
                        ForEach(sortTypes, id : \.self) { sort in
                            Text(sort)
                        }
                    }).font(.headline).dynamicTypeSize(.medium)
                    
                    // Will create a list view that is sorted in some way
                    if sortType != "None" {
                        ForEach(transactions.customSort(method: sortType.stringToSortMethod(), unsorted: transactions.items), id : \.id) { trans in
                            NavigationLink(destination: TransactionViewDetailed(transaction: trans), label: {
                                LittleTransactionView(transaction: trans).dynamicTypeSize(.medium)
                            })
                        }
                    }
                    // Unsorted list
                    else {
                        ForEach(transactions.items, id : \.id) { trans in
                            NavigationLink(destination: TransactionViewDetailed(transaction: trans), label: {
                                LittleTransactionView(transaction: trans)
                            })
                        }.onDelete(perform: self.deleteItem).dynamicTypeSize(.medium)
                    }
                    
                }
                
                // Buttons for adding a transaction
                
                HStack {
                    
                    // Link to the "add transaction page"
                    NavigationLink(destination: NewTransaction(), label: {
                        StyledText(text: "Add a transaction", foreGroundColor: .blue)
                    })
                    
                }
                
                // So this sheet, which is controlled by the question mark, will be popped up it helpPresented is true
            }.sheet(isPresented: $helpPresented, content: {
                TransactionsTutorial()
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
        
        // button to add transaction
        else {
            NavigationLink(destination: NewTransaction(), label: {
                StyledText(text: "Add a transaction to get started!", foreGroundColor: Color.blue).font(.largeTitle)
            }
                           
            ).sheet(isPresented: $helpPresented, content: {
                TransactionsTutorial()
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
    
}

// This is what is displayed in the sheet and will make up the tutorial
struct TransactionsTutorial: View {
    
    // From https://www.hackingwithswift.com/quick-start/swiftui/how-to-make-a-view-dismiss-itself, allows the view to dismiss itself
    @Environment(\.presentationMode) var isPresented
    @Environment(\.colorScheme) var colorScheme
    let screenSize: CGRect = UIScreen.main.bounds
    
    func lightOrDarkVideo(nameOfVideo : String) -> String {
        // Return statement is implied when function has one line
        colorScheme == .light ? "\(nameOfVideo)_light" : "\(nameOfVideo)_dark"
    }
    
    var body: some View {
        Form {
            Text("Transactions help").font(.title)
            
            Section {
                HStack {
                    Text("What are they?").font(.title2)
                    Spacer()
                }
                Text("Transactions are the main tool to track income and spending, providing you with a picture of your cashflow")
            }
            
            Section {
                HStack {
                    Text("The menu").font(.title2)
                    Spacer()
                }
                Text("A transaction in Budget Wallet is just any flow of cash in and out of your accounts. This may be from income or spending")
                Text("The menu allows you to see your net cashflow at a glance. You can change the time period of your cashflow by using the selector near the top of the page, as shown in the video below")
                
                TutorialVideo(name: "Changing_transactions_timeframe", ext: "MOV")
                
                Text("The menu also allows you to see your transactions in a handy table. Get more data on any particular transaction by tapping on it")
                
                TutorialVideo(name: "Tapping_transaction_details", ext: "mov")
                
                Text("Sort your transactions by using the sort menu at the top of the list of the transactions. You can sort or filter the transactions by a variety of criteria")
                TutorialVideo(name: "Sorting_transactions", ext: "mov")
                
            }
            
            Section {
                HStack {
                    Text("Adding transactions").font(.title2)
                    Spacer()
                }
                Text("Tap the blue \"Add transaction\" button on the bottom of the menu to add a transaction. It looks like this")
                // I thought about using a photo or video for this but there is literally no reason to in this situation - just put the label for the actual butoon
                StyledText(text: "Add a transaction", foreGroundColor: .blue).offset(x : 0.19*screenSize.width)
                
                Text("You will then be prompted to enter in some data about a particular transaction, such as its amount, category and whether it is recurring or not")
                Text("For example, a car repayment paid monthly may look like this")
                TutorialVideo(name: "Add_transaction", ext: "mov")
                
                // Image of screenshots
                Text("Remember that all data must be filled in order for the transaction to be added. The button will be grey and not work if you do not do this")
                Image(lightOrDarkVideo(nameOfVideo: "Error_transactions")).resizable().frame(width: screenSize.width*0.81, height: screenSize.height/7)
                
                Text("When you're done, add the transaction to your existing transactions")
                
            }
            
            Section {
                HStack {
                    Text("Editing and deleting").font(.title2)
                    Spacer()
                }
                
                Text("Delete any transaction by pressing the delete transaction button. You can delete transactions by first tapping on it acessing the deletion buttion there. The entire process looks like this")
                TutorialVideo(name: "Delete_transaction", ext: "mov")
                Text("Alternatively you can delete transactions by sliding on them, as long as they are unsorted")
                TutorialVideo(name : "Slide_delete_transaction", ext : "mov")
                                
                Text("Edit any transaction by accessing the edit button, placed just above the delete button. You will be taken to another screen which prompts you to change any details from the original transaction, as if you are adding a new transaction")
                Text("When you're done, slide back to the main menu by pressing the back button on the top left corner or by sliding back with your finger")
                // Show video of going back to main menu
                TutorialVideo(name: "Edit_transaction", ext: "mov")
                Text("Please note that the data for the transaction will only update AFTER you go back to the main menu.")
                
            }
            
            
            // This button dismisses the tutorial by dismissing the sheet
            
            Section {
                Button(action: {
                    isPresented.wrappedValue.dismiss() }, label: {
                        Text("Dismiss").frame(alignment: .center)
                    })
            }
            
        }
    }
}
