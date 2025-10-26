import Foundation
import SwiftData

// MARK: - StatsService
public final class StatsService {
    public static let shared = StatsService()
    private init() {}
    
    // MARK: - Weeks Active (Current Streak)
    
    /// Calculates the current streak of consecutive weeks with at least one workout
    public func getWeeksActiveStreak(workouts: [Workout]) -> Int {
        guard !workouts.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        var currentWeek = calendar.dateInterval(of: .weekOfYear, for: Date())
        var streak = 0
        var foundWorkout = true
        
        // Start from the current week
        while foundWorkout {
            guard let weekStart = currentWeek?.start,
                  let weekEnd = currentWeek?.end else { break }
            
            foundWorkout = workouts.contains { workout in
                workout.date >= weekStart && workout.date < weekEnd
            }
            
            if foundWorkout {
                streak += 1
                // Move to previous week
                currentWeek = calendar.dateInterval(
                    of: .weekOfYear,
                    for: calendar.date(byAdding: .day, value: -7, to: weekStart)!
                )
            }
        }
        
        return streak
    }
    
    // MARK: - Total Volume
    
    /// Calculates total volume (weight × reps) for all time from workout sets
    public func getTotalVolume(allSets: [WorkoutSet]) -> Double {
        return allSets.reduce(0) { total, set in
            total + (set.weight * Double(set.reps))
        }
    }
    
    /// Formats large numbers with SI units (K, M, B)
    public func formatVolume(_ volume: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        
        switch volume {
        case 0:
            return "0"
        case 1..<1_000:
            return formatNumber(volume)
        case 1_000..<1_000_000:
            return "\(formatter.string(from: NSNumber(value: volume / 1_000)) ?? "0")K"
        case 1_000_000..<1_000_000_000:
            return "\(formatter.string(from: NSNumber(value: volume / 1_000_000)) ?? "0")M"
        default:
            return "\(formatter.string(from: NSNumber(value: volume / 1_000_000_000)) ?? "0")B"
        }
    }
    
    private func formatNumber(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = number.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 1
        return formatter.string(from: NSNumber(value: number)) ?? "0"
    }
    
    // MARK: - Days Since Last Lift
    
    /// Calculates days since the most recent workout with exercises
    public func getDaysSinceLastLift(workouts: [Workout]) -> String {
        guard !workouts.isEmpty else {
            return "Never"
        }
        
        // Find the most recent workout
        let sortedWorkouts = workouts.sorted { $0.date > $1.date }
        guard let mostRecentWorkout = sortedWorkouts.first,
              !mostRecentWorkout.exercises.isEmpty else {
            return "Never"
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let workoutDate = calendar.startOfDay(for: mostRecentWorkout.date)
        
        guard let days = calendar.dateComponents([.day], from: workoutDate, to: today).day else {
            return "Never"
        }
        
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "1 day"
        } else {
            return "\(days) days"
        }
    }
}

