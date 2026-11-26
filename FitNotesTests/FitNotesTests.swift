//
//  FitNotesTests.swift
//  FitNotesTests
//
//  Created by Reed Rawlings on 10/14/25.
//

import XCTest
import SwiftData
@testable import FitNotes

final class E1RMCalculatorTests: XCTestCase {

    private func makeSet(order: Int, weight: Double?, reps: Int?, isCompleted: Bool = true) -> WorkoutSet {
        WorkoutSet(exerciseId: UUID(), order: order, reps: reps, weight: weight, isCompleted: isCompleted)
    }

    func testFromSessionUsesBestSetNotFirst() {
        // Lighter opener first, heavier top set later — E1RM must come from the top set
        let sets = [
            makeSet(order: 1, weight: 60, reps: 10),   // E1RM 80.0
            makeSet(order: 2, weight: 110, reps: 8),   // E1RM ≈ 139.33
        ]
        let e1rm = E1RMCalculator.fromSession(sets)
        XCTAssertNotNil(e1rm)
        XCTAssertEqual(e1rm!, 110 * (1 + 8.0 / 30.0), accuracy: 0.01)
    }

    func testFromSessionIgnoresIncompleteSets() {
        let sets = [
            makeSet(order: 1, weight: 200, reps: 5, isCompleted: false),
            makeSet(order: 2, weight: 100, reps: 5),
        ]
        let e1rm = E1RMCalculator.fromSession(sets)
        XCTAssertEqual(e1rm!, 100 * (1 + 5.0 / 30.0), accuracy: 0.01)
    }

    func testFromSessionSkipsOutOfRepRangeSets() {
        // A 12-rep set has no valid Epley E1RM; the 5-rep set should still count
        let sets = [
            makeSet(order: 1, weight: 110, reps: 12),
            makeSet(order: 2, weight: 100, reps: 5),
        ]
        let e1rm = E1RMCalculator.fromSession(sets)
        XCTAssertNotNil(e1rm)
        XCTAssertEqual(e1rm!, 100 * (1 + 5.0 / 30.0), accuracy: 0.01)
    }

    func testSingleRepReturnsTheLiftedWeight() {
        // A true 1RM single IS the 1RM — Epley must not inflate it by 3.3%
        XCTAssertEqual(E1RMCalculator.calculate(weight: 225, reps: 1), 225)
    }

    func testFromSessionReturnsNilWhenNoValidSets() {
        XCTAssertNil(E1RMCalculator.fromSession([]))
        XCTAssertNil(E1RMCalculator.fromSession([makeSet(order: 1, weight: 100, reps: 5, isCompleted: false)]))
        XCTAssertNil(E1RMCalculator.fromSession([makeSet(order: 1, weight: 100, reps: 15)]))
    }
}

final class SessionSummaryTests: XCTestCase {

    private let exerciseId = UUID()

    private func makeSet(
        order: Int,
        weight: Double?,
        reps: Int?,
        unit: String = "kg",
        isCompleted: Bool = true
    ) -> WorkoutSet {
        WorkoutSet(
            exerciseId: exerciseId,
            order: order,
            reps: reps,
            weight: weight,
            unit: unit,
            isCompleted: isCompleted
        )
    }

    private func summary(
        _ sets: [WorkoutSet],
        min: Int? = 8,
        max: Int? = 12,
        useWarmupSet: Bool = false,
        progressionSetCount: Int? = nil
    ) -> SessionSummary {
        SessionSummary(
            date: Date(),
            sets: sets,
            targetRepMin: min,
            targetRepMax: max,
            useWarmupSet: useWarmupSet,
            progressionSetCount: progressionSetCount
        )
    }

    // MARK: - Top of range (weight-increase trigger)

    func testPartialTopOfRangeDoesNotTriggerWeightIncrease() {
        // 12/12/8 in an 8-12 range: the last set still has room at this weight
        let session = summary([
            makeSet(order: 1, weight: 100, reps: 12),
            makeSet(order: 2, weight: 100, reps: 12),
            makeSet(order: 3, weight: 100, reps: 8),
        ])

        XCTAssertTrue(session.hitTargetReps, "Every set met the 8-rep minimum")
        XCTAssertFalse(session.hitTopOfRange, "One set is below the top of the range")
        XCTAssertEqual(session.minReps, 8)
    }

