import SwiftUI

// MARK: - RecentPRsListView
/// Scrollable list of recent personal records
struct RecentPRsListView: View {
    let prs: [(exercise: Exercise, weight: Double, reps: Int, date: Date, oneRM: Double)]
    let unit: String // "kg" or "lbs"
    @EnvironmentObject var appState: AppState

    private func formatDateAgo(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: date, to: now)

        if let days = components.day {
            if days == 0 {
                return "Today"
            } else if days == 1 {
                return "1 day ago"
            } else if days < 7 {
                return "\(days) days ago"
            } else if days < 30 {
                let weeks = days / 7
                return weeks == 1 ? "1 week ago" : "\(weeks) weeks ago"
            } else {
                let months = days / 30
                return months == 1 ? "1 month ago" : "\(months) months ago"
            }
        }
        return "Recently"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Title
            Text("Recent Personal Records")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.textPrimary)

            if prs.isEmpty {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.textTertiary.opacity(0.3))

                    Text("No personal records yet")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                VStack(spacing: 8) {
                    ForEach(prs.indices, id: \.self) { index in
                        let pr = prs[index]
                        PRRowView(
                            exercise: pr.exercise,
                            weight: pr.weight,
                            reps: pr.reps,
                            date: pr.date,
                            oneRM: pr.oneRM,
                            unit: unit,
                            dateAgo: formatDateAgo(pr.date),
                            appState: appState
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

// MARK: - PRRowView
struct PRRowView: View {
    let exercise: Exercise
    let weight: Double
    let reps: Int
    let date: Date
    let oneRM: Double
    let unit: String
    let dateAgo: String
    let appState: AppState

    private func formatWeight(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))"
        } else {
            return String(format: "%.1f", value)
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Trophy icon
            Image(systemName: "trophy.fill")
                .font(.system(size: 16))
                .foregroundColor(.accentPrimary)
                .frame(width: 24, height: 24)
                .padding(.top, 2)

            // Exercise info
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)

                // Weight and reps
                Text("\(formatWeight(weight)) \(unit) × \(reps)")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.textPrimary)

                // 1RM estimate
                Text("~\(formatWeight(oneRM)) \(unit) 1RM")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            // Date badge
            Text(dateAgo)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.textTertiary)
                .padding(.top, 2)
        }
        .padding(12)
        .background(Color.tertiaryBg)
        .cornerRadius(12)
        .onTapGesture {
            appState.selectedExercise = exercise
        }
    }
}

// MARK: - Preview
#Preview {
    let sampleExercises = [
        Exercise(name: "Bench Press", primaryCategory: "Chest"),
        Exercise(name: "Squat", primaryCategory: "Legs"),
        Exercise(name: "Deadlift", primaryCategory: "Back"),
        Exercise(name: "Overhead Press", primaryCategory: "Shoulders")
    ]

    let samplePRs = [
        (exercise: sampleExercises[0], weight: 100.0, reps: 5, date: Date().addingTimeInterval(-2 * 24 * 3600), oneRM: 116.7),
        (exercise: sampleExercises[1], weight: 140.0, reps: 8, date: Date().addingTimeInterval(-5 * 24 * 3600), oneRM: 177.3),
        (exercise: sampleExercises[2], weight: 180.0, reps: 3, date: Date().addingTimeInterval(-7 * 24 * 3600), oneRM: 198.0),
        (exercise: sampleExercises[3], weight: 60.0, reps: 10, date: Date().addingTimeInterval(-14 * 24 * 3600), oneRM: 80.0)
    ]

    return ZStack {
        Color.primaryBg
            .ignoresSafeArea()

        ScrollView {
            RecentPRsListView(prs: samplePRs, unit: "kg")
                .padding()
                .environmentObject(AppState())
        }
    }
}
