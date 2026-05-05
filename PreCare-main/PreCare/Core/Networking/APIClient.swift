import Foundation

enum APIError: LocalizedError {
    case invalidResponse
    case unauthorized
    case badStatus(Int, String)
    case invalidPayload
    case missingToken

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response."
        case .unauthorized:
            return "Session expired. Please sign in again."
        case .badStatus(let status, let message):
            return message.isEmpty ? "Request failed (\(status))." : message
        case .invalidPayload:
            return "Unexpected server payload."
        case .missingToken:
            return "Not authenticated."
        }
    }
}

struct RegisterPayload {
    let email: String
    let name: String
    let password: String
    let role: String
    let phone: String?
    let emergencyContact: String?

    var dictionary: [String: Any] {
        var body: [String: Any] = [
            "email": email,
            "name": name,
            "password": password,
            "role": role
        ]

        if let phone, !phone.isEmpty {
            body["phone"] = phone
        }

        if let emergencyContact, !emergencyContact.isEmpty {
            body["emergency_contact"] = emergencyContact
        }

        return body
    }
}

struct LoginPayload {
    let email: String
    let password: String

    var dictionary: [String: Any] {
        ["email": email, "password": password]
    }
}

struct AuthSession {
    let accessToken: String
    let userID: String?
    let role: UserRole?
}

struct EmergencyContactPayload {
    let label: String
    let phoneNumber: String
    let relationship: String
    let isPrimary: Bool

    var dictionary: [String: Any] {
        [
            "label": label,
            "phone_number": phoneNumber,
            "relationship": relationship,
            "is_primary": isPrimary
        ]
    }
}

struct HealthMetricsPayload {
    let hemoglobin: Double
    let systolicBP: Int
    let diastolicBP: Int
    let bloodGlucose: Int
    let weightKG: Double

    var dictionary: [String: Any] {
        [
            "hemoglobin": hemoglobin,
            "systolic_bp": systolicBP,
            "diastolic_bp": diastolicBP,
            "blood_glucose": bloodGlucose,
            "weight_kg": weightKG
        ]
    }
}

struct HealthTrackingSummary {
    let hemoglobin: Double?
    let systolicBP: Int?
    let diastolicBP: Int?
    let bloodGlucose: Int?
    let weightKG: Double?
    let hemoglobinStatus: String?
    let bloodPressureStatus: String?
    let bloodGlucoseStatus: String?
    let weightStatus: String?

    static func from(json: [String: Any]) -> HealthTrackingSummary {
        let source = (json["summary"] as? [String: Any]) ?? json

        let hemoValue = APIClient.readDouble(source, keys: ["hemoglobin"]) ?? APIClient.readNestedDouble(source, key: "hemoglobin")
        let systolic = APIClient.readInt(source, keys: ["systolic_bp"]) ?? APIClient.readNestedInt(source, key: "blood_pressure", nestedKey: "systolic")
        let diastolic = APIClient.readInt(source, keys: ["diastolic_bp"]) ?? APIClient.readNestedInt(source, key: "blood_pressure", nestedKey: "diastolic")
        let glucose = APIClient.readInt(source, keys: ["blood_glucose"]) ?? APIClient.readNestedInt(source, key: "blood_glucose")
        let weight = APIClient.readDouble(source, keys: ["weight_kg"]) ?? APIClient.readNestedDouble(source, key: "weight_kg")

        return HealthTrackingSummary(
            hemoglobin: hemoValue,
            systolicBP: systolic,
            diastolicBP: diastolic,
            bloodGlucose: glucose,
            weightKG: weight,
            hemoglobinStatus: APIClient.readStatus(source, baseKey: "hemoglobin"),
            bloodPressureStatus: APIClient.readStatus(source, baseKey: "blood_pressure"),
            bloodGlucoseStatus: APIClient.readStatus(source, baseKey: "blood_glucose"),
            weightStatus: APIClient.readStatus(source, baseKey: "weight_kg")
        )
    }
}

struct MayaChatHistoryItem {
    let id: String
    let message: String
    let isUser: Bool
    let createdAt: Date

    init?(json: [String: Any], defaultDate: Date? = nil) {
        guard let message = APIClient.readString(json, keys: ["message", "content", "text", "reply", "response"]) else {
            return nil
        }

        self.id = APIClient.readString(json, keys: ["id", "created_at", "timestamp"]) ?? UUID().uuidString
        if let rawDate = APIClient.readString(json, keys: ["created_at", "timestamp", "time"]),
           let parsed = APIClient.parseServerDate(rawDate) {
            self.createdAt = parsed
        } else if let defaultDate {
            self.createdAt = defaultDate
        } else {
            self.createdAt = Date()
        }

        if let isUser = json["is_user"] as? Bool {
            self.isUser = isUser
        } else if let role = APIClient.readString(json, keys: ["role", "sender"]) {
            self.isUser = role.lowercased() == "user"
        } else {
            self.isUser = false
        }

        self.message = message
    }
}