    func testAllSetsAtTopOfRangeTriggersWeightIncrease() {
        let session = summary([
            makeSet(order: 1, weight: 100, reps: 12),
            makeSet(order: 2, weight: 100, reps: 12),
            makeSet(order: 3, weight: 100, reps: 12),
        ])

        XCTAssertTrue(session.hitTargetReps)
        XCTAssertTrue(session.hitTopOfRange)
        XCTAssertEqual(session.minReps, 12)
    }

    func testExceedingTopOfRangeStillCountsAsTopOfRange() {
        let session = summary([
            makeSet(order: 1, weight: 100, reps: 14),
            makeSet(order: 2, weight: 100, reps: 12),
        ])

        XCTAssertTrue(session.hitTopOfRange)
    }

    func testBelowMinimumFailsBothTargets() {
        let session = summary([
            makeSet(order: 1, weight: 100, reps: 12),
            makeSet(order: 2, weight: 100, reps: 5),
        ])

        XCTAssertFalse(session.hitTargetReps)
        XCTAssertFalse(session.hitTopOfRange)
    }

    // MARK: - Deterministic mode

    func testModeTieBreaksTowardLowerReps() {
        XCTAssertEqual(SessionSummary.mode(of: [12, 8]), 8)
        XCTAssertEqual(SessionSummary.mode(of: [8, 12]), 8)
        XCTAssertEqual(SessionSummary.mode(of: [10, 12, 8]), 8)
        XCTAssertEqual(SessionSummary.mode(of: [12, 12, 8]), 12, "A clear majority still wins")
        XCTAssertNil(SessionSummary.mode(of: []))
    }

    func testTypicalRepsIsDeterministicOnTie() {
        let session = summary([
            makeSet(order: 1, weight: 100, reps: 12),
            makeSet(order: 2, weight: 100, reps: 8),
        ])

        XCTAssertEqual(session.typicalReps, 8, "Ties resolve to the conservative lower count")
    }

    // MARK: - Warm up exclusion

    func testUncheckedWarmupDoesNotDropAWorkingSet() {
        // The user logged a warm up but never checked it off
        let session = summary([
            makeSet(order: 1, weight: 40, reps: 10, isCompleted: false),
            makeSet(order: 2, weight: 100, reps: 12),
            makeSet(order: 3, weight: 100, reps: 12),
        ], useWarmupSet: true)

        XCTAssertEqual(session.workingSets.count, 2, "Both working sets survive the warm up filter")
        XCTAssertEqual(session.topWeightKg, 100)
        XCTAssertTrue(session.hitTopOfRange)
    }

    func testCheckedWarmupIsStillExcluded() {
        let session = summary([
            makeSet(order: 1, weight: 40, reps: 10),
            makeSet(order: 2, weight: 100, reps: 12),
            makeSet(order: 3, weight: 100, reps: 12),
        ], useWarmupSet: true)

        XCTAssertEqual(session.workingSets.count, 2)
        XCTAssertEqual(session.topWeightKg, 100)
        XCTAssertTrue(session.hitTopOfRange, "The 10-rep warm up must not drag the session below the range")
    }

    func testWarmupIsIdentifiedByOrderNotArrayPosition() {
        // Sets arrive out of order from the fetch
        let session = summary([
            makeSet(order: 3, weight: 100, reps: 12),
            makeSet(order: 1, weight: 40, reps: 10),
            makeSet(order: 2, weight: 100, reps: 12),
        ], useWarmupSet: true)

        XCTAssertEqual(session.workingSets.count, 2)
        XCTAssertEqual(session.topWeightKg, 100)
    }

    // MARK: - Empty working sets

