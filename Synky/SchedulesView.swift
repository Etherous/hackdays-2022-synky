//
//  HomeView.swift
//  Synky
//
//  Created by Brandon Lyon on 2/28/22.
//

import SwiftUI
import CoreData

struct SchedulesView: View {
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ScheduleModel.index, ascending: true)],
        animation: .default)
    private var schedules: FetchedResults<ScheduleModel>

    var body: some View {
        NavigationView {
            List {
                ForEach(schedules) { schedule in
                    NavigationLink {
                        ScheduleView(context: context, schedule: schedule)
                            .onDisappear(perform: { save() })
                    } label: {
                        Text(scheduleDisplayName(schedule))
                    }
                }
                .onDelete(perform: deleteSchedules)
            }
            .toolbar {
                ToolbarItem(placement: .principal) { // <3>
                    VStack {
                        Text("Schedules").font(.headline)
                        Text("Manage your schedules").font(.subheadline)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addSchedule) {
                        Label("Add Schedule", systemImage: "plus")
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
    
    private func addSchedule() {
        withAnimation {
            let newSchedule = ScheduleModel(context: context)
            save()
        }
    }

    private func deleteSchedules(offsets: IndexSet) {
        withAnimation {
            offsets.map { schedules[$0] }.forEach(context.delete)
            save()
        }
    }
}
