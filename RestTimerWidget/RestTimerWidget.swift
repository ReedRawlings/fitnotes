import ActivityKit
import WidgetKit
import SwiftUI
import os.log

// Logger for widget debugging
private let widgetLogger = Logger(subsystem: "com.fitnotes.widget", category: "DynamicIsland")

// Color extension for vibrant Dynamic Island display
extension Color {
    static let accentPrimary = Color(hex: "#FF6B35")   // Coral-orange for main timer
    static let accentSuccess = Color(hex: "#00D9A3")   // Bright teal for icons

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 255, 255, 255)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

@main
struct RestTimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        RestTimerLiveActivityWidget()
    }
}

struct RestTimerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestTimerAttributes.self) { context in
            // Lock screen UI
            widgetLogger.info("🔒 Rendering Lock Screen view - Exercise: '\(context.attributes.exerciseName)', Set: \(context.state.setNumber), EndTime: \(context.state.endTime)")
            return RestTimerLockScreenView(context: context)
        } dynamicIsland: { context in
            widgetLogger.info("🏝️ Rendering Dynamic Island - Exercise: '\(context.attributes.exerciseName)', Set: \(context.state.setNumber), EndTime: \(context.state.endTime), IsCompleted: \(context.state.isCompleted)")

            return DynamicIsland {
                // Expanded - Exercise name with vibrant timer
                DynamicIslandExpandedRegion(.center) {
                    widgetLogger.info("📱 Rendering expanded center region with exercise '\(context.attributes.exerciseName)' and timer: \(context.state.endTime)")
                    return VStack(spacing: 4) {
                        Text(context.attributes.exerciseName)
                            .font(.caption)
                            .foregroundColor(.accentSuccess)
                            .lineLimit(1)
                        Text(context.state.endTime, style: .timer)
                            .monospacedDigit()
                            .foregroundColor(.accentPrimary)
                            .font(.title)
                    }
                }

            } compactLeading: {
                // Teal timer icon
                widgetLogger.info("🔵 Rendering compact leading view with timer icon")
                return Image(systemName: "timer.circle.fill")
                    .foregroundColor(.accentSuccess)
            } compactTrailing: {
                // Coral timer countdown
                widgetLogger.info("🟢 Rendering compact trailing view with timer text: \(context.state.endTime)")
                return Text(context.state.endTime, style: .timer)
                    .monospacedDigit()
                    .foregroundColor(.accentPrimary)
                    .font(.caption)
            } minimal: {
                // Vibrant icon
                widgetLogger.info("⚪ Rendering minimal view with timer icon")
                return Image(systemName: "timer.circle.fill")
                    .foregroundColor(.accentSuccess)
            }
        }
    }
}

// MARK: - Lock Screen View
struct RestTimerLockScreenView: View {
    let context: ActivityViewContext<RestTimerAttributes>

    var body: some View {
        widgetLogger.info("🔓 Lock screen body rendering - Exercise: '\(context.attributes.exerciseName)', Set: \(context.state.setNumber), Timer: \(context.state.endTime)")
        return HStack(spacing: 16) {
            // Vibrant icon
            Image(systemName: "timer.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.accentSuccess)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.exerciseName)
                    .font(.system(.headline, design: .default))
                    .foregroundColor(.accentPrimary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text("Set \(context.state.setNumber)")
                        .font(.system(.caption, design: .default))
                        .foregroundColor(.accentSuccess)

                    Text(context.state.endTime, style: .timer)
                        .monospacedDigit()
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.accentPrimary)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
}


// MARK: - Preview
#Preview("Live Activity", as: .content, using: RestTimerAttributes(exerciseName: "Bench Press")) {
    RestTimerLiveActivityWidget()
} contentStates: {
    RestTimerAttributes.ContentState(
        setNumber: 3,
        endTime: Date().addingTimeInterval(90),
        duration: 90,
        isCompleted: false
    )

    RestTimerAttributes.ContentState(
        setNumber: 3,
        endTime: Date().addingTimeInterval(30),
        duration: 90,
        isCompleted: false
    )

    RestTimerAttributes.ContentState(
        setNumber: 3,
        endTime: Date(),
        duration: 90,
        isCompleted: true
    )
}
