//
//  DashboardView.swift
//  FitnessTracker
//
//  Created by Blink on 1/20/25.
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var goalService = GoalService()
    @State private var workouts: [Workout] = []
    @State private var showingGoalSheet = false
    @State private var editingGoal: Goal?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Goal Progress Section
                    goalProgressSection
                    
                    // Workout Summary Section
                    workoutSummarySection
                    
                    // Top Activities - Single Session
                    singleSessionRecordsSection
                    
                    // Top Activities - All Time
                    allTimeActivitiesSection
                }
                .padding()
            }
            .navigationTitle("Fitness Dashboard")
            .refreshable {
                await loadData()
            }
            .onAppear {
                Task {
                    await loadData()
                }
            }
            .sheet(isPresented: $showingGoalSheet) {
                GoalFormView(existingGoal: editingGoal) { goalInput in
                    Task {
                        do {
                            if let existingGoal = editingGoal {
                                try await goalService.updateGoal(existingGoal, with: goalInput)
                            } else {
                                try await goalService.createGoal(goalInput)
                            }
                            editingGoal = nil
                        } catch {
                            print("Error saving goal: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Goal Progress Section
    private var goalProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Goal Progress")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Track your quarterly fitness goals")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let currentGoal = goalService.getCurrentGoal() {
                    Button("Edit") {
                        editingGoal = currentGoal
                        showingGoalSheet = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            if let currentGoal = goalService.getCurrentGoal() {
                GoalProgressCard(goal: currentGoal, workouts: workouts)
            } else {
                // No Goal Card
                VStack(spacing: 12) {
                    Image(systemName: "target")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("No Goal Set for \(Calendar.current.component(.year, from: Date()))")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Text("Create an annual fitness goal to track your progress with quarterly milestones.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Create \(Calendar.current.component(.year, from: Date())) Goal") {
                        editingGoal = nil
                        showingGoalSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Workout Summary Section
    private var workoutSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading) {
                Text("Workout Summary")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Your all-time statistics")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Main Stats Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatCard(title: "Total Sessions", value: "\(workouts.count)", icon: "calendar")
                StatCard(title: "Total Minutes", value: formatNumber(totalMinutes), icon: "clock")
                StatCard(title: "Total Miles", value: String(format: "%.0f", totalMiles), icon: "location")
                StatCard(title: "Total Lbs Lifted", value: formatNumber(Int(totalWeight)), icon: "scalemass")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Single Session Records Section
    private var singleSessionRecordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Activities - Single Session")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                if let longestDistance = longestDistanceRecord {
                    SingleSessionRecordCard(
                        title: "Longest Distance",
                        value: String(format: "%.1f mi", longestDistance.miles ?? 0),
                        subtitle: "\(longestDistance.activity) • \(longestDistance.source)",
                        color: .green,
                        icon: "arrow.up.right"
                    )
                }
                
                if let mostWeight = mostWeightRecord {
                    SingleSessionRecordCard(
                        title: "Most Weight Lifted",
                        value: formatWeight(mostWeight.weight ?? 0),
                        subtitle: "\(mostWeight.activity) • \(mostWeight.source)",
                        color: .purple,
                        icon: "scalemass"
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - All Time Activities Section
    private var allTimeActivitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Activities - All Time")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                ForEach(topActivities.prefix(3), id: \.0) { activity, stats in
                    AllTimeActivityCard(
                        activity: activity,
                        sessions: stats.count,
                        minutes: stats.minutes
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Computed Properties
    private var totalMinutes: Int {
        workouts.reduce(0) { $0 + Int($1.minutes) }
    }
    
    private var totalMiles: Double {
        workouts.reduce(0) { $0 + ($1.miles ?? 0) }
    }
    
    private var totalWeight: Double {
        workouts.reduce(0) { $0 + ($1.weight ?? 0) }
    }
    
    private var longestDistanceRecord: Workout? {
        workouts.max { ($0.miles ?? 0) < ($1.miles ?? 0) }
    }
    
    private var mostWeightRecord: Workout? {
        workouts.max { ($0.weight ?? 0) < ($1.weight ?? 0) }
    }
    
    private var topActivities: [(String, (count: Int, minutes: Int))] {
        let activityBreakdown = workouts.reduce(into: [String: (count: Int, minutes: Int)]()) { result, workout in
            let activity = workout.activity
            let current = result[activity] ?? (count: 0, minutes: 0)
            result[activity] = (count: current.count + 1, minutes: current.minutes + Int(workout.minutes))
        }
        
        return activityBreakdown.sorted { $0.value.minutes > $1.value.minutes }
    }
    
    // MARK: - Helper Functions
    private func loadData() async {
        // Load goals from API
        do {
            try await goalService.fetchGoals()
        } catch {
            print("Error loading goals: \(error)")
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    private func formatWeight(_ weight: Double) -> String {
        if weight >= 1000 {
            return String(format: "%.0fk lbs", weight / 1000)
        } else {
            return String(format: "%.0f lbs", weight)
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
