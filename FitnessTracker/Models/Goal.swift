//
//  Goal.swift
//  FitnessTracker
//
//  Created by Blink on 1/20/25.
//

import Foundation

struct Goal: Identifiable, Codable {
    let id: String
    let name: String
    let year: Int
    
    // Annual targets
    let annualWeightTarget: Double // Total lbs for the year
    let minutesPerSession: Int // Minutes per individual session
    let weeklySessionsTarget: Int // Sessions per week
    
    // Calculated fields (derived from above)
    let weeklyMinutesTarget: Int // minutesPerSession * weeklySessionsTarget
    let annualMinutesTarget: Int // weeklyMinutesTarget * 52
    let quarterlyWeightTarget: Double // annualWeightTarget / 4
    let quarterlyMinutesTarget: Int // annualMinutesTarget / 4
    let quarterlySessionsTarget: Int // weeklySessionsTarget * 13
    
    let createdAt: Date
    let updatedAt: Date
    
    // For API encoding/decoding
    enum CodingKeys: String, CodingKey {
        case id, name, year
        case annualWeightTarget, minutesPerSession, weeklySessionsTarget
        case weeklyMinutesTarget, annualMinutesTarget
        case quarterlyWeightTarget, quarterlyMinutesTarget, quarterlySessionsTarget
        case createdAt, updatedAt
    }
}

// Goal creation helper
struct GoalInput {
    let name: String
    let year: Int
    let annualWeightTarget: Double
    let minutesPerSession: Int
    let weeklySessionsTarget: Int
    
