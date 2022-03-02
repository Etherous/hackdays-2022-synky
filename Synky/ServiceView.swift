//
//  ServiceView.swift
//  Synky
//
//  Created by Brandon Lyon on 2/28/22.
//

import SwiftUI
import CoreData

struct ServiceView: View {
    var context : NSManagedObjectContext
    
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var service: ServiceModel
    
    @State private var confirmDelete = false
    
    @State private var showTestSheet = false

    @State private var testAccount: AccountModel?
    
    @State private var testResult: ServiceCallResult? = nil

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \AccountModel.index, ascending: true),
                          NSSortDescriptor(keyPath: \AccountModel.name, ascending: true)],
        animation: .default)
    private var accounts: FetchedResults<AccountModel>

    var serviceTypeProxy : Binding<ServiceType> {
        Binding<ServiceType>(
            get: {
                service.type != nil ? ServiceType.find(service.type!) ?? .none : .none
            },
            set: {
                service.type = $0.rawValue
            }
        )
    }
    
    var body: some View {
        Form {
            Section(header: Text("Basic")) {
                TextField("Name", text: $service.name ?? "", onEditingChanged: { if !$0 {save()} })
                TextField("Host/Port", text: $service.host ?? "", onEditingChanged: { if !$0 {save()} })
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(TextInputAutocapitalization.never)
                VStack {
                    Picker("Type", selection: serviceTypeProxy) {
                        ForEach(ServiceType.allCases) { type in
                            Text(type.rawValue)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: service.type, perform: {_ in save()})
                }
            }
        }
        .navigationBarTitle("Service")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Test") {
                    testResult = nil
                    showTestSheet = true
                }
                .sheet(isPresented: $showTestSheet) {
                    Picker("Account", selection: $testAccount) {
                        Text("Select Account to Test")
                            .tag(nil as Int?)
                        ForEach(accounts) { account in
                            Text(accountDisplayName(account))
                                .tag(account as AccountModel?)
                        }
                    }
                    .padding()
                    Button("Test", action: testConnection)
                        .disabled(testAccount == nil)
                        .padding()
                    if testResult != nil {
                        if testResult!.success == nil {
                            Text("Testing...")
                                .foregroundColor(.yellow)
                        } else if testResult!.success! {
                            Text("Success!")
                                .foregroundColor(.green)
                        } else {
                            Text("Error: \(testResult!.error!)")
                                .foregroundColor(.red)
                        }
                    } else {
                        Text("(Not tested)")
                            .foregroundColor(.gray)
                    }
                }
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
    
    private func delete () {
        context.delete(service)
        save()
        presentationMode.wrappedValue.dismiss()
    }
    
    private func testConnection (){
        var client = createServiceClient(service: service, account: testAccount!)!
        testResult = client.test{result in testResult = result}
    }
}
