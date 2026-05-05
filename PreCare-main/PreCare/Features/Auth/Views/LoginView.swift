import SwiftUI

struct LoginView: View {

    @StateObject private var vm = AuthViewModel()
    @EnvironmentObject var router: AppRouter

    var body: some View {
        VStack(spacing: 24) {

            Spacer().frame(height: 40)

            VStack(spacing: 4) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(Color(hex: "#FF2D6F"))
                    Text("PreCare")
                        .font(.system(size: 18, weight: .bold))
                }
                Text("AI Healthcare Platform")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }

            Spacer().frame(height: 30)

            Text("Welcome back")
                .font(.system(size: 26, weight: .bold))

            VStack(spacing: 16) {
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
            }

            Button {
                vm.loginUser {
                    router.push(.dashboard)
                }
            } label: {
                Text(vm.isLoading ? "Signing in..." : "Sign in")
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

            HStack {
                Text("Don't have an account?")
                    .foregroundColor(.gray)

                NavigationLink("Sign up") {
                    RegisterView()
                }
                .foregroundColor(Color(hex: "#FF2D6F"))
            }

            Spacer().frame(height: 20)
        }
        .padding(.horizontal, 24)
        .navigationBarBackButtonHidden(true)
    }
}
