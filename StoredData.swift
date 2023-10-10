//
//  StoredData.swift
//  Budget Prototype
//
//  Created by Johnny Wu on 27/1/2022.
//

// Module which deals with data persistence - ie it can store data and it will be kept there after the app stops
import Foundation


// These three classes to store data in secondary memory are all basically clones of each other. Each are ObserveableObjects - ie they can be passed around to other views
// This does literally one thing - it turns off the tutorial and keeps it turned off when it is done. It stores ONE boolean variable ONLY
class FirstTime : ObservableObject {
    
    // Here is the variable - it shows whether it is the first time if the user is using the app, by default, it is true until changed, which occurs when the user sees the real main menu for the first time
    // @Published tells everything else that the variable is updated when whatever is in didSet runs
    @Published var firstTime = true
    
    {
        // didSet changes the variable whenever the system detects a change
        didSet {
            // Everything in here is run when the value of items changes (aka the list of transactions/gpals when the user taps the "add transaction" button
            do {
                let encoded = try JSONEncoder().encode(firstTime)
                // Reset the new value for firstTime and encode it
                UserDefaults.standard.set(encoded, forKey: "firstTime")
            }
            catch {
                // This should never run
                fatalError()
            }
        }
    }
    
    init() {
        // When the variable is created, find the variable and bring it back. This is what can store data in long term memory on the phone itself, and this value won't change even if the user quits the app.
        // Needs a code to decode what was encoded
        if let savedFirst = UserDefaults.standard.data(forKey: "firstTime") {
            do {
                let decocer = JSONDecoder()
                // Decode the value
                let t = try decocer.decode(Bool.self, from: savedFirst)
                // Set the value of firstTime to the new decoded value
                self.firstTime = t
            }
            catch {
                fatalError()
            }
        }
        
        
        // If that failed (or if there was nothing in the array) then send back nothing
        
    }
    
}

// This enumeration is used for all the sorting methods
enum WaysToSort {
    case unsorted,alphabetical, reverseAlphabetical, amountAscending, amountDescending, dateAscending, dateDescending, income, expenses, recurring, notRecurring, amountContributed, amountContributedReversed, amountRemaining, amountRemainingReversed
}

// Important because this class stores the array of all the items - Transactions ≠ Transaction: "Transactions" stores all of it and deals with persistence. It includes an array made up of "Transaction"
class Transactions : ObservableObject {
    
    // The storing, encoding, retrieving and decoding were all mainly taken and inspired from https://www.hackingwithswift.com/books/ios-swiftui/archiving-swift-objects-with-codable. However, I did have to change some essential parts to make it for my project
        
    // Store all the transactions in a common class which holds an array of transactions
    @Published var items : [Transaction] = []
    
    // When it changes - encode the new data into JSON
    {
        didSet {
            // Everything in here is run when the value of items changes (aka the list of transactions/gpals when the user taps the "add transaction" button
            do {
                let encoded = try JSONEncoder().encode(items)
                UserDefaults.standard.set(encoded, forKey: "Transactions")
            }
            
            catch {
                fatalError()
            }
        }
        
    }
    // When we need to obtain the data (aka when we initialize the Transactions class), attempt to decode the data and set the decoded data to items
    init() {
        
        // I need to get both the transactions and goals
        if let savedTransactions = UserDefaults.standard.data(forKey: "Transactions") {
            do {
                let decocer = JSONDecoder()
                let t = try decocer.decode([Transaction].self, from: savedTransactions)
                self.items = t
            }
            catch {
                
            }
        }
        // If that failed (or if there was nothing in the array) then send back an empty array.
    }

