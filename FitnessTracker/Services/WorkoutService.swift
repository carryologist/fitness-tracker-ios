//
//  WorkoutService.swift
//  FitnessTracker
//
//  Created by Blink on 1/20/25.
//

import Foundation

class WorkoutService: ObservableObject {
    // Update this to match your deployed web app URL
    private let baseURL = "https://fitness-tracker-q1z4d0okx-rob-whiteleys-projects.vercel.app"
    
    private let session = URLSession.shared
    
    func syncWorkout(_ workout: Workout) async throws {
        guard let url = URL(string: "\(baseURL)/api/workouts") else {
            throw WorkoutServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Convert our Workout model to the format expected by your web API
        let apiWorkout = APIWorkout(
            date: ISO8601DateFormatter().string(from: workout.date),
            source: workout.source,
            activity: workout.activity,
            minutes: workout.minutes,
            miles: workout.miles,
            weightLifted: workout.weightLifted,
            notes: workout.notes
        )
        
        do {
            let jsonData = try JSONEncoder().encode(apiWorkout)
            request.httpBody = jsonData
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw WorkoutServiceError.invalidResponse
            }
            
            if httpResponse.statusCode == 201 {
                print("✅ Workout synced successfully: \(workout.activity) on \(workout.date)")
            } else if httpResponse.statusCode == 409 {
                // Workout already exists - this is fine
                print("ℹ️ Workout already exists: \(workout.activity) on \(workout.date)")
            } else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw WorkoutServiceError.serverError(httpResponse.statusCode, errorMessage)
            }
        } catch let error as WorkoutServiceError {
            throw error
        } catch {
            throw WorkoutServiceError.networkError(error)
        }
    }
    
    func fetchWorkouts() async throws -> [Workout] {
        guard let url = URL(string: "\(baseURL)/api/workouts") else {
            throw WorkoutServiceError.invalidURL
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw WorkoutServiceError.invalidResponse
            }
            
            let apiResponse = try JSONDecoder().decode(APIWorkoutsResponse.self, from: data)
            
            // Convert API workouts back to our Workout model
            let workouts = apiResponse.workouts.map { apiWorkout in
                Workout(
                    id: UUID().uuidString, // Generate new ID for API workouts
                    date: ISO8601DateFormatter().date(from: apiWorkout.date) ?? Date(),
                    source: apiWorkout.source,
                    activity: apiWorkout.activity,
                    minutes: apiWorkout.minutes,
                    miles: apiWorkout.miles,
                    weightLifted: apiWorkout.weightLifted,
                    notes: apiWorkout.notes
                )
            }
            
            return workouts
        } catch let error as WorkoutServiceError {
            throw error
        } catch {
            throw WorkoutServiceError.networkError(error)
        }
    }
}

// MARK: - API Models

struct APIWorkout: Codable {
    let date: String
    let source: String
    let activity: String
    let minutes: Int
    let miles: Double?
    let weightLifted: Double?
    let notes: String?
}

struct APIWorkoutsResponse: Codable {
    let workouts: [APIWorkout]
}

// MARK: - Error Types

enum WorkoutServiceError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int, String)
    case networkError(Error)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Data decoding error: \(error.localizedDescription)"
        }
    }
}