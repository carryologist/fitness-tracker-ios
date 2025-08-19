//
//  ContentView.swift
//  FitnessTracker
//
//  Created by Blink on 1/20/25.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @StateObject private var workoutService = WorkoutService()
    @State private var workouts: [Workout] = []
    @State private var isLoading = false
    @State private var lastSyncDate: Date?
    
    var body: some View {
        NavigationView {
            VStack {
                // Sync Status
                HStack {
                    Image(systemName: healthKitManager.isAuthorized ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(healthKitManager.isAuthorized ? .green : .orange)
                    
                    Text(healthKitManager.isAuthorized ? "Connected to Apple Health" : "Apple Health Access Needed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let lastSync = lastSyncDate {
                        Text("Last sync: \(lastSync, style: .time)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Sync Button
                Button(action: syncWorkouts) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text(isLoading ? "Syncing..." : "Sync Workouts")
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .disabled(isLoading || !healthKitManager.isAuthorized)
                .padding(.horizontal)
                
                // Workout List
                if workouts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No workouts found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(healthKitManager.isAuthorized ? 
                             "Complete a Peloton or Tonal workout, then tap 'Sync Workouts' to see your data here." :
                             "Grant Apple Health access to sync your workouts.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(workouts) { workout in
                        WorkoutRowView(workout: workout)
                    }
                }
            }
            .navigationTitle("Fitness Tracker")
            .refreshable {
                await syncWorkoutsAsync()
            }
        }
    }
    
    private func syncWorkouts() {
        Task {
            await syncWorkoutsAsync()
        }
    }
    
    private func syncWorkoutsAsync() async {
        guard healthKitManager.isAuthorized else { return }
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            // Fetch workouts from HealthKit
            let healthKitWorkouts = try await healthKitManager.fetchRecentWorkouts()
            
            // Convert to our Workout model
            let convertedWorkouts = healthKitWorkouts.map { hkWorkout in
                Workout.fromHealthKitWorkout(hkWorkout)
            }
            
            // Sync to web API
            for workout in convertedWorkouts {
                try await workoutService.syncWorkout(workout)
            }
            
            await MainActor.run {
                workouts = convertedWorkouts.sorted { $0.date > $1.date }
                lastSyncDate = Date()
                isLoading = false
            }
        } catch {
            print("Error syncing workouts: \(error)")
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

struct WorkoutRowView: View {
    let workout: Workout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // Activity Icon
                Image(systemName: workout.activityIcon)
                    .foregroundColor(workout.activityColor)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(workout.activity)
                        .font(.headline)
                    
                    Text(workout.source)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(workout.minutes) min")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(workout.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Additional metrics
            HStack(spacing: 16) {
                if let miles = workout.miles, miles > 0 {
                    Label("\(miles, specifier: "%.1f") mi", systemImage: "location")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let weight = workout.weightLifted, weight > 0 {
                    Label("\(Int(weight)) lbs", systemImage: "dumbbell")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let calories = workout.calories, calories > 0 {
                    Label("\(Int(calories)) cal", systemImage: "flame")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
        .environmentObject(HealthKitManager())
}