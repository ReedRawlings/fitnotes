import SwiftUI
import SwiftData

struct ExerciseStatsView: View {
    @Bindable var exercise: Exercise
    let currentVolume: Double
    let lastVolume: Double?
    let currentE1RM: Double?
    let lastE1RM: Double?
    let unit: String

    // Computed properties for change percentages
    private var volumeChange: Double? {
        guard let lastVol = lastVolume, lastVol > 0 else { return nil }
        return ((currentVolume - lastVol) / lastVol) * 100
    }

    private var e1rmChange: Double? {
        guard let current = currentE1RM, let last = lastE1RM, last > 0 else { return nil }
        return ((current - last) / last) * 100
    }

    // Determine if the view should be expanded
    private var isExpanded: Bool {
        switch exercise.statsDisplayPreference {
        case .alwaysCollapsed:
            return false
        case .alwaysExpanded:
            return true
        case .rememberLastState:
            return exercise.statsIsExpanded
        }
    }

    // Determine if tap is allowed (only for rememberLastState)
    private var canToggle: Bool {
        exercise.statsDisplayPreference == .rememberLastState
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header row (always visible)
            Button(action: {
                if canToggle {
                    exercise.statsIsExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    // Simplified stats indicator
                    SimplifiedStatsIndicator(
                        volumeChange: volumeChange,
                        e1rmChange: e1rmChange
                    )

                    Spacer()

                    // Chevron indicator (only show if can toggle)
                    if canToggle {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.textTertiary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.secondaryBg)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!canToggle)

            // Expanded details
            if isExpanded {
                VStack(spacing: 12) {
                    Divider()
                        .background(Color.white.opacity(0.06))

                    // Volume row
                    statsRow(
                        title: "Volume",
                        lastValue: lastVolume,
                        currentValue: currentVolume,
                        changePercent: volumeChange,
                        unit: unit,
                        showDecimals: true
                    )

                    // E1RM row
                    if let currentE1RM = currentE1RM {
                        statsRow(
                            title: "E1RM",
                            lastValue: lastE1RM,
                            currentValue: currentE1RM,
                            changePercent: e1rmChange,
                            unit: unit,
                            showDecimals: false
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .background(Color.secondaryBg)
            }
        }
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func statsRow(
        title: String,
        lastValue: Double?,
        currentValue: Double,
        changePercent: Double?,
        unit: String,
        showDecimals: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.textTertiary)
                .textCase(.uppercase)
                .kerning(0.3)

            HStack(spacing: 16) {
                // Last session value
                VStack(alignment: .leading, spacing: 2) {
                    Text("Last")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.textTertiary)

                    if let lastValue = lastValue {
                        Text(formatValue(lastValue, showDecimals: showDecimals) + " " + unit)
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundColor(.textSecondary)
                    } else {
                        Text("—")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.textTertiary)
                    }
                }

                // Arrow indicator
                Image(systemName: "arrow.right")
                    .font(.system(size: 12))
                    .foregroundColor(.textTertiary)

                // Current session value
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.textTertiary)

                    Text(formatValue(currentValue, showDecimals: showDecimals) + " " + unit)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(.textPrimary)
                }

                Spacer()

                // Change percentage
                if let changePercent = changePercent {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Change")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.textTertiary)

                        HStack(spacing: 4) {
                            Text(arrow(for: changePercent))
                                .font(.system(size: 14))
                                .foregroundColor(color(for: changePercent))

                            Text(String(format: "%.1f%%", abs(changePercent)))
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundColor(color(for: changePercent))
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color.tertiaryBg)
        .cornerRadius(8)
    }

    private func formatValue(_ value: Double, showDecimals: Bool) -> String {
        if showDecimals {
            return String(format: "%.1f", value)
        } else {
            return String(format: "%.0f", value)
        }
    }

    private func arrow(for change: Double) -> String {
        if change > 2.0 {
            return "↑"
        } else if change < -2.0 {
            return "↓"
        } else {
            return "→"
        }
    }

    private func color(for change: Double) -> Color {
        if change > 2.0 {
            return .accentSuccess
        } else if change < -2.0 {
            return .errorRed
        } else {
            return .textSecondary.opacity(0.6)
        }
    }
}
