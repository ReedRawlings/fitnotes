import Foundation
import SwiftData

/// iCloud sync settings. The store's CloudKit mode is chosen when the ModelContainer is built,
/// so a change to `isEnabled` takes effect on the next launch.
enum CloudSync {
    static let containerIdentifier = "iCloud.Future-Selves.FitNotes"
    static let enabledKey = "iCloudSyncEnabled"

    static var isEnabled: Bool {
        // Unit tests run inside the app; keep the host app's store local so tests never touch iCloud.
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil { return false }
        return UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true
    }
}

/// Merges records that sync duplicated.
///
/// CloudKit can't enforce uniqueness, so before two devices have synced each can create its own
/// copy of the default exercise library, today's workout and the preferences record. When the
/// copies meet, this keeps one and folds the others into it without losing any sets.
///
/// The survivor is chosen deterministically (oldest `createdAt`, then lowest id), so two devices
/// deduplicating at the same moment keep the same record and their deletions agree.
enum SyncDeduplicator {

    /// Returns true if anything was merged (and saved).
    @discardableResult
    static func run(modelContext: ModelContext, aliases: ExerciseAliasStore = .standard) -> Bool {
        var changed = false
        changed = mergeDuplicateExercises(modelContext, aliases: aliases) || changed
        changed = remapAliasedReferences(modelContext, aliases: aliases) || changed
        changed = mergeDuplicateWorkouts(modelContext) || changed
        changed = mergeDuplicatePreferences(modelContext) || changed
        if changed {
            try? modelContext.save()
        }
        return changed
    }

    static func survivorFirst(_ a: (createdAt: Date, id: UUID), _ b: (createdAt: Date, id: UUID)) -> Bool {
        if a.createdAt != b.createdAt { return a.createdAt < b.createdAt }
        return a.id.uuidString < b.id.uuidString
    }

    // MARK: - Exercises

    /// Built-in exercises with the same name are the same exercise. Custom exercises are left alone:
    /// sync never copies them, and two the user made with one name may be meant to differ.
    private static func mergeDuplicateExercises(_ context: ModelContext, aliases: ExerciseAliasStore) -> Bool {
        let descriptor = FetchDescriptor<Exercise>(predicate: #Predicate { !$0.isCustom })
        guard let exercises = try? context.fetch(descriptor) else { return false }

        var changed = false
        for (_, group) in Dictionary(grouping: exercises, by: \.name) where group.count > 1 {
            let sorted = group.sorted { survivorFirst(($0.createdAt, $0.id), ($1.createdAt, $1.id)) }
            let keeper = sorted[0]
            for duplicate in sorted.dropFirst() where duplicate.id != keeper.id {
                aliases.record(duplicate.id, as: keeper.id)
                remapReferences(from: duplicate.id, to: keeper.id, in: context)
                context.delete(duplicate)
                changed = true
            }
        }
        return changed
    }

    /// Sets can arrive from another device after the exercise they point at was merged away here.
    private static func remapAliasedReferences(_ context: ModelContext, aliases: ExerciseAliasStore) -> Bool {
        var changed = false
        for (oldId, newId) in aliases.all() {
            changed = remapReferences(from: oldId, to: newId, in: context) || changed
        }
        return changed
    }

    @discardableResult
    private static func remapReferences(from oldId: UUID, to newId: UUID, in context: ModelContext) -> Bool {
        var changed = false
        let sets = (try? context.fetch(FetchDescriptor<WorkoutSet>(predicate: #Predicate { $0.exerciseId == oldId }))) ?? []
        for set in sets { set.exerciseId = newId; changed = true }
        let workoutExercises = (try? context.fetch(FetchDescriptor<WorkoutExercise>(predicate: #Predicate { $0.exerciseId == oldId }))) ?? []
        for item in workoutExercises { item.exerciseId = newId; changed = true }
        let routineExercises = (try? context.fetch(FetchDescriptor<RoutineExercise>(predicate: #Predicate { $0.exerciseId == oldId }))) ?? []
        for item in routineExercises { item.exerciseId = newId; changed = true }
        let optionalOldId: UUID? = oldId
        let goals = (try? context.fetch(FetchDescriptor<FitnessGoal>(predicate: #Predicate { $0.exerciseId == optionalOldId }))) ?? []
        for goal in goals { goal.exerciseId = newId; changed = true }
        return changed
    }

    // MARK: - Workouts

    /// The app keeps one workout per calendar day. Sets belong to an exercise and a date, not to a
    /// workout, so merging only has to move the exercise rows; no set is touched.
    private static func mergeDuplicateWorkouts(_ context: ModelContext) -> Bool {
        guard let workouts = try? context.fetch(FetchDescriptor<Workout>()) else { return false }
        let calendar = Calendar.current

        var changed = false
        for (_, group) in Dictionary(grouping: workouts, by: { calendar.startOfDay(for: $0.date) }) where group.count > 1 {
            let sorted = group.sorted { survivorFirst(($0.createdAt, $0.id), ($1.createdAt, $1.id)) }
            let keeper = sorted[0]
            for duplicate in sorted.dropFirst() where duplicate.id != keeper.id {
                merge(duplicate, into: keeper, context: context)
                context.delete(duplicate)
                changed = true
            }
        }
        return changed
    }

    private static func merge(_ duplicate: Workout, into keeper: Workout, context: ModelContext) {
        if keeper.exercises.isEmpty && !duplicate.exercises.isEmpty {
            keeper.name = duplicate.name
            keeper.routineTemplateId = keeper.routineTemplateId ?? duplicate.routineTemplateId
        }
        if keeper.notes?.isEmpty ?? true { keeper.notes = duplicate.notes }
        keeper.finishedAt = [keeper.finishedAt, duplicate.finishedAt].compactMap { $0 }.max()

        var present = Set(keeper.exercises.map(\.exerciseId))
        var nextOrder = (keeper.exercises.map(\.order).max() ?? -1) + 1
        for item in duplicate.exercises.sorted(by: { $0.order < $1.order }) {
            if present.contains(item.exerciseId) {
                context.delete(item)
            } else {
                item.order = nextOrder
                nextOrder += 1
                item.workout = keeper
                present.insert(item.exerciseId)
            }
        }
        duplicate.exerciseItems = []
        keeper.updatedAt = Date()
    }

    // MARK: - Preferences

    private static func mergeDuplicatePreferences(_ context: ModelContext) -> Bool {
        guard let preferences = try? context.fetch(FetchDescriptor<UserPreferences>()), preferences.count > 1 else {
            return false
        }
        let sorted = preferences.sorted { survivorFirst(($0.createdAt, $0.id), ($1.createdAt, $1.id)) }
        for duplicate in sorted.dropFirst() {
            context.delete(duplicate)
        }
        return true
    }
}

/// Remembers which exercise ids were merged into which, per device.
struct ExerciseAliasStore {
    let defaults: UserDefaults
    let key: String

    static let standard = ExerciseAliasStore(defaults: .standard, key: "mergedExerciseAliases")

    func record(_ oldId: UUID, as newId: UUID) {
        var map = defaults.dictionary(forKey: key) as? [String: String] ?? [:]
        map[oldId.uuidString] = newId.uuidString
        defaults.set(map, forKey: key)
    }

    func all() -> [(UUID, UUID)] {
        let map = defaults.dictionary(forKey: key) as? [String: String] ?? [:]
        return map.compactMap { key, value in
            guard let old = UUID(uuidString: key), let new = UUID(uuidString: value) else { return nil }
            return (old, new)
        }
    }
}
