//
//  GoalService.swift
//  FitnessTracker
//
//  Created by Blink on 1/20/25.
//

import Foundation
import Combine

class GoalService: ObservableObject {
    @Published var goals: [Goal] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let baseURL = "https://fitness-tracker-one-sigma.vercel.app/api"
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadGoalsFromStorage()
    }
    
    // Fetch goals from API
    func fetchGoals() async throws {
        guard let url = URL(string: "\(baseURL)/goals") else {
            throw GoalServiceError.invalidURL
        }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw GoalServiceError.invalidResponse
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let goalsResponse = try decoder.decode(GoalsResponse.self, from: data)
            
            DispatchQueue.main.async {
                self.goals = goalsResponse.goals
                self.saveGoalsToStorage()
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.error = error.localizedDescription
            }
            throw error
        }
    }
    
    // Create a new goal
    func createGoal(_ goalInput: GoalInput) async throws {
        guard let url = URL(string: "\(baseURL)/goals") else {
            throw GoalServiceError.invalidURL
        }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            
            // Create payload matching web app structure
            let payload = GoalPayload(
                name: goalInput.name,
                year: goalInput.year,
                annualWeightTarget: goalInput.annualWeightTarget,
                minutesPerSession: goalInput.minutesPerSession,
                weeklySessionsTarget: goalInput.weeklySessionsTarget
            )
            
            request.httpBody = try encoder.encode(payload)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GoalServiceError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                let goalResponse = try decoder.decode(GoalCreateResponse.self, from: data)
                
                DispatchQueue.main.async {
                    self.goals.append(goalResponse.goal)
                    self.saveGoalsToStorage()
                    self.isLoading = false
                }
            } else {
                if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw GoalServiceError.apiError(errorData.error)
                } else {
                    throw GoalServiceError.httpError(httpResponse.statusCode)
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.error = error.localizedDescription
            }
            throw error
        }
    }
    
    // Update an existing goal
    func updateGoal(_ goal: Goal, with goalInput: GoalInput) async throws {
        guard let url = URL(string: "\(baseURL)/goals") else {
            throw GoalServiceError.invalidURL
        }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            
            // Create payload with ID for update
            let payload = GoalUpdatePayload(
                id: goal.id,
                name: goalInput.name,
                year: goalInput.year,
                annualWeightTarget: goalInput.annualWeightTarget,
                minutesPerSession: goalInput.minutesPerSession,
                weeklySessionsTarget: goalInput.weeklySessionsTarget
            )
            
            request.httpBody = try encoder.encode(payload)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GoalServiceError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                let goalResponse = try decoder.decode(GoalCreateResponse.self, from: data)
                
                DispatchQueue.main.async {
                    if let index = self.goals.firstIndex(where: { $0.id == goal.id }) {
                        self.goals[index] = goalResponse.goal
                    }
                    self.saveGoalsToStorage()
                    self.isLoading = false
                }
            } else {
                if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw GoalServiceError.apiError(errorData.error)
                } else {
                    throw GoalServiceError.httpError(httpResponse.statusCode)
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.error = error.localizedDescription
            }
            throw error
        }
    }
    
    // Get current year's goal
    func getCurrentGoal() -> Goal? {
        let currentYear = Calendar.current.component(.year, from: Date())
        return goals.first { $0.year == currentYear }
    }
    
    // Save goals to UserDefaults for offline access
    private func saveGoalsToStorage() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(goals)
            UserDefaults.standard.set(data, forKey: "fitness_tracker_goals")
        } catch {
            print("Failed to save goals to storage: \(error)")
        }
    }
    
    // Load goals from UserDefaults
    private func loadGoalsFromStorage() {
        guard let data = UserDefaults.standard.data(forKey: "fitness_tracker_goals") else {
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            goals = try decoder.decode([Goal].self, from: data)
        } catch {
            print("Failed to load goals from storage: \(error)")
        }
    }
}

// API Response structures
struct GoalsResponse: Codable {
    let goals: [Goal]
}

struct GoalCreateResponse: Codable {
    let goal: Goal
}

// API Payload structures
struct GoalPayload: Codable {
    let name: String
    let year: Int
    let annualWeightTarget: Double
    let minutesPerSession: Int
    let weeklySessionsTarget: Int
}

struct GoalUpdatePayload: Codable {
    let id: String
    let name: String
    let year: Int
    let annualWeightTarget: Double
    let minutesPerSession: Int
    let weeklySessionsTarget: Int
}

// Custom errors
enum GoalServiceError: Error, LocalizedError {
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
