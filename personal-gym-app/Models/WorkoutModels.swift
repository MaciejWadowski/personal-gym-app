//
//  WorkoutModels.swift
//  personal-gym-app
//
//  Created by Assistant on 23/03/2026.
//

import Foundation
import SwiftData

@Model
final class WorkoutPlan {
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var exercises: [ExerciseTemplate] = []
    var sessions: [WorkoutSession] = []

    init(name: String, createdAt: Date = .now, updatedAt: Date = .now) {
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class ExerciseTemplate {
    var name: String
    var sets: Int
    var targetMaxReps: Int
    var defaultWeight: Double?
    var restSeconds: Int
    var orderIndex: Int

    @Relationship(inverse: \WorkoutPlan.exercises)
    var plan: WorkoutPlan?

    init(name: String,
         sets: Int,
         targetMaxReps: Int,
         defaultWeight: Double? = nil,
         restSeconds: Int,
         orderIndex: Int = 0,
         plan: WorkoutPlan? = nil) {
        self.name = name
        self.sets = sets
        self.targetMaxReps = targetMaxReps
        self.defaultWeight = defaultWeight
        self.restSeconds = restSeconds
        self.orderIndex = orderIndex
        self.plan = plan
    }
}

@Model
final class WorkoutSession {
    var date: Date
    var planName: String
    var isCompleted: Bool

    var exercises: [ExerciseSession] = []

    @Relationship(inverse: \WorkoutPlan.sessions)
    var plan: WorkoutPlan?

    init(date: Date = .now, planName: String, isCompleted: Bool = false, plan: WorkoutPlan? = nil) {
        self.date = date
        self.planName = planName
        self.isCompleted = isCompleted
        self.plan = plan
    }
}

@Model
final class ExerciseSession {
    var exerciseName: String
    var targetSets: Int
    var targetMaxReps: Int
    var restSeconds: Int
    var weight: Double?

    var sets: [SetLog] = []

    @Relationship
    var template: ExerciseTemplate?

    @Relationship(inverse: \WorkoutSession.exercises)
    var session: WorkoutSession?

    init(exerciseName: String,
         targetSets: Int,
         targetMaxReps: Int,
         restSeconds: Int,
         weight: Double? = nil,
         template: ExerciseTemplate? = nil,
         session: WorkoutSession? = nil) {
        self.exerciseName = exerciseName
        self.targetSets = targetSets
        self.targetMaxReps = targetMaxReps
        self.restSeconds = restSeconds
        self.weight = weight
        self.template = template
        self.session = session
    }
}

@Model
final class SetLog {
    var setIndex: Int
    var reps: Int
    var weight: Double?
    var timestamp: Date

    @Relationship(inverse: \ExerciseSession.sets)
    var exercise: ExerciseSession?

    init(setIndex: Int, reps: Int, weight: Double?, timestamp: Date = .now, exercise: ExerciseSession? = nil) {
        self.setIndex = setIndex
        self.reps = reps
        self.weight = weight
        self.timestamp = timestamp
        self.exercise = exercise
    }
}
