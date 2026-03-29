//
//  ExportServiceTests.swift
//  personal-gym-appTests
//

import Testing
import Foundation
import SwiftData
@testable import personal_gym_app

@Suite("ExportService")
struct ExportServiceTests {

    @Test("Exporting with no sessions throws noData error")
    @MainActor func exportNoData() throws {
        let context = try makeTestContext()
        let plan = WorkoutPlan(name: "Empty Plan")
        context.insert(plan)
        try context.save()

        #expect(throws: ExportService.ExportError.self) {
            _ = try ExportService.exportCSV(for: plan, from: context)
        }
    }

    @Test("Exporting generates a CSV file with correct header")
    @MainActor func exportCSVHeader() throws {
        let context = try makeTestContext()
        let plan = makeSamplePlan(context: context)

        // Create a session with one logged set
        let vm = ActiveSessionViewModel(from: plan, context: context)
        vm.logSet(reps: 10, weight: 60.0)
        vm.markCompleted()

        let url = try ExportService.exportCSV(for: plan, from: context)
        let csv = try String(contentsOf: url, encoding: .utf8)
        let lines = csv.components(separatedBy: "\n")

        #expect(lines.first == "Workout Name,Date,Exercise,Set #,Reps,Weight (kg)")
    }

    @Test("Exported CSV contains set data rows")
    @MainActor func exportCSVContainsData() throws {
        let context = try makeTestContext()
        let plan = makeSamplePlan(context: context)

        let vm = ActiveSessionViewModel(from: plan, context: context)
        vm.logSet(reps: 10, weight: 60.0)
        vm.stopRest()
        vm.logSet(reps: 8, weight: 60.0)
        vm.markCompleted()

        let url = try ExportService.exportCSV(for: plan, from: context)
        let csv = try String(contentsOf: url, encoding: .utf8)
        let lines = csv.components(separatedBy: "\n")

        // Header + at least 2 data rows for the logged sets + exercises with 0 sets + totals section
        #expect(lines.count > 3)

        // Find a line with "Bench Press" and "10" reps
        let benchLines = lines.filter { $0.contains("Bench Press") && $0.contains(",10,") }
        #expect(!benchLines.isEmpty)
    }

    @Test("Exported CSV includes totals/averages section")
    @MainActor func exportCSVTotals() throws {
        let context = try makeTestContext()
        let plan = makeSamplePlan(context: context)

        let vm = ActiveSessionViewModel(from: plan, context: context)
        vm.logSet(reps: 10, weight: 60.0)
        vm.markCompleted()

        let url = try ExportService.exportCSV(for: plan, from: context)
        let csv = try String(contentsOf: url, encoding: .utf8)

        #expect(csv.contains("Totals/Averages"))
        #expect(csv.contains("Exercise,Total Sets,Total Reps,Average Reps/Set,Average Weight (kg)"))
    }

    @Test("CSV file is written to a valid URL")
    @MainActor func exportCSVFileExists() throws {
        let context = try makeTestContext()
        let plan = makeSamplePlan(context: context)

        let vm = ActiveSessionViewModel(from: plan, context: context)
        vm.logSet(reps: 10, weight: 60.0)
        vm.markCompleted()

        let url = try ExportService.exportCSV(for: plan, from: context)

        #expect(FileManager.default.fileExists(atPath: url.path))

        // Cleanup
        try? FileManager.default.removeItem(at: url)
    }
}
