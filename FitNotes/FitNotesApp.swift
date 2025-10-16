//
//  FitNotesApp.swift
//  FitNotes
//
//  Created by Reed Rawlings on 10/14/25.
//

import SwiftUI
import SwiftData

// Import model classes
// Note: In a real project, you might want to create a single Models.swift file
// or use a different import strategy, but for now we'll reference them directly

@main
struct FitNotesApp: App {
    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Exercise.self,
            Workout.self,
            WorkoutSet.self,
            Program.self,
            BodyMetric.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