    func testNoCompletedSetsYieldsInsufficientData() {
        let session = summary([
            makeSet(order: 1, weight: 100, reps: 12, isCompleted: false),
            makeSet(order: 2, weight: 100, reps: 12, isCompleted: false),
        ])

        XCTAssertFalse(session.hitTargetReps, "An empty working set list must not vacuously hit targets")
        XCTAssertFalse(session.hitTopOfRange)
        XCTAssertNil(session.topWeightKg, "No working sets means no top weight, not zero")
        XCTAssertNil(session.typicalReps)
        XCTAssertNil(session.minReps)
        XCTAssertEqual(session.totalVolume, 0)
    }

    func testWarmupOnlySessionYieldsInsufficientData() {
        let session = summary([
            makeSet(order: 1, weight: 40, reps: 10),
        ], useWarmupSet: true)

        XCTAssertTrue(session.workingSets.isEmpty)
        XCTAssertFalse(session.hitTargetReps)
        XCTAssertNil(session.topWeightKg)
    }

    func testMissingRepTargetsMeansNoTargetHit() {
        let session = summary([
            makeSet(order: 1, weight: 100, reps: 12),
        ], min: nil, max: nil)

        XCTAssertFalse(session.hitTargetReps)
        XCTAssertFalse(session.hitTopOfRange)
        XCTAssertEqual(session.topWeightKg, 100)
    }

    // MARK: - Unit normalisation

    func testTopWeightIsNormalisedToKilograms() {
        let session = summary([
            makeSet(order: 1, weight: 225, reps: 8, unit: "lbs"),
        ])

        XCTAssertNotNil(session.topWeightKg)
        XCTAssertEqual(session.topWeightKg!, 225 * 0.453592, accuracy: 0.001)
    }

    func testSwitchingUnitsIsNotReadAsARegression() {
        // 100 kg one session, then 225 lbs (~102 kg) the next — that's an increase, not a collapse
        let inKg = summary([makeSet(order: 1, weight: 100, reps: 10)])
        let inLbs = summary([makeSet(order: 1, weight: 225, reps: 10, unit: "lbs")])

        XCTAssertGreaterThan(inLbs.topWeightKg!, inKg.topWeightKg!)
    }

    func testMixedUnitsWithinOneSessionPickTheHeaviestSet() {
        // 135 lbs ≈ 61.2 kg, so the 80 kg set is the top set
        let session = summary([
            makeSet(order: 1, weight: 135, reps: 10, unit: "lbs"),
            makeSet(order: 2, weight: 80, reps: 10),
        ])

        XCTAssertEqual(session.topWeightKg!, 80, accuracy: 0.001)
    }

    // MARK: - Progression set count

    func testProgressionSetCountLimitsToLeadingCompletedSets() {
        let session = summary([
            makeSet(order: 1, weight: 100, reps: 12),
            makeSet(order: 2, weight: 100, reps: 12),
            makeSet(order: 3, weight: 100, reps: 8),
        ], progressionSetCount: 2)

        XCTAssertEqual(session.workingSets.count, 2)
        XCTAssertTrue(session.hitTopOfRange, "Only the first two sets count toward progression")
    }
}

final class WeightTextFormatterTests: XCTestCase {

    func testWholeNumbersHaveNoDecimals() {
        XCTAssertEqual(WeightTextFormatter.format(100), "100")
        XCTAssertEqual(WeightTextFormatter.format(0), "0")
    }

    func testUpToTwoDecimalsTrimmed() {
        XCTAssertEqual(WeightTextFormatter.format(100.5), "100.5")
        XCTAssertEqual(WeightTextFormatter.format(101.25), "101.25")
        XCTAssertEqual(WeightTextFormatter.format(2.75), "2.75")
    }
}

final class FitNotesTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

final class DataExportServiceTests: XCTestCase {
    func testEscapeQuotesFieldsWithCommasQuotesAndNewlines() {
        XCTAssertEqual(DataExportService.escape("Bench"), "Bench")
        XCTAssertEqual(DataExportService.escape("Row, Cable"), "\"Row, Cable\"")
        XCTAssertEqual(DataExportService.escape("felt \"easy\""), "\"felt \"\"easy\"\"\"")
        XCTAssertEqual(DataExportService.escape("line1\nline2"), "\"line1\nline2\"")
    }

