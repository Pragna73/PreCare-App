import Foundation
import CoreLocation
import UserNotifications
import Combine

final class PermissionManager: NSObject, ObservableObject {

    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
    }

    // MARK: - Location
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    // MARK: - Notifications
    func requestNotificationPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
}

// MARK: - CLLocation Delegate
extension PermissionManager: CLLocationManagerDelegate {}
