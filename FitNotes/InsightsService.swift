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
    ///   - days: Number of days to fetch (typically 7 for week view)
    ///   - modelContext: SwiftData model context
    /// - Returns: Array of (date, volume) tuples sorted by date ascending
    public func getVolumeTrendForPeriod(days: Int, modelContext: ModelContext) -> [(date: Date, volume: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -days, to: today)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        // Fetch all completed sets in the period
        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { set in
                set.isCompleted && set.date >= startDate && set.date < tomorrow
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )

        do {
            let sets = try modelContext.fetch(descriptor)

            // Group by day and calculate volume
            var dailyVolumes: [Date: Double] = [:]

            for set in sets {
                let dayStart = calendar.startOfDay(for: set.date)

                if let weight = set.weight, let reps = set.reps {
                    let volume = weight * Double(reps)
                    dailyVolumes[dayStart, default: 0] += volume
                }
            }

            // Create array with all days in range (including zero-volume days)
            var result: [(date: Date, volume: Double)] = []
            for dayOffset in 0..<days {
                if let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) {
                    let volume = dailyVolumes[date] ?? 0
                    result.append((date: date, volume: volume))
                }
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
    ///   - modelContext: SwiftData model context
    /// - Returns: Array of (weekStart, volume) tuples sorted by week ascending
    public func getWeeklyVolumeTrendForPeriod(weeks: Int, modelContext: ModelContext) -> [(weekStart: Date, volume: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .weekOfYear, value: -weeks, to: today)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        // Fetch all completed sets in the period
        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { set in
                set.isCompleted && set.date >= startDate && set.date < tomorrow
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )

        do {
            let sets = try modelContext.fetch(descriptor)

            // Group by week and calculate volume
            var weeklyVolumes: [Date: Double] = [:]

            for set in sets {
                if let weekStart = calendar.dateInterval(of: .weekOfYear, for: set.date)?.start {
                    if let weight = set.weight, let reps = set.reps {
                        let volume = weight * Double(reps)
                        weeklyVolumes[weekStart, default: 0] += volume
                    }
                }
            }

            // Create array with all weeks in range
            var result: [(weekStart: Date, volume: Double)] = []
            var currentDate = startDate

            while currentDate < tomorrow {
                if let weekStart = calendar.dateInterval(of: .weekOfYear, for: currentDate)?.start {
                    let volume = weeklyVolumes[weekStart] ?? 0
                    result.append((weekStart: weekStart, volume: volume))

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

            return result.sorted { $0.weekStart < $1.weekStart }
        } catch {
            print("Error fetching weekly volume trend: \(error)")
            return []
        }
    }

    // MARK: - Aggregate Stats

    /// Count unique dates with at least one completed set
    public func getWorkoutCount(days: Int, modelContext: ModelContext) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -days, to: today)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { set in
                set.isCompleted && set.date >= startDate && set.date < tomorrow
            }
        )

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
    public func getSetCount(days: Int, modelContext: ModelContext) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -days, to: today)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { set in
                set.isCompleted && set.date >= startDate && set.date < tomorrow
            }
        )

        do {
            let sets = try modelContext.fetch(descriptor)
            return sets.count
        } catch {
            print("Error fetching set count: \(error)")
            return 0
        }
    }

    /// Sum of (weight × reps) for all completed sets
    public func getTotalVolume(days: Int, modelContext: ModelContext) -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -days, to: today)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { set in
                set.isCompleted && set.date >= startDate && set.date < tomorrow
            }
        )

        do {
            let sets = try modelContext.fetch(descriptor)

            return sets.reduce(0) { total, set in
                guard let weight = set.weight, let reps = set.reps else {
                    return total
                }
                return total + (weight * Double(reps))
            }
        } catch {
            print("Error fetching total volume: \(error)")
            return 0
        }
    }

    /// Count of exercises that achieved a new personal record in period
    public func getPRCount(days: Int, modelContext: ModelContext) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -days, to: today)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

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
                let periodRecords = sortedRecords.filter { $0.date >= startDate && $0.date < tomorrow }
                guard let maxInPeriod = periodRecords.map({ $0.volume }).max() else { continue }

                // Find max volume before period
                let beforeRecords = sortedRecords.filter { $0.date < startDate }
                let maxBefore = beforeRecords.map({ $0.volume }).max() ?? 0

                // If period max is greater, it's a PR
                if maxInPeriod > maxBefore {
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
    public func getMuscleGroupBreakdown(days: Int, modelContext: ModelContext) -> [(category: String, volume: Double, percentage: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -days, to: today)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        // Fetch all completed sets in period
        let setsDescriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { set in
                set.isCompleted && set.date >= startDate && set.date < tomorrow
            }
        )

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

                let volume = weight * Double(reps)
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
    public func getRecentPRs(limit: Int = 10, modelContext: ModelContext) -> [(exerciseName: String, weight: Double, reps: Int, date: Date, oneRM: Double)] {
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
            var prs: [(exerciseName: String, weight: Double, reps: Int, date: Date, oneRM: Double)] = []

            for (exerciseId, records) in exerciseRecords {
                guard let exercise = exerciseById[exerciseId] else { continue }

                let sortedRecords = records.sorted { $0.date < $1.date }

                var maxVolumeSoFar: Double = 0

                for record in sortedRecords {
                    if record.volume > maxVolumeSoFar {
                        // This is a PR
                        let oneRM = calculateOneRM(weight: record.weight, reps: record.reps)
                        prs.append((
                            exerciseName: exercise.name,
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
}
