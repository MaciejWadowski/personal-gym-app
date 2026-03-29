//
//  Persistence.swift
//  personal-gym-app
//
//  Created by Maciej Wadowski on 23/03/2026.
//


//
//  Persistence.swift
//  personal-gym-app
//
//  Created by Assistant on 23/03/2026.
//

import Foundation
import SwiftData

@MainActor
struct Persistence {
    static var shared = Persistence()
    let modelContext: ModelContext

    init(container: ModelContainer? = nil) {
        if let container = container {
            self.modelContext = ModelContext(container)
        } else {
            let schema = Schema([
                WorkoutPlan.self,
                ExerciseTemplate.self,
                WorkoutSession.self,
                ExerciseSession.self,
                SetLog.self
            ])
            let config = ModelConfiguration(schema: schema)
            let container = try! ModelContainer(for: schema, configurations: config)
            self.modelContext = ModelContext(container)
        }
    }

    func save() {
        do { try modelContext.save() } catch {
            assertionFailure("SwiftData save error: \(error)")
        }
    }
}
