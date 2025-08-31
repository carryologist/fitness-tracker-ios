//
//  Workout.swift
//  FitnessTracker
//
//  Created by Blink on 1/20/25.
//

import Foundation
import HealthKit

struct Workout: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let source: String
    let activity: String
    let minutes: Double  // Changed from duration to minutes
    let miles: Double?   // Changed from distance to miles
    let weight: Double?  // Added for strength training
    let calories: Double?
    
    // For API encoding
    enum CodingKeys: String, CodingKey {
        case date
        case source
        case activity
        case minutes
        case miles
        case weight
        case calories
    }
}

// Source to activity mapping matching web app
struct WorkoutMapping {
    static let sourceActivityMap: [String: [String]] = [
        "Peloton": ["Cycling", "Outdoor cycling", "Weight lifting", "Walking", "Running", "Yoga"],
        "Tonal": ["Weight lifting"],
        "Cannondale": ["Outdoor cycling"],
        "Gym": ["Weight lifting", "Running", "Swimming"],
        "Other": ["Other"]
    ]
    
    // Map HealthKit workout types to our activity types
    static func mapHealthKitActivity(_ workoutType: HKWorkoutActivityType, source: String) -> String {
        switch workoutType {
        case .cycling:
            return "Cycling"
        case .running:
            return "Running"
        case .walking:
            return "Walking"
        case .yoga:
            return "Yoga"
        case .functionalStrengthTraining, .traditionalStrengthTraining:
            return "Weight lifting"
        case .swimming:
            return "Swimming"
        case .mixedCardio:
            // For outdoor cycling from Cannondale
            if source == "Cannondale" {
                return "Outdoor cycling"
            }
            return "Cycling"
        default:
            return "Other"
        }
    }
    
    // Determine source from HealthKit source name
    static func determineSource(from sourceName: String) -> String {
        let lowercased = sourceName.lowercased()
        
        if lowercased.contains("peloton") {
            return "Peloton"
        } else if lowercased.contains("tonal") {
            return "Tonal"
        } else if lowercased.contains("cannondale") {
            return "Cannondale"
        } else if lowercased.contains("gym") || lowercased.contains("fitness") {
            return "Gym"
        } else {
            return "Other"
        }
    }
    
    // Convert meters to miles
    static func metersToMiles(_ meters: Double) -> Double {
        return meters / 1609.344
    }
}