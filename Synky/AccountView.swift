//
//  AccountView.swift
//  Synky
//
//  Created by Brandon Lyon on 2/28/22.
//

import SwiftUI
import CoreData

struct AccountView: View {
    var context : NSManagedObjectContext
    
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var account: AccountModel
    
    @State private var confirmDelete = false

    var body: some View {
        Form {
            Section(header: Text("Basic")) {
                TextField("Name", text: $account.name ?? "", onEditingChanged: { if !$0 {save()} })
                TextField("Username", text: $account.username ?? "", onEditingChanged: { if !$0 {save()} })
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(TextInputAutocapitalization.never)
                SecureField("Password", text: $account.password ?? "") {
                    save()
                }
                .disableAutocorrection(true)
                .textInputAutocapitalization(TextInputAutocapitalization.never)
            }
        }
        .navigationBarTitle("Account")
        .toolbar {
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
        context.delete(account)
        save()
        presentationMode.wrappedValue.dismiss()
    }
}