    // This function obtains the balance of a particular time period, given in the first parameter as "Daily", "Weekly" or something else picked from a picker. The second and third parameters are used for the "Custom" time period - see below. It is used in the transactions menu as well as the achievability index for goals
    func getBalance(timePeriod : String, startDate : Date = Date.now, endDate : Date = Date.now) -> Double {
        
        var total = 0.0
        let calendar = Calendar(identifier: .gregorian)
        
        // This is needed because if I just use the week of year, the loop will calculate the dates with the same weeknumber but from a seperate year. For example, both Jan 1 2022 and Jan 1 2023 will be calculated in the recurring balance, which is what we do not want for a weekly summary. Also the same for months
        let thisYear = calendar.component(.year, from: Date.now)
        
        switch timePeriod {
            
        case "Daily":
            // Loop through all the transactions
            for transaction in items {
                // Does this transaction have today's date? If so, then include it in the daily balance. Date.now.stripTime() returns today's date at 12:00 am
                if transaction.futureDates.contains(Date.now.stripTime()) {
                    if transaction.type == false {
                        total -= transaction.amount
                    }
                    else {
                        total += transaction.amount
                    }
                }
            }
            
        case "Weekly":
            
            // This line taken from https://weeknumber.com/how-to/swift. It gets the specific week of the year of a specific date
            let thisWeek = calendar.component(.weekOfYear, from: Date.now.stripTime())
            
            for transaction in items {
                // Loop through every payment in the futureDate array of the transaction - this could loop through up to 7 times for a single transaction
                for futureDate in transaction.futureDates {
                    if calendar.component(.weekOfYear, from: futureDate) == thisWeek && calendar.component(.year, from: futureDate) == thisYear {
                        if transaction.type == false {
                            total -= transaction.amount
                        }
                        else {
                            total += transaction.amount
                        }
                    }
                }
            }
            
        case "Monthly":
            
            // Pretty much the same as weekly but we are comparing months instead.
            let thisMonth = calendar.component(.month, from: Date.now)
            
            for transaction in items {
                for futureDate in transaction.futureDates {
                    // This is important because it makes sure that we can't have multiple Z
                    if calendar.component(.month, from: futureDate) == thisMonth && calendar.component(.year, from: futureDate) == thisYear {
                        if transaction.type == false {
                            total -= transaction.amount
                        }
                        else {
                            total += transaction.amount
                        }
                    }
                }
            }
            
        case "Yearly":
            
            
            for transaction in items {
                for futureDate in transaction.futureDates {
                    if calendar.component(.year, from: futureDate) == thisYear {
                        if transaction.type == false {
                            total -= transaction.amount
                        }
                        else {
                            total += transaction.amount
                        }
                    }
                }
            }
            
        case "Custom":
            // See if the future date lies between these two dates
            
            // Problem here is that if the user selects the second date before the first (aka they select 2/1/2022 for the second date but 1/1/2022 for the first date the code will completely break and the app will quit - i want to avoid this
            var dateRange = Date.now.stripTime()...Date.now.stripTime()
            
            // So this will only work IF the user inputs are correct. There will also be an alert which tells the user that they have screwed up big time
            if startDate < endDate {
                dateRange = startDate.stripTime()...endDate.stripTime()
            }
            
            // Same logic as before
            for transaction in items {
                for futureDate in transaction.futureDates {
                    if dateRange.contains(futureDate) {
                        if transaction.type == false {
                            total -= transaction.amount
                        }
                        else {
                            total += transaction.amount
                        }
                    }
                }
            }
            
        default :
            // This shouldn't be needed at all - if you somehow get here then a fatalerror is called - shutting the app down
            fatalError()
        }
        return total
    }
    
    // This function is responsible for the sorting of both transactions and goals (it is repeated below for goals) and sorts the array that holds the transactions/goals, which is then reflected on screen when the user sorts their transactions
    // It takes in the method (which is an enumeration) and the unsorted array
    func customSort(method : WaysToSort, unsorted : [Transaction]) -> [Transaction] {
        
        switch method {
        case .unsorted:
            return items
            
        case .alphabetical:
            // The .sorted(by : {}) takes in a closure (annoynmous function) and sorts the array based upon the rules given in the closure. In this case we are sorting by name, but below there are other methods of sorting. It will then return the sorted array
            return unsorted.sorted(by: {transaction1, transaction2 in
                transaction1.name < transaction2.name
            })
        case .reverseAlphabetical:
            return unsorted.sorted(by: {transaction1, transaction2 in
                transaction1.name > transaction2.name
            })
            
        case .amountAscending:
            return unsorted.sorted(by: {transaction1, transaction2 in
                transaction1.amount < transaction2.amount
            })
        case .amountDescending:

            return unsorted.sorted(by: {transaction1, transaction2 in
                transaction1.amount > transaction2.amount
            })
            
            
        // This sorts by the next transaction date - so ones that are paid first will be on top
        case .dateAscending:
            return unsorted.sorted(by: {transaction1, transaction2 in
                transaction1.getNextTransactionDate() < transaction2.getNextTransactionDate()
            })
        case .dateDescending:

            return unsorted.sorted(by: {transaction1, transaction2 in
                transaction1.getNextTransactionDate() > transaction2.getNextTransactionDate()
            })
            
        
        // The last 4 cases utilise the filter function, which filters an array based upon the rules provided in the closure
        case .income:
            // https://stackoverflow.com/questions/28781031/swift-sort-array-of-objects-based-on-boolean-value
            // Will return all of them with type true, which is all of the ones which are labelled as income
            return unsorted.filter( {$0.type == true})
        case .expenses:
            return unsorted.filter({$0.type == false})
            
        case .recurring:
            // Will return all recurring transactions
            return unsorted.filter({$0.recurring != "Never"})
        case .notRecurring:
            return unsorted.filter({$0.recurring == "Never"})
            
        default:
            fatalError()
        }
        
    }
    
}

