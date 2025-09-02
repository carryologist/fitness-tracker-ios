//
//  ContentView.swift
//  FitnessTracker
//
//  Created by Blink on 1/20/25.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var workoutService = WorkoutService()
    
    @State private var recentWorkouts: [Workout] = []
    @State private var isSyncing = false
    @State private var syncMessage = ""
    @State private var showingSyncAlert = false
    
    var body: some View {
        TabView {
            // Dashboard Tab
            DashboardView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Dashboard")
                }
            
            // Sync Tab
            syncView
                .tabItem {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Sync")
                }
        }
    }
    
    private var syncView: some View {
        NavigationView {
            VStack {
                // Sync Status Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text("Sync Status")
                                .font(.headline)
                            if let lastSync = workoutService.lastSyncDate {
                                Text("Last synced: \(lastSync, formatter: relativeDateFormatter)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Never synced")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: syncWorkouts) {
                            if isSyncing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                            } else {
                                Text("Sync Now")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                        }
                        .disabled(isSyncing || !healthKitManager.isAuthorized)
                    }
                    
                    if !healthKitManager.isAuthorized {
                        Text("⚠️ HealthKit access required")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Workouts List
                if recentWorkouts.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "figure.run.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Recent Workouts")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(healthKitManager.isAuthorized ?
                             "Complete a workout to see your data here." :
                             "Grant HealthKit access to see your workouts.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                } else {
                    List(recentWorkouts) { workout in
                        WorkoutRow(workout: workout)
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Fitness Tracker")
            .onAppear {
                loadWorkouts()
            }
            .alert("Sync Complete", isPresented: $showingSyncAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(syncMessage)
            }
        }
    }
    
    private func loadWorkouts() {
        healthKitManager.fetchRecentWorkouts { workouts in
            self.recentWorkouts = workouts
        }
    }
    
    private func syncWorkouts() {
        isSyncing = true
        
        // Fetch unsynced workouts from HealthKit
        healthKitManager.fetchUnsyncedWorkouts(lastSyncDate: workoutService.lastSyncDate) { workouts in
            if workouts.isEmpty {
                self.syncMessage = "No new workouts to sync"
                self.showingSyncAlert = true
                self.isSyncing = false
                return
            }
            
            // Sync to web API
            Task {
                do {
                    try await workoutService.syncWorkouts(workouts)
                    await MainActor.run {
                        self.syncMessage = "Successfully synced \(workouts.count) workout(s)"
                        self.showingSyncAlert = true
                        self.isSyncing = false
                        self.loadWorkouts() // Reload to show updated list
                    }
                } catch {
                    await MainActor.run {
                        self.syncMessage = "Sync failed: \(error.localizedDescription)"
                        self.showingSyncAlert = true
                        self.isSyncing = false
                    }
                }
            }
        }
    }
}

struct WorkoutRow: View {
    let workout: Workout
    
    var body: some View {
        HStack {
            // Activity Icon
            Image(systemName: activityIcon)
                .font(.title2)
                .foregroundColor(activityColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(workout.activity)
                        .font(.headline)
                    Text("• \(workout.source)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 12) {
                    // Duration
                    Label("\(Int(workout.minutes)) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Distance/Miles
                    if let miles = workout.miles {
                        Label(String(format: "%.1f mi", miles), systemImage: "location")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Weight
                    if let weight = workout.weight {
                        Label(formatWeight(weight), systemImage: "scalemass")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Calories
                    if let calories = workout.calories {
                        Label("\(Int(calories)) cal", systemImage: "flame")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(workout.date, formatter: workoutDateFormatter)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var activityIcon: String {
        switch workout.activity {
        case "Cycling", "Outdoor cycling":
            return "bicycle"
        case "Running":
            return "figure.run"
        case "Walking":
            return "figure.walk"
        case "Weight lifting":
            return "dumbbell.fill"
        case "Yoga":
            return "figure.yoga"
        case "Swimming":
            return "figure.pool.swim"
        default:
            return "figure.mixed.cardio"
        }
    }
    
    private var activityColor: Color {
        switch workout.activity {
        case "Cycling", "Outdoor cycling":
            return .blue
        case "Running":
            return .red
        case "Walking":
            return .green
        case "Weight lifting":
            return .orange
        case "Yoga":
            return .purple
        case "Swimming":
            return .cyan
        default:
            return .gray
        }
    }
    
    private func formatWeight(_ weight: Double) -> String {
        if weight >= 1000 {
            return String(format: "%.0fk lbs", weight / 1000)
        } else {
            return String(format: "%.0f lbs", weight)
        }
    }
}

// Date Formatters
let workoutDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

let relativeDateFormatter: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}