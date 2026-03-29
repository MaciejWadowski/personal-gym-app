//
//  TestHelpers.swift
//  personal-gym-appTests
//

import Foundation
import SwiftData
@testable import personal_gym_app

/// Creates an in-memory ModelContainer and ModelContext for testing.
@MainActor
func makeTestContext() throws -> ModelContext {
    let schema = Schema([
        WorkoutPlan.self,
        ExerciseTemplate.self,
        WorkoutSession.self,
        ExerciseSession.self,
        SetLog.self
    ])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: config)
    return ModelContext(container)
}

/// Creates a WorkoutPlan with exercises already inserted into the given context.
@MainActor
func makeSamplePlan(name: String = "Push Day", context: ModelContext) -> WorkoutPlan {
    let plan = WorkoutPlan(name: name)
    context.insert(plan)

    let bench = ExerciseTemplate(
        name: "Bench Press", sets: 3, targetMaxReps: 10,
        defaultWeight: 60.0, restSeconds: 90, orderIndex: 0, plan: plan
    )
    context.insert(bench)

    let ohp = ExerciseTemplate(
        name: "Overhead Press", sets: 3, targetMaxReps: 8,
        defaultWeight: 40.0, restSeconds: 60, orderIndex: 1, plan: plan
    )
    context.insert(ohp)

    try? context.save()
    return plan
}
