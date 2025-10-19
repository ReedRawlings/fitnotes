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
            BodyMetric.self,
            WorkoutExercise.self,
            WorkoutSet.self,
            RoutineExercise.self,
            Routine.self
        ])
        
        // Use a specific URL for the database to make it easier to manage
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let databaseURL = documentsPath.appendingPathComponent("FitNotes.sqlite")
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: databaseURL,
            cloudKitDatabase: .none
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            return container
        } catch {
            // If there's a schema issue, try to delete the old database and recreate
            print("ModelContainer creation failed: \(error)")
            print("Attempting to recreate database...")
            
            // Delete the existing database file
            try? FileManager.default.removeItem(at: databaseURL)
            
            do {
                let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                print("Successfully recreated ModelContainer")
                return container
            } catch {
                fatalError("Could not create ModelContainer even after recreation: \(error)")
            }
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
