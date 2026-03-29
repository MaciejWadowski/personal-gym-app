//
//  PlansViews.swift
//  personal-gym-app
//
//  Created by Assistant on 23/03/2026.
//

import SwiftUI
import SwiftData

struct PlansListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutPlan.createdAt, order: .reverse) private var plans: [WorkoutPlan]
    @State private var showingNewPlan = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(plans) { plan in
                    NavigationLink(value: plan) {
                        VStack(alignment: .leading) {
                            Text(plan.name).font(.headline)
                            Text("\(plan.exercises.count) exercises").foregroundStyle(.secondary).font(.subheadline)
                        }
                    }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Plans")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingNewPlan = true } label: { Image(systemName: "plus") }
                }
            }
            .navigationDestination(for: WorkoutPlan.self) { plan in
                PlanDetailView(plan: plan)
            }
            .sheet(isPresented: $showingNewPlan) {
                NewPlanSheet()
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets { context.delete(plans[index]) }
        try? context.save()
    }
}

struct NewPlanSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var name: String = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Plan name", text: $name)
            }
            .navigationTitle("New Plan")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let plan = WorkoutPlan(name: name)
                        context.insert(plan)
                        try? context.save()
                        dismiss()
                    }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

struct PlanDetailView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var vm: PlanDetailViewModel

    init(plan: WorkoutPlan) {
        _vm = StateObject(wrappedValue: PlanDetailViewModel(plan: plan))
    }

    var body: some View {
        Form {
            Section("Plan") {
                TextField("Name", text: $vm.name)
                    .onChange(of: vm.name) { vm.updatePlanName() }
            }
            Section("Exercises") {
                if vm.exercises.isEmpty {
                    ContentUnavailableView("No exercises", systemImage: "dumbbell", description: Text("Add exercises to this plan"))
                }
                ForEach(vm.exercises) { ex in
                    VStack(alignment: .leading) {
                        Text(ex.name).font(.headline)
                        HStack(spacing: 12) {
                            Label("Sets: \(ex.sets)", systemImage: "square.stack")
                            Label("Max reps: \(ex.targetMaxReps)", systemImage: "number")
                            Label("Rest: \(ex.restSeconds)s", systemImage: "timer")
                        }.font(.caption).foregroundStyle(.secondary)
                        if let w = ex.defaultWeight { Text("Default weight: \(formatKg(w))").font(.caption).foregroundStyle(.secondary) }
                    }
                }
                .onDelete(perform: delete)
                .onMove(perform: move)
                Button { showingAdd = true } label: { Label("Add exercise", systemImage: "plus") }
            }
            Section {
                NavigationLink { StartWorkoutView(plan: vm.plan) } label: { Text("Start Workout") }
            }
        }
        .navigationTitle("Plan Details")
        .toolbar { EditButton() }
        .sheet(isPresented: $showingAdd) { AddExerciseSheet(vm: vm) }
        .onAppear { vm.attach(context: context) }
    }

    @State private var showingAdd = false

    private func delete(at offsets: IndexSet) { vm.deleteExercises(at: offsets) }
    private func move(from: IndexSet, to: Int) { vm.moveExercises(from: from, to: to) }
}

struct AddExerciseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vm: PlanDetailViewModel

    @State private var name: String = ""
    @State private var sets: Int = 3
    @State private var reps: Int = 8
    @State private var weight: String = ""
    @State private var rest: Int = 90

    var body: some View {
        NavigationStack {
            Form {
                TextField("Exercise name", text: $name)
                Stepper(value: $sets, in: 1...10) { Text("Sets: \(sets)") }
                Stepper(value: $reps, in: 1...30) { Text("Target max reps: \(reps)") }
                TextField("Default weight (kg)", text: $weight)
                    .keyboardType(.decimalPad)
                Stepper(value: $rest, in: 15...300, step: 15) { Text("Rest: \(rest) sec") }
            }
            .navigationTitle("Add Exercise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        vm.addExercise(name: name, sets: sets, targetMaxReps: reps, defaultWeight: parseWeight(weight), restSeconds: rest)
                        dismiss()
                    }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

/// Parse a user-entered decimal string (supports comma as decimal separator).
/// Returns nil only when the text is non-empty but not a valid number.
func parseWeight(_ text: String) -> Double? {
    let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
    if t.isEmpty { return nil }
    return Double(t.replacingOccurrences(of: ",", with: "."))
}
