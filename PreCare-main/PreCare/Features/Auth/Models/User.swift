import Foundation

enum UserRole: String, Codable, CaseIterable {
    case patient = "PATIENT"
    case doctor = "DOCTOR"
    case emergency = "EMERGENCY"
    case staff = "STAFF"

    static func from(raw: String?) -> UserRole {
        switch (raw ?? "").trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
        case "DOCTOR":
            return .doctor
        case "EMERGENCY", "EMERGENCY_RESPONDER", "RESPONDER":
            return .emergency
        case "STAFF", "HEALTHCARE_STAFF":
            return .staff
        default:
            return .patient
        }
    }
}

struct User: Codable, Identifiable {
    let id: String
    let fullName: String
    let email: String
    let role: UserRole
    let phoneNumber: String?
    let createdAt: Date?

    init(id: String, fullName: String, email: String, role: UserRole = .patient, phoneNumber: String? = nil, createdAt: Date? = nil) {
        self.id = id
        self.fullName = fullName
        self.email = email
        self.role = role
        self.phoneNumber = phoneNumber
        self.createdAt = createdAt
    }

    init?(json: [String: Any]) {
        guard let email = APIClient.readString(json, keys: ["email"]) else {
            return nil
        }

        self.id = APIClient.readString(json, keys: ["id", "user_id"]) ?? UUID().uuidString
        self.fullName = APIClient.readString(json, keys: ["full_name", "fullName", "name"]) ?? ""
        self.email = email
        self.role = UserRole.from(raw: APIClient.readString(json, keys: ["role", "user_role"]))
        self.phoneNumber = APIClient.readString(json, keys: ["mobile", "phone_number", "phone"])

        if let rawDate = APIClient.readString(json, keys: ["created_at", "createdAt"]) {
            self.createdAt = ISO8601DateFormatter().date(from: rawDate)
        } else {
            self.createdAt = nil
        }
    }
}
