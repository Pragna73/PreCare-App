

import SwiftUI

import Combine



final class AppRouter: ObservableObject {

    @Published var path = NavigationPath()

    // MARK: - Navigation Helpers
    func push(_ route: AppRoute) {
        path.append(route)
    }

    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    func goToDashboard() {
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        path = NavigationPath()
        path.append(AppRoute.dashboard)
    }
}
