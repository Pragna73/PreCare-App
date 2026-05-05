//
//  AppointmentConfirmationView.swift
//  PreCare
//
 
//

import SwiftUI

import SwiftUI

struct AppointmentConfirmationView: View {

    let doctor: Doctor
    @EnvironmentObject var router: AppRouter
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)

            Text("Appointment Confirmed")
                .font(.title2)
                .fontWeight(.bold)

            Text("Your appointment with \(doctor.name) is confirmed.")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            
            PrimaryButton(title: "Go to Dashboard") {
                router.goToDashboard()
                dismiss()
            }

            Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }
}
