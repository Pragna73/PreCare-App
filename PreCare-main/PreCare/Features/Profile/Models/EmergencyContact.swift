import Foundation

struct EmergencyContact: Identifiable, Codable {
    let id: String
    var name: String
    var relation: String
    var phone: String
    var isPrimary: Bool

    init(id: String = UUID().uuidString, name: String, relation: String, phone: String, isPrimary: Bool = false) {
        self.id = id
        self.name = name
        self.relation = relation
        self.phone = phone
        self.isPrimary = isPrimary
    }

    init?(json: [String: Any]) {
        guard let phone = APIClient.readString(json, keys: ["phone_number", "phone"]) else {
            return nil
        }

        self.id = APIClient.readString(json, keys: ["id", "contact_id"]) ?? UUID().uuidString
        self.name = APIClient.readString(json, keys: ["label", "name"]) ?? "Emergency Contact"
        self.relation = APIClient.readString(json, keys: ["relationship", "relation"]) ?? "Unknown"
        self.phone = phone
        self.isPrimary = json["is_primary"] as? Bool ?? false
    }
}
