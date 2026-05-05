//
//  EmergencyContactsView.swift
//  PreCare
//
 
//


import SwiftUI

struct EmergencyContactsView: View {

    @ObservedObject var vm: ProfileViewModel
    @State private var showAddContact = false

    var body: some View {
        VStack(spacing: 16) {
            if vm.isLoading {
                ProgressView("Loading contacts...")
                    .padding(.top, 20)
            }

            if let errorMessage = vm.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            if vm.emergencyContacts.isEmpty && !vm.isLoading {
                Text("No emergency contacts added")
                    .foregroundColor(.gray)
                    .padding(.top, 20)
            }

            List {
                ForEach(vm.emergencyContacts) { contact in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(contact.name)
                            .font(.headline)

                        Text(contact.relation)
                            .font(.caption)
                            .foregroundColor(.gray)

                        Text(contact.phone)
                            .font(.subheadline)
                    }
                    .padding(.vertical, 6)
                }
            }
            .listStyle(.insetGrouped)

            // MARK: - Add Contact Button
            PrimaryButton(title: "Add Emergency Contact") {
                showAddContact = true
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .navigationTitle("Emergency Contacts")
        .navigationBarTitleDisplayMode(.inline)

        // MARK: - Sheet Routing
        .sheet(isPresented: $showAddContact) {
            AddEmergencyContactView(vm: vm)
        }
        .task {
            await vm.refreshContacts()
        }
    }
}
