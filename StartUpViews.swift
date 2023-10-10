//
//  TutorialIncomeView.swift
//  Budget Prototype
//
//  Created by Johnny Wu on 31/1/2022.
//

import SwiftUI


// This is a customised struct that displays a large icon image on top of a text - used in the grid designs when you first open the app
struct ImageOnTopOfText : View {
    
    let name : String
    
    let type : Bool // Refers to whether a transaction is an income or expense
    
    @Environment(\.colorScheme) var colorScheme
    
    // This function obtains the inputted string from the internal array (incomeCategories) and converts it into the necessary string that is used by the asset system to display the images. Similar to the one in contentView
    func getFileName() -> String {
        
        // Used for income types
        if type == true {
            // I had to do this by cases because I don't have a seperate image for each type of income
            if name == "Social security" {
                return colorScheme == .light ? "Social_security_light" : "Social_security_dark"
            }
            else if name == "Capital gains" {
                return colorScheme == .light ? "Capital_gains_light" : "Capital_gains_dark"
            }
            else if name == "Rent" {
                return name + (colorScheme == .light ? "_light_income" : "_dark_income")
            }
            else if name == "Other" {
                return colorScheme == .light ? "Income_light" : "Income_dark"
            }
            
            // Just return the name and the mode as it is already ordered well
            return name + (colorScheme == .light ? "_light" : "_dark")
        }
        
        // Used for expense types
        else {
            if name == "Interest" {
                return colorScheme == .light ? "Interest_payments_light" : "Interest_payments_dark"
            }
            let name = name
            let theme = colorScheme == .light ? "_light" : "_dark"
            
            return name + theme
        }
    }
    
    var body: some View {
        // This arranges the images in a certain method
        VStack {
            // Image function takes in a variable for the name of the image, and the other modifiers change the shape so it is circular and 70x70 pixels wide
            Image(getFileName())
                .resizable()
                .scaledToFit()
                .clipShape(Circle())
                .frame(width: 70, height: 70)
            Text(name)
                .font(.body)
                .dynamicTypeSize(.medium) // This disables dynamic reading type - essentially an accessibility feature where you can make text bigger - just for this text view as the text doesn't appear if its too big
        }.frame(width: 120, height: 120)
            .background(.ultraThickMaterial)
            .clipShape(RoundedRectangle(cornerRadius : 6)) // Make the view appear as a rounded rectangle (but as sides are of equal length it becomes a square)
    }
}

struct StartUpIncomeView: View {
    
    // This uses the environmentObject which was fed in from ContentView(). The data points to the same location
    @EnvironmentObject var transactions : Transactions

    // Array of all the different types of income that are displayed
    let incomeCategories = ["Wages", "Salary", "Profits", "Capital gains", "Dividends", "Social security", "Rent", "Allowance", "Other"]
    
    var body: some View {
        // Stolen from https://stackoverflow.com/questions/56711736/iterate-a-grid-of-views-swiftui This creates a grid of any element, which I have modified to make it use the custom ImageOnTopOfText
        
        ScrollView(showsIndicators : false) {
            
            Text("First, add your income").font(.title)
            
            // A ForEach loop loops through all items in a certain array (income categories) and will create a new smaller view for each time the object appears. More info https://developer.apple.com/documentation/swiftui/foreach and https://www.hackingwithswift.com/quick-start/swiftui/how-to-create-views-in-a-loop-using-foreach
            ForEach(0 ..< incomeCategories.count/3, id : \.self) { row in // create number of rows. The foreach will create a different view for each thing in an array
                HStack {
                    ForEach(0..<3) { column in // create 3 columns. Using two foreach loops makes a 2D array (essentially a grid) of views
                        // NavigationLink creates a destination - the new transaction page, with some variables that are already filled in - so if the user wants to add a transport expense it will already be labelled as "transport"
                        let incomeIndex = row * 3 + column
                        NavigationLink(destination: NewTransaction(newCategory: incomeCategories[incomeIndex], type : "Income"), label: {
                            ImageOnTopOfText(name: incomeCategories[incomeIndex], type: true)
                        }).buttonStyle(PlainButtonStyle())
                    }
                }
            }
            // Sends you to the next view - button on the botoom
            NavigationLink(destination : StartUpExpensesView() ) {
                StyledText(text: "Next", foreGroundColor: .blue)
            }
        }
    }
}

// This is essentially a clone of the earlier but with expenses instead of income
struct StartUpExpensesView: View {
    
    @EnvironmentObject var transactions : Transactions
    
    let expenseCategories = ["Rent", "Food", "Groceries", "Entertainment", "Subscriptions", "Transport", "Utilities", "Shopping", "Drinks", "Interest", "Savings", "Investments", "Insurance", "Education", "Pets", "Children", "Healthcare", "Other"]
    
    // What this does is that it changes the variable for the startup to "false" - there is no way to turn it back so this is permanent
    func disableStartUp() {
        FirstTime().firstTime = false
    }
    
    var body: some View {
        
        // Display list of expenses without displaying the scrollbar because it looked bad
        ScrollView(showsIndicators : false) {
            Text("Add your expenses").font(.title)
            ForEach(0 ..< expenseCategories.count / 3, id : \.self) { row in // create number of rows
                HStack {
                    ForEach(0..<3) { column in // create 3 columns
                        let expenseIndex = row * 3 + column
                        NavigationLink(destination : NewTransaction(newCategory: expenseCategories[expenseIndex], type: "Expense"), label : {
                            ImageOnTopOfText(name: expenseCategories[expenseIndex], type: false)
                        }).buttonStyle(PlainButtonStyle())
                    }
                }
            }

            NavigationLink(destination : ContentView(), label :  {
                StyledText(text: "Done", foreGroundColor: .blue)
            }
            ).onAppear(perform: {
                disableStartUp()
            }
            )
        }
    }
}
