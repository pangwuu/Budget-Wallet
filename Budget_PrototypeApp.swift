//
//  Budget_PrototypeApp.swift
//  Budget Prototype
//
//  Created by Johnny Wu on 17/1/2022.
//

// SwiftUI provides views, controls, and layout structures for declaring your app’s user interface. The framework provides event handlers for delivering taps, gestures, and other types of input to your app, and tools to manage the flow of data from your app’s models down to the views and controls that users will see and interact with. From https://developer.apple.com/documentation/swiftui/
import SwiftUI

@main

// :App means that the BudgetPrototypeApp conforms to App, a protocol which declares what an app is
struct Budget_PrototypeApp: App {
    
    // This is initialised here and tracks whether it is the first time that the user is opening the app. In ContentView() it determines which view is loaded
    @StateObject var firstTime = FirstTime()
    
    // This allows the app (contentView()) to show different views based on the value of firstTime
    @ViewBuilder
    
    // A scene is just a series of Views (screens) which is shown to the user
    var body: some Scene {
        
        // WindowGroup required to conform to Scene
        WindowGroup {
            // Starts the running of the app
            ContentView()
        }
    }
}
