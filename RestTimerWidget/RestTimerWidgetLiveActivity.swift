//
//  RestTimerWidgetLiveActivity.swift
//  RestTimerWidget
//
//  Live Activity for rest timer - displays countdown in Dynamic Island and Lock Screen
//
//  NOTE: RestTimerWidgetAttributes is defined in RestTimerActivityAttributes.swift
//        which must be added to BOTH the FitNotes and RestTimerWidget targets
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Live Activity Widget
struct RestTimerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestTimerWidgetAttributes.self) { context in
            // Lock Screen / Banner UI
            LockScreenTimerView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Dynamic Island (when long-pressed)
                DynamicIslandExpandedRegion(.center) {
                    HStack(spacing: 12) {
                        Image(systemName: "timer")
                            .font(.system(size: 20))
                            .foregroundColor(.orange)

                        if context.state.isCompleted {
                            Text("Rest Complete!")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.green)
                        } else {
                            Text(context.state.endTime, style: .timer)
                                .font(.system(size: 32, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .monospacedDigit()
                        }
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.attributes.exerciseName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            } compactLeading: {
                // Compact leading - timer icon
                Image(systemName: "timer")
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
            } compactTrailing: {
                // Compact trailing - just the countdown
                if context.state.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                } else {
                    Text(context.state.endTime, style: .timer)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .monospacedDigit()
                }
            } minimal: {
                // Minimal view (when other activities are present)
                if context.state.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                } else {
                    Text(context.state.endTime, style: .timer)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.orange)
                        .monospacedDigit()
                }
            }
            .keylineTint(.orange)
        }
    }
}

// MARK: - Lock Screen View
struct LockScreenTimerView: View {
    let context: ActivityViewContext<RestTimerWidgetAttributes>

    var body: some View {
        HStack(spacing: 16) {
            // Left side - Exercise info
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.exerciseName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text("Set \(context.attributes.setNumber) complete")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            // Right side - Timer
            if context.state.isCompleted {
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.green)
                    Text("Rest Complete")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                }
            } else {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(context.state.endTime, style: .timer)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .monospacedDigit()
                    Text("remaining")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .activityBackgroundTint(Color.black.opacity(0.8))
        .activitySystemActionForegroundColor(.white)
    }
}

// MARK: - Previews
#Preview("Notification", as: .content, using: RestTimerWidgetAttributes(
    exerciseName: "Bench Press",
    setNumber: 3,
    duration: 90
)) {
    RestTimerWidgetLiveActivity()
} contentStates: {
    RestTimerWidgetAttributes.ContentState(
        endTime: Date().addingTimeInterval(60),
        isCompleted: false
    )
    RestTimerWidgetAttributes.ContentState(
        endTime: Date(),
        isCompleted: true
    )
}
