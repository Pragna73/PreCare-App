import Foundation

final class SessionStore {
    static let shared = SessionStore()

    private enum Keys {
        static let accessToken = "access_token"
        static let isLoggedIn = "isLoggedIn"
        static let cachedName = "cached_full_name"
        static let cachedEmail = "cached_email"
        static let userID = "user_id"
        static let userRole = "user_role"
        static let latestReportID = "latest_report_id"
    }

    private let defaults = UserDefaults.standard

    private init() {}

    var accessToken: String? {
        defaults.string(forKey: Keys.accessToken)
    }

    var cachedName: String {
        defaults.string(forKey: Keys.cachedName) ?? ""
    }

    var cachedEmail: String {
        defaults.string(forKey: Keys.cachedEmail) ?? ""
    }

    var userID: String {
        defaults.string(forKey: Keys.userID) ?? ""
    }

    var userRole: UserRole {
        UserRole.from(raw: defaults.string(forKey: Keys.userRole))
    }

    var latestReportID: String {
        defaults.string(forKey: Keys.latestReportID) ?? ""
    }

    func saveAccessToken(_ token: String, userID: String? = nil, role: UserRole? = nil) {
        defaults.set(token, forKey: Keys.accessToken)
        if let userID, !userID.isEmpty {
            defaults.set(userID, forKey: Keys.userID)
        }
        if let role {
            defaults.set(role.rawValue, forKey: Keys.userRole)
        }
        defaults.set(true, forKey: Keys.isLoggedIn)
    }

    func saveUser(name: String, email: String, role: UserRole? = nil) {
        defaults.set(name, forKey: Keys.cachedName)
        defaults.set(email, forKey: Keys.cachedEmail)
        if let role {
            defaults.set(role.rawValue, forKey: Keys.userRole)
        }
    }

    func saveLatestReportID(_ reportID: String) {
        defaults.set(reportID, forKey: Keys.latestReportID)
    }

    func clearSession() {
        defaults.removeObject(forKey: Keys.accessToken)
        defaults.removeObject(forKey: Keys.userID)
        defaults.removeObject(forKey: Keys.userRole)
        defaults.removeObject(forKey: Keys.latestReportID)
        defaults.set(false, forKey: Keys.isLoggedIn)
    }
}
