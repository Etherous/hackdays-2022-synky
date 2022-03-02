//
//  ServicesView.swift
//  Synky
//
//  Created by Brandon Lyon on 2/28/22.
//

import SwiftUI
import CoreData

struct ServicesView: View {
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ServiceModel.index, ascending: true),
                          NSSortDescriptor(keyPath: \ServiceModel.name, ascending: true)],
        animation: .default)
    private var services: FetchedResults<ServiceModel>

    var body: some View {
        NavigationView {
            List {
                ForEach(services) { service in
                    NavigationLink {
                        ServiceView(context: context, service: service)
                            .onDisappear(perform: { save() })
                    } label: {
                        Text(serviceDisplayName(service))
                    }
                }
                .onDelete(perform: deleteServices)
            }
            .toolbar {
                ToolbarItem(placement: .principal) { // <3>
                    VStack {
                        Text("Services").font(.headline)
                        Text("Manage your services").font(.subheadline)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addService) {
                        Label("Add Service", systemImage: "plus")
                    }
                }
            }
        }
    }
    
    private func save() {
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    private func addService() {
        withAnimation {
            let newService = ServiceModel(context: context)
            newService.name = nil
            newService.type = ServiceType.webdav.rawValue
            save()
        }
    }

    private func deleteServices(offsets: IndexSet) {
        withAnimation {
            offsets.map { services[$0] }.forEach(context.delete)
            save()
        }
    }
}
