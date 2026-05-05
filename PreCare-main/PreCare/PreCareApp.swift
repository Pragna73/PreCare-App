//
//  PreCareApp.swift
//  PreCare
//
 
//

import SwiftUI

@main
struct PreCareApp: App {

    @StateObject private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {

                Group {
                    if UserDefaults.standard.bool(forKey: "isLoggedIn") {
                        RoleBasedHomeView()
                    } else {
                        LoginView()
                    }
                }

                .navigationDestination(for: AppRoute.self) { route in
                    switch route {

                    case .dashboard:
                        RoleBasedHomeView()

                    case .workflow:
                        WorkflowView()

                    case .analysisResult:
                        AnalysisResultView()

                    case .aiDecision(let severity):
                        AIHealthDecisionView(severity: severity)

                    case .bookDoctor:
                        BookDoctorView()

                    case .appointmentConfirmation(let doctor):
                        AppointmentConfirmationView(doctor: doctor)
                    }
                }
            }
            .environmentObject(router)
        }
    }
}
