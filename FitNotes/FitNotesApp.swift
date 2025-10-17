//
//  FitNotesApp.swift
//  FitNotes
//
//  Created by Reed Rawlings on 10/14/25.
//

import SwiftUI
import SwiftData

@main
struct FitNotesApp: App {
    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Exercise.self,
            Workout.self,
            WorkoutSet.self,
            Program.self,
            BodyMetric.self,
            DailyRoutine.self,
            RoutineExercise.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Initialize default exercises if none exist
            let context = container.mainContext
            let exerciseDescriptor = FetchDescriptor<Exercise>()
            let existingExercises = try context.fetch(exerciseDescriptor)
            
            if existingExercises.isEmpty {
                ExerciseDatabaseService.shared.createDefaultExercises(modelContext: context)
            }
            
            return container
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
