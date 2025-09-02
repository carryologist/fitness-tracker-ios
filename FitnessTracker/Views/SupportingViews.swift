//
//  SupportingViews.swift
//  FitnessTracker
//
//  Created by Blink on 1/20/25.
//

import SwiftUI

// MARK: - StatCard
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - SingleSessionRecordCard
struct SingleSessionRecordCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - AllTimeActivityCard
struct AllTimeActivityCard: View {
    let activity: String
    let sessions: Int
    let minutes: Int
    
    var body: some View {
        HStack {
            Image(systemName: activityIcon)
                .font(.title2)
                .foregroundColor(activityColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity)
                    .font(.headline)
                Text("\(sessions) sessions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(formatNumber(minutes)) min")
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var activityIcon: String {
        switch activity {
        case "Cycling", "Outdoor cycling":
            return "bicycle"
        case "Running":
            return "figure.run"
        case "Walking":
            return "figure.walk"
        case "Weight lifting":
            return "dumbbell"
        case "Yoga":
            return "figure.yoga"
        case "Swimming":
            return "figure.pool.swim"
        default:
            return "figure.mixed.cardio"
        }
    }
    
    private var activityColor: Color {
        switch activity {
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
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - GoalProgressCard
struct GoalProgressCard: View {
    let goal: Goal
    let workouts: [Workout]
    @State private var viewMode: ViewMode = .quarterly
    
    enum ViewMode: String, CaseIterable {
        case quarterly = "Q3"
        case annual = "Annual"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Toggle buttons
            HStack {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Button(mode.rawValue) {
                        viewMode = mode
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(viewMode == mode ? Color.blue : Color(.systemGray5))
                    .foregroundColor(viewMode == mode ? .white : .primary)
                    .cornerRadius(8)
                }
                Spacer()
            }
            
            // Progress metrics
            let progress = GoalCalculations.calculateProgress(goal: goal, workouts: workouts)
            
            VStack(spacing: 12) {
                // Weight Lifted
                ProgressMetricCard(
                    title: "Weight Lifted",
                    status: getStatus(progress, metric: .weight),
                    actual: viewMode == .quarterly ? Int(progress.actualWeightLifted.quarterToDate) : Int(progress.actualWeightLifted.yearToDate),
                    expected: viewMode == .quarterly ? Int(progress.expectedWeightLifted.quarterToDate) : Int(progress.expectedWeightLifted.yearToDate),
                    target: viewMode == .quarterly ? Int(goal.quarterlyWeightTarget) : Int(goal.annualWeightTarget),
                    unit: "lbs",
                    color: .orange,
                    icon: "dumbbell"
                )
                
                // Minutes Completed
                ProgressMetricCard(
                    title: "Minutes Completed",
                    status: getStatus(progress, metric: .minutes),
                    actual: viewMode == .quarterly ? progress.actualMinutes.quarterToDate : progress.actualMinutes.yearToDate,
                    expected: viewMode == .quarterly ? progress.expectedMinutes.quarterToDate : progress.expectedMinutes.yearToDate,
                    target: viewMode == .quarterly ? goal.quarterlyMinutesTarget : goal.annualMinutesTarget,
                    unit: "min",
                    color: .blue,
                    icon: "clock"
                )
                
                // Sessions Completed
                ProgressMetricCard(
                    title: "Sessions Completed",
                    status: getStatus(progress, metric: .sessions),
                    actual: viewMode == .quarterly ? progress.actualSessions.quarterToDate : progress.actualSessions.yearToDate,
                    expected: viewMode == .quarterly ? progress.expectedSessions.quarterToDate : progress.expectedSessions.yearToDate,
                    target: viewMode == .quarterly ? goal.quarterlySessionsTarget : (goal.weeklySessionsTarget * 52),
                    unit: "sessions",
                    color: .green,
                    icon: "checkmark.circle"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func getStatus(_ progress: GoalProgress, metric: MetricType) -> String {
        let (actual, expected): (Double, Double)
        
        switch metric {
        case .weight:
            actual = viewMode == .quarterly ? progress.actualWeightLifted.quarterToDate : progress.actualWeightLifted.yearToDate
            expected = viewMode == .quarterly ? progress.expectedWeightLifted.quarterToDate : progress.expectedWeightLifted.yearToDate
        case .minutes:
            actual = Double(viewMode == .quarterly ? progress.actualMinutes.quarterToDate : progress.actualMinutes.yearToDate)
            expected = Double(viewMode == .quarterly ? progress.expectedMinutes.quarterToDate : progress.expectedMinutes.yearToDate)
        case .sessions:
            actual = Double(viewMode == .quarterly ? progress.actualSessions.quarterToDate : progress.actualSessions.yearToDate)
            expected = Double(viewMode == .quarterly ? progress.expectedSessions.quarterToDate : progress.expectedSessions.yearToDate)
        }
        
        return GoalCalculations.getProgressStatus(actual: actual, expected: expected)
    }
    
    private enum MetricType {
        case weight, minutes, sessions
    }
}

// MARK: - ProgressMetricCard
struct ProgressMetricCard: View {
    let title: String
    let status: String
    let actual: Int
    let expected: Int
    let target: Int
    let unit: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                    Text(status)
                        .font(.caption)
                        .foregroundColor(statusColor)
                }
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Actual")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(formatNumber(actual)) \(unit)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Expected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(formatNumber(expected)) \(unit)")
                        .font(.caption)
                }
                
                HStack {
                    Text("Target")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(formatNumber(target)) \(unit)")
                        .font(.caption)
                }
                
                // Progress bar
                ProgressView(value: Double(actual), total: Double(target))
                    .progressViewStyle(LinearProgressViewStyle(tint: color))
                
                HStack {
                    Text("Progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int((Double(actual) / Double(target)) * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private var statusColor: Color {
        switch status {
        case "On Track":
            return .green
        case "Slightly Behind":
            return .orange
        case "Behind":
            return .red
        default:
            return .secondary
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}
