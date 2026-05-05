

import Foundation

struct Doctor: Identifiable , Hashable  {
    let id = UUID()
    let name: String
    let specialization: String
    let rating: Double
    let availability: String
    let experience: String

    static let sampleDoctors: [Doctor] = [
        Doctor(
            name: "Dr. Ananya Sharma",
            specialization: "Gynecologist",
            rating: 4.8,
            availability: "Available Today" ,
            experience : ""
        ),
        Doctor(
            name: "Dr. Rahul Mehta",
            specialization: "General Physician",
            rating: 4.6,
            availability: "Tomorrow",
            experience : ""
        ),
        Doctor(
            name: "Dr. Sneha Iyer",
            specialization: "Obstetrician",
            rating: 4.9,
            availability: "Available Now",
            experience : ""
        )
    ]
}
