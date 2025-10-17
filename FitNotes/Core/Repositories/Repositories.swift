import Foundation

public protocol ExerciseRepository {
    func all() -> [Exercise]
    func upsert(_ exercise: Exercise)
    func delete(_ exercise: Exercise)
    func deleteAll()
}

public protocol WorkoutRepository {
    func all() -> [Workout]
    func upsert(_ workout: Workout)
}

public protocol WorkoutSetRepository {
    func sets(for workoutId: UUID) -> [WorkoutSet]
    func upsert(_ set: WorkoutSet)
}

public final class InMemoryExerciseRepository: ExerciseRepository {
    private var store: [UUID: Exercise] = [:]

    public init() {}

    public func all() -> [Exercise] { Array(store.values) }

    public func upsert(_ exercise: Exercise) {
        var updated = exercise
        updated.updatedAt = Date()
        store[updated.id] = updated
    }
    
    public func delete(_ exercise: Exercise) {
        store.removeValue(forKey: exercise.id)
    }
    
    public func deleteAll() {
        store.removeAll()
    }
}

public final class InMemoryWorkoutRepository: WorkoutRepository {
    private var store: [UUID: Workout] = [:]

    public init() {}

    public func all() -> [Workout] { Array(store.values) }

    public func upsert(_ workout: Workout) {
        var updated = workout
        updated.updatedAt = Date()
        store[updated.id] = updated
    }
}

public final class InMemoryWorkoutSetRepository: WorkoutSetRepository {
    private var store: [UUID: [WorkoutSet]] = [:]

    public init() {}

    public func sets(for workoutId: UUID) -> [WorkoutSet] {
        store[workoutId] ?? []
    }

    public func upsert(_ set: WorkoutSet) {
        var updated = set
        updated.updatedAt = Date()
        var list = store[updated.workoutId] ?? []
        if let index = list.firstIndex(where: { $0.id == updated.id }) {
            list[index] = updated
        } else {
            list.append(updated)
        }
        store[updated.workoutId] = list.sorted { $0.order < $1.order }
    }
}
