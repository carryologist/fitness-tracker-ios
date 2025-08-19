//
//  HealthKitManager.swift
//  FitnessTracker
//
//  Created by Blink on 1/20/25.
//

import Foundation
import HealthKit
import Combine

class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    
    // HealthKit data types we want to read
    private let readTypes: Set<HKObjectType> = [
        HKObjectType.workoutType(),
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKObjectType.quantityType(forIdentifier: .distanceCycling)!,
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
    ]
    
    init() {
        checkAuthorizationStatus()
    }
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        healthStore.requestAuthorization(toShare: [], read: readTypes) { [weak self] success, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("HealthKit authorization error: \(error.localizedDescription)")
                    return
                }
                
                self?.checkAuthorizationStatus()
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        let workoutType = HKObjectType.workoutType()
        authorizationStatus = healthStore.authorizationStatus(for: workoutType)
        isAuthorized = authorizationStatus == .sharingAuthorized
    }
    
    func fetchRecentWorkouts(days: Int = 30) async throws -> [HKWorkout] {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        
        let workoutType = HKObjectType.workoutType()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        // Sort by start date, most recent first
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let workouts = samples as? [HKWorkout] ?? []
                continuation.resume(returning: workouts)
            }
            
            healthStore.execute(query)
        }
    }
    
    func fetchWorkoutDetails(for workout: HKWorkout) async throws -> WorkoutDetails {
        // Fetch heart rate data for this workout
        let heartRateData = try await fetchHeartRateData(for: workout)
        
        return WorkoutDetails(
            workout: workout,
            heartRateAverage: heartRateData.average,
            heartRateMax: heartRateData.max,
            heartRateMin: heartRateData.min
        )
    }
    
    private func fetchHeartRateData(for workout: HKWorkout) async throws -> (average: Double?, max: Double?, min: Double?) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            return (nil, nil, nil)
        }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: workout.startDate,
            end: workout.endDate,
            options: .strictStartDate
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let heartRateSamples = samples as? [HKQuantitySample], !heartRateSamples.isEmpty else {
                    continuation.resume(returning: (nil, nil, nil))
                    return
                }
                
                let heartRates = heartRateSamples.map { sample in
                    sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                }
                
                let average = heartRates.reduce(0, +) / Double(heartRates.count)
                let max = heartRates.max()
                let min = heartRates.min()
                
                continuation.resume(returning: (average, max, min))
            }
            
            healthStore.execute(query)
        }
    }
    
    // Enable background delivery for workout updates
    func enableBackgroundDelivery() {
        guard isAuthorized else { return }
        
        let workoutType = HKObjectType.workoutType()
        
        healthStore.enableBackgroundDelivery(for: workoutType, frequency: .immediate) { success, error in
            if let error = error {
                print("Failed to enable background delivery: \(error.localizedDescription)")
            } else if success {
                print("Background delivery enabled for workouts")
            }
        }
    }
}

// MARK: - Supporting Types

struct WorkoutDetails {
    let workout: HKWorkout
    let heartRateAverage: Double?
    let heartRateMax: Double?
    let heartRateMin: Double?
}

enum HealthKitError: Error, LocalizedError {
    case notAuthorized
    case dataNotAvailable
    case queryFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "HealthKit access not authorized"
        case .dataNotAvailable:
            return "HealthKit data not available on this device"
        case .queryFailed(let message):
            return "HealthKit query failed: \(message)"
        }
    }
}