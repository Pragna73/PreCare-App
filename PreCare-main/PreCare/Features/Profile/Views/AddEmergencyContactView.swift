//
//  AddEmergencyContactView.swift
//  PreCare
//
 
//

import SwiftUI

struct AddEmergencyContactView: View {

    @ObservedObject var vm: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var relation = ""
    @State private var phone = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Contact Details")) {
                    TextField("Full Name", text: $name)
                    TextField("Relationship", text: $relation)
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                }
            }
            .navigationTitle("Add Contact")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            let didSave = await vm.addEmergencyContact(
                                name: name,
                                relation: relation,
                                phone: phone
                            )
                            if didSave {
                                dismiss()
                            }
                        }
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
