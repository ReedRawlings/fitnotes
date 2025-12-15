import SwiftUI

// MARK: - MuscleRecoveryHeatmapView
/// Interactive body diagram showing muscle group recovery status
struct MuscleRecoveryHeatmapView: View {
    let recoveryStatus: [String: InsightsService.MuscleRecoveryStatus]
    @State private var isExpanded = false
    
    /// Ordered list of recovery statuses by how recovered they are (least recovered first)
    private var orderedStatuses: [InsightsService.MuscleRecoveryStatus] {
        recoveryStatus
            .values
            .sorted { $0.recoveryPercentage < $1.recoveryPercentage }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with expand/collapse
            Button(action: {
                withAnimation(.standardSpring) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Muscle Recovery")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.textPrimary)

                        Text("Based on time since last trained")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.textSecondary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                VStack(spacing: 10) {
                    ForEach(orderedStatuses, id: \.muscleGroup) { status in
                        MuscleRecoveryTimelineRow(status: status)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
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

    private var frontMuscleGroups: [MuscleRegion] {
        [
            MuscleRegion(name: "Chest", position: CGPoint(x: 0.5, y: 0.28), size: CGSize(width: 0.35, height: 0.12)),
            MuscleRegion(name: "Shoulders", position: CGPoint(x: 0.5, y: 0.18), size: CGSize(width: 0.5, height: 0.08)),
            MuscleRegion(name: "Arms", position: CGPoint(x: 0.5, y: 0.38), size: CGSize(width: 0.6, height: 0.15)),
            MuscleRegion(name: "Core", position: CGPoint(x: 0.5, y: 0.48), size: CGSize(width: 0.25, height: 0.12)),
            MuscleRegion(name: "Legs", position: CGPoint(x: 0.5, y: 0.72), size: CGSize(width: 0.35, height: 0.25))
        ]
    }

    private var backMuscleGroups: [MuscleRegion] {
        [
            MuscleRegion(name: "Back", position: CGPoint(x: 0.5, y: 0.3), size: CGSize(width: 0.35, height: 0.2)),
            MuscleRegion(name: "Shoulders", position: CGPoint(x: 0.5, y: 0.18), size: CGSize(width: 0.5, height: 0.08)),
            MuscleRegion(name: "Arms", position: CGPoint(x: 0.5, y: 0.42), size: CGSize(width: 0.6, height: 0.12)),
            MuscleRegion(name: "Legs", position: CGPoint(x: 0.5, y: 0.72), size: CGSize(width: 0.35, height: 0.25))
        ]
    }
}

// MARK: - MuscleRegion
struct MuscleRegion {
    let name: String
    let position: CGPoint  // Center position as fraction of body (0-1)
    let size: CGSize       // Size as fraction of body
}

// MARK: - BodyDiagramView
struct BodyDiagramView: View {
    let title: String
    let muscleGroups: [MuscleRegion]
    let recoveryStatus: [String: InsightsService.MuscleRecoveryStatus]
    let onMuscleSelected: (InsightsService.MuscleRecoveryStatus) -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.textSecondary)

            GeometryReader { geometry in
                ZStack {
                    // Body silhouette background
                    BodySilhouette()
                        .fill(Color.tertiaryBg.opacity(0.3))

                    // Muscle region overlays
                    ForEach(muscleGroups, id: \.name) { region in
                        MuscleRegionOverlay(
                            region: region,
                            status: getConsolidatedStatus(for: region.name),
                            geometry: geometry,
                            onTap: { status in
                                onMuscleSelected(status)
                            }
                        )
                    }
                }
            }
            .frame(width: 100, height: 180)
        }
    }

    private func getConsolidatedStatus(for name: String) -> InsightsService.MuscleRecoveryStatus {
        // Consolidate related muscle groups
        let relatedMuscles: [String]
        switch name {
        case "Arms":
            relatedMuscles = ["Arms", "Biceps", "Triceps"]
        case "Legs":
            relatedMuscles = ["Legs", "Quads", "Hamstrings", "Glutes"]
        case "Core":
            relatedMuscles = ["Core", "Abs"]
        default:
            relatedMuscles = [name]
        }

        let statuses = relatedMuscles.compactMap { recoveryStatus[$0] }
        guard let minStatus = statuses.min(by: { $0.recoveryPercentage < $1.recoveryPercentage }) else {
            return InsightsService.MuscleRecoveryStatus(
                muscleGroup: name,
                hoursSinceLastTrained: nil,
                recoveryPercentage: 100,
                setsCompleted: 0,
                lastTrainedDate: nil
            )
        }

        let totalSets = statuses.reduce(0) { $0 + $1.setsCompleted }
        return InsightsService.MuscleRecoveryStatus(
            muscleGroup: name,
            hoursSinceLastTrained: minStatus.hoursSinceLastTrained,
            recoveryPercentage: minStatus.recoveryPercentage,
            setsCompleted: totalSets,
            lastTrainedDate: minStatus.lastTrainedDate
        )
    }
}

// MARK: - MuscleRecoveryTimelineRow
/// Gantt-style row showing time since last trained and time remaining to full recovery
struct MuscleRecoveryTimelineRow: View {
    let status: InsightsService.MuscleRecoveryStatus

    private let fullRecoveryHours: Double = 72

    private var elapsedHours: Double {
        status.hoursSinceLastTrained ?? fullRecoveryHours
    }

    private var remainingHours: Double {
        max(0, fullRecoveryHours - elapsedHours)
    }

    private var elapsedProgress: Double {
        min(1, max(0, elapsedHours / fullRecoveryHours))
    }

    private var timeSinceText: String {
        guard let hours = status.hoursSinceLastTrained else {
            return "Not trained recently"
        }

        if hours < 1 {
            return "Just trained"
        } else if hours < 24 {
            return "\(Int(hours))h ago"
        } else {
            let days = Int(hours / 24)
            return days == 1 ? "1 day ago" : "\(days) days ago"
        }
    }

    private var restRemainingText: String {
        if remainingHours == 0 {
            return "Fully recovered"
        }

        if remainingHours < 24 {
            return String(format: "~%.0fh to fully recovered", remainingHours)
        } else {
            let days = remainingHours / 24
            return String(format: "~%.1fd to fully recovered", days)
        }
    }

    private var recoveryColor: Color {
        let rgb = status.recoveryColorRGB
        return Color(red: rgb.red, green: rgb.green, blue: rgb.blue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(status.muscleGroup)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textPrimary)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(timeSinceText)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.textSecondary)

                    Text(restRemainingText)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.textSecondary.opacity(0.8))
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Full 72h window
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.tertiaryBg)
                        .frame(height: 8)

