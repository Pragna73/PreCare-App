
import SwiftUI

import Foundation

enum AppRoute: Hashable {
    case dashboard
    case workflow
    case analysisResult
    case aiDecision(HealthSeverity)
    case bookDoctor
    case appointmentConfirmation(Doctor)
}
