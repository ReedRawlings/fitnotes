import SwiftUI

// MARK: - MuscleGroupBreakdownView
/// Horizontal bar chart showing volume breakdown by muscle group
struct MuscleGroupBreakdownView: View {
    let breakdown: [(category: String, volume: Double, percentage: Double)]

    private func colorForCategory(_ category: String) -> Color {
        switch category.lowercased() {
        case "chest":
            return Color(hex: "#FF6B35") // Coral
        case "back":
            return Color(hex: "#00D9A3") // Teal
        case "legs", "quads", "hamstrings", "glutes":
            return Color(hex: "#F7931E") // Amber
        case "shoulders":
            return Color(hex: "#5B9FFF") // Blue
        case "arms", "biceps", "triceps":
            return Color(hex: "#BA68C8") // Purple
        case "core", "abs":
            return Color(hex: "#FF7597") // Pink
        case "cardio":
            return Color(hex: "#FF9800") // Orange
        default:
            return .accentPrimary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Title
            Text("Muscle Group Breakdown")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.textPrimary)

            if breakdown.isEmpty {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.textTertiary.opacity(0.3))

                    Text("No data for this period")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                VStack(spacing: 12) {
                    ForEach(breakdown.indices, id: \.self) { index in
                        let item = breakdown[index]
                        MuscleGroupRow(
                            category: item.category,
                            volume: item.volume,
                            percentage: item.percentage,
                            color: colorForCategory(item.category)
                        )
                    }
                }
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

// MARK: - MuscleGroupRow
struct MuscleGroupRow: View {
    let category: String
    let volume: Double
    let percentage: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Category name and stats
            HStack {
                Text(category)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textPrimary)

                Spacer()

                HStack(spacing: 6) {
                    Text(StatsService.shared.formatVolume(volume))
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(.textPrimary)

                    Text("(\(Int(percentage.rounded()))%)")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.textTertiary)
                }
            }

            // Horizontal bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.tertiaryBg)
                        .frame(height: 24)

                    // Filled portion
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color)
                        .frame(width: geometry.size.width * (percentage / 100), height: 24)
                }
            }
            .frame(height: 24)
        }
    }
}

// MARK: - Preview
#Preview {
    let sampleBreakdown = [
        (category: "Chest", volume: 5420.0, percentage: 35.0),
        (category: "Back", volume: 4200.0, percentage: 27.0),
        (category: "Legs", volume: 3100.0, percentage: 20.0),
        (category: "Shoulders", volume: 1800.0, percentage: 12.0),
        (category: "Arms", volume: 900.0, percentage: 6.0)
    ]

    return ZStack {
        Color.primaryBg
            .ignoresSafeArea()

        MuscleGroupBreakdownView(breakdown: sampleBreakdown)
            .padding()
    }
}
