//
//  PlansListViewModelTests.swift
//  personal-gym-appTests
//

import Testing
import Foundation
import SwiftData
@testable import personal_gym_app

@Suite("PlansListViewModel")
struct PlansListViewModelTests {

    // MARK: - Plan CRUD

    @Test("Adding a plan persists it and appears in the list")
    @MainActor func addPlan() throws {
        let context = try makeTestContext()
        let vm = PlansListViewModel(context: context)

        vm.addPlan(name: "Leg Day")

        #expect(vm.plans.count == 1)
        #expect(vm.plans.first?.name == "Leg Day")
    }

    @Test("Adding multiple plans returns them in reverse-creation order")
    @MainActor func addMultiplePlans() throws {
        let context = try makeTestContext()
        let vm = PlansListViewModel(context: context)

        vm.addPlan(name: "Plan A")
        vm.addPlan(name: "Plan B")

        #expect(vm.plans.count == 2)
        #expect(vm.plans.first?.name == "Plan B")
    }

    @Test("Deleting a plan removes it from the list")
    @MainActor func deletePlan() throws {
        let context = try makeTestContext()
        let vm = PlansListViewModel(context: context)

        vm.addPlan(name: "To Delete")
        #expect(vm.plans.count == 1)

        vm.delete(at: IndexSet(integer: 0))
        #expect(vm.plans.isEmpty)
    }
}

@Suite("PlanDetailViewModel")
struct PlanDetailViewModelTests {

    // MARK: - Exercise CRUD

    @Test("Adding an exercise to a plan persists it")
    @MainActor func addExercise() throws {
        let context = try makeTestContext()
        let plan = makeSamplePlan(name: "Test Plan", context: context)
        let vm = PlanDetailViewModel(plan: plan)
        vm.attach(context: context)

        let initialCount = vm.exercises.count
        vm.addExercise(name: "Curls", sets: 3, targetMaxReps: 12, defaultWeight: 15.0, restSeconds: 60)

        #expect(vm.exercises.count == initialCount + 1)
        #expect(vm.exercises.last?.name == "Curls")
        #expect(vm.exercises.last?.defaultWeight == 15.0)
    }

    @Test("Deleting an exercise removes it from the plan")
    @MainActor func deleteExercise() throws {
        let context = try makeTestContext()
        let plan = makeSamplePlan(context: context)
        let vm = PlanDetailViewModel(plan: plan)
        vm.attach(context: context)

        let initialCount = vm.exercises.count
        vm.deleteExercises(at: IndexSet(integer: 0))

        #expect(vm.exercises.count == initialCount - 1)
    }

    @Test("Moving exercises reorders them correctly")
    @MainActor func moveExercises() throws {
        let context = try makeTestContext()
        let plan = makeSamplePlan(context: context)
        let vm = PlanDetailViewModel(plan: plan)
        vm.attach(context: context)

        // Move first exercise (Bench Press) to after second (Overhead Press)
        let firstName = vm.exercises.first!.name
        vm.moveExercises(from: IndexSet(integer: 0), to: 2)

        #expect(vm.exercises.last?.name == firstName)
    }

    @Test("Updating plan name persists the change")
    @MainActor func updatePlanName() throws {
        let context = try makeTestContext()
        let plan = makeSamplePlan(context: context)
        let vm = PlanDetailViewModel(plan: plan)
        vm.attach(context: context)

        vm.name = "Updated Name"
        vm.updatePlanName()

        #expect(plan.name == "Updated Name")
    }

    @Test("Adding exercise with nil weight stores nil")
    @MainActor func addExerciseNoWeight() throws {
        let context = try makeTestContext()
        let plan = makeSamplePlan(context: context)
        let vm = PlanDetailViewModel(plan: plan)
        vm.attach(context: context)

        vm.addExercise(name: "Bodyweight Dips", sets: 3, targetMaxReps: 15, defaultWeight: nil, restSeconds: 60)

        #expect(vm.exercises.last?.defaultWeight == nil)
    }

    @Test("Exercise orderIndex increments correctly")
    @MainActor func orderIndexIncrement() throws {
        let context = try makeTestContext()
        let plan = WorkoutPlan(name: "Empty")
        context.insert(plan)
        try context.save()

        let vm = PlanDetailViewModel(plan: plan)
        vm.attach(context: context)

        vm.addExercise(name: "Ex1", sets: 1, targetMaxReps: 1, defaultWeight: nil, restSeconds: 30)
        vm.addExercise(name: "Ex2", sets: 1, targetMaxReps: 1, defaultWeight: nil, restSeconds: 30)
        vm.addExercise(name: "Ex3", sets: 1, targetMaxReps: 1, defaultWeight: nil, restSeconds: 30)

        #expect(vm.exercises[0].orderIndex == 0)
        #expect(vm.exercises[1].orderIndex == 1)
        #expect(vm.exercises[2].orderIndex == 2)
    }
}
