//
//  ScheduleView.swift
//  Synky
//
//  Created by Brandon Lyon on 2/28/22.
//

import SwiftUI
import CoreData

struct ScheduleView: View {
    var context : NSManagedObjectContext
    
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var schedule: ScheduleModel
    
    @State private var confirmDelete = false
    
    var localUrlsProxy : Binding<[URL]> {
        Binding<[URL]>(
            get: {
                schedule.localPath != nil ? [schedule.localPath!] : []
            },
            set: {
                if $0.count > 0 {
                    schedule.localPath = $0[0]
                } else {
                    schedule.localPath = nil
                }
            }
        )
    }

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ServiceModel.index, ascending: true),
                          NSSortDescriptor(keyPath: \ServiceModel.name, ascending: true)],
        animation: .default)
    private var services: FetchedResults<ServiceModel>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \AccountModel.index, ascending: true),
                          NSSortDescriptor(keyPath: \AccountModel.name, ascending: true)],
        animation: .default)
    private var accounts: FetchedResults<AccountModel>
    
    @State private var showLocalFolderPicker = false
    
    @State private var runResult : ServiceCallResult? = nil

    var scheduleTypeProxy : Binding<ScheduleType> {
        Binding<ScheduleType>(
            get: {
                schedule.type != nil ? ScheduleType.find(schedule.type!) ?? .off : .off
            },
            set: {
                schedule.type = $0.rawValue
            }
        )
    }

    var syncDirectionProxy : Binding<SyncDirection> {
        Binding<SyncDirection>(
            get: {
                schedule.direction != nil ? SyncDirection.find(schedule.direction!) ?? .up : .up
            },
            set: {
                schedule.direction = $0.rawValue
            }
        )
    }

    var body: some View {
        Form {
            Section(header: Text("Basic")) {
                TextField("Name", text: $schedule.name ?? "", onEditingChanged: { if !$0 {save()} })
                VStack {
                    Picker("Type", selection: scheduleTypeProxy) {
                        ForEach(ScheduleType.allCases) { type in
                            Text(type.rawValue)
                        }
                    }
                    .onChange(of: schedule.type, perform: {_ in save()})
                }
                VStack {
                    Picker("Service", selection: $schedule.service) {
                        ForEach(services) { service in
                            Text(serviceDisplayName(service))
                                .tag(service as ServiceModel?)
                        }
                    }
                    .onChange(of: schedule.service, perform: {_ in save()})
                }
                VStack {
                    Picker("Account", selection: $schedule.account) {
                        ForEach(accounts) { account in
                            Text(accountDisplayName(account))
                                .tag(account as AccountModel?)
                        }
                    }
                    .onChange(of: schedule.service, perform: {_ in save()})
                }
                Toggle(isOn: $schedule.useCellular) {
                    Text("Use cellular data")
                }
                Button(schedule.localPath?.lastPathComponent ?? "(Select Local Folder)") {
                    showLocalFolderPicker = true
                }
                .sheet(isPresented: $showLocalFolderPicker) {
                    FilePicker(selection: localUrlsProxy)
                        .onDisappear (perform: save)
                }
                TextField("Remote Path", text: $schedule.remotePath ?? "", onEditingChanged: { if !$0 {save()} })
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(TextInputAutocapitalization.never)
                VStack {
                    Picker("Direction", selection: syncDirectionProxy) {
                        ForEach(SyncDirection.allCases) { direction in
                            Text(direction.description)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: schedule.direction, perform: {_ in save()})
                }
                // TODO: Delete extra files?
                // TODO: Skip newer files?
            }
        }
        .navigationBarTitle("Schedule")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Run", action: runOnce)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Delete") {
                    confirmDelete = true
                }
                .foregroundColor(.red)
                .confirmationDialog("Really delete?", isPresented: $confirmDelete) {
                    Button("Delete", role: .destructive, action: delete)
                    Button("Cancel", role: .cancel, action: {})
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
    
    private func runOnce() {
        let client = createServiceClient(service: schedule.service!, account: schedule.account!)!
        runResult = client.runSchedule(schedule, isForced: true) {result in runResult = result}
    }
    
    private func delete () {
        context.delete(schedule)
        save()
        presentationMode.wrappedValue.dismiss()
    }
}
