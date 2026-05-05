//
//  BookDoctorView.swift
//  PreCare
//
 
//


import SwiftUI

struct BookDoctorView: View {

    @State private var selectedDoctor: Doctor?
    @State private var showConfirmation = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {

                // MARK: - AI Recommendation
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI Recommendation")
                        .font(.headline)
                        .foregroundColor(.purple)

                    Text("Based on your report, we recommend consulting a gynecologist or general physician.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.purple.opacity(0.1))
                .cornerRadius(16)

                // MARK: - Doctors List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Available Doctors")
                        .font(.title3)
                        .fontWeight(.semibold)

                    ForEach(Doctor.sampleDoctors) { doctor in
                        DoctorCard(
                            doctor: doctor,
                            isSelected: selectedDoctor?.id == doctor.id
                        )
                        .onTapGesture {
                            selectedDoctor = doctor
                        }
                    }
                }

                // MARK: - Book Button
                PrimaryButton(
                    title: selectedDoctor == nil
                        ? "Select a Doctor"
                        : "Book Appointment with \(selectedDoctor!.name)"
                ) {
                    showConfirmation = true
                }
                .disabled(selectedDoctor == nil)
                .opacity(selectedDoctor == nil ? 0.6 : 1)

                Spacer(minLength: 20)
            }
            .padding()
        }
        .navigationTitle("Book Doctor")
        .navigationBarTitleDisplayMode(.inline)

        // ✅ SAFE NAVIGATION
        .navigationDestination(isPresented: $showConfirmation) {
            if let doctor = selectedDoctor {
                AppointmentConfirmationView(doctor: doctor)
            }
        }
    }
}