    func createGoal() -> Goal {
        let weeklyMinutesTarget = minutesPerSession * weeklySessionsTarget
        let annualMinutesTarget = weeklyMinutesTarget * 52
        let quarterlyWeightTarget = annualWeightTarget / 4
        let quarterlyMinutesTarget = annualMinutesTarget / 4
        let quarterlySessionsTarget = weeklySessionsTarget * 13
        
        return Goal(
            id: UUID().uuidString,
            name: name,
            year: year,
            annualWeightTarget: annualWeightTarget,
            minutesPerSession: minutesPerSession,
            weeklySessionsTarget: weeklySessionsTarget,
            weeklyMinutesTarget: weeklyMinutesTarget,
            annualMinutesTarget: annualMinutesTarget,
            quarterlyWeightTarget: quarterlyWeightTarget,
            quarterlyMinutesTarget: quarterlyMinutesTarget,
            quarterlySessionsTarget: quarterlySessionsTarget,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// Goal progress calculations
struct GoalProgress {
    let currentQuarter: Int
    let currentYear: Int
    
    // Actual progress
    let actualWeightLifted: (quarterToDate: Double, yearToDate: Double)
    let actualMinutes: (quarterToDate: Int, yearToDate: Int)
    let actualSessions: (quarterToDate: Int, yearToDate: Int)
    
    // Expected progress (based on time elapsed)
    let expectedWeightLifted: (quarterToDate: Double, yearToDate: Double)
    let expectedMinutes: (quarterToDate: Int, yearToDate: Int)
    let expectedSessions: (quarterToDate: Int, yearToDate: Int)
    
    // Sessions needed to hit targets
    let sessionsNeededForQuarter: Int
    let sessionsNeededForYear: Int
    
    // Time remaining
    let daysRemainingInQuarter: Int
}

// Helper functions for goal calculations
struct GoalCalculations {
    static func calculateProgress(goal: Goal, workouts: [Workout]) -> GoalProgress {
        let now = Date()
        let calendar = Calendar.current
        let currentQuarter = (calendar.component(.month, from: now) - 1) / 3 + 1
        let currentYear = calendar.component(.year, from: now)
        
        // Calculate quarter date range
        let quarterStartMonth = (currentQuarter - 1) * 3 + 1
        let quarterStart = calendar.date(from: DateComponents(year: currentYear, month: quarterStartMonth, day: 1))!
        let quarterEnd = calendar.date(byAdding: DateComponents(month: 3, day: -1), to: quarterStart)!
        
        // Calculate year date range
        let yearStart = calendar.date(from: DateComponents(year: currentYear, month: 1, day: 1))!
        let yearEnd = calendar.date(from: DateComponents(year: currentYear, month: 12, day: 31))!
        
        // Filter workouts for current periods
        let quarterWorkouts = workouts.filter { workout in
            workout.date >= quarterStart && workout.date <= quarterEnd
        }
        let yearWorkouts = workouts.filter { workout in
            workout.date >= yearStart && workout.date <= yearEnd
        }
        
        // Calculate actual progress
        let actualWeightQuarter = quarterWorkouts.reduce(0) { $0 + ($1.weight ?? 0) }
        let actualWeightYear = yearWorkouts.reduce(0) { $0 + ($1.weight ?? 0) }
        let actualMinutesQuarter = quarterWorkouts.reduce(0) { $0 + Int($1.minutes) }
        let actualMinutesYear = yearWorkouts.reduce(0) { $0 + Int($1.minutes) }
        let actualSessionsQuarter = quarterWorkouts.count
        let actualSessionsYear = yearWorkouts.count
        
        // Calculate expected progress based on time elapsed
        let totalDaysInQuarter = calendar.dateInterval(of: .quarter, for: now)?.duration ?? 0
        let daysIntoQuarter = now.timeIntervalSince(quarterStart) / (24 * 60 * 60)
        let quarterProgress = min(daysIntoQuarter / (totalDaysInQuarter / (24 * 60 * 60)), 1.0)
        
        let totalDaysInYear = calendar.dateInterval(of: .year, for: now)?.duration ?? 0
        let daysIntoYear = now.timeIntervalSince(yearStart) / (24 * 60 * 60)
        let yearProgress = min(daysIntoYear / (totalDaysInYear / (24 * 60 * 60)), 1.0)
        
        let expectedWeightQuarter = goal.quarterlyWeightTarget * quarterProgress
        let expectedWeightYear = goal.annualWeightTarget * yearProgress
        let expectedMinutesQuarter = Double(goal.quarterlyMinutesTarget) * quarterProgress
        let expectedMinutesYear = Double(goal.annualMinutesTarget) * yearProgress
        let expectedSessionsQuarter = Double(goal.quarterlySessionsTarget) * quarterProgress
        let expectedSessionsYear = Double(goal.weeklySessionsTarget * 52) * yearProgress
        
        // Calculate sessions needed
        let remainingMinutesQuarter = max(0, goal.quarterlyMinutesTarget - actualMinutesQuarter)
        let sessionsNeededForQuarter = max(0, Int(ceil(Double(remainingMinutesQuarter) / Double(goal.minutesPerSession))))
        
        let remainingMinutesYear = max(0, goal.annualMinutesTarget - actualMinutesYear)
        let sessionsNeededForYear = max(0, Int(ceil(Double(remainingMinutesYear) / Double(goal.minutesPerSession))))
        
        // Calculate days remaining in quarter
        let daysRemainingInQuarter = max(0, calendar.dateComponents([.day], from: now, to: quarterEnd).day ?? 0)
        
        return GoalProgress(
            currentQuarter: currentQuarter,
            currentYear: currentYear,
            actualWeightLifted: (actualWeightQuarter, actualWeightYear),
            actualMinutes: (actualMinutesQuarter, actualMinutesYear),
            actualSessions: (actualSessionsQuarter, actualSessionsYear),
            expectedWeightLifted: (expectedWeightQuarter, expectedWeightYear),
            expectedMinutes: (Int(expectedMinutesQuarter), Int(expectedMinutesYear)),
            expectedSessions: (Int(expectedSessionsQuarter), Int(expectedSessionsYear)),
            sessionsNeededForQuarter: sessionsNeededForQuarter,
            sessionsNeededForYear: sessionsNeededForYear,
            daysRemainingInQuarter: daysRemainingInQuarter
        )
    }
    
    static func getProgressStatus(actual: Double, expected: Double) -> String {
        if actual >= expected {
            return "On Track"
        } else if actual >= expected * 0.8 {
            return "Slightly Behind"
        } else {
            return "Behind"
        }
    }
}
