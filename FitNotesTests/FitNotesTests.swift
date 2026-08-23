//
//  FitNotesTests.swift
//  FitNotesTests
//
//  Created by Reed Rawlings on 10/14/25.
//

import XCTest
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