struct MayaChatResponse {
    let reply: String
    let latestRisk: String?
}

struct AgentPlanItem {
    let action: String
    let status: String
    let appointmentId: String?
    let doctor: String?
    let hospital: String?
    let appointmentTime: String?

    init?(json: [String: Any]) {
        guard let action = APIClient.readString(json, keys: ["action"]) else {
            return nil
        }
        self.action = action
        self.status = APIClient.readString(json, keys: ["status"]) ?? "UNKNOWN"

        let payload = (json["payload"] as? [String: Any]) ?? [:]
        self.appointmentId = APIClient.readString(payload, keys: ["appointment_id", "id"])
        self.doctor = APIClient.readString(payload, keys: ["doctor", "doctor_name"])
        self.hospital = APIClient.readString(payload, keys: ["hospital", "hospital_name"])
        self.appointmentTime = APIClient.readString(payload, keys: ["appointment_time", "time"])
    }
}

struct ReportItem: Identifiable {
    let id: String
    let status: String?
    let patientName: String?
    let fileName: String?
    let extractedText: String?
    let structuredData: [String: String]
    let riskLevel: String?
    let riskScore: Double?
    let riskReason: String?
    let recommendation: String?
    let keySignals: [String]
    let confirmationStatus: String?
    let requiresConfirmation: Bool
    let agentPlans: [AgentPlanItem]

    init(
        id: String,
        status: String?,
        patientName: String?,
        fileName: String?,
        extractedText: String?,
        structuredData: [String: String],
        riskLevel: String?,
        riskScore: Double?,
        riskReason: String?,
        recommendation: String?,
        keySignals: [String],
        confirmationStatus: String?,
        agentPlans: [AgentPlanItem],
        requiresConfirmation: Bool
    ) {
        self.id = id
        self.status = status
        self.patientName = patientName
        self.fileName = fileName
        self.extractedText = extractedText
        self.structuredData = structuredData
        self.riskLevel = riskLevel
        self.riskScore = riskScore
        self.riskReason = riskReason
        self.recommendation = recommendation
        self.keySignals = keySignals
        self.confirmationStatus = confirmationStatus
        self.agentPlans = agentPlans
        self.requiresConfirmation = requiresConfirmation
    }

    init?(json: [String: Any]) {
        guard let id = APIClient.readString(json, keys: ["id", "report_id"]) else {
            return nil
        }

        let reportAnalysis = (json["report_analysis"] as? [String: Any]) ?? [:]
        let structuredDataRaw = (json["structured_data"] as? [String: Any]) ?? (reportAnalysis["structured_data"] as? [String: Any]) ?? [:]
        var structuredData: [String: String] = [:]
        for (key, value) in structuredDataRaw {
            if let stringValue = value as? String {
                structuredData[key] = stringValue
            } else if let intValue = value as? Int {
                structuredData[key] = String(intValue)
            } else if let doubleValue = value as? Double {
                structuredData[key] = String(doubleValue)
            }
        }
        let riskObject = (json["risk"] as? [String: Any]) ?? reportAnalysis
        let riskLevel =
            APIClient.readString(riskObject, keys: ["risk", "level", "risk_level"]) ??
            APIClient.readString(json, keys: ["risk", "risk_level"])
        let riskScore =
            APIClient.readDouble(riskObject, keys: ["score", "confidence"]) ??
            APIClient.readDouble(json, keys: ["risk_score", "score", "confidence"])
        let riskReason =
            APIClient.readString(riskObject, keys: ["reason", "reasoning"]) ??
            APIClient.readString(reportAnalysis, keys: ["reasoning"])
        let recommendation =
            APIClient.readString(riskObject, keys: ["recommendation"]) ??
            APIClient.readString(reportAnalysis, keys: ["recommendation"])
        let keySignals = riskObject["key_signals"] as? [String] ?? []
        let requiresConfirmation = APIClient.readBool(json, keys: ["requires_confirmation", "confirmation_required"]) ?? false
        let confirmationStatus = APIClient.readString(json, keys: ["confirmation_status"])
        let agentPlans = (json["agent_plan"] as? [[String: Any]] ?? []).compactMap(AgentPlanItem.init(json:))
        let outcome = (json["outcome"] as? [String: Any]) ?? [:]
        let autoActions = (outcome["auto_actions"] as? [String: Any]) ?? [:]
        let outcomeType = APIClient.readString(outcome, keys: ["type"]) ?? riskLevel
        let outcomeMessage = APIClient.readString(outcome, keys: ["message"])
        let autoStatus = APIClient.readString(autoActions, keys: ["status"])

        self.id = id
        self.status = APIClient.readString(json, keys: ["status"]) ?? autoStatus
        self.patientName = APIClient.readString(json, keys: ["patient_name", "patientName"])
        self.fileName = APIClient.readString(json, keys: ["file_name", "filename", "name"])
        self.extractedText = APIClient.readString(json, keys: ["extracted_text", "text"]) ?? APIClient.readString(reportAnalysis, keys: ["extracted_text"])
        self.structuredData = structuredData
        self.riskLevel = outcomeType ?? riskLevel
        self.riskScore = riskScore
        self.riskReason = riskReason ?? outcomeMessage
        self.recommendation = recommendation ?? outcomeMessage
        self.keySignals = keySignals
        self.confirmationStatus = confirmationStatus
        self.agentPlans = agentPlans
        self.requiresConfirmation = requiresConfirmation
    }
}