    func testCSVHasHeaderAndOneRowPerSet() {
        let exerciseId = UUID()
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 4, hour: 9))!
        let sets = [
            WorkoutSet(exerciseId: exerciseId, order: 1, reps: 5, weight: 100, unit: "kg", notes: "solid, fast", isCompleted: true, completedAt: date, date: date),
            WorkoutSet(exerciseId: UUID(), order: 2, reps: 8, weight: 62.5, unit: "lbs", date: date)
        ]
        let lines = DataExportService.csv(sets: sets, exerciseById: [:])
            .split(separator: "\n", omittingEmptySubsequences: true)

        XCTAssertEqual(lines.count, 3)
        XCTAssertTrue(lines[0].hasPrefix("Date,Time,Exercise"))
        XCTAssertEqual(lines[1], "2026-03-04,09:00,Unknown exercise,,1,100,kg,5,,,,,Yes,\"solid, fast\"")
        XCTAssertEqual(lines[2], "2026-03-04,,Unknown exercise,,2,62.5,lbs,8,,,,,No,")
    }
}

final class SchemaMigrationTests: XCTestCase {

    /// Builds a store with the frozen V1 schema, then reopens it the way the app does
    /// (current schema + migration plan, so V1 → V2 → V3) and checks the data survived with the
    /// new fields defaulted.
    func testV1StoreMigratesToCurrent() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("FitNotes.sqlite")

        let exerciseId = UUID()
        let workoutExerciseId = UUID()
        do {
            let v1Schema = Schema(versionedSchema: FitNotesSchemaV1.self)
            let container = try ModelContainer(for: v1Schema, configurations: [ModelConfiguration(schema: v1Schema, url: url, cloudKitDatabase: .none)])
            let context = ModelContext(container)
            context.insert(FitNotesSchemaV1.Exercise(id: exerciseId, name: "Bench Press", primaryCategory: "Chest"))
            let workout = FitNotesSchemaV1.Workout(name: "Old workout")
            context.insert(workout)
            let workoutExercise = FitNotesSchemaV1.WorkoutExercise(id: workoutExerciseId, exerciseId: exerciseId, order: 1)
            context.insert(workoutExercise)
            workoutExercise.workout = workout
            let routine = FitNotesSchemaV1.Routine(name: "Push")
            context.insert(routine)
            let routineExercise = FitNotesSchemaV1.RoutineExercise(exerciseId: exerciseId, order: 1)
            context.insert(routineExercise)
            routineExercise.routine = routine
            context.insert(WorkoutSet(exerciseId: exerciseId, order: 1, reps: 5, weight: 100, isCompleted: true))
            try context.save()
        }

        let context = try Self.openCurrentStore(at: url)

        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        XCTAssertEqual(exercises.count, 1)
        XCTAssertEqual(exercises.first?.id, exerciseId)
        XCTAssertEqual(exercises.first?.trackingType, .weightAndReps)

        let workoutExercises = try context.fetch(FetchDescriptor<WorkoutExercise>())
        XCTAssertEqual(workoutExercises.map(\.id), [workoutExerciseId])
        XCTAssertNil(workoutExercises.first?.supersetGroupId)
        XCTAssertEqual(workoutExercises.first?.workout?.name, "Old workout")

        let routines = try context.fetch(FetchDescriptor<Routine>())
        XCTAssertEqual(routines.first?.exercises.count, 1)
        XCTAssertNil(routines.first?.exercises.first?.supersetGroupId)

