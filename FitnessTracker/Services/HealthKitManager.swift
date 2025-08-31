//
//  HealthKitManager.swift
//  FitnessTracker
//
//  Created by Blink on 1/20/25.
//

import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    @Published var isAuthorized = false
    
    init() {
        checkAuthorization()
    }
    
    func checkAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .distanceCycling)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!  // For weight tracking
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                if let error = error {
                    print("HealthKit authorization error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func fetchRecentWorkouts(completion: @escaping ([Workout]) -> Void) {
        let workoutType = HKObjectType.workoutType()
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: 100, sortDescriptors: [sortDescriptor]) { [weak self] _, samples, error in
            if let error = error {
                print("Error fetching workouts: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            guard let workouts = samples as? [HKWorkout] else {
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            // Convert HKWorkouts to our Workout model
            let convertedWorkouts = workouts.compactMap { hkWorkout -> Workout? in
                self?.convertHealthKitWorkout(hkWorkout)
            }
            
            DispatchQueue.main.async {
                completion(convertedWorkouts)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func convertHealthKitWorkout(_ hkWorkout: HKWorkout) -> Workout? {
        let sourceName = hkWorkout.sourceRevision.source.name
        let source = WorkoutMapping.determineSource(from: sourceName)
        
        // Skip workouts from unknown sources if needed
        // For now, we'll include all as "Other"
        
        let activity = WorkoutMapping.mapHealthKitActivity(hkWorkout.workoutActivityType, source: source)
        let minutes = hkWorkout.duration / 60.0
        
        // Extract distance and convert to miles
        var miles: Double?
        if let distanceQuantity = hkWorkout.totalDistance {
            let meters = distanceQuantity.doubleValue(for: .meter())
            miles = WorkoutMapping.metersToMiles(meters)
        }
        
        // Extract calories
        var calories: Double?
        if let energyQuantity = hkWorkout.totalEnergyBurned {
            calories = energyQuantity.doubleValue(for: .kilocalorie())
        }
        
        // Extract weight lifted for strength training
        var weight: Double?
        if activity == "Weight lifting" {
            // For Tonal workouts, weight data might be in metadata
            if let metadata = hkWorkout.metadata {
                // Check for custom weight lifted key (some apps store this)
                if let weightLifted = metadata["HKMetadataKeyWeightLifted"] as? Double {
                    weight = weightLifted
                } else if let totalWeight = metadata["total_weight"] as? Double {
                    weight = totalWeight
                } else if source == "Tonal" {
                    // Tonal typically stores weight in a specific format
                    // Estimate based on workout duration and calories if no direct data
                    if let cal = calories {
                        // More sophisticated calculation for Tonal
                        // Assuming ~100 calories per 1000 lbs lifted (rough estimate)
                        weight = cal * 10
                    }
                } else {
                    // For other strength workouts, use a general estimate
                    if let cal = calories {
                        // General gym estimate: ~50 calories per 1000 lbs
                        weight = cal * 20
                    }
                }
            }
        }
        
        return Workout(
            date: hkWorkout.startDate,
            source: source,
            activity: activity,
            minutes: minutes,
            miles: miles,
            weight: weight,
            calories: calories
        )
    }
    
    // Fetch workouts that haven't been synced yet
    func fetchUnsyncedWorkouts(lastSyncDate: Date?, completion: @escaping ([Workout]) -> Void) {
        let workoutType = HKObjectType.workoutType()
        let endDate = Date()
        let startDate = lastSyncDate ?? Calendar.current.date(byAdding: .day, value: -7, to: endDate)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { [weak self] _, samples, error in
            if let error = error {
                print("Error fetching unsynced workouts: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            guard let workouts = samples as? [HKWorkout] else {
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            // Filter and convert workouts
            let convertedWorkouts = workouts.compactMap { hkWorkout -> Workout? in
                // Only include workouts from supported sources
                let sourceName = hkWorkout.sourceRevision.source.name
                let source = WorkoutMapping.determineSource(from: sourceName)
                
                // Convert the workout
                return self?.convertHealthKitWorkout(hkWorkout)
            }
            
            DispatchQueue.main.async {
                completion(convertedWorkouts)
            }
        }
        
        healthStore.execute(query)
    }
}

// ... existing code ...