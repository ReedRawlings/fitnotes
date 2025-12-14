import SwiftUI

// MARK: - StreakConsistencyView
/// Shows workout streak and weekly consistency heatmap
struct StreakConsistencyView: View {
    let streakData: InsightsService.StreakData

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Streak Display
            HStack(spacing: 20) {
                // Current Streak
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(streakData.currentStreak)")
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(.accentPrimary)

                        Text(streakData.streakUnit)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }

                    Text("Current Streak")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                // Best Streak
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(streakData.bestStreak)")
                            .font(.system(size: 20, weight: .semibold, design: .monospaced))
                            .foregroundColor(.textPrimary)

                        Text(streakData.streakUnit)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.textTertiary)
                    }

                    Text("Best Streak")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.textSecondary)
                }

                // Streak flame icon
                Image(systemName: streakData.currentStreak > 0 ? "flame.fill" : "flame")
                    .font(.system(size: 24))
                    .foregroundColor(streakData.currentStreak > 0 ? .accentPrimary : .textTertiary)
            }

            // Streak encouragement message
            if streakData.currentStreak > 0 {
                StreakEncouragementBanner(streakData: streakData)
            } else if streakData.lastWorkoutDate != nil {
                WelcomeBackBanner()
            }

            // Weekly Consistency Grid
            VStack(alignment: .leading, spacing: 8) {
                Text("Weekly Activity")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textSecondary)

                ConsistencyGrid(weeklyData: streakData.weeklyConsistency)
            }
        }
        .padding(16)
        .background(Color.secondaryBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - StreakEncouragementBanner
struct StreakEncouragementBanner: View {
    let streakData: InsightsService.StreakData

    private var message: String {
        if streakData.isAtRisk {
            return "Keep your momentum going! Every workout counts."
        } else if streakData.currentStreak >= streakData.bestStreak && streakData.currentStreak > 3 {
            return "You're on fire! This is your best streak ever!"
        } else if streakData.currentStreak >= 7 {
            return "A full week of consistency! Great work!"
        } else if streakData.currentStreak >= 3 {
            return "Building momentum! Keep it up!"
        } else {
            return "Great start! Consistency is key."
        }
    }

    private var backgroundColor: Color {
        if streakData.isAtRisk {
            return Color(hex: "#FFB84D").opacity(0.15)  // Warning amber
        } else {
            return Color.accentSuccess.opacity(0.15)  // Success green
        }
    }

    private var iconColor: Color {
        if streakData.isAtRisk {
            return Color(hex: "#FFB84D")
        } else {
            return Color.accentSuccess
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: streakData.isAtRisk ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(iconColor)

            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textPrimary)

            Spacer()
        }
        .padding(12)
        .background(backgroundColor)
        .cornerRadius(10)
    }
}

// MARK: - WelcomeBackBanner
struct WelcomeBackBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 16))
                .foregroundColor(.accentPrimary)

            Text("Welcome back! Every workout counts—let's start fresh.")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textPrimary)

            Spacer()
        }
        .padding(12)
        .background(Color.accentPrimary.opacity(0.15))
        .cornerRadius(10)
    }
}

// MARK: - ConsistencyGrid
/// GitHub-style contribution graph for weekly workout consistency
struct ConsistencyGrid: View {
    let weeklyData: [(weekStart: Date, workoutCount: Int)]

    private func cellColor(for count: Int) -> Color {
        switch count {
        case 0:
            return Color.tertiaryBg
        case 1...2:
            return Color.accentPrimary.opacity(0.25)
        case 3...4:
            return Color.accentPrimary.opacity(0.5)
        default:
            return Color.accentPrimary.opacity(0.85)
        }
    }

    private var weekFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }

    var body: some View {
        VStack(spacing: 8) {
            // Grid
            HStack(spacing: 4) {
                ForEach(weeklyData.indices, id: \.self) { index in
                    let week = weeklyData[index]
                    ConsistencyCell(
                        workoutCount: week.workoutCount,
                        color: cellColor(for: week.workoutCount)
                    )
                }
            }

            // Legend
            HStack(spacing: 4) {
                Text("Less")
                    .font(.system(size: 10))
                    .foregroundColor(.textTertiary)

                ForEach([0, 2, 4, 5], id: \.self) { count in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(cellColor(for: count))
                        .frame(width: 12, height: 12)
                }

                Text("More")
                    .font(.system(size: 10))
                    .foregroundColor(.textTertiary)

                Spacer()

                // Date range
                if let first = weeklyData.first, let last = weeklyData.last {
                    Text("\(weekFormatter.string(from: first.weekStart)) - \(weekFormatter.string(from: last.weekStart))")
                        .font(.system(size: 10))
                        .foregroundColor(.textTertiary)
                }
            }
        }
    }
}

// MARK: - ConsistencyCell
struct ConsistencyCell: View {
    let workoutCount: Int
    let color: Color

    @State private var isHovered = false

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(color)
            .frame(height: 24)
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
            )
    }
}

// MARK: - Preview
#Preview {
    let sampleData = InsightsService.StreakData(
        currentStreak: 5,
        bestStreak: 12,
        streakUnit: "days",
        isAtRisk: false,
        lastWorkoutDate: Date(),
        weeklyConsistency: [
            (weekStart: Date().addingTimeInterval(-11 * 7 * 24 * 3600), workoutCount: 2),
            (weekStart: Date().addingTimeInterval(-10 * 7 * 24 * 3600), workoutCount: 4),
            (weekStart: Date().addingTimeInterval(-9 * 7 * 24 * 3600), workoutCount: 3),
            (weekStart: Date().addingTimeInterval(-8 * 7 * 24 * 3600), workoutCount: 5),
            (weekStart: Date().addingTimeInterval(-7 * 7 * 24 * 3600), workoutCount: 4),
            (weekStart: Date().addingTimeInterval(-6 * 7 * 24 * 3600), workoutCount: 2),
            (weekStart: Date().addingTimeInterval(-5 * 7 * 24 * 3600), workoutCount: 0),
            (weekStart: Date().addingTimeInterval(-4 * 7 * 24 * 3600), workoutCount: 1),
            (weekStart: Date().addingTimeInterval(-3 * 7 * 24 * 3600), workoutCount: 3),
            (weekStart: Date().addingTimeInterval(-2 * 7 * 24 * 3600), workoutCount: 4),
            (weekStart: Date().addingTimeInterval(-1 * 7 * 24 * 3600), workoutCount: 5),
            (weekStart: Date(), workoutCount: 3)
        ]
    )

    return ZStack {
        Color.primaryBg
            .ignoresSafeArea()

        StreakConsistencyView(streakData: sampleData)
            .padding()
    }
}
