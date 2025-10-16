import Foundation

final class AppEnvironment: ObservableObject {
    let exercises: ExerciseRepository
    let workouts: WorkoutRepository
    let workoutSets: WorkoutSetRepository

    let healthKit: HealthKitService
    let watchSync: WatchSyncService
    let csv: CSVImportExportService
    let settings: SettingsManager

    init(
        exercises: ExerciseRepository = InMemoryExerciseRepository(),
        workouts: WorkoutRepository = InMemoryWorkoutRepository(),
        workoutSets: WorkoutSetRepository = InMemoryWorkoutSetRepository(),
        healthKit: HealthKitService = HealthKitService(),
        watchSync: WatchSyncService = WatchSyncService(),
        csv: CSVImportExportService = CSVImportExportService(),
        settings: SettingsManager = SettingsManager()
    ) {
        self.exercises = exercises
        self.workouts = workouts
        self.workoutSets = workoutSets
        self.healthKit = healthKit
        self.watchSync = watchSync
        self.csv = csv
        self.settings = settings
    }
}
