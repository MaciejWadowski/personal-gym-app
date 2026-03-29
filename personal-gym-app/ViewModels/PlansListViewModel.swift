//
//  PlanViewModels.swift
//  personal-gym-app
//
//  Created by Assistant on 23/03/2026.
//

import Foundation
import SwiftData
import SwiftUI
import Combine


@MainActor
final class PlansListViewModel: ObservableObject {
    @Published var plans: [WorkoutPlan] = []

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
        load()
    }

    func load() {
        let descriptor = FetchDescriptor<WorkoutPlan>(sortBy: [SortDescriptor(\WorkoutPlan.createdAt, order: .reverse)])
        do {
            plans = try context.fetch(descriptor)
        } catch {
            plans = []
        }
    }

    func addPlan(name: String) {
        let plan = WorkoutPlan(name: name)
        context.insert(plan)
        saveAndReload()
    }

    func delete(at offsets: IndexSet) {
        for idx in offsets { context.delete(plans[idx]) }
        saveAndReload()
    }

    func saveAndReload() {
        do { try context.save() } catch { }
        load()
    }
}

@MainActor
final class PlanDetailViewModel: ObservableObject {
    @Published var name: String
    @Published var exercises: [ExerciseTemplate]

    private var context: ModelContext?
    let plan: WorkoutPlan

    init(plan: WorkoutPlan) {
        self.plan = plan
        self.context = plan.modelContext
        self.name = plan.name
        self.exercises = plan.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })
    }

    func attach(context: ModelContext) {
        if self.context == nil {
            self.context = context
        }
        refresh()
    }

    func addExercise(name: String, sets: Int, targetMaxReps: Int, defaultWeight: Double?, restSeconds: Int) {
        guard let context else { return }
        let ex = ExerciseTemplate(name: name, sets: sets, targetMaxReps: targetMaxReps, defaultWeight: defaultWeight, restSeconds: restSeconds, orderIndex: (plan.exercises.map { $0.orderIndex }.max() ?? -1) + 1, plan: plan)
        context.insert(ex)
        save()
        refresh()
    }

    func deleteExercises(at offsets: IndexSet) {
        guard let context else { return }
        let sorted = plan.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })
        for idx in offsets { context.delete(sorted[idx]) }
        save()
        refresh()
    }

    func moveExercises(from: IndexSet, to: Int) {
        var items = plan.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })
        items.move(fromOffsets: from, toOffset: to)
        for (i, item) in items.enumerated() { item.orderIndex = i }
        save()
        refresh()
    }

    func updatePlanName() {
        plan.name = name
        plan.updatedAt = .now
        save()
    }

    private func save() {
        guard let context else { return }
        do { try context.save() } catch { }
    }

    func refresh() {
        exercises = plan.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })
    }
}
