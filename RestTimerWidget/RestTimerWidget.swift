import ActivityKit
import WidgetKit
import SwiftUI
import os.log

// Logger for widget debugging
private let widgetLogger = Logger(subsystem: "com.fitnotes.widget", category: "DynamicIsland")

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
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            widgetLogger.info("🏝️ Rendering Dynamic Island - Exercise: '\(context.attributes.exerciseName)', Set: \(context.state.setNumber), EndTime: \(context.state.endTime), IsCompleted: \(context.state.isCompleted)")

            return DynamicIsland {
                // Expanded - just timer
                DynamicIslandExpandedRegion(.center) {
                    widgetLogger.info("📱 Rendering expanded center region with timer: \(context.state.endTime)")
                    return Text(context.state.endTime, style: .timer)
                        .monospacedDigit()
                        .foregroundColor(.white)
                        .font(.title)
                }

            } compactLeading: {
                // Timer icon
                widgetLogger.info("🔵 Rendering compact leading view with timer icon")
                return Image(systemName: "timer")
                    .foregroundColor(.white)
            } compactTrailing: {
                // Timer countdown
                widgetLogger.info("🟢 Rendering compact trailing view with timer text: \(context.state.endTime)")
                return Text(context.state.endTime, style: .timer)
                    .monospacedDigit()
                    .foregroundColor(.white)
                    .font(.caption)
            } minimal: {
                // Just icon
                widgetLogger.info("⚪ Rendering minimal view with timer icon")
                return Image(systemName: "timer")
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Lock Screen View
struct RestTimerLockScreenView: View {
    let context: ActivityViewContext<RestTimerAttributes>

    var body: some View {
        widgetLogger.info("🔓 Lock screen body rendering - Set: \(context.state.setNumber), Timer: \(context.state.endTime)")
        return HStack {
            Image(systemName: "timer")
            Text(context.state.endTime, style: .timer)
                .monospacedDigit()
                .foregroundColor(.white)
        }
        .padding()
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
