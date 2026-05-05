//
//  EmergencyViewModel.swift
//  PreCare
//
 
//

import Foundation
import Combine

final class EmergencyViewModel: ObservableObject {

    @Published var etaMinutes: Int = 8
    @Published var distance: String = "0.8 mi away"

    @Published var paramedicsStatus: EmergencyStatus = .enRoute
    @Published var doctorNotified = true
    @Published var familyNotified = true
}
