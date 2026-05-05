//
//  HealthMetric.swift
//  PreCare
//
 
//


import Foundation

struct HealthMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let unit: String
    let status: String
}
