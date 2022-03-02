//
//  AccountsView.swift
//  Synky
//
//  Created by Brandon Lyon on 2/28/22.
//

import SwiftUI
import CoreData

struct AccountsView: View {
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \AccountModel.index, ascending: true),
                          NSSortDescriptor(keyPath: \AccountModel.name, ascending: true)],
        animation: .default)
    private var accounts: FetchedResults<AccountModel>

    var body: some View {
        NavigationView {
            List {
                ForEach(accounts) { account in
                    NavigationLink {
                        AccountView(context: context, account: account)
                            .onDisappear(perform: { save() })
                    } label: {
                        Text(accountDisplayName(account))
                    }
                }
                .onDelete(perform: deleteAccounts)
            }
            .toolbar {
                ToolbarItem(placement: .principal) { // <3>
                    VStack {
                        Text("Accounts").font(.headline)
                        Text("Manage your accounts").font(.subheadline)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addAccount) {
                        Label("Add Account", systemImage: "plus")
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
    
    private func addAccount() {
        withAnimation {
            let newAccount = AccountModel(context: context)
            newAccount.name = nil
            save()
        }
    }

    private func deleteAccounts(offsets: IndexSet) {
        withAnimation {
            offsets.map { accounts[$0] }.forEach(context.delete)
            save()
        }
    }
}
