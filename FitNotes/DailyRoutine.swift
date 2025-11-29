import Foundation
import SwiftData

// MARK: - Weight Unit Conversion

/// Utility for converting between weight units
public enum WeightUnitConverter {
    private static let lbsToKgRatio = 0.453592
    private static let kgToLbsRatio = 2.20462

    /// Converts a weight value to kilograms
    /// - Parameters:
    ///   - weight: The weight value to convert
    ///   - unit: The unit of the weight ("kg" or "lbs")
    /// - Returns: Weight in kilograms
    public static func toKg(_ weight: Double, from unit: String) -> Double {
        guard unit.lowercased() == "lbs" else { return weight }
        return weight * lbsToKgRatio
    }

    /// Converts a weight value from kilograms to a target unit
    /// - Parameters:
    ///   - weight: The weight value in kilograms
    ///   - unit: The target unit ("kg" or "lbs")
    /// - Returns: Weight in the target unit
    public static func fromKg(_ weight: Double, to unit: String) -> Double {
        guard unit.lowercased() == "lbs" else { return weight }
        return weight * kgToLbsRatio
    }

    /// Calculates volume in kg (converts weight to kg first)
    /// - Parameters:
    ///   - weight: The weight value
    ///   - reps: Number of repetitions
    ///   - unit: Unit of the weight ("kg" or "lbs")
    /// - Returns: Volume in kg units
    public static func volumeInKg(_ weight: Double, reps: Int, unit: String) -> Double {
        let weightInKg = toKg(weight, from: unit)
        return weightInKg * Double(reps)
    }
}

// MARK: - Routine Schedule Type
public enum RoutineScheduleType: String, Codable {
    case none = "none"           // No schedule set
    case weekly = "weekly"       // Repeats on specific days of the week
    case interval = "interval"   // Repeats every X days from a start date
}

// MARK: - Routine Model (Reusable Templates)
@Model
public final class Routine {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var routineDescription: String?
    public var createdAt: Date
    public var updatedAt: Date
    @Relationship(deleteRule: .cascade) public var exercises: [RoutineExercise] = []

    // MARK: - Scheduling Fields

    /// The type of schedule (none, weekly, or interval)
    public var scheduleTypeRaw: String = RoutineScheduleType.none.rawValue

    /// For weekly schedules: days of the week (0 = Sunday, 1 = Monday, etc.)
    /// Stored as comma-separated string like "1,3,5" for Mon, Wed, Fri
    public var scheduleDaysRaw: String?

    /// For interval schedules: repeat every X days
    public var scheduleIntervalDays: Int?

    /// For interval schedules: the start date for the interval calculation
    public var scheduleStartDate: Date?

    // MARK: - Computed Properties for Schedule

    public var scheduleType: RoutineScheduleType {
        get { RoutineScheduleType(rawValue: scheduleTypeRaw) ?? .none }
        set { scheduleTypeRaw = newValue.rawValue }
    }

    /// Days of the week for weekly schedule (0 = Sunday, 6 = Saturday)
    public var scheduleDays: Set<Int> {
        get {
            guard let raw = scheduleDaysRaw, !raw.isEmpty else { return [] }
            let days = raw.split(separator: ",").compactMap { Int($0) }
            return Set(days)
        }
        set {
            if newValue.isEmpty {
                scheduleDaysRaw = nil
            } else {
                scheduleDaysRaw = newValue.sorted().map { String($0) }.joined(separator: ",")
            }
        }
    }

    /// Returns whether the routine is scheduled for a given date
    public func isScheduledFor(date: Date) -> Bool {
        let calendar = Calendar.current

        switch scheduleType {
        case .none:
            return false

        case .weekly:
            let weekday = calendar.component(.weekday, from: date) - 1 // Convert to 0-based (0 = Sunday)
            return scheduleDays.contains(weekday)

        case .interval:
            guard let startDate = scheduleStartDate,
                  let intervalDays = scheduleIntervalDays,
                  intervalDays > 0 else {
                return false
            }

            let startOfStartDate = calendar.startOfDay(for: startDate)
            let startOfCheckDate = calendar.startOfDay(for: date)

            // Don't schedule before start date
            if startOfCheckDate < startOfStartDate {
                return false
            }

            let daysSinceStart = calendar.dateComponents([.day], from: startOfStartDate, to: startOfCheckDate).day ?? 0
            return daysSinceStart % intervalDays == 0
        }
    }