        let sets = try context.fetch(FetchDescriptor<WorkoutSet>())
        XCTAssertEqual(sets.first?.weight, 100)
    }

    /// V2 → V3 drops unique constraints and renames the to-many relationships to the optional
    /// `exerciseItems`. Relationships, ids and V2 fields must all survive.
    func testV2StoreMigratesToV3() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("FitNotes.sqlite")

        let exerciseId = UUID()
        let supersetId = UUID()
        let finishedAt = Date(timeIntervalSince1970: 1_800_000_000)
        do {
            let v2Schema = Schema(versionedSchema: FitNotesSchemaV2.self)
            let container = try ModelContainer(for: v2Schema, configurations: [ModelConfiguration(schema: v2Schema, url: url, cloudKitDatabase: .none)])
            let context = ModelContext(container)
            let exercise = FitNotesSchemaV2.Exercise(id: exerciseId, name: "Jump Rope", primaryCategory: "Cardio")
            exercise.trackingTypeRaw = "repsOnly"
            context.insert(exercise)
            let workout = FitNotesSchemaV2.Workout(name: "Today")
            workout.finishedAt = finishedAt
            context.insert(workout)
            for order in 0..<2 {
                let item = FitNotesSchemaV2.WorkoutExercise(exerciseId: exerciseId, order: order)
                item.supersetGroupId = supersetId
                context.insert(item)
                item.workout = workout
            }
            let routine = FitNotesSchemaV2.Routine(name: "Legs")
            context.insert(routine)
            let routineExercise = FitNotesSchemaV2.RoutineExercise(exerciseId: exerciseId, order: 0)
            context.insert(routineExercise)
            routineExercise.routine = routine
            context.insert(FitNotesSchemaV2.WorkoutSet(exerciseId: exerciseId, order: 1, reps: 100, weight: nil, isCompleted: true))
            context.insert(FitNotesSchemaV2.UserPreferences(defaultWeightUnit: "lbs"))
            context.insert(FitNotesSchemaV2.FitnessGoal(typeRaw: "weekly_workouts", targetValue: 3))
            context.insert(FitNotesSchemaV2.BodyMetric(type: "weight", value: 80))
            try context.save()
        }

        let context = try Self.openCurrentStore(at: url)

        let exercise = try XCTUnwrap(context.fetch(FetchDescriptor<Exercise>()).first)
        XCTAssertEqual(exercise.id, exerciseId)
        XCTAssertEqual(exercise.trackingType, .repsOnly)

        let workout = try XCTUnwrap(context.fetch(FetchDescriptor<Workout>()).first)
        XCTAssertEqual(workout.finishedAt, finishedAt)
        XCTAssertEqual(workout.exercises.count, 2)
        XCTAssertEqual(Set(workout.exercises.map(\.supersetGroupId)), [supersetId])
        XCTAssertEqual(workout.exercises.first?.workout?.id, workout.id)

        let routine = try XCTUnwrap(context.fetch(FetchDescriptor<Routine>()).first)
        XCTAssertEqual(routine.exercises.map(\.exerciseId), [exerciseId])

        XCTAssertEqual(try context.fetch(FetchDescriptor<WorkoutSet>()).first?.reps, 100)
        XCTAssertEqual(try context.fetch(FetchDescriptor<UserPreferences>()).first?.defaultWeightUnit, "lbs")
        XCTAssertEqual(try context.fetch(FetchDescriptor<FitnessGoal>()).first?.targetValue, 3)
        XCTAssertEqual(try context.fetch(FetchDescriptor<BodyMetric>()).first?.value, 80)

        // Deleting a workout still cascades to its exercises through the renamed relationship.
        context.delete(workout)
        try context.save()
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<WorkoutExercise>()), 0)
    }

    private static func openCurrentStore(at url: URL) throws -> ModelContext {
        let schema = Schema(versionedSchema: FitNotesSchemaV3.self)
        let container = try ModelContainer(
            for: schema,
            migrationPlan: FitNotesMigrationPlan.self,
            configurations: [ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)]
        )
        return ModelContext(container)
    }
}

final class SyncDeduplicatorTests: XCTestCase {
    private var context: ModelContext!
    private var aliases: ExerciseAliasStore!

