import Foundation
import SwiftData

// MARK: - InsightsService
/// Service for calculating insights, trends, and statistics from workout data
public final class InsightsService {
    public static let shared = InsightsService()
    private init() {}

    // MARK: - Volume Trends

    /// Returns daily volume totals for the past N days
    /// - Parameters:
    ///   - days: Number of days to fetch (typically 7 for week view), or nil for all-time
    ///   - modelContext: SwiftData model context
    /// - Returns: Array of (date, volume) tuples sorted by date ascending
    public func getVolumeTrendForPeriod(days: Int?, modelContext: ModelContext) -> [(date: Date, volume: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        // Determine start date based on days parameter
        let startDate: Date?
        if let days = days {
            startDate = calendar.date(byAdding: .day, value: -days, to: today)!
        } else {
            startDate = nil // No start date filter for all-time
        }

        // Fetch all completed sets in the period
        let descriptor: FetchDescriptor<WorkoutSet>
        if let startDate = startDate {
            descriptor = FetchDescriptor<WorkoutSet>(
                predicate: #Predicate { set in
                    set.isCompleted && set.date >= startDate && set.date < tomorrow
                },
                sortBy: [SortDescriptor(\.date, order: .forward)]
            )
        } else {
            // All-time: no start date filter
            descriptor = FetchDescriptor<WorkoutSet>(
                predicate: #Predicate { set in
                    set.isCompleted && set.date < tomorrow
                },
                sortBy: [SortDescriptor(\.date, order: .forward)]
            )
        }

        do {
            let sets = try modelContext.fetch(descriptor)

            // Group by day and calculate volume
            var dailyVolumes: [Date: Double] = [:]

            for set in sets {
                let dayStart = calendar.startOfDay(for: set.date)

                if let weight = set.weight, let reps = set.reps {
                    let volume = WeightUnitConverter.volumeInKg(weight, reps: reps, unit: set.unit)
                    dailyVolumes[dayStart, default: 0] += volume
                }
            }

            // Create array with all days in range (including zero-volume days)
            var result: [(date: Date, volume: Double)] = []

            if let days = days, let startDate = startDate {
                // For bounded periods, include all days in range
                for dayOffset in 0..<days {
                    if let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) {
                        let volume = dailyVolumes[date] ?? 0
                        result.append((date: date, volume: volume))
                    }
                }
            } else {
                // For all-time, only include days with data
                result = dailyVolumes.map { (date: $0.key, volume: $0.value) }
            }

