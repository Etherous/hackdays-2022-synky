//
//  SynkyApp.swift
//  Synky
//
//  Created by Brandon Lyon on 2/28/22.
//

import SwiftUI

@main
struct SynkyApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