    override func setUpWithError() throws {
        let schema = Schema(versionedSchema: FitNotesSchemaV3.self)
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)])
        context = ModelContext(container)
        let suite = "SyncDeduplicatorTests-\(UUID().uuidString)"
        aliases = ExerciseAliasStore(defaults: UserDefaults(suiteName: suite)!, key: "aliases")
    }

    private let old = Date(timeIntervalSince1970: 1_700_000_000)
    private let new = Date(timeIntervalSince1970: 1_800_000_000)

    func testDuplicateDefaultExercisesMergeIntoTheOldestAndKeepEverySet() throws {
        let original = Exercise(name: "Barbell Bench Press", primaryCategory: "Chest", targetRepMin: 5, createdAt: old)
        let copy = Exercise(name: "Barbell Bench Press", primaryCategory: "Chest", createdAt: new)
        context.insert(original)
        context.insert(copy)
        context.insert(WorkoutSet(exerciseId: original.id, order: 1, reps: 5, weight: 100))
        context.insert(WorkoutSet(exerciseId: copy.id, order: 1, reps: 5, weight: 105))
        let routineExercise = RoutineExercise(exerciseId: copy.id, order: 0)
        context.insert(routineExercise)
        try context.save()

        XCTAssertTrue(SyncDeduplicator.run(modelContext: context, aliases: aliases))

        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        XCTAssertEqual(exercises.map(\.id), [original.id])
        XCTAssertEqual(exercises.first?.targetRepMin, 5)
        XCTAssertEqual(Set(try context.fetch(FetchDescriptor<WorkoutSet>()).map(\.exerciseId)), [original.id])
        XCTAssertEqual(routineExercise.exerciseId, original.id)
    }

    func testCustomExercisesWithTheSameNameAreLeftAlone() throws {
        context.insert(Exercise(name: "My Lift", primaryCategory: "Back", isCustom: true, createdAt: old))
        context.insert(Exercise(name: "My Lift", primaryCategory: "Back", isCustom: true, createdAt: new))
        try context.save()

        XCTAssertFalse(SyncDeduplicator.run(modelContext: context, aliases: aliases))
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Exercise>()), 2)
    }

    func testSetsArrivingLaterForAMergedExerciseAreRemapped() throws {
        let original = Exercise(name: "Barbell Squat", primaryCategory: "Legs", createdAt: old)
        let copy = Exercise(name: "Barbell Squat", primaryCategory: "Legs", createdAt: new)
        context.insert(original)
        context.insert(copy)
        try context.save()
        SyncDeduplicator.run(modelContext: context, aliases: aliases)

        let late = WorkoutSet(exerciseId: copy.id, order: 1, reps: 5, weight: 140)
        context.insert(late)
        try context.save()
        SyncDeduplicator.run(modelContext: context, aliases: aliases)

        XCTAssertEqual(late.exerciseId, original.id)
    }

    func testTwoWorkoutsOnOneDayMergeWithoutDuplicatingExercises() throws {
        let bench = UUID(), squat = UUID(), row = UUID()
        let day = Calendar.current.startOfDay(for: new)
        let first = Workout(name: "Push", date: day.addingTimeInterval(3600), createdAt: old)
        let second = Workout(name: "Workout", date: day.addingTimeInterval(7200), createdAt: new)
        context.insert(first)
        context.insert(second)
        for (workout, ids) in [(first, [bench, squat]), (second, [squat, row])] {
            for (order, id) in ids.enumerated() {
                let item = WorkoutExercise(exerciseId: id, order: order)
                context.insert(item)
                item.workout = workout
            }
        }
        second.finishedAt = new
        try context.save()

        XCTAssertTrue(SyncDeduplicator.run(modelContext: context, aliases: aliases))

        let workouts = try context.fetch(FetchDescriptor<Workout>())
        XCTAssertEqual(workouts.map(\.id), [first.id])
        XCTAssertEqual(first.exercises.sorted { $0.order < $1.order }.map(\.exerciseId), [bench, squat, row])
        XCTAssertEqual(first.finishedAt, new)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<WorkoutExercise>()), 3)
    }

    func testWorkoutsOnDifferentDaysAreKept() throws {
        context.insert(Workout(name: "A", date: old))
        context.insert(Workout(name: "B", date: new))
        try context.save()

        XCTAssertFalse(SyncDeduplicator.run(modelContext: context, aliases: aliases))
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Workout>()), 2)
    }

    func testOnlyTheOldestPreferencesSurvive() throws {
        let original = UserPreferences(defaultWeightUnit: "lbs", createdAt: old)
        context.insert(original)
        context.insert(UserPreferences(defaultWeightUnit: "kg", createdAt: new))
        try context.save()

        SyncDeduplicator.run(modelContext: context, aliases: aliases)

        XCTAssertEqual(try context.fetch(FetchDescriptor<UserPreferences>()).map(\.id), [original.id])
    }
}

