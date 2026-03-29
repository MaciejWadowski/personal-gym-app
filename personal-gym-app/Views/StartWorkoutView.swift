//
//  WorkoutFlowViews.swift
//  personal-gym-app
//
//  Created by Assistant on 23/03/2026.
//

import SwiftUI
import SwiftData
import Foundation

struct StartWorkoutView: View {
    @Environment(\.modelContext) private var context
    let plan: WorkoutPlan
    @State private var vm: ActiveSessionViewModel?

    var body: some View {
        Group {
            if let vm {
                ActiveSessionView(vm: vm)
            } else {
                ProgressView().task {
                    vm = ActiveSessionViewModel(from: plan, context: context)
                }
            }
        }
        .navigationTitle("Workout")
        .toolbarTitleDisplayMode(.inline)
    }
}

struct ActiveSessionView: View {
    @ObservedObject var vm: ActiveSessionViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.selectedTab) private var selectedTab
    @State private var repsText: String = ""
    @FocusState private var repsFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            let current = vm.exercises[vm.currentExerciseIndex]
            VStack(alignment: .leading, spacing: 8) {
                Text(current.exerciseName).font(.title2).bold()
                HStack(spacing: 12) {
                    Label("Set \(current.sets.count + 1)/\(current.targetSets)", systemImage: "number")
                    Label("Rest \(current.restSeconds)s", systemImage: "timer")
                }.font(.subheadline).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                TextField("Reps", text: $repsText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 100)
                    .focused($repsFocused)
                WeightField(weight: Binding(
                    get: { current.weight ?? 0 },
                    set: { w in current.weight = w }
                ))
            }

            if vm.isResting {
                RestTimerView(remaining: vm.restRemaining)
                Button("Skip Rest") { vm.stopRest() }
                    .font(.subheadline)
                    .buttonStyle(.bordered)
            }

            Button {
                if vm.isResting { vm.stopRest() }
                let reps = Int(repsText) ?? 0
                vm.logSet(reps: reps, weight: vm.exercises[vm.currentExerciseIndex].weight)
                repsText = ""
                repsFocused = true
            } label: {
                Text("Log Set & Start Rest")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled((Int(repsText) ?? 0) <= 0)

            Divider()

            List {
                ForEach(Array(vm.exercises.enumerated()), id: \.offset) { idx, ex in
                    Section {
                        ForEach(ex.sets.sorted(by: { $0.setIndex < $1.setIndex })) { set in
                            HStack {
                                Text("Set \(set.setIndex + 1)")
                                Spacer()
                                Text("\(set.reps) reps")
                                if let w = set.weight { Text("@ \(formatKg(w))").foregroundStyle(.secondary) }
                            }
                        }
                    } header: {
                        HStack {
                            Text(ex.exerciseName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(idx == vm.currentExerciseIndex ? Color.accentColor : .primary)
                            if idx == vm.currentExerciseIndex {
                                Text("current")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor, in: Capsule())
                            }
                            Spacer()
                            Text("\(ex.sets.count)/\(ex.targetSets) sets")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .textCase(nil)
                    }
                }
            }

            HStack {
                Button("Previous") { if vm.currentExerciseIndex > 0 { vm.currentExerciseIndex -= 1 } }
                Spacer()
                Button("Next") { vm.moveToNextExerciseIfPossible() }
            }

            Button("Mark Workout Completed") {
                vm.markCompleted()
                selectedTab.wrappedValue = .history
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

struct WeightField: View {
    @Binding var weight: Double
    @State private var text: String = ""

    init(weight: Binding<Double>) {
        _weight = weight
        _text = State(initialValue: Self.formatWeight(weight.wrappedValue))
    }

    var body: some View {
        HStack {
            TextField("Weight (kg)", text: $text)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .onChange(of: text) {
                    let normalized = text.replacingOccurrences(of: ",", with: ".")
                    if normalized != text { text = normalized }
                    weight = Double(normalized) ?? 0
                }
            Text("kg").foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private static func formatWeight(_ value: Double) -> String {
        if value == 0 { return "" }
        if value == value.rounded() { return String(Int(value)) }
        return String(format: "%.1f", value)
    }
}

struct RestTimerView: View {
    let remaining: Int

    var body: some View {
        HStack {
            Image(systemName: "timer")
            Text("Rest: \(remaining)s")
        }
        .font(.headline)
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// Format a weight value for display: "22 kg" or "22.5 kg"
func formatKg(_ value: Double) -> String {
    if value == value.rounded() {
        return "\(Int(value)) kg"
    }
    return String(format: "%.1f kg", value)
}