class Goals : ObservableObject {
    
    // When the app launches - we need to calculate ALL the transactions for this specific day - then display them
    
    // Store all the goals in a common class which holds an array of goals
    @Published var items : [Goal] = []
    
    // When it changes - encode the new data into JSON
    
    {
        didSet {
            // Everything in here is run when the value of items changes (aka the list of transactions)
            if let encoded = try? JSONEncoder().encode(items) {
                UserDefaults.standard.set(encoded, forKey: "Goals")
            }
            
        }
    }
    
    // When we need to obtain the data (aka when we initialize the Goals class), attempt to decode the data and set the decoded data to items
    init() {
        if let saved = UserDefaults.standard.data(forKey: "Goals") {
            if let decodedItems = try? JSONDecoder().decode([Goal].self, from : saved) {
                items = decodedItems
                return
            }
        }
        // If that failed (or if there was nothing in the array) then send back an empty array.
        items = []
    }
    
    // Exactly the same as the initializer BUT available on demand. Needed as sometimes the data won't update by itself and I need to force it
    func updateData() {
        if let saved = UserDefaults.standard.data(forKey: "Goals") {
            if let decodedItems = try? JSONDecoder().decode([Goal].self, from : saved) {
                items = decodedItems
                return
            }
        }
        // If that failed (or if there was nothing in the array) then send back an empty array.
        items = []
    }
    
    // Modifies the stored data. It will add a specified amount to a specified goal
    func addContribution(goal : Goal, amount : Double) {
        for index in 0 ..< items.count{
            if items[index] == goal {
                items[index].amountContributed += amount
                return
            }
        }
    }
    
    // Same thing as the goal
    func customSort(method : WaysToSort, unsorted : [Goal]) -> [Goal] {
        
        switch method {
        case .alphabetical:
            
            // Sorts the array by name which will then change the order of which it is seen
            return unsorted.sorted(by: {goal1, goal2 in
                goal1.name < goal2.name
            })
            
        case .reverseAlphabetical:
            return unsorted.sorted(by: {goal1, goal2 in
                goal1.name > goal2.name
            })
        case .amountAscending:
            return unsorted.sorted(by: {goal1, goal2 in
                goal1.amount < goal2.amount
            })
            // Amount isn't working please fix
        case .amountDescending:
            return unsorted.sorted(by: {goal1, goal2 in
                goal1.amount > goal2.amount
            })
        case .dateAscending:
            return unsorted.sorted(by: {goal1, goal2 in
                goal1.dueDate < goal2.dueDate
            })
        case .dateDescending:
            return unsorted.sorted(by: {goal1, goal2 in
                goal1.dueDate > goal2.dueDate
            })
        case .amountContributed:
            return unsorted.sorted(by: {goal1, goal2 in
                goal1.amountContributed < goal2.amountContributed
            })
        case .amountContributedReversed:
            return unsorted.sorted(by: {goal1, goal2 in
                goal1.amountContributed > goal2.amountContributed
            })
        // There is actaully no attribute for "amount remaining" so it's calculated here
        case .amountRemaining:
            return unsorted.sorted(by: {goal1, goal2 in
                (goal1.amount - goal1.amountContributed) < (goal2.amount - goal2.amountContributed)
            })
        case .amountRemainingReversed:
            return unsorted.sorted(by: {goal1, goal2 in
                (goal1.amount - goal1.amountContributed) > (goal2.amount - goal2.amountContributed)
            })
        default:
            return unsorted
        }
        
    }
    
}