final class SupersetLayoutTests: XCTestCase {

    private func makeItems(_ count: Int) -> [WorkoutExercise] {
        (1...count).map { WorkoutExercise(exerciseId: UUID(), order: $0) }
    }

    func testLinkingTwoExercisesMakesOneSuperset() {
        let items = makeItems(3)
        SupersetLayout.toggleLink(at: 0, in: items)

        XCTAssertEqual(SupersetLayout.runs(in: items), [0..<2])
        XCTAssertTrue(SupersetLayout.isLinkedToNext(at: 0, in: items))
        XCTAssertFalse(SupersetLayout.isLinkedToNext(at: 1, in: items))
        let slots = SupersetLayout.slots(for: items)
        XCTAssertEqual(slots[items[0].id]?.label, "A1")
        XCTAssertEqual(slots[items[1].id]?.label, "A2")
        XCTAssertEqual(slots[items[1].id]?.position, .last)
        XCTAssertNil(slots[items[2].id])
    }

    func testLinkingOntoAnExistingSupersetExtendsIt() {
        let items = makeItems(4)
        SupersetLayout.toggleLink(at: 0, in: items)
        SupersetLayout.toggleLink(at: 1, in: items)
        XCTAssertEqual(SupersetLayout.runs(in: items), [0..<3])
        XCTAssertEqual(SupersetLayout.slots(for: items)[items[1].id]?.position, .middle)
    }

    func testLinkingTwoSupersetsMergesThem() {
        let items = makeItems(4)
        SupersetLayout.toggleLink(at: 0, in: items)
        SupersetLayout.toggleLink(at: 2, in: items)
        XCTAssertEqual(SupersetLayout.runs(in: items), [0..<2, 2..<4])
        XCTAssertEqual(SupersetLayout.slots(for: items)[items[2].id]?.label, "B1")

        SupersetLayout.toggleLink(at: 1, in: items)
        XCTAssertEqual(SupersetLayout.runs(in: items), [0..<4])
    }

    func testUnlinkingInTheMiddleSplitsIntoTwoSupersets() {
        let items = makeItems(4)
        SupersetLayout.toggleLink(at: 0, in: items)
        SupersetLayout.toggleLink(at: 1, in: items)
        SupersetLayout.toggleLink(at: 2, in: items)

        SupersetLayout.toggleLink(at: 1, in: items)
        XCTAssertEqual(SupersetLayout.runs(in: items), [0..<2, 2..<4])
        XCTAssertNotEqual(items[0].supersetGroupId, items[2].supersetGroupId)
    }

    func testUnlinkingAPairClearsBoth() {
        let items = makeItems(2)
        SupersetLayout.toggleLink(at: 0, in: items)
        SupersetLayout.toggleLink(at: 0, in: items)
        XCTAssertTrue(SupersetLayout.runs(in: items).isEmpty)
        XCTAssertNil(items[0].supersetGroupId)
        XCTAssertNil(items[1].supersetGroupId)
    }

    func testMembersSeparatedByReorderAreNotASuperset() {
        let items = makeItems(3)
        SupersetLayout.toggleLink(at: 0, in: items)
        // Simulate moving the second member to the end: [A1, plain, A2]
        let reordered = [items[0], items[2], items[1]]
        XCTAssertTrue(SupersetLayout.runs(in: reordered).isEmpty)
        XCTAssertNil(SupersetLayout.run(containing: items[0].id, in: reordered))

        SupersetLayout.normalize(reordered)
        XCTAssertNil(items[0].supersetGroupId)
        XCTAssertNil(items[1].supersetGroupId)
    }

    func testRunContainingReturnsTheWholeSuperset() {
        let items = makeItems(3)
        SupersetLayout.toggleLink(at: 1, in: items)
        XCTAssertEqual(SupersetLayout.run(containing: items[2].id, in: items)?.map(\.id), [items[1].id, items[2].id])
        XCTAssertNil(SupersetLayout.run(containing: items[0].id, in: items))
    }
}

