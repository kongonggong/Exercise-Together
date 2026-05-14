//
//  Exercise_TogetherApp.swift
//  Exercise-Together
//

import SwiftUI
import CoreData

@main
struct Exercise_TogetherApp: App {

    let persistenceController = PersistenceController.shared

    var body: some Scene {

        WindowGroup {

            ContentView()
                .environment(
                    \.managedObjectContext,
                    persistenceController.container.viewContext
                )
        }
    }
}
