//
//  GoalFormView.swift
//  FitnessTracker
//
//  Created by Blink on 1/20/25.
//

import SwiftUI

struct GoalFormView: View {
    let existingGoal: Goal?
    let onSave: (GoalInput) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var year: Int
    @State private var annualWeightTarget: String
    @State private var minutesPerSession: String
    @State private var weeklySessionsTarget: String
    
    init(existingGoal: Goal? = nil, onSave: @escaping (GoalInput) -> Void) {
        self.existingGoal = existingGoal
        self.onSave = onSave
        
        // Initialize state with existing goal values or defaults
        _name = State(initialValue: existingGoal?.name ?? "")
        _year = State(initialValue: existingGoal?.year ?? Calendar.current.component(.year, from: Date()))
        _annualWeightTarget = State(initialValue: existingGoal?.annualWeightTarget.formatted() ?? "500000")
        _minutesPerSession = State(initialValue: existingGoal?.minutesPerSession.formatted() ?? "45")
        _weeklySessionsTarget = State(initialValue: existingGoal?.weeklySessionsTarget.formatted() ?? "5")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Goal Details")) {
                    TextField("Goal Name", text: $name)
                        .placeholder(when: name.isEmpty) {
                            Text("e.g., 2025 Fitness Challenge")
                                .foregroundColor(.secondary)
                        }
                    
                    Picker("Year", selection: $year) {
                        ForEach(2024...2030, id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                }
                
                Section(header: Text("Annual Targets")) {
                    VStack(alignment: .leading) {
                        Text("Annual Weight Target (lbs)")
                        TextField("500,000", text: $annualWeightTarget)
                            .keyboardType(.numberPad)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Minutes per Session")
                        TextField("45", text: $minutesPerSession)
                            .keyboardType(.numberPad)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Weekly Sessions Target")
                        TextField("5", text: $weeklySessionsTarget)
                            .keyboardType(.numberPad)
                    }
                }
                
                Section(header: Text("Calculated Targets")) {
                    if let calculatedTargets = calculateTargets() {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Weekly Minutes:")
                                Spacer()
                                Text("\(calculatedTargets.weeklyMinutes) min")
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Annual Minutes:")
                                Spacer()
                                Text("\(formatNumber(calculatedTargets.annualMinutes)) min")
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Quarterly Weight:")
                                Spacer()
                                Text("\(formatNumber(Int(calculatedTargets.quarterlyWeight))) lbs")
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Quarterly Minutes:")
                                Spacer()
                                Text("\(formatNumber(calculatedTargets.quarterlyMinutes)) min")
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Quarterly Sessions:")
                                Spacer()
                                Text("\(calculatedTargets.quarterlySessions) sessions")
                                    .fontWeight(.medium)
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    } else {
                        Text("Enter values above to see calculated targets")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(existingGoal == nil ? "Create Goal" : "Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveGoal()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty &&
        Double(annualWeightTarget) != nil &&
        Int(minutesPerSession) != nil &&
        Int(weeklySessionsTarget) != nil
    }
    
    private func calculateTargets() -> (weeklyMinutes: Int, annualMinutes: Int, quarterlyWeight: Double, quarterlyMinutes: Int, quarterlySessions: Int)? {
        guard let weightTarget = Double(annualWeightTarget),
              let minutesSession = Int(minutesPerSession),
              let sessionsWeek = Int(weeklySessionsTarget) else {
            return nil
        }
        
        let weeklyMinutes = minutesSession * sessionsWeek
        let annualMinutes = weeklyMinutes * 52
        let quarterlyWeight = weightTarget / 4
        let quarterlyMinutes = annualMinutes / 4
        let quarterlySessions = sessionsWeek * 13
        
        return (weeklyMinutes, annualMinutes, quarterlyWeight, quarterlyMinutes, quarterlySessions)
    }
    
    private func saveGoal() {
        guard let weightTarget = Double(annualWeightTarget),
              let minutesSession = Int(minutesPerSession),
              let sessionsWeek = Int(weeklySessionsTarget) else {
            return
        }
        
        let goalInput = GoalInput(
            name: name,
            year: year,
            annualWeightTarget: weightTarget,
            minutesPerSession: minutesSession,
            weeklySessionsTarget: sessionsWeek
        )
        
        onSave(goalInput)
        dismiss()
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// Helper extension for placeholder text
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

struct GoalFormView_Previews: PreviewProvider {
    static var previews: some View {
        GoalFormView { _ in }
    }
}
