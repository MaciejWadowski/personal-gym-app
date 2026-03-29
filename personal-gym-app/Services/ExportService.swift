//
//  ExportService.swift
//  personal-gym-app
//
//  Created by Maciej Wadowski on 23/03/2026.
//


//
//  ExportService.swift
//  personal-gym-app
//
//  Created by Assistant on 23/03/2026.
//

import Foundation
import SwiftData

struct ExportService {
    enum ExportError: Error { case noData }

    static func exportCSV(for plan: WorkoutPlan, from context: ModelContext) throws -> URL {
        // Fetch sessions for this plan name
        let planName = plan.name
        let fetch = FetchDescriptor<WorkoutSession>(predicate: #Predicate { $0.planName == planName }, sortBy: [SortDescriptor(\WorkoutSession.date, order: .forward)])
        let sessions = try context.fetch(fetch)
        guard !sessions.isEmpty else { throw ExportError.noData }

        var rows: [String] = []
        // Header
        rows.append("Workout Name,Date,Exercise,Set #,Reps,Weight (kg)")

        for s in sessions {
            for ex in s.exercises {
                let base = "\(s.planName),\(Self.formatDate(s.date)),\(Self.escape(ex.exerciseName))"
                if ex.sets.isEmpty {
                    rows.append(base + ",,,")
                } else {
                    for set in ex.sets.sorted(by: { $0.setIndex < $1.setIndex }) {
                        let weightStr = set.weight != nil ? String(format: "%.2f", set.weight!) : ""
                        rows.append(base + ",\(set.setIndex + 1),\(set.reps),\(weightStr)")
                    }
                }
            }
        }

        // Totals & averages per exercise across sessions
        rows.append("")
        rows.append("Totals/Averages")
        rows.append("Exercise,Total Sets,Total Reps,Average Reps/Set,Average Weight (kg)")
        let exerciseGroups = sessions.flatMap { $0.exercises }.reduce(into: [String: [SetLog]]()) { dict, ex in
            dict[ex.exerciseName, default: []].append(contentsOf: ex.sets)
        }
        for (name, logs) in exerciseGroups {
            let totalSets = logs.count
            let totalReps = logs.reduce(0) { $0 + $1.reps }
            let avgReps = totalSets > 0 ? Double(totalReps) / Double(totalSets) : 0
            let weights = logs.compactMap { $0.weight }
            let avgWeight = weights.isEmpty ? 0 : (weights.reduce(0, +) / Double(weights.count))
            rows.append("\(Self.escape(name)),\(totalSets),\(totalReps),\(String(format: "%.2f", avgReps)),\(String(format: "%.2f", avgWeight))")
        }

        let csv = rows.joined(separator: "\n")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(plan.name)-history.csv")
        try csv.data(using: .utf8)?.write(to: url)
        return url
    }

    private static func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .none
        return f.string(from: date)
    }

    private static func escape(_ s: String) -> String {
        if s.contains(",") || s.contains("\"") {
            let escaped = s.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return s
    }
}