struct DashboardSnapshot {
    let lastUploadedReportID: String?
    let latestRiskLevel: String?
    let systemState: String?
    let nextAppointmentLabel: String?
    let emergencyStatus: String?

    static func from(json: [String: Any]) -> DashboardSnapshot {
        let lastUploadedReportID: String? = {
            if let last = json["last_uploaded_report"] as? [String: Any] {
                return APIClient.readString(last, keys: ["id", "report_id"])
            }
            if let last = json["last_report"] as? [String: Any] {
                return APIClient.readString(last, keys: ["id", "report_id"])
            }
            return nil
        }()

        let latestRiskLevel: String? = {
            if let ai = json["ai_health_status"] as? [String: Any] {
                return APIClient.readString(ai, keys: ["latest_risk_level"])
            }
            if let last = json["last_report"] as? [String: Any] {
                return APIClient.readString(last, keys: ["risk"])
            }
            return APIClient.readString(json, keys: ["health_status"])
        }()

        let systemState: String? = {
            if let ai = json["ai_health_status"] as? [String: Any] {
                return APIClient.readString(ai, keys: ["system_state"])
            }
            return nil
        }()

        let nextAppointmentLabel: String? = {
            if let next = json["next_appointment"] as? [String: Any] {
                return APIClient.readString(next, keys: ["time", "date", "doctor"])
            }
            if let list = json["upcoming_appointments"] as? [[String: Any]], let first = list.first {
                let doctor = APIClient.readString(first, keys: ["doctor", "doctor_name"]) ?? "Doctor"
                let time = APIClient.readString(first, keys: ["time", "appointment_time"]) ?? "Scheduled"
                return "\(doctor) • \(time)"
            }
            if let text = APIClient.readString(json, keys: ["next_appointment"]), !text.isEmpty, text.lowercased() != "null" {
                return text
            }
            return nil
        }()

        let emergencyStatus: String? = {
            if let status = json["emergency_status"] as? [String: Any] {
                return APIClient.readString(status, keys: ["status", "message", "label"])
            }
            return APIClient.readString(json, keys: ["emergency_status"])
        }()

        return DashboardSnapshot(
            lastUploadedReportID: lastUploadedReportID,
            latestRiskLevel: latestRiskLevel,
            systemState: systemState,
            nextAppointmentLabel: nextAppointmentLabel,
            emergencyStatus: emergencyStatus
        )
    }
}

struct ReportSummaryItem: Identifiable {
    let id: String
    let userID: String?
    let filename: String
    let riskLevel: String
    let confidence: Double?
    let createdAt: String?

    init?(json: [String: Any]) {
        guard let reportID = APIClient.readString(json, keys: ["report_id", "id"]) else {
            return nil
        }
        self.id = reportID
        self.userID = APIClient.readString(json, keys: ["user_id"])
        self.filename = APIClient.readString(json, keys: ["filename", "file_name"]) ?? "Report"
        self.riskLevel = APIClient.readString(json, keys: ["risk_level", "risk"]) ?? "UNKNOWN"
        self.confidence = APIClient.readDouble(json, keys: ["confidence", "score"])
        self.createdAt = APIClient.readString(json, keys: ["created_at"])
    }
}

