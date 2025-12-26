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
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Exercise.self,
            Workout.self,
            BodyMetric.self,
            WorkoutExercise.self,
            WorkoutSet.self,
            RoutineExercise.self,
            Routine.self,
            UserPreferences.self,
            FitnessGoal.self
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

            // Create a context for initialization tasks
            let initContext = ModelContext(container)

            #if DEBUG
            // Seed development demo data the first time if the store is empty.
            DevDataSeeder.seedIfNeeded(modelContext: initContext)
            #endif

            // Sync default exercises library (adds new exercises, updates equipment types)
            // Safe to run on every launch - only adds missing exercises
            ExerciseDatabaseService.shared.syncDefaultExercises(modelContext: initContext)

            return container
        } catch {
            // If there's a schema issue, try to delete the old database and recreate
            print("ModelContainer creation failed: \(error)")
            print("Attempting to recreate database...")
            
            // Delete the existing database file
            try? FileManager.default.removeItem(at: databaseURL)
            
            do {
                let container = try ModelContainer(for: schema, configurations: [modelConfiguration])

                let initContext = ModelContext(container)

                #if DEBUG
                DevDataSeeder.seedIfNeeded(modelContext: initContext)
                #endif

                // Sync default exercises library
                ExerciseDatabaseService.shared.syncDefaultExercises(modelContext: initContext)

                print("Successfully recreated ModelContainer")
                return container
            } catch {
                fatalError("Could not create ModelContainer even after recreation: \(error)")
            }
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
            } else {
                OnboardingContainerView()
                    .onReceive(NotificationCenter.default.publisher(for: .onboardingCompleted)) { _ in
                        withAnimation(.standardSpring) {
                            hasCompletedOnboarding = true
                        }
                    }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - Notification for onboarding completion
extension Notification.Name {
    static let onboardingCompleted = Notification.Name("onboardingCompleted")
}
