//
//  ContentView.swift
//  personal-gym-app
//
//  Created by Maciej Wadowski on 23/03/2026.
//

import SwiftUI
import SwiftData

enum AppTab: Hashable {
    case plans, history, export
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .plans

    var body: some View {
        TabView(selection: $selectedTab) {
            PlansListView()
                .tabItem { Label("Plans", systemImage: "list.bullet.rectangle") }
                .tag(AppTab.plans)

            HistoryListView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                .tag(AppTab.history)

            ExportView()
                .tabItem { Label("Export", systemImage: "square.and.arrow.up") }
                .tag(AppTab.export)
        }
        .environment(\.selectedTab, $selectedTab)
    }
}

private struct SelectedTabKey: EnvironmentKey {
    static let defaultValue: Binding<AppTab> = .constant(.plans)
}

extension EnvironmentValues {
    var selectedTab: Binding<AppTab> {
        get { self[SelectedTabKey.self] }
        set { self[SelectedTabKey.self] = newValue }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [WorkoutPlan.self, ExerciseTemplate.self, WorkoutSession.self, ExerciseSession.self, SetLog.self], inMemory: true)
}
