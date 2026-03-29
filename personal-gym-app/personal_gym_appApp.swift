//
//  personal_gym_appApp.swift
//  personal-gym-app
//
//  Created by Maciej Wadowski on 23/03/2026.
//

import SwiftUI
import SwiftData

@main
struct personal_gym_appApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [WorkoutPlan.self, ExerciseTemplate.self, WorkoutSession.self, ExerciseSession.self, SetLog.self])
    }
}
