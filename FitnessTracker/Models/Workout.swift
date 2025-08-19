//
//  Workout.swift
//  FitnessTracker
//
//  Created by Blink on 1/20/25.
//

import Foundation
import HealthKit
import SwiftUI

struct Workout: Identifiable, Codable {
    let id: String
    let date: Date
    let source: String
    let activity: String
    let minutes: Int
    let miles: Double?
    let weightLifted: Double?
    let notes: String?
    let calories: Double?
    
    // Additional HealthKit data
    let heartRateAverage: Double?
    let heartRateMax: Double?
    
    init(id: String = UUID().uuidString,
         date: Date,
         source: String,
         activity: String,
         minutes: Int,
         miles: Double? = nil,
         weightLifted: Double? = nil,
         notes: String? = nil,
         calories: Double? = nil,
         heartRateAverage: Double? = nil,
         heartRateMax: Double? = nil) {
        self.id = id
        self.date = date
        self.source = source
        self.activity = activity
        self.minutes = minutes
        self.miles = miles
        self.weightLifted = weightLifted
        self.notes = notes
        self.calories = calories
        self.heartRateAverage = heartRateAverage
        self.heartRateMax = heartRateMax
    }
    
    // Convert from HealthKit workout
    static func fromHealthKitWorkout(_ hkWorkout: HKWorkout) -> Workout {
        let source = hkWorkout.sourceRevision.source.name
        let activity = hkWorkout.workoutActivityType.displayName
        let minutes = Int(hkWorkout.duration / 60)
        
        // Extract distance (miles)
        var miles: Double?
        if let distanceQuantity = hkWorkout.totalDistance {
            miles = distanceQuantity.doubleValue(for: .mile())
        }
        
        // Extract calories
        var calories: Double?
        if let energyQuantity = hkWorkout.totalEnergyBurned {
            calories = energyQuantity.doubleValue(for: .kilocalorie())
        }
        
        // For strength training, we'll estimate weight lifted based on calories
        // This is a rough approximation - real weight data would need additional HealthKit queries
        var weightLifted: Double?
        if hkWorkout.workoutActivityType == .traditionalStrengthTraining ||
           hkWorkout.workoutActivityType == .functionalStrengthTraining {
            if let cal = calories {
                // Rough estimate: 1 calorie ≈ 3-4 lbs lifted (very approximate)
                weightLifted = cal * 3.5
            }
        }
        
        return Workout(
            id: hkWorkout.uuid.uuidString,
            date: hkWorkout.startDate,
            source: source,
            activity: activity,
            minutes: minutes,
            miles: miles,
            weightLifted: weightLifted,
            notes: nil,
            calories: calories
        )
    }
    
    // UI helpers
    var activityIcon: String {
        switch activity.lowercased() {
        case let str where str.contains("cycling") || str.contains("bike"):
            return "bicycle"
        case let str where str.contains("running") || str.contains("run"):
            return "figure.run"
        case let str where str.contains("walking") || str.contains("walk"):
            return "figure.walk"
        case let str where str.contains("strength") || str.contains("weight"):
            return "dumbbell.fill"
        case let str where str.contains("yoga"):
            return "figure.yoga"
        case let str where str.contains("rowing") || str.contains("row"):
            return "figure.rowing"
        case let str where str.contains("swimming") || str.contains("swim"):
            return "figure.pool.swim"
        case let str where str.contains("hiking") || str.contains("hike"):
            return "figure.hiking"
        default:
            return "figure.mixed.cardio"
        }
    }
    
    var activityColor: Color {
        switch activity.lowercased() {
        case let str where str.contains("cycling") || str.contains("bike"):
            return .blue
        case let str where str.contains("running") || str.contains("run"):
            return .red
        case let str where str.contains("walking") || str.contains("walk"):
            return .green
        case let str where str.contains("strength") || str.contains("weight"):
            return .orange
        case let str where str.contains("yoga"):
            return .purple
        case let str where str.contains("rowing") || str.contains("row"):
            return .teal
        case let str where str.contains("swimming") || str.contains("swim"):
            return .cyan
        case let str where str.contains("hiking") || str.contains("hike"):
            return .brown
        default:
            return .gray
        }
    }
}

// Extension to get display names for workout types
extension HKWorkoutActivityType {
    var displayName: String {
        switch self {
        case .cycling:
            return "Cycling"
        case .running:
            return "Running"
        case .walking:
            return "Walking"
        case .traditionalStrengthTraining:
            return "Strength Training"
        case .functionalStrengthTraining:
            return "Functional Training"
        case .yoga:
            return "Yoga"
        case .rowing:
            return "Rowing"
        case .swimming:
            return "Swimming"
        case .hiking:
            return "Hiking"
        case .mixedCardio:
            return "Mixed Cardio"
        default:
            return "Workout"
        }
    }
}