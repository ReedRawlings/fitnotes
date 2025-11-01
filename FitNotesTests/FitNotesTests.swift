//
//  FitNotesTests.swift
//  FitNotesTests
//
//  Created by Reed Rawlings on 10/14/25.
//

import XCTest
@testable import FitNotes

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

    func testExerciseDefaultRestTimerSettings() throws {
        let exercise = Exercise(
            name: "Bench Press",
            primaryCategory: "Chest"
        )
        XCTAssertEqual(exercise.restTimerDuration, 60)
        XCTAssertTrue(exercise.autoStartRestTimer)
    }

    func testExerciseCustomRestTimerSettings() throws {
        let exercise = Exercise(
            name: "Squat",
            primaryCategory: "Legs",
            restTimerDuration: 90,
            autoStartRestTimer: false
        )
        XCTAssertEqual(exercise.restTimerDuration, 90)
        XCTAssertFalse(exercise.autoStartRestTimer)
    }

}