final class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let baseURL = URL(string: "http://127.0.0.1:8000")!
    private let isDebugLoggingEnabled = true
    private var wsSession: URLSession?
    private var mayaWebSocketTask: URLSessionWebSocketTask?
    private var onMayaSocketText: ((String) -> Void)?
    private var onMayaSocketError: ((String) -> Void)?

    private init(session: URLSession = .shared) {
        self.session = session
    }

    func health() async throws {
        _ = try await request(path: "/health")
    }

    func register(_ payload: RegisterPayload) async throws -> String? {
        let data = try await request(path: "/auth/signup", method: "POST", body: payload.dictionary)
        let object = try jsonObject(from: data)

        if let json = object as? [String: Any] {
            if let nested = json["user"] as? [String: Any] {
                return APIClient.readString(nested, keys: ["id", "user_id"])
            }
            return APIClient.readString(json, keys: ["id", "user_id"])
        }

        return nil
    }

    func login(_ payload: LoginPayload) async throws -> AuthSession {
        let data = try await request(path: "/auth/login", method: "POST", body: payload.dictionary)
        let object = try jsonObject(from: data)

        guard
            let json = object as? [String: Any],
            let token = APIClient.readString(json, keys: ["access_token", "token", "accessToken"])
        else {
            throw APIError.invalidPayload
        }

        let userID: String? = {
            if let user = json["user"] as? [String: Any] {
                return APIClient.readString(user, keys: ["id", "user_id"])
            }
            return APIClient.readString(json, keys: ["user_id", "id"])
        }()

        let role: UserRole? = {
            if let user = json["user"] as? [String: Any] {
                return UserRole.from(raw: APIClient.readString(user, keys: ["role"]))
            }
            if let value = APIClient.readString(json, keys: ["role"]) {
                return UserRole.from(raw: value)
            }
            return nil
        }()

        return AuthSession(accessToken: token, userID: userID, role: role)
    }

    func me() async throws -> User {
        let data = try await request(path: "/auth/me", requiresAuth: true)
        let object = try jsonObject(from: data)

        if let user = parseUser(object: object) {
            return user
        }

        throw APIError.invalidPayload
    }

    func logout() async throws {
        _ = try await request(path: "/auth/logout", method: "POST", requiresAuth: true)
    }

    func addEmergencyContact(_ payload: EmergencyContactPayload) async throws -> EmergencyContact {
        let data = try await request(path: "/auth/emergency-contacts", method: "POST", body: payload.dictionary, requiresAuth: true)
        let object = try jsonObject(from: data)

        if let json = object as? [String: Any] {
            if let nested = json["contact"] as? [String: Any], let mapped = EmergencyContact(json: nested) {
                return mapped
            }

            if let mapped = EmergencyContact(json: json) {
                return mapped
            }
        }

        throw APIError.invalidPayload
    }

    func emergencyContacts() async throws -> [EmergencyContact] {
        let data = try await request(path: "/auth/emergency-contacts", requiresAuth: true)
        let object = try jsonObject(from: data)

        if let json = object as? [String: Any], let list = json["items"] as? [[String: Any]] {
            return list.compactMap(EmergencyContact.init(json:))
        }

        if let json = object as? [String: Any], let list = json["contacts"] as? [[String: Any]] {
            return list.compactMap(EmergencyContact.init(json:))
        }

        if let list = object as? [[String: Any]] {
            return list.compactMap(EmergencyContact.init(json:))
        }

        throw APIError.invalidPayload
    }

    func submitHealthMetrics(_ payload: HealthMetricsPayload) async throws {
        _ = try await request(path: "/health-tracking/metrics", method: "POST", body: payload.dictionary, requiresAuth: true)
    }

    func healthTrackingSummary() async throws -> HealthTrackingSummary {
        let data = try await request(path: "/health-tracking/summary", requiresAuth: true)
        let object = try jsonObject(from: data)

        guard let json = object as? [String: Any] else {
            throw APIError.invalidPayload
        }

        return HealthTrackingSummary.from(json: json)
    }

    func sendMayaMessage(_ message: String) async throws -> MayaChatResponse {
        let data = try await request(path: "/maya/chat", method: "POST", body: ["message": message], requiresAuth: true)
        if isDebugLoggingEnabled {
            debugLogResponse(statusCode: 200, data: data)
        }
        let object = try jsonObject(from: data)

        guard let json = object as? [String: Any] else {
            throw APIError.invalidPayload
        }

        if let reply = APIClient.readString(json, keys: ["reply", "response", "message", "content"]) {
            let latestRisk = APIClient.readString(json, keys: ["latest_risk", "latestRisk", "risk"])
            return MayaChatResponse(reply: reply, latestRisk: latestRisk)
        }

        if let nested = json["data"] as? [String: Any],
           let reply = APIClient.readString(nested, keys: ["reply", "response", "message", "content"]) {
            let latestRisk = APIClient.readString(nested, keys: ["latest_risk", "latestRisk", "risk"])
            return MayaChatResponse(reply: reply, latestRisk: latestRisk)
        }

        throw APIError.invalidPayload
    }

    func mayaChatHistory(limit: Int = 20) async throws -> [MayaChatHistoryItem] {
        let data = try await request(
            path: "/maya/chat/history",
            queryItems: [URLQueryItem(name: "limit", value: String(limit))],
            requiresAuth: true
        )

        let object = try jsonObject(from: data)

        if let list = object as? [[String: Any]] {
            return list.compactMap { MayaChatHistoryItem(json: $0) }
        }

        if let json = object as? [String: Any], let list = json["history"] as? [[String: Any]] {
            return list.compactMap { MayaChatHistoryItem(json: $0) }
        }

        if let json = object as? [String: Any], let list = json["items"] as? [[String: Any]] {
            return list.compactMap { MayaChatHistoryItem(json: $0) }
        }

        throw APIError.invalidPayload
    }

    func mayaGroupedChatHistory(limit: Int = 100) async throws -> [MayaChatHistoryItem] {
        let data = try await request(
            path: "/maya/chat/history/grouped",
            queryItems: [URLQueryItem(name: "limit", value: String(limit))],
            requiresAuth: true
        )

        let object = try jsonObject(from: data)
        guard let json = object as? [String: Any] else {
            throw APIError.invalidPayload
        }

        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now
        let earlier = Calendar.current.date(byAdding: .day, value: -2, to: now) ?? now

        let todayItems = (json["today"] as? [[String: Any]] ?? []).compactMap {
            MayaChatHistoryItem(json: $0, defaultDate: now)
        }
        let yesterdayItems = (json["yesterday"] as? [[String: Any]] ?? []).compactMap {
            MayaChatHistoryItem(json: $0, defaultDate: yesterday)
        }
        let earlierItems = (json["earlier"] as? [[String: Any]] ?? []).compactMap {
            MayaChatHistoryItem(json: $0, defaultDate: earlier)
        }

        return todayItems + yesterdayItems + earlierItems
    }

    func connectMayaWebSocket(
        onText: @escaping (String) -> Void,
        onError: @escaping (String) -> Void
    ) throws {
        guard let token = SessionStore.shared.accessToken, !token.isEmpty else {
            throw APIError.missingToken
        }

        disconnectMayaWebSocket()

        var components = URLComponents(url: url(path: "/maya/ws"), resolvingAgainstBaseURL: false)
        components?.scheme = baseURL.scheme == "https" ? "wss" : "ws"
        components?.queryItems = [URLQueryItem(name: "token", value: token)]

        guard let wsURL = components?.url else {
            throw APIError.invalidResponse
        }

        let session = URLSession(configuration: .default)
        let task = session.webSocketTask(with: wsURL)

        wsSession = session
        mayaWebSocketTask = task
        onMayaSocketText = onText
        onMayaSocketError = onError

        task.resume()
        receiveMayaSocketMessages()
    }

    func sendMayaWebSocketMessage(_ message: String) async throws {
        guard let task = mayaWebSocketTask else {
            throw APIError.invalidResponse
        }
        try await task.send(.string(message))
    }

    func disconnectMayaWebSocket() {
        mayaWebSocketTask?.cancel(with: .goingAway, reason: nil)
        mayaWebSocketTask = nil
        wsSession = nil
        onMayaSocketText = nil
        onMayaSocketError = nil
    }

    func uploadReport(fileURL: URL, userID: String, patientName: String?) async throws -> ReportItem {
        guard let token = SessionStore.shared.accessToken, !token.isEmpty else {
            throw APIError.missingToken
        }

        var request = URLRequest(url: url(path: "/reports/upload"))
        request.httpMethod = "POST"
        request.timeoutInterval = 60

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        var body = Data()

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"user_id\"\r\n\r\n")
        body.append("\(userID)\r\n")

        if let patientName, !patientName.isEmpty {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"patient_name\"\r\n\r\n")
            body.append("\(patientName)\r\n")
        }

        let fileData = try Data(contentsOf: fileURL)
        let filename = fileURL.lastPathComponent
        let mime = mimeType(for: fileURL.pathExtension)

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
        body.append("Content-Type: \(mime)\r\n\r\n")
        body.append(fileData)
        body.append("\r\n")
        body.append("--\(boundary)--\r\n")

        request.httpBody = body

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)

        let object = try jsonObject(from: data)
        if let json = object as? [String: Any], let report = ReportItem(json: json) {
            return report
        }

        if let json = object as? [String: Any], let nested = json["report"] as? [String: Any], let report = ReportItem(json: nested) {
            return report
        }

        throw APIError.invalidPayload
    }

    func report(id: String) async throws -> ReportItem {
        let data = try await request(path: "/reports/\(id)", requiresAuth: true)
        let object = try jsonObject(from: data)

        if let json = object as? [String: Any], let report = ReportItem(json: json) {
            return report
        }

        if let json = object as? [String: Any], let nested = json["report"] as? [String: Any], let report = ReportItem(json: nested) {
            return report
        }

        throw APIError.invalidPayload
    }

    func confirmReport(id: String, confirm: Bool) async throws {
        _ = try await request(path: "/reports/\(id)/confirm", method: "POST", body: ["confirm": confirm], requiresAuth: true)
    }

    func extractReport(reportID: String) async throws -> String {
        let data = try await request(path: "/reports/\(reportID)/extract", method: "POST", requiresAuth: true)
        guard let json = (try? jsonObject(from: data)) as? [String: Any] else {
            return "Report text extracted successfully."
        }

        let extracted = APIClient.readString(json, keys: ["extracted_text"]) ?? "Text extracted."
        return "Extraction complete.\n\(extracted.prefix(220))"
    }

    func analyzeRisk(reportID: String, text: String) async throws -> String {
        let data = try await request(
            path: "/ai/analyze-risk",
            method: "POST",
            body: ["report_id": reportID, "text": text],
            requiresAuth: true
        )
        guard let json = (try? jsonObject(from: data)) as? [String: Any] else {
            return "Risk analysis completed."
        }

        let level = APIClient.readString(json, keys: ["risk_level", "risk"]) ?? "UNKNOWN"
        let confidence = APIClient.readDouble(json, keys: ["confidence", "score"]) ?? 0
        let recommendation = APIClient.readString(json, keys: ["recommendation"]) ?? "Follow your doctor advice."
        return "Risk: \(level)\nConfidence: \(String(format: "%.0f%%", confidence * 100))\nRecommendation: \(recommendation)"
    }

    func planAgent(userID: String, riskLevel: String, reportID: String) async throws -> String {
        let data = try await request(
            path: "/agent/plan",
            method: "POST",
            body: ["user_id": userID, "risk_level": riskLevel, "report_id": reportID],
            requiresAuth: true
        )
        guard let json = (try? jsonObject(from: data)) as? [String: Any] else {
            return "Care plan generated."
        }

        let steps = (json["plan"] as? [String] ?? []).prefix(3)
        if steps.isEmpty {
            return "Care plan generated successfully."
        }
        return "Care plan ready:\n• " + steps.joined(separator: "\n• ")
    }

    func bookAppointment(userID: String, preferredDate: String) async throws -> String {
        let data = try await request(
            path: "/appointments/book",
            method: "POST",
            body: ["user_id": userID, "preferred_date": preferredDate],
            requiresAuth: true
        )
        guard let json = (try? jsonObject(from: data)) as? [String: Any] else {
            return "Appointment booked successfully."
        }
        let doctor = APIClient.readString(json, keys: ["doctor", "doctor_name"]) ?? "Doctor assigned"
        let hospital = APIClient.readString(json, keys: ["hospital", "hospital_name"]) ?? "Hospital assigned"
        let time = APIClient.readString(json, keys: ["time", "appointment_time"]) ?? "Time to be confirmed"
        return "Appointment booked with \(doctor), \(hospital) at \(time)."
    }

    func autoBookAppointment(userID: String, location: String) async throws -> String {
        let data = try await request(
            path: "/appointments/auto-book",
            method: "POST",
            body: ["user_id": userID, "location": location],
            requiresAuth: true
        )
        guard let json = (try? jsonObject(from: data)) as? [String: Any] else {
            return "Nearest appointment scheduled automatically."
        }
        let doctor = APIClient.readString(json, keys: ["doctor", "doctor_name"]) ?? "Doctor assigned"
        let hospital = APIClient.readString(json, keys: ["hospital", "hospital_name"]) ?? "Nearby hospital"
        let time = APIClient.readString(json, keys: ["time", "appointment_time"]) ?? "Soon"
        return "Nearest doctor auto-scheduled: \(doctor), \(hospital), \(time)."
    }

    func triggerEmergency(userID: String, location: String, severity: String) async throws -> String {
        let data = try await request(
            path: "/emergency/trigger",
            method: "POST",
            body: ["user_id": userID, "location": location, "severity": severity],
            requiresAuth: true
        )
        guard let json = (try? jsonObject(from: data)) as? [String: Any] else {
            return "Emergency protocol activated."
        }

        let eta = APIClient.readInt(json, keys: ["eta_minutes"]).map { "\($0) mins" } ?? "shortly"
        let ambulance = APIClient.readString(json, keys: ["ambulance"]) ?? "dispatched"
        return "Emergency activated: Ambulance \(ambulance), ETA \(eta). Doctor and family have been notified."
    }

    func userDashboard(userID: String) async throws -> String {
        let data = try await request(path: "/dashboard/\(userID)", requiresAuth: true)
        guard let json = (try? jsonObject(from: data)) as? [String: Any] else {
            return "Dashboard loaded."
        }
        let health = APIClient.readString(json, keys: ["health_status"]) ?? "Status available"
        let emergency = APIClient.readString(json, keys: ["emergency_status"]) ?? "No active emergency"
        return "Health status: \(health). Emergency: \(emergency)."
    }

    func createTwin(userID: String, age: Int, bpHistory: [String], hemoglobin: Double, diabetes: Bool) async throws -> String {
        let data = try await request(
            path: "/twin/create",
            method: "POST",
            body: [
                "user_id": userID,
                "age": age,
                "bp_history": bpHistory,
                "hemoglobin": hemoglobin,
                "diabetes": diabetes
            ],
            requiresAuth: true
        )
        guard let json = (try? jsonObject(from: data)) as? [String: Any] else {
            return "Digital twin created successfully."
        }
        let prediction = APIClient.readString(json, keys: ["risk_prediction"]) ?? "Prediction generated."
        let alert = APIClient.readString(json, keys: ["future_alert"]) ?? "No immediate alert."
        return "Digital twin ready.\nPrediction: \(prediction)\nNext alert: \(alert)"
    }

    func confirmAgent(reportID: String, actionTaken: Bool) async throws -> String {
        let data = try await request(
            path: "/agent/confirm",
            method: "POST",
            body: ["report_id": reportID, "action_taken": actionTaken],
            requiresAuth: true
        )
        guard let json = (try? jsonObject(from: data)) as? [String: Any] else {
            return "Action confirmation updated."
        }
        let status = APIClient.readString(json, keys: ["status"]) ?? "confirmed"
        return "Action \(status)."
    }

    func dashboard() async throws -> String {
        let data = try await request(path: "/dashboard/", requiresAuth: true)

        if data.isEmpty {
            return "Dashboard loaded"
        }

        if
            let object = try? jsonObject(from: data),
            let json = object as? [String: Any]
        {
            let latestRisk = ((json["ai_health_status"] as? [String: Any]).flatMap { APIClient.readString($0, keys: ["latest_risk_level"]) }) ?? "No reports yet"
            return "Dashboard ready. Latest risk level: \(latestRisk)."
        }

        return "Dashboard loaded."
    }

    func dashboardSnapshot(userID: String?) async throws -> DashboardSnapshot {
        let data: Data
        if let userID, !userID.isEmpty {
            data = try await request(path: "/dashboard/\(userID)", requiresAuth: true)
        } else {
            data = try await request(path: "/dashboard/", requiresAuth: true)
        }
        let object = try jsonObject(from: data)
        guard let json = object as? [String: Any] else {
            throw APIError.invalidPayload
        }
        return DashboardSnapshot.from(json: json)
    }

    func docsURL() -> URL {
        url(path: "/docs")
    }

    func userReports(userID: String) async throws -> [ReportSummaryItem] {
        let data = try await request(path: "/reports/user/\(userID)", requiresAuth: true)
        let object = try jsonObject(from: data)
        guard let json = object as? [String: Any] else { return [] }
        let reports = (json["reports"] as? [[String: Any]] ?? []).compactMap(ReportSummaryItem.init(json:))
        return reports
    }

    func allReports() async throws -> [ReportSummaryItem] {
        let data = try await request(path: "/reports/all", requiresAuth: true)
        let object = try jsonObject(from: data)
        guard let json = object as? [String: Any] else { return [] }
        let reports = (json["reports"] as? [[String: Any]] ?? []).compactMap(ReportSummaryItem.init(json:))
        return reports
    }

    func openAPIJSON() async throws -> Data {
        try await request(path: "/openapi.json")
    }

    private func request(
        path: String,
        queryItems: [URLQueryItem]? = nil,
        method: String = "GET",
        body: [String: Any]? = nil,
        requiresAuth: Bool = false
    ) async throws -> Data {
        var request = URLRequest(url: url(path: path, queryItems: queryItems))
        request.httpMethod = method
        request.timeoutInterval = 30

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            if isDebugLoggingEnabled {
                debugLogRequest(request, body: body)
            }
        } else if isDebugLoggingEnabled {
            debugLogRequest(request, body: nil)
        }

        if requiresAuth {
            guard let token = SessionStore.shared.accessToken, !token.isEmpty else {
                throw APIError.missingToken
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
        return data
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if http.statusCode == 401 {
            throw APIError.unauthorized
        }

        guard (200...299).contains(http.statusCode) else {
            let message = extractErrorMessage(from: data)
            if isDebugLoggingEnabled {
                debugLogResponse(statusCode: http.statusCode, data: data)
            }
            throw APIError.badStatus(http.statusCode, message)
        }
    }

    private func url(path: String, queryItems: [URLQueryItem]? = nil) -> URL {
        let normalized = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let base = baseURL.appendingPathComponent(normalized)

        guard let queryItems, !queryItems.isEmpty else {
            return base
        }

        var components = URLComponents(url: base, resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems
        return components?.url ?? base
    }

    private func jsonObject(from data: Data) throws -> Any {
        guard !data.isEmpty else {
            return [:]
        }

        return try JSONSerialization.jsonObject(with: data)
    }

    private func parseUser(object: Any) -> User? {
        if let json = object as? [String: Any], let nested = json["user"] as? [String: Any] {
            return User(json: nested)
        }

        if let json = object as? [String: Any] {
            return User(json: json)
        }

        return nil
    }

    private func extractErrorMessage(from data: Data) -> String {
        guard
            let object = try? JSONSerialization.jsonObject(with: data),
            let json = object as? [String: Any]
        else {
            return String(data: data, encoding: .utf8) ?? ""
        }

        if let detailText = APIClient.readString(json, keys: ["detail", "message", "error"]), !detailText.isEmpty {
            return detailText
        }

        if let detailObject = json["detail"], let lines = parseValidationDetail(detailObject), !lines.isEmpty {
            return lines.joined(separator: "\n")
        }

        return String(data: data, encoding: .utf8) ?? ""
    }

    private func parseValidationDetail(_ detail: Any) -> [String]? {
        if let items = detail as? [[String: Any]] {
            let lines = items.compactMap { item -> String? in
                let message = item["msg"] as? String ?? "Invalid value"
                if let locItems = item["loc"] as? [Any] {
                    let field = locItems.dropFirst().map { String(describing: $0) }.joined(separator: ".")
                    return field.isEmpty ? message : "\(field): \(message)"
                }
                return message
            }
            return lines
        }

        if let dict = detail as? [String: Any],
           let nestedMessage = APIClient.readString(dict, keys: ["message", "error", "detail"]) {
            return [nestedMessage]
        }

        if let detailString = detail as? String {
            return [detailString]
        }

        return nil
    }

    private func mimeType(for ext: String) -> String {
        switch ext.lowercased() {
        case "pdf":
            return "application/pdf"
        case "png":
            return "image/png"
        case "jpg", "jpeg":
            return "image/jpeg"
        default:
            return "application/octet-stream"
        }
    }

    static func readString(_ json: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = json[key] as? String, !value.isEmpty {
                return value
            }
            if let intValue = json[key] as? Int {
                return String(intValue)
            }
            if let doubleValue = json[key] as? Double {
                return String(doubleValue)
            }
        }
        return nil
    }

    static func readInt(_ json: [String: Any], keys: [String]) -> Int? {
        for key in keys {
            if let value = json[key] as? Int {
                return value
            }
            if let value = json[key] as? Double {
                return Int(value)
            }
            if let value = json[key] as? String, let intValue = Int(value) {
                return intValue
            }
        }
        return nil
    }

    static func readDouble(_ json: [String: Any], keys: [String]) -> Double? {
        for key in keys {
            if let value = json[key] as? Double {
                return value
            }
            if let value = json[key] as? Int {
                return Double(value)
            }
            if let value = json[key] as? String, let doubleValue = Double(value) {
                return doubleValue
            }
        }
        return nil
    }

    static func readBool(_ json: [String: Any], keys: [String]) -> Bool? {
        for key in keys {
            if let value = json[key] as? Bool {
                return value
            }
            if let value = json[key] as? Int {
                return value != 0
            }
            if let value = json[key] as? String {
                let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if ["true", "1", "yes"].contains(normalized) { return true }
                if ["false", "0", "no"].contains(normalized) { return false }
            }
        }
        return nil
    }

    static func readNestedDouble(_ json: [String: Any], key: String, nestedKey: String = "value") -> Double? {
        guard let nested = json[key] as? [String: Any] else {
            return nil
        }
        return readDouble(nested, keys: [nestedKey])
    }

    static func readNestedInt(_ json: [String: Any], key: String, nestedKey: String = "value") -> Int? {
        guard let nested = json[key] as? [String: Any] else {
            return nil
        }
        return readInt(nested, keys: [nestedKey])
    }

    static func readStatus(_ json: [String: Any], baseKey: String) -> String? {
        if let status = readString(json, keys: ["\(baseKey)_status", "status_\(baseKey)"]) {
            return status
        }

        if let nested = json[baseKey] as? [String: Any] {
            return readString(nested, keys: ["status"])
        }

        return nil
    }

    static func parseServerDate(_ value: String) -> Date? {
        let isoWithFraction = ISO8601DateFormatter()
        isoWithFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoWithFraction.date(from: value) {
            return date
        }

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        if let date = iso.date(from: value) {
            return date
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: value)
    }

    private func debugLogRequest(_ request: URLRequest, body: [String: Any]?) {
        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "unknown"
        if let body {
            print("[API] \(method) \(url) body=\(body)")
        } else {
            print("[API] \(method) \(url)")
        }
    }

    private func debugLogResponse(statusCode: Int, data: Data) {
        let text = String(data: data, encoding: .utf8) ?? "<non-utf8-body>"
        print("[API] status=\(statusCode) response=\(text)")
    }

    private func receiveMayaSocketMessages() {
        guard let task = mayaWebSocketTask else { return }

        task.receive { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.onMayaSocketText?(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.onMayaSocketText?(text)
                    }
                @unknown default:
                    break
                }
                self.receiveMayaSocketMessages()
            case .failure(let error):
                self.onMayaSocketError?(error.localizedDescription)
            }
        }
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
