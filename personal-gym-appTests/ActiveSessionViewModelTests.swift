//
//  ActiveSessionViewModelTests.swift
//  personal-gym-appTests
//

import Testing
import Foundation
import SwiftData
@testable import personal_gym_app

@Suite("ActiveSessionViewModel")
struct ActiveSessionViewModelTests {

    // MARK: - Session creation

    @Test("Creating a session populates exercise sessions from plan templates")
    @MainActor func sessionCreation() throws {
        let context = try makeTestContext()
        let plan = makeSamplePlan(context: context)

        let vm = ActiveSessionViewModel(from: plan, context: context)

        #expect(vm.exercises.count == 2)
        #expect(vm.exercises[0].exerciseName == "Bench Press")
        #expect(vm.exercises[1].exerciseName == "Overhead Press")
        #expect(vm.session.planName == "Push Day")
        #expect(vm.session.isCompleted == false)
    }

    @Test("Session auto-populates default weight from template")
    @MainActor func defaultWeightPopulated() throws {
        let context = try makeTestContext()
        let plan = makeSamplePlan(context: context)

        let vm = ActiveSessionViewModel(from: plan, context: context)

        #expect(vm.exercises[0].weight == 60.0)
        #expect(vm.exercises[1].weight == 40.0)
    }

    // MARK: - Logging sets

    @Test("Logging a set creates a SetLog and starts rest")
    @MainActor func logSet() throws {
        let context = try makeTestContext()
        let plan = makeSamplePlan(context: context)
        let vm = ActiveSessionViewModel(from: plan, context: context)

        vm.logSet(reps: 10, weight: 60.0)

        #expect(vm.exercises[0].sets.count == 1)
        let logged = vm.exercises[0].sets.first
        #expect(logged?.reps == 10)
        #expect(logged?.weight == 60.0)
        #expect(logged?.setIndex == 0)
        #expect(vm.isResting == true)
    }

    @Test("Logging multiple sets increments setIndex")
    @MainActor func logMultipleSets() throws {
        let context = try makeTestContext()
        let plan = makeSamplePlan(context: context)
        let vm = ActiveSessionViewModel(from: plan, context: context)

        vm.stopRest()
        vm.logSet(reps: 10, weight: 60.0)
        vm.stopRest()
        vm.logSet(reps: 8, weight: 60.0)

        let sets = vm.exercises[0].sets.sorted(by: { $0.setIndex < $1.setIndex })
        #expect(sets.count == 2)
        #expect(sets[0].setIndex == 0)
        #expect(sets[1].setIndex == 1)
        #expect(sets[1].reps == 8)
    }

    @Test("Weight is updated on exercise session when logging a set")
    @MainActor func weightUpdated() throws {
        let context = try makeTestContext()
        let plan = makeSamplePlan(context: context)
        let vm = ActiveSessionViewModel(from: plan, context: context)

        vm.logSet(reps: 10, weight: 65.0)

        #expect(vm.exercises[0].weight == 65.0)
    }

    // MARK: - Exercise navigation

    @Test("Auto-advances to next exercise after completing all sets")
    @MainActor func autoAdvance() throws {
        let context = try makeTestContext()
        let plan = makeSamplePlan(context: context)
        let vm = ActiveSessionViewModel(from: plan, context: context)

        // Bench Press has 3 sets
        for _ in 0..<3 {
            vm.stopRest()
            vm.logSet(reps: 10, weight: 60.0)
        }

        #expect(vm.currentExerciseIndex == 1)
    }

    @Test("moveToNextExerciseIfPossible advances index")
    @MainActor func moveNext() throws {
        let context = try makeTestContext()
        let plan = makeSamplePlan(context: context)
        let vm = ActiveSessionViewModel(from: plan, context: context)

        #expect(vm.currentExerciseIndex == 0)
        vm.moveToNextExerciseIfPossible()
        #expect(vm.currentExerciseIndex == 1)
    }

    @Test("moveToNextExerciseIfPossible does not exceed bounds")
    @MainActor func moveNextAtEnd() throws {
        let context = try makeTestContext()
        let plan = makeSamplePlan(context: context)
        let vm = ActiveSessionViewModel(from: plan, context: context)

        vm.moveToNextExerciseIfPossible() // -> 1
        vm.moveToNextExerciseIfPossible() // should stay at 1
        #expect(vm.currentExerciseIndex == 1)
    }

    // MARK: - Rest timer

    @Test("stopRest cancels the timer and resets state")
    @MainActor func stopRest() throws {
        let context = try makeTestContext()
        let plan = makeSamplePlan(context: context)
        let vm = ActiveSessionViewModel(from: plan, context: context)

        vm.startRest(seconds: 90)
        #expect(vm.isResting == true)
        #expect(vm.restRemaining == 90)

        vm.stopRest()
        #expect(vm.isResting == false)
        #expect(vm.restRemaining == 0)
    }

    // MARK: - Completion

    @Test("markCompleted sets isCompleted to true")
    @MainActor func markCompleted() throws {
        let context = try makeTestContext()
        let plan = makeSamplePlan(context: context)
        let vm = ActiveSessionViewModel(from: plan, context: context)

        vm.markCompleted()

        #expect(vm.session.isCompleted == true)
    }

    // MARK: - Last used weight

    @Test("Last used weight is retrieved from previous session")
    @MainActor func lastUsedWeight() throws {
        let context = try makeTestContext()
        let plan = makeSamplePlan(context: context)

        // First session: log bench at 70kg
        let vm1 = ActiveSessionViewModel(from: plan, context: context)
        vm1.logSet(reps: 10, weight: 70.0)
        vm1.markCompleted()

        // Second session: should auto-populate 70kg for bench
        let vm2 = ActiveSessionViewModel(from: plan, context: context)

        #expect(vm2.exercises[0].weight == 70.0)
    }
}