                    // Elapsed recovery time
                    RoundedRectangle(cornerRadius: 4)
                        .fill(recoveryColor)
                        .frame(width: geometry.size.width * elapsedProgress, height: 8)
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: elapsedProgress)
                }
            }
            .frame(height: 8)
        }
        .padding(10)
        .background(Color.tertiaryBg.opacity(0.7))
        .cornerRadius(12)
    }
}

// MARK: - MuscleRegionOverlay
struct MuscleRegionOverlay: View {
    let region: MuscleRegion
    let status: InsightsService.MuscleRecoveryStatus
    let geometry: GeometryProxy
    let onTap: (InsightsService.MuscleRecoveryStatus) -> Void

    @State private var isPressed = false

    private var recoveryColor: Color {
        let rgb = status.recoveryColorRGB
        return Color(red: rgb.red, green: rgb.green, blue: rgb.blue)
    }

    var body: some View {
        let width = geometry.size.width * region.size.width
        let height = geometry.size.height * region.size.height
        let x = geometry.size.width * region.position.x - width / 2
        let y = geometry.size.height * region.position.y - height / 2

        RoundedRectangle(cornerRadius: 6)
            .fill(recoveryColor.opacity(0.6))
            .frame(width: width, height: height)
            .position(x: x + width / 2, y: y + height / 2)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onTapGesture {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                onTap(status)
            }
            .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
                isPressed = pressing
            }, perform: {})
    }
}

