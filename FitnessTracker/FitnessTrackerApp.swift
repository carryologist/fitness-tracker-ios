//
//  FitnessTrackerApp.swift
//  FitnessTracker
//
//  Created by Blink on 1/20/25.
//

import SwiftUI
import HealthKit

@main
struct FitnessTrackerApp: App {
    @StateObject private var healthKitManager = HealthKitManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthKitManager)
                .onAppear {
                    healthKitManager.requestAuthorization()
                }
        }
    }
}