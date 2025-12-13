import SwiftUI
import Charts

// MARK: - TopExercisesView
/// Shows the most frequently performed exercises with tap to view stats
struct TopExercisesView: View {
    let topExercises: [(exercise: Exercise, setCount: Int)]
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @State private var selectedExercise: Exercise?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Exercises")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.textPrimary)

            if topExercises.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.textTertiary.opacity(0.3))

                    Text("No exercises logged yet")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                VStack(spacing: 8) {
                    ForEach(topExercises, id: \.exercise.id) { item in
                        TopExerciseRow(
                            exercise: item.exercise,
                            setCount: item.setCount,
                            onTap: {
                                selectedExercise = item.exercise
                            }
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
        .sheet(item: $selectedExercise) { exercise in
            ExerciseStatsSheet(exercise: exercise, unit: appState.weightUnit)
                .environmentObject(appState)
        }
    }
}

// MARK: - TopExerciseRow
struct TopExerciseRow: View {
    let exercise: Exercise
    let setCount: Int
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)

                    Text(exercise.primaryCategory)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("\(setCount)")
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundColor(.accentPrimary)

                    Text("sets")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.textSecondary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textTertiary)
            }
            .padding(12)
            .background(Color.tertiaryBg)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - ExerciseStatsSheet
struct ExerciseStatsSheet: View {
    let exercise: Exercise
    let unit: String
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private var stats: InsightsService.ExerciseStats {
        InsightsService.shared.getExerciseStats(exerciseId: exercise.id, unit: unit, modelContext: modelContext)
    }

    private func formatWeight(_ value: Double?) -> String {
        guard let value = value else { return "–" }
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))"
        } else {
            return String(format: "%.1f", value)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.primaryBg
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Exercise Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exercise.name)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.textPrimary)

                            Text(exercise.primaryCategory)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.horizontal, 4)

                        // Summary Stats Card
                        SummaryStatsCard(stats: stats, unit: unit)

                        // E1RM Progression Chart
                        if !stats.e1rmProgression.isEmpty {
                            E1RMProgressionChart(data: stats.e1rmProgression, unit: unit)
                        }

                        // Rep Records
                        if !stats.repRecords.isEmpty {
                            RepRecordsView(records: stats.repRecords, unit: unit)
                        }

                        // Recent History
                        if !stats.recentHistory.isEmpty {
                            RecentHistoryView(history: stats.recentHistory)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Exercise Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.accentPrimary)
                }
            }
        }
        .presentationDetents([.large])
        .presentationBackground(Color.primaryBg)
    }
}

// MARK: - SummaryStatsCard
struct SummaryStatsCard: View {
    let stats: InsightsService.ExerciseStats
    let unit: String

    private func formatWeight(_ value: Double?) -> String {
        guard let value = value else { return "–" }
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))"
        } else {
            return String(format: "%.1f", value)
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Top row
            HStack(spacing: 16) {
                StatItem(
                    value: formatWeight(stats.bestWeight) + " \(unit)",
                    label: "Best Weight"
                )

                StatItem(
                    value: stats.bestVolumeSet != nil ?
                        "\(formatWeight(stats.bestVolumeSet?.weight)) × \(stats.bestVolumeSet?.reps ?? 0)" : "–",
                    label: "Best Set"
                )
            }

            // Middle row
            HStack(spacing: 16) {
                StatItem(
                    value: stats.currentE1RM != nil ?
                        "~\(formatWeight(stats.currentE1RM)) \(unit)" : "N/A",
                    label: "Est. 1RM"
                )

                StatItem(
                    value: StatsService.shared.formatVolume(stats.totalVolume),
                    label: "Total Volume"
                )
            }

            // Bottom row
            HStack(spacing: 16) {
                StatItem(
                    value: "\(stats.timesPerformed)",
                    label: "Sessions"
                )

                // Placeholder for symmetry
                StatItem(
                    value: stats.e1rmProgression.count > 1 ? "\(stats.e1rmProgression.count)" : "–",
                    label: "Data Points"
                )
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

// MARK: - StatItem
struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.accentPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - E1RMProgressionChart
struct E1RMProgressionChart: View {
    let data: [(date: Date, e1rm: Double)]
    let unit: String

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Est. 1RM Progression")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.textPrimary)

            Chart {
                ForEach(data.indices, id: \.self) { index in
                    let item = data[index]

                    AreaMark(
                        x: .value("Date", item.date),
                        y: .value("E1RM", item.e1rm)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentPrimary.opacity(0.15), Color.accentPrimary.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("E1RM", item.e1rm)
                    )
                    .foregroundStyle(Color.accentPrimary)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                    PointMark(
                        x: .value("Date", item.date),
                        y: .value("E1RM", item.e1rm)
                    )
                    .foregroundStyle(Color.accentPrimary)
                    .symbolSize(30)
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(dateFormatter.string(from: date))
                                .font(.system(size: 10))
                                .foregroundColor(.textSecondary)
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(0.06))
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                    AxisValueLabel {
                        if let e1rm = value.as(Double.self) {
                            Text("\(Int(e1rm))")
                                .font(.system(size: 10))
                                .foregroundColor(.textSecondary)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.white.opacity(0.06))
                }
            }
            .frame(height: 180)
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

// MARK: - RepRecordsView
struct RepRecordsView: View {
    let records: [Int: Double]
    let unit: String

    private let targetReps = [1, 3, 5, 8, 10, 12]

    private func formatWeight(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))"
        } else {
            return String(format: "%.1f", value)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rep Records")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(targetReps, id: \.self) { reps in
                        RepRecordChip(
                            reps: reps,
                            weight: records[reps],
                            unit: unit
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

// MARK: - RepRecordChip
struct RepRecordChip: View {
    let reps: Int
    let weight: Double?
    let unit: String

    private func formatWeight(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))"
        } else {
            return String(format: "%.1f", value)
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Text("\(reps)RM")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.textSecondary)

            if let weight = weight {
                Text(formatWeight(weight))
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.accentPrimary)

                Text(unit)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.textTertiary)
            } else {
                Text("–")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.textTertiary)
            }
        }
        .frame(width: 60)
        .padding(.vertical, 12)
        .background(Color.tertiaryBg)
        .cornerRadius(10)
    }
}

// MARK: - RecentHistoryView
struct RecentHistoryView: View {
    let history: [(date: Date, sets: Int, bestSet: String)]

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent History")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.textPrimary)

            VStack(spacing: 8) {
                ForEach(history.indices, id: \.self) { index in
                    let session = history[index]
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(dateFormatter.string(from: session.date))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.textPrimary)

                            Text("\(session.sets) sets")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.textSecondary)
                        }

                        Spacer()

                        Text(session.bestSet)
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.textSecondary)
                    }
                    .padding(12)
                    .background(Color.tertiaryBg)
                    .cornerRadius(10)
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

// MARK: - Preview
#Preview {
    let sampleExercise = Exercise(name: "Bench Press", primaryCategory: "Chest")

    return ZStack {
        Color.primaryBg
            .ignoresSafeArea()

        TopExercisesView(topExercises: [
            (exercise: sampleExercise, setCount: 48),
            (exercise: Exercise(name: "Squat", primaryCategory: "Legs"), setCount: 36),
            (exercise: Exercise(name: "Deadlift", primaryCategory: "Back"), setCount: 24)
        ])
        .padding()
        .environmentObject(AppState())
    }
}
