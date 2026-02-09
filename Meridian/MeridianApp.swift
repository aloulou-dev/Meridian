//
//  MeridianApp.swift
//  Meridian
//
//  Created by Malek Aloulou on 2/9/26.
//

import SwiftUI
import CoreData

@main
struct MeridianApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
