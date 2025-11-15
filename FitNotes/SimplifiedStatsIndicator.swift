import SwiftUI

struct SimplifiedStatsIndicator: View {
    let volumeChange: Double?
    let e1rmChange: Double?

    var body: some View {
        HStack(spacing: 12) {
            // Volume indicator
            if let volumeChange = volumeChange {
                HStack(spacing: 4) {
                    Text("Vol:")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textSecondary)

                    Text(arrow(for: volumeChange))
                        .font(.system(size: 13))
                        .foregroundColor(color(for: volumeChange))

                    Text(String(format: "%.1f%%", abs(volumeChange)))
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(color(for: volumeChange))
                }
            }

            // Separator
            if volumeChange != nil && e1rmChange != nil {
                Text("|")
                    .font(.system(size: 13))
                    .foregroundColor(.textTertiary)
            }

            // E1RM indicator
            if let e1rmChange = e1rmChange {
                HStack(spacing: 4) {
                    Text("E1RM:")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textSecondary)

                    Text(arrow(for: e1rmChange))
                        .font(.system(size: 13))
                        .foregroundColor(color(for: e1rmChange))

                    Text(String(format: "%.1f%%", abs(e1rmChange)))
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(color(for: e1rmChange))
                }
            }
        }
    }

    // Arrow logic: > 2% = ↑, < -2% = ↓, otherwise →
    private func arrow(for change: Double) -> String {
        if change > 2.0 {
            return "↑"
        } else if change < -2.0 {
            return "↓"
        } else {
            return "→"
        }
    }

    // Colors: green (positive), red (negative), gray (neutral)
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
