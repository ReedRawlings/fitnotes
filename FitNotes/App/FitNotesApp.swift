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
        let schema = Schema(versionedSchema: FitNotesSchemaV2.self)

        // Use a specific URL for the database to make it easier to manage
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let databaseURL = documentsPath.appendingPathComponent("FitNotes.sqlite")

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: databaseURL,
            cloudKitDatabase: .none
        )

        func makeContainer() throws -> ModelContainer {
            let container = try ModelContainer(
                for: schema,
                migrationPlan: FitNotesMigrationPlan.self,
                configurations: [modelConfiguration]
            )
            let initContext = ModelContext(container)

            #if DEBUG
            // Seed development demo data the first time if the store is empty.
            DevDataSeeder.seedIfNeeded(modelContext: initContext)
            #endif

            // Sync default exercises library (adds new exercises, updates equipment types)
            // Safe to run on every launch - only adds missing exercises
            ExerciseDatabaseService.shared.syncDefaultExercises(modelContext: initContext)
            return container
        }

        do {
            return try makeContainer()
        } catch {
            // NEVER delete user data. The store could not be opened (e.g. a schema change shipped
            // without a migration stage), so move it aside intact where it can be recovered by a
            // fixed build, then start with an empty store so the app still launches.
            print("ModelContainer creation failed: \(error)")
            let preservedAt = DatabaseRecovery.moveStoreAside(databaseURL)
            print("Preserved unreadable store at: \(preservedAt?.path ?? "<move failed>")")

            do {
                return try makeContainer()
            } catch {
                fatalError("Could not create ModelContainer even after moving the old store aside: \(error)")
            }
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            Group {
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
            // The design is dark-only; without this, sheets and nav titles render dark-on-dark
            // when the phone is in light mode
            .preferredColorScheme(.dark)
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - Notification for onboarding completion
extension Notification.Name {
    static let onboardingCompleted = Notification.Name("onboardingCompleted")
}

// MARK: - Schema versioning
//
// Every future change to a @Model (added/removed/renamed property, new model) must:
//   1. freeze the current shape of each changed model (and any model whose relationships
//      point at one) as nested types in a new FitNotesSchemaVN file, like SchemaV1.swift,
//   2. add the new version below, append it to `schemas`, and
//   3. add a .lightweight or .custom stage to `stages`.
// Shipping a model change without this means existing users' stores fail to open.

/// The current schema: the live model classes.
/// V2 added Exercise.trackingTypeRaw (reps-only exercises) and
/// RoutineExercise/WorkoutExercise.supersetGroupId (supersets).
enum FitNotesSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            Exercise.self,
            Workout.self,
            BodyMetric.self,
            WorkoutExercise.self,
            WorkoutSet.self,
            RoutineExercise.self,
            Routine.self,
            UserPreferences.self,
            FitnessGoal.self
        ]
    }
}

enum FitNotesMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [FitNotesSchemaV1.self, FitNotesSchemaV2.self] }

    static var stages: [MigrationStage] { [migrateV1toV2] }

    /// Only adds properties with defaults, so a lightweight migration is enough.
    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: FitNotesSchemaV1.self,
        toVersion: FitNotesSchemaV2.self
    )
}

enum DatabaseRecovery {
    /// Moves the SQLite store and its -wal/-shm sidecars into Documents/RecoveredStores/<timestamp>/.
    /// Returns the folder, or nil if nothing could be moved.
    static func moveStoreAside(_ storeURL: URL) -> URL? {
        let fm = FileManager.default
        let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let folder = storeURL.deletingLastPathComponent()
            .appendingPathComponent("RecoveredStores", isDirectory: true)
            .appendingPathComponent(stamp, isDirectory: true)
        do {
            try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        } catch {
            return nil
        }
        var movedAny = false
        for suffix in ["", "-wal", "-shm"] {
            let source = URL(fileURLWithPath: storeURL.path + suffix)
            guard fm.fileExists(atPath: source.path) else { continue }
            if (try? fm.moveItem(at: source, to: folder.appendingPathComponent(source.lastPathComponent))) != nil {
                movedAny = true
            }
        }
        return movedAny ? folder : nil
    }
}