final class PlateCalculatorTests: XCTestCase {

    func testLoadsStandardPoundPlates() {
        let result = PlateCalculator.plates(target: 225, bar: 45, available: PlateCalculator.standardPlates(unit: "lbs"))
        XCTAssertEqual(result.perSide, [45, 45])
        XCTAssertEqual(result.remainder, 0)
        XCTAssertEqual(result.loadedWeight, 225)
    }

    func testMixedPlatesHeaviestFirst() {
        let result = PlateCalculator.plates(target: 185, bar: 45, available: PlateCalculator.standardPlates(unit: "lbs"))
        XCTAssertEqual(result.perSide, [45, 25])
    }

    func testFractionalKilogramPlates() {
        let result = PlateCalculator.plates(target: 102.5, bar: 20, available: PlateCalculator.standardPlates(unit: "kg"))
        XCTAssertEqual(result.perSide, [25, 15, 1.25])
        XCTAssertEqual(result.remainder, 0)
    }

    func testReportsWhatCannotBeLoaded() {
        let result = PlateCalculator.plates(target: 136, bar: 45, available: PlateCalculator.standardPlates(unit: "lbs"))
        XCTAssertEqual(result.perSide, [45])
        XCTAssertEqual(result.loadedWeight, 135)
        XCTAssertEqual(result.remainder, 1, accuracy: 0.001)
    }

    func testTargetAtOrBelowBarLoadsNothing() {
        XCTAssertEqual(PlateCalculator.plates(target: 45, bar: 45, available: [45]).perSide, [])
        XCTAssertEqual(PlateCalculator.plates(target: 30, bar: 45, available: [45]).perSide, [])
    }
}

final class ReviewPromptTests: XCTestCase {

    func testWaitsForEnoughWorkouts() {
        XCTAssertFalse(ReviewPrompt.shouldRequest(workoutCount: 2, lastRequestDate: nil, lastRequestVersion: nil, currentVersion: "1.0"))
        XCTAssertTrue(ReviewPrompt.shouldRequest(workoutCount: 3, lastRequestDate: nil, lastRequestVersion: nil, currentVersion: "1.0"))
    }

    func testAsksOncePerVersion() {
        let longAgo = Date(timeIntervalSinceNow: -365 * 86_400)
        XCTAssertFalse(ReviewPrompt.shouldRequest(workoutCount: 10, lastRequestDate: longAgo, lastRequestVersion: "1.0", currentVersion: "1.0"))
        XCTAssertTrue(ReviewPrompt.shouldRequest(workoutCount: 10, lastRequestDate: longAgo, lastRequestVersion: "1.0", currentVersion: "1.1"))
    }

    func testSpacesRequestsApart() {
        let recent = Date(timeIntervalSinceNow: -30 * 86_400)
        XCTAssertFalse(ReviewPrompt.shouldRequest(workoutCount: 10, lastRequestDate: recent, lastRequestVersion: "1.0", currentVersion: "1.1"))
    }
}

final class RepsOnlyTests: XCTestCase {

    func testRepsOnlyExerciseNeverRecommendsWeight() throws {
        let schema = Schema(versionedSchema: FitNotesSchemaV3.self)
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)])
        let context = ModelContext(container)
        let exercise = Exercise(name: "Jump Squats", primaryCategory: "Cardio", targetRepMin: 10, targetRepMax: 15, trackingType: .repsOnly)
        context.insert(exercise)
        let calendar = Calendar.current
        for daysAgo in [2, 1] {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
            for order in 1...3 {
                context.insert(WorkoutSet(exerciseId: exercise.id, order: order, reps: 15, weight: nil, isCompleted: true, date: date))
            }
        }
        try context.save()

        let status = ProgressionService.analyzeProgressionStatus(exercise: exercise, modelContext: context)
        guard case .readyToIncreaseReps(let reps) = status else {
            return XCTFail("Expected a rep increase, got \(status)")
        }
        XCTAssertEqual(reps, 16)
    }
}
