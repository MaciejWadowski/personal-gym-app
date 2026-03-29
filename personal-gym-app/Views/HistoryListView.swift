//
//  HistoryListView.swift
//  personal-gym-app
//
//  Created by Maciej Wadowski on 23/03/2026.
//


//
//  HistoryExportViews.swift
//  personal-gym-app
//
//  Created by Assistant on 23/03/2026.
//

import SwiftUI
import SwiftData

struct HistoryListView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    var body: some View {
        NavigationStack {
            List(sessions) { session in
                NavigationLink(value: session) {
                    VStack(alignment: .leading) {
                        Text(session.planName).font(.headline)
                        HStack(spacing: 12) {
                            Text(session.date, style: .date)
                            if session.isCompleted { Label("Completed", systemImage: "checkmark.circle.fill").foregroundStyle(.green) } else { Label("Skipped", systemImage: "xmark.circle").foregroundStyle(.red) }
                        }.font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("History")
            .navigationDestination(for: WorkoutSession.self) { sess in
                SessionDetailView(session: sess)
            }
        }
    }
}

struct SessionDetailView: View {
    let session: WorkoutSession

    var body: some View {
        List {
            Section(header: Text("Summary")) {
                HStack {
                    Text("Plan")
                    Spacer()
                    Text(session.planName)
                }
                HStack {
                    Text("Date")
                    Spacer()
                    Text(session.date, style: .date)
                }
                HStack {
                    Text("Status")
                    Spacer()
                    Text(session.isCompleted ? "Completed" : "Skipped").foregroundStyle(session.isCompleted ? .green : .red)
                }
            }
            ForEach(session.exercises) { ex in
                Section {
                    let sortedSets = ex.sets.sorted(by: { $0.setIndex < $1.setIndex })
                    if sortedSets.isEmpty {
                        Text("No sets logged").foregroundStyle(.secondary)
                    } else {
                        ForEach(sortedSets) { set in
                            HStack {
                                Text("Set \(set.setIndex + 1)")
                                Spacer()
                                Text("\(set.reps) reps")
                                if let w = set.weight { Text("@ \(formatKg(w))").foregroundStyle(.secondary) }
                            }
                        }
                    }
                    if let w = ex.weight {
                        HStack {
                            Text("Weight used")
                            Spacer()
                            Text(formatKg(w)).foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text(ex.exerciseName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .textCase(nil)
                }
            }
        }
        .navigationTitle("Session")
    }
}

struct ExportView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutPlan.createdAt, order: .reverse) private var plans: [WorkoutPlan]
    @State private var exportURL: URL?
    @State private var showingShare = false
    @State private var alert: AlertItem?

    var body: some View {
        NavigationStack {
            List {
                ForEach(plans) { plan in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(plan.name).font(.headline)
                            Text("Tap to export CSV").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Export") { export(plan) }
                    }
                }
            }
            .navigationTitle("Export")
            .sheet(isPresented: $showingShare) {
                if let url = exportURL { ShareSheet(activityItems: [url]) }
            }
            .alert(item: $alert) { item in
                Alert(title: Text(item.title), message: Text(item.message), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func export(_ plan: WorkoutPlan) {
        do {
            let url = try ExportService.exportCSV(for: plan, from: context)
            exportURL = url
            showingShare = true
        } catch {
            alert = .init(title: "No Data", message: "No sessions found for this plan.")
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct AlertItem: Identifiable { let id = UUID(); let title: String; let message: String }