    /// Returns the next scheduled date from a given date (inclusive)
    public func nextScheduledDate(from date: Date) -> Date? {
        let calendar = Calendar.current
        let startOfDate = calendar.startOfDay(for: date)

        switch scheduleType {
        case .none:
            return nil

        case .weekly:
            guard !scheduleDays.isEmpty else { return nil }

            // Check the next 7 days (will definitely find a match if any days are selected)
            for dayOffset in 0..<7 {
                if let checkDate = calendar.date(byAdding: .day, value: dayOffset, to: startOfDate) {
                    let weekday = calendar.component(.weekday, from: checkDate) - 1
                    if scheduleDays.contains(weekday) {
                        return checkDate
                    }
                }
            }
            return nil

        case .interval:
            guard let startDate = scheduleStartDate,
                  let intervalDays = scheduleIntervalDays,
                  intervalDays > 0 else {
                return nil
            }

            let startOfStartDate = calendar.startOfDay(for: startDate)

            // If we're before the start date, the next scheduled date is the start date
            if startOfDate < startOfStartDate {
                return startOfStartDate
            }

            let daysSinceStart = calendar.dateComponents([.day], from: startOfStartDate, to: startOfDate).day ?? 0
            let daysUntilNext = intervalDays - (daysSinceStart % intervalDays)

            if daysUntilNext == intervalDays {
                // We're on a scheduled day
                return startOfDate
            }

            return calendar.date(byAdding: .day, value: daysUntilNext, to: startOfDate)
        }
    }

    /// Shifts the schedule forward or backward by one occurrence
    public func shiftSchedule(forward: Bool) {
        let calendar = Calendar.current

        switch scheduleType {
        case .none:
            break

        case .weekly:
            // For weekly, shifting doesn't change the pattern - it stays the same days
            // But we could shift which days are selected
            break

        case .interval:
            guard let startDate = scheduleStartDate,
                  let intervalDays = scheduleIntervalDays else {
                return
            }

            // Shift the start date by the interval amount
            let shiftAmount = forward ? intervalDays : -intervalDays
            if let newStartDate = calendar.date(byAdding: .day, value: shiftAmount, to: startDate) {
                scheduleStartDate = newStartDate
            }
        }
    }

    public init(
        id: UUID = UUID(),
        name: String,
        routineDescription: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.routineDescription = routineDescription
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Workout Model (Individual Day's Exercises)
@Model
public final class Workout {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var date: Date
    public var notes: String?
    public var routineTemplateId: UUID? // Reference to the template routine
    public var createdAt: Date
    public var updatedAt: Date
    @Relationship(deleteRule: .cascade) public var exercises: [WorkoutExercise] = []

    public init(
        id: UUID = UUID(),
        name: String,
        date: Date = Date(),
        notes: String? = nil,
        routineTemplateId: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.date = date
        self.notes = notes
        self.routineTemplateId = routineTemplateId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - RoutineExercise (for Routine templates)
@Model
public final class RoutineExercise {
    @Attribute(.unique) public var id: UUID
    public var exerciseId: UUID
    public var order: Int
    public var sets: Int
    public var reps: Int?
    public var weight: Double?
    public var duration: Int? // For time-based exercises
    public var distance: Double? // For distance-based exercises
    public var notes: String?
    public var createdAt: Date
    public var updatedAt: Date
    public var routine: Routine?

    public init(
        id: UUID = UUID(),
        exerciseId: UUID,
        order: Int,
        sets: Int = 1,
        reps: Int? = nil,
        weight: Double? = nil,
        duration: Int? = nil,
        distance: Double? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.order = order
        self.sets = sets
        self.reps = reps
        self.weight = weight
        self.duration = duration
        self.distance = distance
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - WorkoutSet (Individual Set Data)
@Model
public final class WorkoutSet {
    @Attribute(.unique) public var id: UUID
    public var exerciseId: UUID       // Which exercise
    public var order: Int             // Set number (1, 2, 3...)
    public var reps: Int?
    public var weight: Double?
    public var unit: String           // Weight unit (kg or lbs) - stored when set was logged
    public var duration: Int?         // For cardio/timed
    public var distance: Double?      // For distance-based
    public var notes: String?
    public var isCompleted: Bool
    public var completedAt: Date?
    public var date: Date             // When this was logged (used for grouping by day)
    public var rpe: Int?               // Rate of Perceived Exertion (0-10)
    public var rir: Int?               // Reps in Reserve (0-10)
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        exerciseId: UUID,
        order: Int,
        reps: Int?,
        weight: Double?,
        unit: String = "kg",
        duration: Int? = nil,
        distance: Double? = nil,
        notes: String? = nil,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        date: Date = Date(),
        rpe: Int? = nil,
        rir: Int? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.order = order
        self.reps = reps
        self.weight = weight
        self.unit = unit
        self.duration = duration
        self.distance = distance
        self.notes = notes
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.date = date
        // Validate RPE/RIR range (0-10)
        if let rpeValue = rpe, (rpeValue < 0 || rpeValue > 10) {
            self.rpe = nil
        } else {
            self.rpe = rpe
        }
        if let rirValue = rir, (rirValue < 0 || rirValue > 10) {
            self.rir = nil
        } else {
            self.rir = rir
        }
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - WorkoutExercise (for individual workouts)
@Model
public final class WorkoutExercise {
    @Attribute(.unique) public var id: UUID
    public var exerciseId: UUID
    public var order: Int
    public var notes: String?
    public var createdAt: Date
    public var updatedAt: Date
    public var workout: Workout?

    public init(
        id: UUID = UUID(),
        exerciseId: UUID,
        order: Int,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.order = order
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
