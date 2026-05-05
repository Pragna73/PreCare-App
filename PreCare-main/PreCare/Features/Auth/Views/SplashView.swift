//
//  SplashView.swift
//  PreCare
//
 
//

import SwiftUI

struct SplashView: View {

    @EnvironmentObject var router: AppRouter

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "#FF2D6F"))

            Text("PreCare")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("AI Healthcare Platform")
                .foregroundColor(.gray)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                if UserDefaults.standard.bool(forKey: "isLoggedIn") {
                    router.push(.dashboard)
                }
            }
        }
    }
}
