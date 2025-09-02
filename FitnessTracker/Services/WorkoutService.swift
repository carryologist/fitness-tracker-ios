//
//  WorkoutService.swift
//  FitnessTracker
//
//  Created by Blink on 1/20/25.
//

import Foundation
import Combine

class WorkoutService: ObservableObject {
    @Published var workouts: [Workout] = []
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    
    private let baseURL = "https://fitness-tracker-one-sigma.vercel.app/api"
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadLastSyncDate()
    }
    
    // Sync workouts to the web API
    func syncWorkouts(_ workouts: [Workout]) async throws {
        guard !workouts.isEmpty else { return }
        
        DispatchQueue.main.async {
            self.isSyncing = true
            self.syncError = nil
        }
        
        do {
            // Prepare the request
            guard let url = URL(string: "\(baseURL)/workouts") else {
                throw WorkoutServiceError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Convert workouts to JSON
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            
            // Create payload matching web app structure
            let payload = workouts.map { workout in
                WorkoutPayload(
                    date: workout.date,
                    source: workout.source,
                    activity: workout.activity,
                    minutes: Int(workout.minutes),  // Convert to Int for API
                    miles: workout.miles,
                    weightLifted: workout.weight,  // Use weightLifted field name
                    calories: workout.calories
                )
            }
            
            request.httpBody = try encoder.encode(["workouts": payload])
            
            // Send the request
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw WorkoutServiceError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                // Success - update last sync date
                DispatchQueue.main.async {
                    self.lastSyncDate = Date()
                    self.saveLastSyncDate()
                    self.isSyncing = false
                    print("Successfully synced \(workouts.count) workouts")
                }
            } else {
                // Try to parse error message
                if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw WorkoutServiceError.apiError(errorData.error)
                } else {
                    throw WorkoutServiceError.httpError(httpResponse.statusCode)
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isSyncing = false
                self.syncError = error.localizedDescription
                print("Sync error: \(error)")
            }
            throw error
        }
    }
    
    // Fetch workouts from the web API
    func fetchWorkouts() async throws {
        guard let url = URL(string: "\(baseURL)/workouts") else {
            throw WorkoutServiceError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw WorkoutServiceError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let fetchedWorkouts = try decoder.decode([Workout].self, from: data)
        
        DispatchQueue.main.async {
            self.workouts = fetchedWorkouts
        }
    }
    
    // Save last sync date to UserDefaults
    private func saveLastSyncDate() {
        UserDefaults.standard.set(lastSyncDate, forKey: "lastWorkoutSyncDate")
    }
    
    // Load last sync date from UserDefaults
    private func loadLastSyncDate() {
        lastSyncDate = UserDefaults.standard.object(forKey: "lastWorkoutSyncDate") as? Date
    }
}

// Payload structure for API
struct WorkoutPayload: Codable {
    let date: Date
    let source: String
    let activity: String
    let minutes: Int
    let miles: Double?
    let weightLifted: Double?  // Changed from weight
    let calories: Double?
}

// Error response from API
struct ErrorResponse: Codable {
    let error: String
}

// Custom errors
enum WorkoutServiceError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(String)
    case httpError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let message):
            return "API Error: \(message)"
        case .httpError(let code):
            return "HTTP Error: \(code)"
        }
    }
}