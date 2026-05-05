//
//  RegisterView.swift
//  PreCare
//
 
//


import SwiftUI

struct RegisterView: View {

    @StateObject private var vm = AuthViewModel()
    @EnvironmentObject var router: AppRouter

    var body: some View {
        VStack(spacing: 24) {

            Spacer().frame(height: 40)

            Text("Create your account")
                .font(.system(size: 26, weight: .bold))

            VStack(spacing: 16) {

                InputField(
                    icon: "person",
                    placeholder: "Full name",
                    text: $vm.fullName
                )

                InputField(
                    icon: "envelope",
                    placeholder: "Email address",
                    text: $vm.email
                )

                InputField(
                    icon: "lock",
                    placeholder: "Password",
                    text: $vm.password,
                    isSecure: true
                )

                InputField(
                    icon: "phone",
                    placeholder: "Mobile (optional)",
                    text: $vm.phone
                )

                InputField(
                    icon: "phone.badge.plus",
                    placeholder: "Emergency Contact Phone (optional)",
                    text: $vm.emergencyContact
                )
            }

            Button {
                vm.registerUser {
                    router.push(.dashboard)
                }
            } label: {
                Text(vm.isLoading ? "Creating account..." : "Create account")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(Color(hex: "#FF2D6F"))
                    .cornerRadius(14)
            }
            .disabled(vm.isLoading)

            if let errorMessage = vm.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            NavigationLink("Already have an account? Sign in") {
                LoginView()
            }
            .foregroundColor(Color(hex: "#FF2D6F"))

            Spacer().frame(height: 20)
        }
        .padding(.horizontal, 24)
    }
}
