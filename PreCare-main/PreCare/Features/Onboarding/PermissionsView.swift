//
//  PermissionsView.swift
//  PreCare
//
 
//

import SwiftUI

struct PermissionsView: View {

    @EnvironmentObject var router: AppRouter
    @StateObject private var permissionManager = PermissionManager()

    var body: some View {
        VStack(spacing: 32) {

            Spacer()

            Text("PreCare Needs Access")
                .font(.title)
                .fontWeight(.bold)

            PermissionRow(
                icon: "location.fill",
                title: "Location",
                subtitle: "Track emergency services"
            )

            PermissionRow(
                icon: "bell.fill",
                title: "Notifications",
                subtitle: "Emergency alerts & updates"
            )

            PermissionRow(
                icon: "phone.fill",
                title: "Phone",
                subtitle: "Call emergency contacts"
            )

            Spacer()

            PrimaryButton(title: "Allow & Continue") {
                permissionManager.requestLocationPermission()
                permissionManager.requestNotificationPermission()

                UserDefaults.standard.set(true, forKey: "didCompletePermissions")
                UserDefaults.standard.set(false, forKey: "isLoggedIn")
                router.path = NavigationPath()
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }
}
