import ActivityKit
import WidgetKit
import SwiftUI

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
            RestTimerLockScreenView(context: context)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded - hardcoded test
                DynamicIslandExpandedRegion(.center) {
                    Text("90")
                }

            } compactLeading: {
                // Timer icon
                Image(systemName: "timer")
            } compactTrailing: {
                // Hardcoded test text
                Text("90")
            } minimal: {
                // Just icon
                Image(systemName: "timer")
            }
        }
    }
}

// MARK: - Lock Screen View
struct RestTimerLockScreenView: View {
    let context: ActivityViewContext<RestTimerAttributes>

    var body: some View {
        HStack {
            Image(systemName: "timer")
            Text(context.state.endTime, style: .timer)
                .monospacedDigit()
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