            return result.sorted { $0.date < $1.date }
        } catch {
            print("Error fetching volume trend: \(error)")
            return []
        }
    }

    /// Returns weekly volume aggregates for past N weeks
    /// - Parameters:
    ///   - weeks: Number of weeks to fetch
    ///   - isAllTime: Whether to fetch all-time data (ignores weeks parameter start date)
    ///   - modelContext: SwiftData model context
    /// - Returns: Array of (date, volume) tuples sorted by week ascending
    public func getWeeklyVolumeTrendForPeriod(weeks: Int, isAllTime: Bool = false, modelContext: ModelContext) -> [(date: Date, volume: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = isAllTime ? nil : calendar.date(byAdding: .weekOfYear, value: -weeks, to: today)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        // Fetch all completed sets in the period
        let descriptor: FetchDescriptor<WorkoutSet>
        if let startDate = startDate {
            descriptor = FetchDescriptor<WorkoutSet>(
                predicate: #Predicate { set in
                    set.isCompleted && set.date >= startDate && set.date < tomorrow
                },
                sortBy: [SortDescriptor(\.date, order: .forward)]
            )
        } else {
            // All-time: no start date filter
            descriptor = FetchDescriptor<WorkoutSet>(
                predicate: #Predicate { set in
                    set.isCompleted && set.date < tomorrow
                },
                sortBy: [SortDescriptor(\.date, order: .forward)]
            )
        }

        do {
            let sets = try modelContext.fetch(descriptor)

            // Group by week and calculate volume
            var weeklyVolumes: [Date: Double] = [:]

            for set in sets {
                if let weekStart = calendar.dateInterval(of: .weekOfYear, for: set.date)?.start {
                    if let weight = set.weight, let reps = set.reps {
                        let volume = WeightUnitConverter.volumeInKg(weight, reps: reps, unit: set.unit)
                        weeklyVolumes[weekStart, default: 0] += volume
                    }
                }
            }

            if isAllTime {
                // For all-time, return all weeks with data
                return weeklyVolumes.map { (date: $0.key, volume: $0.value) }.sorted { $0.date < $1.date }
            }

            // Create array with all weeks in range
            var result: [(date: Date, volume: Double)] = []
            var currentDate = startDate!

            while currentDate < tomorrow {
                if let weekStart = calendar.dateInterval(of: .weekOfYear, for: currentDate)?.start {
                    let volume = weeklyVolumes[weekStart] ?? 0
                    result.append((date: weekStart, volume: volume))

                    // Move to next week
                    if let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) {
                        currentDate = nextWeek
                    } else {
                        break
                    }
                } else {
                    break
                }
            }

            return result.sorted { $0.date < $1.date }
        } catch {
            print("Error fetching weekly volume trend: \(error)")
            return []
        }
    }

    // MARK: - Aggregate Stats

    /// Count unique dates with at least one completed set
    /// - Parameters:
    ///   - days: Number of days to look back, or nil for all-time
    ///   - modelContext: SwiftData model context
    public func getWorkoutCount(days: Int?, modelContext: ModelContext) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        let descriptor: FetchDescriptor<WorkoutSet>
        if let days = days {
            let startDate = calendar.date(byAdding: .day, value: -days, to: today)!
            descriptor = FetchDescriptor<WorkoutSet>(
                predicate: #Predicate { set in
                    set.isCompleted && set.date >= startDate && set.date < tomorrow
                }
            )
        } else {
            // All-time
            descriptor = FetchDescriptor<WorkoutSet>(
                predicate: #Predicate { set in
                    set.isCompleted && set.date < tomorrow
                }
            )
        }

        do {
            let sets = try modelContext.fetch(descriptor)

            // Get unique dates
            let uniqueDates = Set(sets.map { calendar.startOfDay(for: $0.date) })
            return uniqueDates.count
        } catch {
            print("Error fetching workout count: \(error)")
            return 0
        }
    }

    /// Count all completed sets in period
    /// - Parameters:
    ///   - days: Number of days to look back, or nil for all-time
    ///   - modelContext: SwiftData model context
    public func getSetCount(days: Int?, modelContext: ModelContext) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        let descriptor: FetchDescriptor<WorkoutSet>
        if let days = days {
            let startDate = calendar.date(byAdding: .day, value: -days, to: today)!
            descriptor = FetchDescriptor<WorkoutSet>(
                predicate: #Predicate { set in
                    set.isCompleted && set.date >= startDate && set.date < tomorrow
                }
            )
        } else {
            // All-time
            descriptor = FetchDescriptor<WorkoutSet>(
                predicate: #Predicate { set in
                    set.isCompleted && set.date < tomorrow
                }
            )
        }

        do {
            let sets = try modelContext.fetch(descriptor)
            return sets.count
        } catch {
            print("Error fetching set count: \(error)")
            return 0
        }
    }

    /// Sum of (weight × reps) for all completed sets
    /// - Parameters:
    ///   - days: Number of days to look back, or nil for all-time
    ///   - modelContext: SwiftData model context
    public func getTotalVolume(days: Int?, modelContext: ModelContext) -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        let descriptor: FetchDescriptor<WorkoutSet>
        if let days = days {
            let startDate = calendar.date(byAdding: .day, value: -days, to: today)!
            descriptor = FetchDescriptor<WorkoutSet>(
                predicate: #Predicate { set in
                    set.isCompleted && set.date >= startDate && set.date < tomorrow
                }
            )
        } else {
            // All-time
            descriptor = FetchDescriptor<WorkoutSet>(
                predicate: #Predicate { set in
                    set.isCompleted && set.date < tomorrow
                }
            )
        }

        do {
            let sets = try modelContext.fetch(descriptor)

            return sets.reduce(0) { total, set in
                guard let weight = set.weight, let reps = set.reps else {
                    return total
                }
                return total + WeightUnitConverter.volumeInKg(weight, reps: reps, unit: set.unit)
            }
        } catch {
            print("Error fetching total volume: \(error)")
            return 0
        }
    }

    /// Count of exercises that achieved a new personal record in period
    /// - Parameters:
    ///   - days: Number of days to look back, or nil for all-time
    ///   - modelContext: SwiftData model context
    public func getPRCount(days: Int?, modelContext: ModelContext) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        let startDate: Date?
        if let days = days {
            startDate = calendar.date(byAdding: .day, value: -days, to: today)!
        } else {
            startDate = nil // All-time
        }

        // Fetch all completed sets
        let allSetsDescriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { set in
                set.isCompleted
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )

        do {
            let allSets = try modelContext.fetch(allSetsDescriptor)

            // Group by exercise
            var exerciseRecords: [UUID: [(date: Date, volume: Double)]] = [:]

            for set in allSets {
                guard let weight = set.weight, let reps = set.reps else { continue }
                let volume = weight * Double(reps)
                exerciseRecords[set.exerciseId, default: []].append((date: set.date, volume: volume))
            }

            // Count PRs in the period
            var prCount = 0

            for (_, records) in exerciseRecords {
                let sortedRecords = records.sorted { $0.date < $1.date }

                // Find max volume in period
                let periodRecords: [(date: Date, volume: Double)]
                if let startDate = startDate {
                    periodRecords = sortedRecords.filter { $0.date >= startDate && $0.date < tomorrow }
                } else {
                    // All-time: count total unique PRs (each new max is a PR)
                    periodRecords = sortedRecords.filter { $0.date < tomorrow }
                }
                guard let maxInPeriod = periodRecords.map({ $0.volume }).max() else { continue }

                // Find max volume before period (for all-time, there's no "before")
                if let startDate = startDate {
                    let beforeRecords = sortedRecords.filter { $0.date < startDate }
                    let maxBefore = beforeRecords.map({ $0.volume }).max() ?? 0

                    // If period max is greater, it's a PR
                    if maxInPeriod > maxBefore {
                        prCount += 1
                    }
                } else {
                    // For all-time, count any exercise that has at least one record as having a PR
                    prCount += 1
                }
            }

            return prCount
        } catch {
            print("Error calculating PR count: \(error)")
            return 0
        }
    }

    // MARK: - Muscle Group Breakdown

    /// Get volume breakdown by muscle group category
    /// - Parameters:
    ///   - days: Number of days to look back, or nil for all-time
    ///   - modelContext: SwiftData model context
    public func getMuscleGroupBreakdown(days: Int?, modelContext: ModelContext) -> [(category: String, volume: Double, percentage: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        // Fetch all completed sets in period
        let setsDescriptor: FetchDescriptor<WorkoutSet>
        if let days = days {
            let startDate = calendar.date(byAdding: .day, value: -days, to: today)!
            setsDescriptor = FetchDescriptor<WorkoutSet>(
                predicate: #Predicate { set in
                    set.isCompleted && set.date >= startDate && set.date < tomorrow
                }
            )
        } else {
            // All-time
            setsDescriptor = FetchDescriptor<WorkoutSet>(
                predicate: #Predicate { set in
                    set.isCompleted && set.date < tomorrow
                }
            )
        }

        // Fetch all exercises
        let exercisesDescriptor = FetchDescriptor<Exercise>()

        do {
            let sets = try modelContext.fetch(setsDescriptor)
            let exercises = try modelContext.fetch(exercisesDescriptor)

            // Create exercise lookup
            let exerciseById = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })

            // Calculate volume per category
            var categoryVolumes: [String: Double] = [:]

            for set in sets {
                guard let weight = set.weight,
                      let reps = set.reps,
                      let exercise = exerciseById[set.exerciseId] else {
                    continue
                }

                let volume = WeightUnitConverter.volumeInKg(weight, reps: reps, unit: set.unit)
                let category = exercise.primaryCategory
                categoryVolumes[category, default: 0] += volume
            }

            // Calculate total volume
            let totalVolume = categoryVolumes.values.reduce(0, +)

            guard totalVolume > 0 else {
                return []
            }

            // Sort by volume descending
            let sortedCategories = categoryVolumes.sorted { $0.value > $1.value }

            // Take top 6, combine rest as "Other"
            var result: [(category: String, volume: Double, percentage: Double)] = []

            for (index, (category, volume)) in sortedCategories.enumerated() {
                let percentage = (volume / totalVolume) * 100

                if index < 6 {
                    result.append((category: category, volume: volume, percentage: percentage))
                } else {
                    // Combine remaining as "Other"
                    if let otherIndex = result.firstIndex(where: { $0.category == "Other" }) {
                        result[otherIndex].volume += volume
                        result[otherIndex].percentage += percentage
                    } else {
                        result.append((category: "Other", volume: volume, percentage: percentage))
                    }
                }
            }

            return result
        } catch {
            print("Error calculating muscle group breakdown: \(error)")
            return []
        }
    }

    // MARK: - Personal Records

    /// Get recent personal records
    public func getRecentPRs(limit: Int = 10, modelContext: ModelContext) -> [(exercise: Exercise, weight: Double, reps: Int, date: Date, oneRM: Double)] {
        // Fetch all completed sets
        let setsDescriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { set in
                set.isCompleted
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )

        // Fetch all exercises
        let exercisesDescriptor = FetchDescriptor<Exercise>()

        do {
            let allSets = try modelContext.fetch(setsDescriptor)
            let exercises = try modelContext.fetch(exercisesDescriptor)

            // Create exercise lookup
            let exerciseById = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })

            // Group by exercise
            var exerciseRecords: [UUID: [(date: Date, weight: Double, reps: Int, volume: Double)]] = [:]

            for set in allSets {
                guard let weight = set.weight, let reps = set.reps else { continue }
                let volume = weight * Double(reps)
                exerciseRecords[set.exerciseId, default: []].append((
                    date: set.date,
                    weight: weight,
                    reps: reps,
                    volume: volume
                ))
            }

            // Find PRs for each exercise
            var prs: [(exercise: Exercise, weight: Double, reps: Int, date: Date, oneRM: Double)] = []

            for (exerciseId, records) in exerciseRecords {
                guard let exercise = exerciseById[exerciseId] else { continue }

                let sortedRecords = records.sorted { $0.date < $1.date }

                var maxVolumeSoFar: Double = 0

                for record in sortedRecords {
                    if record.volume > maxVolumeSoFar {
                        // This is a PR
                        let oneRM = calculateOneRM(weight: record.weight, reps: record.reps)
                        prs.append((
                            exercise: exercise,
                            weight: record.weight,
                            reps: record.reps,
                            date: record.date,
                            oneRM: oneRM
                        ))
                        maxVolumeSoFar = record.volume
                    }
                }
            }

            // Sort by date descending and take limit
            return prs.sorted { $0.date > $1.date }.prefix(limit).map { $0 }
        } catch {
            print("Error fetching recent PRs: \(error)")
            return []
        }
    }

    // MARK: - Helper Methods

    /// Calculate estimated 1RM using Epley formula
    /// Formula: weight × (1 + reps / 30)
    public func calculateOneRM(weight: Double, reps: Int) -> Double {
        return weight * (1 + Double(reps) / 30)
    }

    // MARK: - Comparison Stats

    /// Represents the comparison between current and previous period
    public struct PeriodComparison {
        public let currentValue: Double
        public let previousValue: Double
        public let percentChange: Double?
        public let hasData: Bool

        public init(current: Double, previous: Double) {
            self.currentValue = current
            self.previousValue = previous
            self.hasData = previous > 0
            if previous > 0 {
                self.percentChange = ((current - previous) / previous) * 100
            } else {
                self.percentChange = nil
            }
        }
    }

    /// Get comparison stats for the current period vs previous equivalent period
    /// - Parameters:
    ///   - days: Number of days for current period (or nil for all-time, which disables comparison)
    ///   - modelContext: SwiftData model context
    /// - Returns: Tuple of comparisons for workouts, sets, volume, and PRs
    public func getComparisonStats(days: Int?, modelContext: ModelContext) -> (
        workouts: PeriodComparison,
        sets: PeriodComparison,
        volume: PeriodComparison,
        prs: PeriodComparison
    ) {
        guard let days = days else {
            // For all-time, comparison doesn't make sense - return zero comparison
            let currentWorkouts = Double(getWorkoutCount(days: nil, modelContext: modelContext))
            let currentSets = Double(getSetCount(days: nil, modelContext: modelContext))
            let currentVolume = getTotalVolume(days: nil, modelContext: modelContext)
            let currentPRs = Double(getPRCount(days: nil, modelContext: modelContext))

            return (
                workouts: PeriodComparison(current: currentWorkouts, previous: 0),
                sets: PeriodComparison(current: currentSets, previous: 0),
                volume: PeriodComparison(current: currentVolume, previous: 0),
                prs: PeriodComparison(current: currentPRs, previous: 0)
            )
        }

        // Current period stats
        let currentWorkouts = Double(getWorkoutCount(days: days, modelContext: modelContext))
        let currentSets = Double(getSetCount(days: days, modelContext: modelContext))
        let currentVolume = getTotalVolume(days: days, modelContext: modelContext)
        let currentPRs = Double(getPRCount(days: days, modelContext: modelContext))

        // Previous period stats (same number of days, but shifted back)
        let previousWorkouts = Double(getWorkoutCountForPreviousPeriod(days: days, modelContext: modelContext))
        let previousSets = Double(getSetCountForPreviousPeriod(days: days, modelContext: modelContext))
        let previousVolume = getTotalVolumeForPreviousPeriod(days: days, modelContext: modelContext)
        let previousPRs = Double(getPRCountForPreviousPeriod(days: days, modelContext: modelContext))

        return (
            workouts: PeriodComparison(current: currentWorkouts, previous: previousWorkouts),
            sets: PeriodComparison(current: currentSets, previous: previousSets),
            volume: PeriodComparison(current: currentVolume, previous: previousVolume),
            prs: PeriodComparison(current: currentPRs, previous: previousPRs)
        )
    }

    // MARK: - Previous Period Calculations

    /// Count workouts in the previous period (days before the current period start)
    private func getWorkoutCountForPreviousPeriod(days: Int, modelContext: ModelContext) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let currentPeriodStart = calendar.date(byAdding: .day, value: -days, to: today)!
        let previousPeriodStart = calendar.date(byAdding: .day, value: -days, to: currentPeriodStart)!

        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { set in
                set.isCompleted && set.date >= previousPeriodStart && set.date < currentPeriodStart
            }
        )

        do {
            let sets = try modelContext.fetch(descriptor)
            let uniqueDates = Set(sets.map { calendar.startOfDay(for: $0.date) })
            return uniqueDates.count
        } catch {
            return 0
        }
    }

    /// Count sets in the previous period
    private func getSetCountForPreviousPeriod(days: Int, modelContext: ModelContext) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let currentPeriodStart = calendar.date(byAdding: .day, value: -days, to: today)!
        let previousPeriodStart = calendar.date(byAdding: .day, value: -days, to: currentPeriodStart)!

        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { set in
                set.isCompleted && set.date >= previousPeriodStart && set.date < currentPeriodStart
            }
        )

        do {
            let sets = try modelContext.fetch(descriptor)
            return sets.count
        } catch {
            return 0
        }
    }

    /// Get total volume for previous period
    private func getTotalVolumeForPreviousPeriod(days: Int, modelContext: ModelContext) -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let currentPeriodStart = calendar.date(byAdding: .day, value: -days, to: today)!
        let previousPeriodStart = calendar.date(byAdding: .day, value: -days, to: currentPeriodStart)!

        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { set in
                set.isCompleted && set.date >= previousPeriodStart && set.date < currentPeriodStart
            }
        )

        do {
            let sets = try modelContext.fetch(descriptor)
            return sets.reduce(0) { total, set in
                guard let weight = set.weight, let reps = set.reps else { return total }
                return total + WeightUnitConverter.volumeInKg(weight, reps: reps, unit: set.unit)
            }
        } catch {
            return 0
        }
    }

    /// Count PRs in the previous period
    private func getPRCountForPreviousPeriod(days: Int, modelContext: ModelContext) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let currentPeriodStart = calendar.date(byAdding: .day, value: -days, to: today)!
        let previousPeriodStart = calendar.date(byAdding: .day, value: -days, to: currentPeriodStart)!

        // Fetch all completed sets
        let allSetsDescriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { set in
                set.isCompleted
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )

        do {
            let allSets = try modelContext.fetch(allSetsDescriptor)

            // Group by exercise
            var exerciseRecords: [UUID: [(date: Date, volume: Double)]] = [:]

            for set in allSets {
                guard let weight = set.weight, let reps = set.reps else { continue }
                let volume = weight * Double(reps)
                exerciseRecords[set.exerciseId, default: []].append((date: set.date, volume: volume))
            }

            // Count PRs in the previous period
            var prCount = 0

            for (_, records) in exerciseRecords {
                let sortedRecords = records.sorted { $0.date < $1.date }

                // Find max volume in previous period
                let periodRecords = sortedRecords.filter { $0.date >= previousPeriodStart && $0.date < currentPeriodStart }
                guard let maxInPeriod = periodRecords.map({ $0.volume }).max() else { continue }

                // Find max volume before previous period
                let beforeRecords = sortedRecords.filter { $0.date < previousPeriodStart }
                let maxBefore = beforeRecords.map({ $0.volume }).max() ?? 0

                // If period max is greater, it's a PR
                if maxInPeriod > maxBefore {
                    prCount += 1
                }
            }

            return prCount
        } catch {
            return 0
        }
    }

    // MARK: - Muscle Recovery

    /// Represents the recovery status of a muscle group
    public struct MuscleRecoveryStatus {
        public let muscleGroup: String
        public let hoursSinceLastTrained: Double?
        public let recoveryPercentage: Double
        public let setsCompleted: Int
        public let lastTrainedDate: Date?

        /// Recovery color as RGB values (0-1 range)
        /// Red (0-40%), Yellow/Orange (40-80%), Green (80-100%)
        public var recoveryColorRGB: (red: Double, green: Double, blue: Double) {
            if recoveryPercentage <= 40 {
                // Red zone (0-40%): #FF4444 to #FFB84D blend
                let t = recoveryPercentage / 40
                return (red: 1.0, green: 0.27 + t * 0.45, blue: 0.27 - t * 0.07)
            } else if recoveryPercentage <= 80 {
                // Yellow zone (40-80%): #FFB84D to yellow-green blend
                let t = (recoveryPercentage - 40) / 40
                return (red: 1.0 - t * 0.5, green: 0.72 + t * 0.13, blue: 0.3 + t * 0.1)
            } else {
                // Green zone (80-100%): Yellow-green to #00D9A3 (teal)
                let t = (recoveryPercentage - 80) / 20
                return (red: 0.5 - t * 0.5, green: 0.85, blue: 0.4 + t * 0.24)
            }
        }
    }

    /// Calculate recovery status for all muscle groups
    /// - Parameters:
    ///   - modelContext: SwiftData model context
    /// - Returns: Dictionary of muscle group name to recovery status
    public func getMuscleRecoveryStatus(modelContext: ModelContext) -> [String: MuscleRecoveryStatus] {
        let calendar = Calendar.current
        let now = Date()

        // Fetch all exercises to map exerciseId to primaryCategory
        let exercisesDescriptor = FetchDescriptor<Exercise>()
        let exerciseMap: [UUID: Exercise]

        do {
            let exercises = try modelContext.fetch(exercisesDescriptor)
            exerciseMap = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
        } catch {
            return [:]
        }

        // Fetch completed sets from last 7 days (enough to determine recovery)
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
        let setsDescriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { set in
                set.isCompleted && set.date >= weekAgo
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            let sets = try modelContext.fetch(setsDescriptor)

            // Group sets by muscle group (primaryCategory)
            var muscleGroupData: [String: (lastDate: Date, sets: Int)] = [:]

            for set in sets {
                guard let exercise = exerciseMap[set.exerciseId] else { continue }
                let category = exercise.primaryCategory

                if let existing = muscleGroupData[category] {
                    // Keep the most recent date, accumulate sets
                    if set.date > existing.lastDate {
                        muscleGroupData[category] = (lastDate: set.date, sets: existing.sets + 1)
                    } else {
                        muscleGroupData[category] = (lastDate: existing.lastDate, sets: existing.sets + 1)
                    }
                } else {
                    muscleGroupData[category] = (lastDate: set.date, sets: 1)
                }
            }

            // Calculate recovery status for each muscle group
            var recoveryStatuses: [String: MuscleRecoveryStatus] = [:]

            // Standard muscle groups
            let allMuscleGroups = ["Chest", "Back", "Shoulders", "Arms", "Biceps", "Triceps", "Legs", "Quads", "Hamstrings", "Glutes", "Core", "Abs", "Cardio"]

            for muscleGroup in allMuscleGroups {
                if let data = muscleGroupData[muscleGroup] {
                    let hoursSince = now.timeIntervalSince(data.lastDate) / 3600
                    let recoveryPercent = calculateRecoveryPercentage(hoursSince: hoursSince)

                    recoveryStatuses[muscleGroup] = MuscleRecoveryStatus(
                        muscleGroup: muscleGroup,
                        hoursSinceLastTrained: hoursSince,
                        recoveryPercentage: recoveryPercent,
                        setsCompleted: data.sets,
                        lastTrainedDate: data.lastDate
                    )
                } else {
                    // Never trained or not trained in last 7 days = fully recovered
                    recoveryStatuses[muscleGroup] = MuscleRecoveryStatus(
                        muscleGroup: muscleGroup,
                        hoursSinceLastTrained: nil,
                        recoveryPercentage: 100,
                        setsCompleted: 0,
                        lastTrainedDate: nil
                    )
                }
            }

            return recoveryStatuses
        } catch {
            return [:]
        }
    }

    /// Calculate recovery percentage based on hours since last trained
    /// Recovery model: 0-24h = 0-40%, 24-48h = 40-80%, 48-72h = 80-100%, 72h+ = 100%
    private func calculateRecoveryPercentage(hoursSince: Double) -> Double {
        if hoursSince >= 72 {
            return 100
        } else if hoursSince >= 48 {
            // 48-72h: 80-100%
            let progress = (hoursSince - 48) / 24
            return 80 + (progress * 20)
        } else if hoursSince >= 24 {
            // 24-48h: 40-80%
            let progress = (hoursSince - 24) / 24
            return 40 + (progress * 40)
        } else {
            // 0-24h: 0-40%
            let progress = hoursSince / 24
            return progress * 40
        }
    }

    // MARK: - Per-Exercise Statistics

    /// Represents detailed statistics for a single exercise
    public struct ExerciseStats {
        public let exerciseId: UUID
        public let bestWeight: Double?           // Highest weight ever lifted
        public let bestVolumeSet: (weight: Double, reps: Int)?  // Best single set by volume
        public let currentE1RM: Double?          // Most recent E1RM (from sets with ≤10 reps)
        public let totalVolume: Double           // All-time total volume
        public let timesPerformed: Int           // Number of unique workout days
        public let e1rmProgression: [(date: Date, e1rm: Double)]  // E1RM over time
        public let repRecords: [Int: Double]     // Best weight at each rep count (1, 3, 5, 8, 10, 12)
        public let recentHistory: [(date: Date, sets: Int, bestSet: String)]  // Last 10 sessions
    }

    /// Get detailed statistics for a specific exercise
    public func getExerciseStats(exerciseId: UUID, unit: String, modelContext: ModelContext) -> ExerciseStats {
        // Fetch all completed sets for this exercise
        let setsDescriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { set in
                set.isCompleted && set.exerciseId == exerciseId
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )

        do {
            let sets = try modelContext.fetch(setsDescriptor)
            let calendar = Calendar.current

            // Calculate best weight
            let bestWeight = sets.compactMap { $0.weight }.max()

            // Calculate best volume set
            var bestVolumeSet: (weight: Double, reps: Int)?
            var maxVolume: Double = 0
            for set in sets {
                guard let weight = set.weight, let reps = set.reps else { continue }
                let volume = weight * Double(reps)
                if volume > maxVolume {
                    maxVolume = volume
                    bestVolumeSet = (weight: weight, reps: reps)
                }
            }

            // Calculate current E1RM (most recent valid set with ≤10 reps)
            var currentE1RM: Double?
            for set in sets.reversed() {
                guard let weight = set.weight, let reps = set.reps, reps <= 10 else { continue }
                currentE1RM = calculateOneRM(weight: weight, reps: reps)
                break
            }

            // Calculate total volume
            let totalVolume = sets.reduce(0.0) { total, set in
                guard let weight = set.weight, let reps = set.reps else { return total }
                return total + (weight * Double(reps))
            }

            // Calculate times performed (unique days)
            let uniqueDays = Set(sets.map { calendar.startOfDay(for: $0.date) })
            let timesPerformed = uniqueDays.count

            // Calculate E1RM progression (best E1RM per day for sets with ≤10 reps)
            var dailyE1RMs: [Date: Double] = [:]
            for set in sets {
                guard let weight = set.weight, let reps = set.reps, reps <= 10 else { continue }
                let day = calendar.startOfDay(for: set.date)
                let e1rm = calculateOneRM(weight: weight, reps: reps)
                dailyE1RMs[day] = max(dailyE1RMs[day] ?? 0, e1rm)
            }
            let e1rmProgression = dailyE1RMs.map { (date: $0.key, e1rm: $0.value) }.sorted { $0.date < $1.date }

            // Calculate rep records (best weight at 1, 3, 5, 8, 10, 12 reps)
            var repRecords: [Int: Double] = [:]
            let targetReps = [1, 3, 5, 8, 10, 12]
            for set in sets {
                guard let weight = set.weight, let reps = set.reps else { continue }
                if targetReps.contains(reps) {
                    repRecords[reps] = max(repRecords[reps] ?? 0, weight)
                }
            }

            // Calculate recent history (last 10 sessions)
            var sessionData: [Date: (sets: Int, bestWeight: Double, bestReps: Int, bestVolume: Double)] = [:]
            for set in sets {
                let day = calendar.startOfDay(for: set.date)
                var existing = sessionData[day] ?? (sets: 0, bestWeight: 0, bestReps: 0, bestVolume: 0)
                existing.sets += 1
                if let weight = set.weight, let reps = set.reps {
                    let volume = weight * Double(reps)
                    if volume > existing.bestVolume {
                        existing.bestWeight = weight
                        existing.bestReps = reps
                        existing.bestVolume = volume
                    }
                }
                sessionData[day] = existing
            }

            let recentHistory: [(date: Date, sets: Int, bestSet: String)] = sessionData
                .sorted { $0.key > $1.key }
                .prefix(10)
                .map { day, data in
                    let weightStr = data.bestWeight.truncatingRemainder(dividingBy: 1) == 0 ?
                        "\(Int(data.bestWeight))" : String(format: "%.1f", data.bestWeight)
                    let bestSetStr = data.bestVolume > 0 ? "\(weightStr) \(unit) × \(data.bestReps)" : "–"
                    return (date: day, sets: data.sets, bestSet: bestSetStr)
                }

            return ExerciseStats(
                exerciseId: exerciseId,
                bestWeight: bestWeight,
                bestVolumeSet: bestVolumeSet,
                currentE1RM: currentE1RM,
                totalVolume: totalVolume,
                timesPerformed: timesPerformed,
                e1rmProgression: e1rmProgression,
                repRecords: repRecords,
                recentHistory: recentHistory
            )
        } catch {
            return ExerciseStats(
                exerciseId: exerciseId,
                bestWeight: nil,
                bestVolumeSet: nil,
                currentE1RM: nil,
                totalVolume: 0,
                timesPerformed: 0,
                e1rmProgression: [],
                repRecords: [:],
                recentHistory: []
            )
        }
    }

    /// Get top exercises by number of times performed
    public func getTopExercises(limit: Int = 5, modelContext: ModelContext) -> [(exercise: Exercise, setCount: Int)] {
        // Fetch all completed sets
        let setsDescriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { set in
                set.isCompleted
            }
        )

        // Fetch all exercises
        let exercisesDescriptor = FetchDescriptor<Exercise>()

        do {
            let sets = try modelContext.fetch(setsDescriptor)
            let exercises = try modelContext.fetch(exercisesDescriptor)
            let exerciseById = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })

            // Count sets per exercise
            var exerciseSetCounts: [UUID: Int] = [:]
            for set in sets {
                exerciseSetCounts[set.exerciseId, default: 0] += 1
            }

            // Sort by count and take top N
            let topExercises = exerciseSetCounts
                .sorted { $0.value > $1.value }
                .prefix(limit)
                .compactMap { id, count -> (exercise: Exercise, setCount: Int)? in
                    guard let exercise = exerciseById[id] else { return nil }
                    return (exercise: exercise, setCount: count)
                }

            return Array(topExercises)
        } catch {
            return []
        }
    }

    // MARK: - Streak & Consistency

    /// Represents streak and consistency data
    public struct StreakData {
        public let currentStreak: Int          // Consecutive weeks with workouts
        public let bestStreak: Int             // All-time best weekly streak
        public let streakUnit: String          // "weeks"
        public let isAtRisk: Bool              // True if no workout yet this week but recent activity exists
        public let lastWorkoutDate: Date?      // Most recent workout date
        public let weeklyConsistency: [(weekStart: Date, workoutCount: Int)]  // Last 12 weeks
    }

    /// Calculate streak and consistency data
    public func getStreakData(modelContext: ModelContext) -> StreakData {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Fetch all completed sets to determine workout dates
        let setsDescriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { set in
                set.isCompleted
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            let sets = try modelContext.fetch(setsDescriptor)

            // Get unique workout dates
            let workoutDates = Set(sets.map { calendar.startOfDay(for: $0.date) })
            let sortedDates = workoutDates.sorted(by: >)  // Most recent first
            
            // Build set of active week starts (weeks with at least one workout)
            var activeWeekStarts: Set<Date> = []
            for date in workoutDates {
                if let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start {
                    activeWeekStarts.insert(weekStart)
                }
            }

            // Calculate current weekly streak (consecutive weeks with workouts, starting from this week)
            var currentStreak = 0
            var currentWeekInterval = calendar.dateInterval(of: .weekOfYear, for: today)
            var foundWorkoutInWeek = true

            while let week = currentWeekInterval, foundWorkoutInWeek {
                let weekStart = week.start
                let weekEnd = week.end

                let hasWorkoutThisWeek = workoutDates.contains { $0 >= weekStart && $0 < weekEnd }
                foundWorkoutInWeek = hasWorkoutThisWeek

                if hasWorkoutThisWeek {
                    currentStreak += 1

                    if let previousWeekAnchor = calendar.date(byAdding: .day, value: -7, to: weekStart) {
                        currentWeekInterval = calendar.dateInterval(of: .weekOfYear, for: previousWeekAnchor)
                    } else {
                        break
                    }
                }
            }

            // Calculate best weekly streak ever
            let sortedWeekStarts = activeWeekStarts.sorted()
            var bestStreak = 0
            var tempStreak = 0
            var previousWeekStart: Date?

            for weekStart in sortedWeekStarts {
                if let prev = previousWeekStart {
                    let weeksBetween = calendar.dateComponents([.weekOfYear], from: prev, to: weekStart).weekOfYear ?? 0
                    if weeksBetween == 1 {
                        tempStreak += 1
                    } else {
                        bestStreak = max(bestStreak, tempStreak)
                        tempStreak = 1
                    }
                } else {
                    tempStreak = 1
                }
                previousWeekStart = weekStart
            }
            bestStreak = max(bestStreak, tempStreak)

            // Check if streak is at risk: no workout yet this week, but there was at least one workout in the last 12 weeks
            let currentWeek = calendar.dateInterval(of: .weekOfYear, for: today)!
            let hasWorkoutThisWeek = workoutDates.contains { $0 >= currentWeek.start && $0 < currentWeek.end }
            let twelveWeeksAgo = calendar.date(byAdding: .weekOfYear, value: -12, to: today)!
            let hadRecentActivity = workoutDates.contains { $0 >= twelveWeeksAgo && $0 < currentWeek.end }
            let isAtRisk = !hasWorkoutThisWeek && hadRecentActivity

            // Calculate weekly consistency (last 12 weeks)
            var weeklyConsistency: [(weekStart: Date, workoutCount: Int)] = []
            for weekOffset in 0..<12 {
                let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today)!
                let weekStartNormalized = calendar.dateInterval(of: .weekOfYear, for: weekStart)?.start ?? weekStart

                // Count workouts in this week
                let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStartNormalized)!
                let workoutsInWeek = workoutDates.filter { date in
                    date >= weekStartNormalized && date < weekEnd
                }.count

                weeklyConsistency.append((weekStart: weekStartNormalized, workoutCount: workoutsInWeek))
            }

            return StreakData(
                currentStreak: currentStreak,
                bestStreak: bestStreak,
                streakUnit: "weeks",
                isAtRisk: isAtRisk,
                lastWorkoutDate: sortedDates.first,
                weeklyConsistency: weeklyConsistency.reversed()
            )
        } catch {
            return StreakData(
                currentStreak: 0,
                bestStreak: 0,
                streakUnit: "days",
                isAtRisk: false,
                lastWorkoutDate: nil,
                weeklyConsistency: []
            )
        }
    }

    // MARK: - Goals & Targets

    /// Represents the progress towards a fitness goal
    public struct GoalProgress {
        public let goal: FitnessGoal
        public let currentValue: Double
        public let targetValue: Double
        public let progressPercentage: Double
        public let isAchieved: Bool
        public let displayCurrentValue: String
        public let displayTargetValue: String

        public init(goal: FitnessGoal, currentValue: Double, targetValue: Double, displayCurrent: String, displayTarget: String) {
            self.goal = goal
            self.currentValue = currentValue
            self.targetValue = targetValue
            self.progressPercentage = targetValue > 0 ? min(100, (currentValue / targetValue) * 100) : 0
            self.isAchieved = currentValue >= targetValue
            self.displayCurrentValue = displayCurrent
            self.displayTargetValue = displayTarget
        }
    }

    /// Get progress for all active goals
    public func getGoalProgress(goals: [FitnessGoal], modelContext: ModelContext) -> [GoalProgress] {
        return goals.filter { $0.isActive }.compactMap { goal in
            calculateProgressForGoal(goal, modelContext: modelContext)
        }
    }

    /// Calculate progress for a single goal
    private func calculateProgressForGoal(_ goal: FitnessGoal, modelContext: ModelContext) -> GoalProgress? {
        switch goal.goalType {
        case .weeklyWorkouts:
            return calculateWeeklyWorkoutsProgress(goal, modelContext: modelContext)
        case .weeklyVolume:
            return calculateWeeklyVolumeProgress(goal, modelContext: modelContext)
        case .specificLift:
            return calculateSpecificLiftProgress(goal, modelContext: modelContext)
        }
    }

    /// Calculate progress for weekly workouts goal
    private func calculateWeeklyWorkoutsProgress(_ goal: FitnessGoal, modelContext: ModelContext) -> GoalProgress {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get start of current week (Sunday)
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return GoalProgress(goal: goal, currentValue: 0, targetValue: goal.targetValue, displayCurrent: "0", displayTarget: "\(Int(goal.targetValue))")
        }

        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!

        // Fetch completed sets this week
        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { set in
                set.isCompleted && set.date >= weekStart && set.date < weekEnd
            }
        )

        do {
            let sets = try modelContext.fetch(descriptor)
            let uniqueDates = Set(sets.map { calendar.startOfDay(for: $0.date) })
            let workoutCount = Double(uniqueDates.count)

            return GoalProgress(
                goal: goal,
                currentValue: workoutCount,
                targetValue: goal.targetValue,
                displayCurrent: "\(Int(workoutCount))",
                displayTarget: "\(Int(goal.targetValue))"
            )
        } catch {
            return GoalProgress(goal: goal, currentValue: 0, targetValue: goal.targetValue, displayCurrent: "0", displayTarget: "\(Int(goal.targetValue))")
        }
    }

    /// Calculate progress for weekly volume goal
    private func calculateWeeklyVolumeProgress(_ goal: FitnessGoal, modelContext: ModelContext) -> GoalProgress {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get start of current week (Sunday)
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return GoalProgress(goal: goal, currentValue: 0, targetValue: goal.targetValue, displayCurrent: "0 kg", displayTarget: formatVolumeTarget(goal.targetValue))
        }

        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!

        // Fetch completed sets this week
        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { set in
                set.isCompleted && set.date >= weekStart && set.date < weekEnd
            }
        )

        do {
            let sets = try modelContext.fetch(descriptor)
            let totalVolume = sets.reduce(0.0) { total, set in
                guard let weight = set.weight, let reps = set.reps else { return total }
                return total + WeightUnitConverter.volumeInKg(weight, reps: reps, unit: set.unit)
            }

            return GoalProgress(
                goal: goal,
                currentValue: totalVolume,
                targetValue: goal.targetValue,
                displayCurrent: formatVolumeTarget(totalVolume),
                displayTarget: formatVolumeTarget(goal.targetValue)
            )
        } catch {
            return GoalProgress(goal: goal, currentValue: 0, targetValue: goal.targetValue, displayCurrent: "0 kg", displayTarget: formatVolumeTarget(goal.targetValue))
        }
    }

    /// Calculate progress for specific lift goal
    private func calculateSpecificLiftProgress(_ goal: FitnessGoal, modelContext: ModelContext) -> GoalProgress? {
        guard let exerciseId = goal.exerciseId else { return nil }

        // Fetch all completed sets for this exercise
        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { set in
                set.isCompleted && set.exerciseId == exerciseId
            }
        )

        do {
            let sets = try modelContext.fetch(descriptor)
            let bestWeight = sets.compactMap { $0.weight }.max() ?? 0

            let unit = goal.weightUnit ?? "kg"
            let targetDisplay = formatWeight(goal.targetValue, unit: unit)
            let currentDisplay = formatWeight(bestWeight, unit: unit)

            return GoalProgress(
                goal: goal,
                currentValue: bestWeight,
                targetValue: goal.targetValue,
                displayCurrent: currentDisplay,
                displayTarget: targetDisplay
            )
        } catch {
            let unit = goal.weightUnit ?? "kg"
            return GoalProgress(
                goal: goal,
                currentValue: 0,
                targetValue: goal.targetValue,
                displayCurrent: "0 \(unit)",
                displayTarget: formatWeight(goal.targetValue, unit: unit)
            )
        }
    }

    /// Format volume for display
    private func formatVolumeTarget(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk kg", volume / 1000)
        } else {
            return "\(Int(volume)) kg"
        }
    }

    /// Format weight for display
    private func formatWeight(_ weight: Double, unit: String) -> String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(weight)) \(unit)"
        } else {
            return String(format: "%.1f %@", weight, unit)
        }
    }

    // MARK: - Goal CRUD Operations

    /// Create a new fitness goal
    public func createGoal(type: GoalType, targetValue: Double, exerciseId: UUID? = nil, exerciseName: String? = nil, weightUnit: String? = nil, modelContext: ModelContext) -> FitnessGoal? {
        // Check if max active goals reached (3)
        let activeGoals = getActiveGoals(modelContext: modelContext)
        guard activeGoals.count < 3 else { return nil }

        let goal = FitnessGoal(
            type: type,
            targetValue: targetValue,
            exerciseId: exerciseId,
            exerciseName: exerciseName,
            weightUnit: weightUnit
        )

        modelContext.insert(goal)

        do {
            try modelContext.save()
            return goal
        } catch {
            print("Error creating goal: \(error)")
            return nil
        }
    }

    /// Get all active goals
    public func getActiveGoals(modelContext: ModelContext) -> [FitnessGoal] {
        let descriptor = FetchDescriptor<FitnessGoal>(
            predicate: #Predicate { goal in
                goal.isActive
            },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            return []
        }
    }

    /// Mark a goal as achieved
    public func markGoalAchieved(_ goal: FitnessGoal, modelContext: ModelContext) {
        goal.achievedAt = Date()

        do {
            try modelContext.save()
        } catch {
            print("Error marking goal achieved: \(error)")
        }
    }

    /// Delete a goal
    public func deleteGoal(_ goal: FitnessGoal, modelContext: ModelContext) {
        modelContext.delete(goal)

        do {
            try modelContext.save()
        } catch {
            print("Error deleting goal: \(error)")
        }
    }

    /// Deactivate a goal (without deleting)
    public func deactivateGoal(_ goal: FitnessGoal, modelContext: ModelContext) {
        goal.isActive = false

        do {
            try modelContext.save()
        } catch {
            print("Error deactivating goal: \(error)")
        }
    }

    // MARK: - Year in Review

    /// Represents a complete year in review summary
    public struct YearInReviewData {
        public let year: Int
        public let totalWorkouts: Int
        public let totalSets: Int
        public let totalVolume: Double
        public let uniqueExercises: Int
        public let favoriteExercise: (name: String, count: Int)?
        public let mostTrainedMuscle: (name: String, percentage: Double)?
        public let personalRecords: Int
        public let longestStreak: Int
        public let activeWeeks: Int
        public let avgWorkoutsPerWeek: Double
        public let monthlyWorkouts: [(month: Int, count: Int)]
        public let topThreeExercises: [(name: String, count: Int)]
        public let volumeGrowth: Double?  // Percentage growth from previous year
        public let bestMonth: (month: Int, workouts: Int)?
    }

    /// Get year in review data for a specific year
    public func getYearInReview(year: Int, modelContext: ModelContext) -> YearInReviewData {
        let calendar = Calendar.current

        // Define year boundaries
        var startComponents = DateComponents()
        startComponents.year = year
        startComponents.month = 1
        startComponents.day = 1
        let yearStart = calendar.date(from: startComponents)!

        var endComponents = DateComponents()
        endComponents.year = year + 1
        endComponents.month = 1
        endComponents.day = 1
        let yearEnd = calendar.date(from: endComponents)!

        // Fetch all completed sets for the year
        let setsDescriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { set in
                set.isCompleted && set.date >= yearStart && set.date < yearEnd
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )

        // Fetch all exercises
        let exercisesDescriptor = FetchDescriptor<Exercise>()

        do {
            let sets = try modelContext.fetch(setsDescriptor)
            let exercises = try modelContext.fetch(exercisesDescriptor)
            let exerciseById = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })

            // Calculate basic stats
            let uniqueDates = Set(sets.map { calendar.startOfDay(for: $0.date) })
            let totalWorkouts = uniqueDates.count
            let totalSets = sets.count

            // Calculate total volume
            let totalVolume = sets.reduce(0.0) { total, set in
                guard let weight = set.weight, let reps = set.reps else { return total }
                return total + WeightUnitConverter.volumeInKg(weight, reps: reps, unit: set.unit)
            }

            // Unique exercises performed
            let uniqueExerciseIds = Set(sets.map { $0.exerciseId })
            let uniqueExercisesCount = uniqueExerciseIds.count

            // Exercise frequency
            var exerciseFrequency: [UUID: Int] = [:]
            for set in sets {
                exerciseFrequency[set.exerciseId, default: 0] += 1
            }

            // Favorite exercise (most sets)
            var favoriteExercise: (name: String, count: Int)?
            if let topExercise = exerciseFrequency.max(by: { $0.value < $1.value }),
               let exercise = exerciseById[topExercise.key] {
                favoriteExercise = (name: exercise.name, count: topExercise.value)
            }

            // Top 3 exercises
            let sortedExercises = exerciseFrequency.sorted { $0.value > $1.value }
            let topThree = sortedExercises.prefix(3).compactMap { id, count -> (name: String, count: Int)? in
                guard let exercise = exerciseById[id] else { return nil }
                return (name: exercise.name, count: count)
            }

            // Muscle group breakdown
            var muscleGroupVolume: [String: Double] = [:]
            for set in sets {
                guard let weight = set.weight,
                      let reps = set.reps,
                      let exercise = exerciseById[set.exerciseId] else { continue }
                let volume = WeightUnitConverter.volumeInKg(weight, reps: reps, unit: set.unit)
                muscleGroupVolume[exercise.primaryCategory, default: 0] += volume
            }

            let totalMuscleVolume = muscleGroupVolume.values.reduce(0, +)
            var mostTrainedMuscle: (name: String, percentage: Double)?
            if let topMuscle = muscleGroupVolume.max(by: { $0.value < $1.value }), totalMuscleVolume > 0 {
                let percentage = (topMuscle.value / totalMuscleVolume) * 100
                mostTrainedMuscle = (name: topMuscle.key, percentage: percentage)
            }

            // Calculate PRs achieved in the year
            let prCount = calculateYearPRs(sets: sets)

            // Calculate longest streak in the year
            let longestStreak = calculateLongestStreakInYear(dates: uniqueDates, calendar: calendar)

            // Calculate active weeks (weeks with at least one workout)
            let activeWeeks = calculateActiveWeeks(dates: uniqueDates, calendar: calendar)

            // Average workouts per week
            let weeksInYear = 52.0
            let avgWorkoutsPerWeek = Double(totalWorkouts) / weeksInYear

            // Monthly breakdown
            var monthlyWorkouts: [Int: Int] = [:]
            for date in uniqueDates {
                let month = calendar.component(.month, from: date)
                monthlyWorkouts[month, default: 0] += 1
            }
            let monthlyData = (1...12).map { month in
                (month: month, count: monthlyWorkouts[month] ?? 0)
            }

            // Best month
            var bestMonth: (month: Int, workouts: Int)?
            if let best = monthlyWorkouts.max(by: { $0.value < $1.value }) {
                bestMonth = (month: best.key, workouts: best.value)
            }

            // Volume growth from previous year
            let volumeGrowth = calculateVolumeGrowth(currentYearVolume: totalVolume, year: year, modelContext: modelContext)

            return YearInReviewData(
                year: year,
                totalWorkouts: totalWorkouts,
                totalSets: totalSets,
                totalVolume: totalVolume,
                uniqueExercises: uniqueExercisesCount,
                favoriteExercise: favoriteExercise,
                mostTrainedMuscle: mostTrainedMuscle,
                personalRecords: prCount,
                longestStreak: longestStreak,
                activeWeeks: activeWeeks,
                avgWorkoutsPerWeek: avgWorkoutsPerWeek,
                monthlyWorkouts: monthlyData,
                topThreeExercises: Array(topThree),
                volumeGrowth: volumeGrowth,
                bestMonth: bestMonth
            )
        } catch {
            return YearInReviewData(
                year: year,
                totalWorkouts: 0,
                totalSets: 0,
                totalVolume: 0,
                uniqueExercises: 0,
                favoriteExercise: nil,
                mostTrainedMuscle: nil,
                personalRecords: 0,
                longestStreak: 0,
                activeWeeks: 0,
                avgWorkoutsPerWeek: 0,
                monthlyWorkouts: [],
                topThreeExercises: [],
                volumeGrowth: nil,
                bestMonth: nil
            )
        }
    }

    /// Calculate PRs achieved in the given sets
    private func calculateYearPRs(sets: [WorkoutSet]) -> Int {
        // Group by exercise
        var exerciseRecords: [UUID: [(date: Date, volume: Double)]] = [:]

        for set in sets {
            guard let weight = set.weight, let reps = set.reps else { continue }
            let volume = weight * Double(reps)
            exerciseRecords[set.exerciseId, default: []].append((date: set.date, volume: volume))
        }

        var prCount = 0

        for (_, records) in exerciseRecords {
            let sortedRecords = records.sorted { $0.date < $1.date }
            var maxVolumeSoFar: Double = 0

            for record in sortedRecords {
                if record.volume > maxVolumeSoFar {
                    prCount += 1
                    maxVolumeSoFar = record.volume
                }
            }
        }

        return prCount
    }

    /// Calculate longest streak of consecutive workout days in a year
    private func calculateLongestStreakInYear(dates: Set<Date>, calendar: Calendar) -> Int {
        guard !dates.isEmpty else { return 0 }

        let sortedDates = dates.sorted()
        var longestStreak = 1
        var currentStreak = 1

        for i in 1..<sortedDates.count {
            let daysBetween = calendar.dateComponents([.day], from: sortedDates[i-1], to: sortedDates[i]).day ?? 0
            if daysBetween == 1 {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }

        return longestStreak
    }

    /// Calculate number of weeks with at least one workout
    private func calculateActiveWeeks(dates: Set<Date>, calendar: Calendar) -> Int {
        var activeWeekStarts: Set<Date> = []

        for date in dates {
            if let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start {
                activeWeekStarts.insert(weekStart)
            }
        }

        return activeWeekStarts.count
    }

    /// Calculate volume growth percentage from previous year
    private func calculateVolumeGrowth(currentYearVolume: Double, year: Int, modelContext: ModelContext) -> Double? {
        guard currentYearVolume > 0 else { return nil }

        let calendar = Calendar.current

        // Previous year boundaries
        var prevStartComponents = DateComponents()
        prevStartComponents.year = year - 1
        prevStartComponents.month = 1
        prevStartComponents.day = 1
        let prevYearStart = calendar.date(from: prevStartComponents)!

        var prevEndComponents = DateComponents()
        prevEndComponents.year = year
        prevEndComponents.month = 1
        prevEndComponents.day = 1
        let prevYearEnd = calendar.date(from: prevEndComponents)!

        // Fetch previous year sets
        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { set in
                set.isCompleted && set.date >= prevYearStart && set.date < prevYearEnd
            }
        )

        do {
            let prevSets = try modelContext.fetch(descriptor)

            let prevVolume = prevSets.reduce(0.0) { total, set in
                guard let weight = set.weight, let reps = set.reps else { return total }
                return total + WeightUnitConverter.volumeInKg(weight, reps: reps, unit: set.unit)
            }

            guard prevVolume > 0 else { return nil }

            return ((currentYearVolume - prevVolume) / prevVolume) * 100
        } catch {
            return nil
        }
    }
}
