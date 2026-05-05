//
//  EmergencyModels.swift
//  PreCare
//
 
//

import MapKit

struct MapPinItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
}