// MARK: - BodySilhouette
struct BodySilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        // Simplified body outline
        // Head
        path.addEllipse(in: CGRect(x: width * 0.35, y: height * 0.02, width: width * 0.3, height: height * 0.1))

        // Neck
        path.addRect(CGRect(x: width * 0.42, y: height * 0.11, width: width * 0.16, height: height * 0.04))

        // Torso
        path.addRoundedRect(in: CGRect(x: width * 0.28, y: height * 0.15, width: width * 0.44, height: height * 0.38), cornerSize: CGSize(width: 12, height: 12))

        // Left arm
        path.addRoundedRect(in: CGRect(x: width * 0.1, y: height * 0.18, width: width * 0.15, height: height * 0.32), cornerSize: CGSize(width: 8, height: 8))

        // Right arm
        path.addRoundedRect(in: CGRect(x: width * 0.75, y: height * 0.18, width: width * 0.15, height: height * 0.32), cornerSize: CGSize(width: 8, height: 8))

        // Left leg
        path.addRoundedRect(in: CGRect(x: width * 0.28, y: height * 0.54, width: width * 0.18, height: height * 0.44), cornerSize: CGSize(width: 8, height: 8))

        // Right leg
        path.addRoundedRect(in: CGRect(x: width * 0.54, y: height * 0.54, width: width * 0.18, height: height * 0.44), cornerSize: CGSize(width: 8, height: 8))

        return path
    }
}

// MARK: - LegendItem
struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .foregroundColor(.textSecondary)
        }
    }
}

// MARK: - MuscleDetailCard
struct MuscleDetailCard: View {
    let status: InsightsService.MuscleRecoveryStatus

    private var recoveryColor: Color {
        let rgb = status.recoveryColorRGB
        return Color(red: rgb.red, green: rgb.green, blue: rgb.blue)
    }

    private var timeText: String {
        guard let hours = status.hoursSinceLastTrained else {
            return "Not trained recently"
        }

        if hours < 1 {
            return "Just trained"
        } else if hours < 24 {
            return "\(Int(hours))h ago"
        } else {
            let days = Int(hours / 24)
            return days == 1 ? "1 day ago" : "\(days) days ago"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Recovery indicator
            Circle()
                .fill(recoveryColor)
                .frame(width: 40, height: 40)
                .overlay(
                    Text("\(Int(status.recoveryPercentage))%")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.textInverse)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(status.muscleGroup)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.textPrimary)

                HStack(spacing: 8) {
                    Text(timeText)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.textSecondary)

                    if status.setsCompleted > 0 {
                        Text("\(status.setsCompleted) sets")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                }
            }

            Spacer()
        }
        .padding(12)
        .background(Color.tertiaryBg)
        .cornerRadius(12)
    }
}

// MARK: - Preview
#Preview {
    let sampleStatus: [String: InsightsService.MuscleRecoveryStatus] = [
        "Chest": InsightsService.MuscleRecoveryStatus(muscleGroup: "Chest", hoursSinceLastTrained: 12, recoveryPercentage: 20, setsCompleted: 16, lastTrainedDate: Date().addingTimeInterval(-12 * 3600)),
        "Back": InsightsService.MuscleRecoveryStatus(muscleGroup: "Back", hoursSinceLastTrained: 48, recoveryPercentage: 80, setsCompleted: 20, lastTrainedDate: Date().addingTimeInterval(-48 * 3600)),
        "Shoulders": InsightsService.MuscleRecoveryStatus(muscleGroup: "Shoulders", hoursSinceLastTrained: 36, recoveryPercentage: 60, setsCompleted: 12, lastTrainedDate: Date().addingTimeInterval(-36 * 3600)),
        "Arms": InsightsService.MuscleRecoveryStatus(muscleGroup: "Arms", hoursSinceLastTrained: 72, recoveryPercentage: 100, setsCompleted: 8, lastTrainedDate: Date().addingTimeInterval(-72 * 3600)),
        "Legs": InsightsService.MuscleRecoveryStatus(muscleGroup: "Legs", hoursSinceLastTrained: nil, recoveryPercentage: 100, setsCompleted: 0, lastTrainedDate: nil),
        "Core": InsightsService.MuscleRecoveryStatus(muscleGroup: "Core", hoursSinceLastTrained: 24, recoveryPercentage: 40, setsCompleted: 6, lastTrainedDate: Date().addingTimeInterval(-24 * 3600))
    ]

    return ZStack {
        Color.primaryBg
            .ignoresSafeArea()

        MuscleRecoveryHeatmapView(recoveryStatus: sampleStatus)
            .padding()
    }
}
