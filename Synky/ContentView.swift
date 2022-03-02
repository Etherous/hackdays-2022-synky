//
//  ContentView.swift
//  Synky
//
//  Created by Brandon Lyon on 2/28/22.
//

import SwiftUI
import CoreData

struct ContentView: View {
    var body: some View {
        TabView {
            SchedulesView()
                .tabItem {
                    Label("Schedules", systemImage: "clock")
                        .foregroundColor(.blue)
                }
            AccountsView()
                .tabItem {
                    Label("Accounts", systemImage: "person")
                        .foregroundColor(.blue)
                }
            ServicesView()
                .tabItem {
                    Label("Services", systemImage: "cloud")
                        .foregroundColor(.blue)
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext).previewInterfaceOrientation(.portraitUpsideDown)
            ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
}
