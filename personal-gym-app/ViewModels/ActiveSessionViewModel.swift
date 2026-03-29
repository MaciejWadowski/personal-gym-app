//
//  ActiveSessionViewModel.swift
//  personal-gym-app
//
//  Created by Maciej Wadowski on 23/03/2026.
//


//
//  SessionViewModels.swift
//  personal-gym-app
//
//  Created by Assistant on 23/03/2026.
//

import Foundation
import SwiftData
import SwiftUI
import Combine
import AudioToolbox

@MainActor
final class ActiveSessionViewModel: ObservableObject {
    @Published var session: WorkoutSession
    @Published var exercises: [ExerciseSession]
    @Published var currentExerciseIndex: Int = 0
    @Published var isResting: Bool = false
    @Published var restRemaining: Int = 0

    private var timerTask: Task<Void, Never>?
    private let context: ModelContext

    init(from plan: WorkoutPlan, context: ModelContext) {
        self.context = context
        // Create new session with auto-populated weights from last usage
        let session = WorkoutSession(planName: plan.name, isCompleted: false, plan: plan)
        self.session = session
        context.insert(session)

        // Build exercise sessions
        var exSessions: [ExerciseSession] = []
        for tmpl in plan.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }) {
            let weight = Self.lastUsedWeight(for: tmpl, context: context) ?? tmpl.defaultWeight
            let ex = ExerciseSession(exerciseName: tmpl.name,
                                     targetSets: tmpl.sets,
                                     targetMaxReps: tmpl.targetMaxReps,
                                     restSeconds: tmpl.restSeconds,
                                     weight: weight,
                                     template: tmpl,
                                     session: session)
            context.insert(ex)
            exSessions.append(ex)
        }
        self.exercises = exSessions
        save()
    }

    static func lastUsedWeight(for template: ExerciseTemplate, context: ModelContext) -> Double? {
        // Find most recent session for this template name
        let planName = template.plan?.name ?? ""
        let fetch = FetchDescriptor<WorkoutSession>(predicate: #Predicate { $0.planName == planName }, sortBy: [SortDescriptor(\WorkoutSession.date, order: .reverse)])
        guard let lastSession = try? context.fetch(fetch).first else { return nil }
        if let ex = lastSession.exercises.first(where: { $0.exerciseName == template.name }) {
            return ex.weight
        }
        return nil
    }

    func startRest(seconds: Int) {
        timerTask?.cancel()
        restRemaining = seconds
        isResting = true
        timerTask = Task { [weak self] in
            while let self, self.restRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                self.restRemaining -= 1
            }
            guard let self, !Task.isCancelled else { return }
            // Play the default timer alarm sound + vibrate
            AudioServicesPlayAlertSound(SystemSoundID(1005))
            self.isResting = false
        }
    }

    func stopRest() {
        timerTask?.cancel()
        timerTask = nil
        restRemaining = 0
        isResting = false
    }

    func logSet(reps: Int, weight: Double?) {
        guard currentExerciseIndex < exercises.count else { return }
        let ex = exercises[currentExerciseIndex]
        let nextIndex = ex.sets.count
        let set = SetLog(setIndex: nextIndex, reps: reps, weight: weight, exercise: ex)
        context.insert(set)
        // Update last used weight on the exercise session
        ex.weight = weight
        save()
        // Start rest automatically
        startRest(seconds: ex.restSeconds)
        // Advance exercise if finished
        if ex.sets.count >= ex.targetSets { moveToNextExerciseIfPossible() }
        objectWillChange.send()
    }

    func moveToNextExerciseIfPossible() {
        if currentExerciseIndex + 1 < exercises.count {
            currentExerciseIndex += 1
        }
    }

    func markCompleted() {
        session.isCompleted = true
        save()
    }

    func save() {
        do { try context.save() } catch { }
    }
}

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var sessions: [WorkoutSession] = []

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
        load()
    }

    func load() {
        let descriptor = FetchDescriptor<WorkoutSession>(sortBy: [SortDescriptor(\WorkoutSession.date, order: .reverse)])
        sessions = (try? context.fetch(descriptor)) ?? []
    }

    func markSkipped(_ session: WorkoutSession) {
        session.isCompleted = false
        do { try context.save() } catch { }
        load()
    }
}
