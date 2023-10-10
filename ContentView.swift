//
//  ContentView.swift
//  Budget Prototype
//
//  Created by Johnny Wu on 17/1/2022.
//


// AVFoundation is an Audio-Video library which allows me to play wonderful multimedia assets
import AVFoundation
import SwiftUI

// This is the label for each of the three rectangular views on the main menu, for transactions, goals and tutorial. It is a general component which has text and a round image inside it
struct MainMenuRectangle : View {
    
    var text : String
    
    // The size of the rectangle is based on the screen size
    let screenSize: CGRect = UIScreen.main.bounds
    
    // This variable tracks whether the user is in light or dark mode. From https://betterprogramming.pub/how-to-detect-light-and-dark-modes-in-swiftui-eef21ba4d11d
    @Environment(\.colorScheme) var colorScheme
    
    // This function takes the text attribute and obtains the required image based on the text displayed and whether the user is in light or dark mode. Light/dark mode matters as I have 2 sets of images for light and dark mode respectively
    func getImageName() -> String {
        switch text {
            // If it is called transactions and if user is in light mode then return transactions_light. Similar for all the rest
        case "Transactions":
            return colorScheme == .light ? "Transactions_light" : "Transactions_dark" // Ternary operator, if the condition is true then the first one will be picked if its not then the second one will be picked
        case "Goals":
            return colorScheme == .light ? "Goals_light" : "Goals_dark"
        case "Reminders":
            return colorScheme == .light ? "Reminders_light" : "Reminders_dark"
        default:
            // If the text is none of these return nothing (this should never happen)
            return ""
        }
        
    }
    
    // A view is made up of the stuff before esseentially class attributes and functions, and the body, which is what is displayed, which is below
    var body : some View {
        
        // A HStack stands for "horizontal stack" - places various elements horizontally
        HStack {
            
            // A VStack stands for "vertical stack" - places various elements vertically
            VStack {
                // Spacers try to make themselves as big as possible and are very flexible
                Spacer()
                // The Text() element displays a piece of text on screen
                Text(text)
                    .font(.title) // <-- These are called modifiers and modify the properties of the element they are attached to. In this case it makes the text a title font and bold
                    .bold()
                Spacer()
            }
            Spacer()
            
            
            // This is the image - resizable and scaled to fit are needed to modify the dimensions of the image - essentially create a scaled copy to its original dimensions.
            Image(getImageName()) // This is where the getImageName() function is used --> the parameter for Image() is a string
                .resizable()
                .scaledToFit()
                .clipShape(Circle()) // Makes the image circular
                .frame(width: 120, height: 120) // .frame() modifies the dimensions of the object it is acting on, it is now 120x120 on screen
            
            // .frame creates the dimensions of any view - in this case it has variable width and height.
        }
        .frame(width: screenSize.width - 55, height: screenSize.height/6)
        .padding() // Padding() creates some empty space between this view and other views.
        .background(.ultraThickMaterial) // The background colour is created using .ultraThickMaterial(), which creates a hazy effect onscreen, creating the grey backgrounds
        .clipShape(RoundedRectangle(cornerRadius: 6.0)) // .clipshape() makes the view a certain shape - in this case a rounded rectangle
        
    }
    
}

// Text that is essentially a bubble with a variable for colour as well
struct StyledText : View {
    
    let text : String
    
    // Specify the colour which is of type "Color"
    let foreGroundColor : Color
    
    var body: some View {
        
        // With minimum width
        Text(text)
            .frame(minWidth: 150.0, alignment: .center) // Alignment places the text in the middle of the capsule, minwidth specifies minimum width
            .padding()
            .foregroundColor(foreGroundColor)
            .background(Material.ultraThick)
            .font(.headline)
            .clipShape(Capsule()) // Capsule clipshape looks like a capsule (like medicine) thats sideways
    }
}

struct ContentView: View {
    
    // StateObjects are used to store common data across the app - this is the first instance of using them - it initializes them. Other views use EnvironmentObjects - which just carry the data from these classes across to other views. All instances of these views will hence point to the same object, this is important as it stores all the data which needs to be the same
    
    // Holds whether it's the first time the user has opened the app
    @StateObject var firstTime = FirstTime()
    // Holds transactions data
    @StateObject var transactions = Transactions()
    // Holds goals data
    @StateObject var goals = Goals()
    // Holds notifications data and other things
    @StateObject var notificationsManager = NotificationsManager()
    
    let screenSize: CGRect = UIScreen.main.bounds
        
    @ViewBuilder
    var body: some View {
       
        // Allows use to go through different views
        NavigationView {
            
            // This is displayed if the user has used the app before
            if firstTime.firstTime == false {
                
                VStack {
                    
                    // NavigationLink s move between differnet screens - you are moving to another struct (which is also a view) - this one is called AtAGlance()
                    NavigationLink(destination: AtAGlance(), label: {
                        MainMenuRectangle(text: "Transactions")
                    })
                    .buttonStyle(PlainButtonStyle()) // From https://stackoverflow.com/questions/57177989/how-to-turn-off-navigationlink-overlay-color-in-swiftui, without the buttonStyle modifier it will be displayed as a blue colour - the default for anything the user can interact with
                    
                    NavigationLink(destination: GoalsOverview(), label: {
                        MainMenuRectangle(text : "Goals")
                    }
                    )
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination:  NotificationView() , label: {
                        MainMenuRectangle(text: "Reminders")
                    }
                    )
                    .buttonStyle(PlainButtonStyle())
                    
                    // Needed to pass data changes around the app so differnet views share the same data. The environment object allows the goals and transactions variables to be passed to another struct
                }.padding()
                    .navigationTitle("Budget Wallet") // A navigationTitle creates a title on the view
                    .environmentObject(goals)
                    .environmentObject(transactions)
                    .environmentObject(notificationsManager)
            }
            
            // This screen appears when you open the app for the very first time --> this is determined by the value of firstTime.firstTime
            else {
                VStack {
                    StyledText(text: "Today, you have chosen to embrace sustainable spending. Let's get started!", foreGroundColor: .primary)
                        .frame(maxWidth: CGFloat(screenSize.width) - 80.0) // Frame with variable maxWidth
                    NavigationLink(destination: StartUpIncomeView(), label: {
                        StyledText(text: "Next", foreGroundColor: .blue)
                    })
                }.navigationTitle("Welcome!")
            }
        }.environmentObject(transactions)
            .environmentObject(goals)
            .navigationBarHidden(true) // NavigationBarHidden hides the Back button error that occurs if you start with the startup screen
            .environmentObject(notificationsManager)
    }
    
}
