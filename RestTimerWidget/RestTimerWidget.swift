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
                // Expanded view
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.attributes.exerciseName)
                            .font(.caption.weight(.medium))
                            .foregroundColor(.white)

                        Text("Set \(context.state.setNumber)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isCompleted {
                        Text("Done!")
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.green)
                    } else {
                        Text(context.state.endTime, style: .timer)
                            .font(.title2.monospacedDigit().weight(.semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    if !context.state.isCompleted {
                        Link(destination: URL(string: "fitnotes://skip-timer")!) {
                            Text("Skip Rest")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color(red: 1.0, green: 0.42, blue: 0.21))
                                .cornerRadius(12)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    if !context.state.isCompleted {
                        TimerProgressBar(endTime: context.state.endTime, duration: context.state.duration)
                            .frame(height: 8)
                    }
                }
                
            } compactLeading: {
                // Compact leading
                Image(systemName: "timer")
                    .foregroundColor(Color(red: 1.0, green: 0.42, blue: 0.21))
            } compactTrailing: {
                // Compact trailing - timer text
                if context.state.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption2)
                } else {
                    Text(context.state.endTime, style: .timer)
                        .font(.caption2.monospacedDigit().weight(.semibold))
                        .foregroundColor(.white)
                }
            } minimal: {
                // Minimal view
                Image(systemName: context.state.isCompleted ? "checkmark.circle.fill" : "timer")
                    .foregroundColor(context.state.isCompleted ? .green : Color(red: 1.0, green: 0.42, blue: 0.21))
            }
        }
    }
}

// MARK: - Lock Screen View
struct RestTimerLockScreenView: View {
    let context: ActivityViewContext<RestTimerAttributes>

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(context.attributes.exerciseName)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
                
                Text("Set \(context.state.setNumber)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))

                if context.state.isCompleted {
                    Text("Rest Complete! 🎉")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.green)
                        .padding(.top, 4)
                } else {
                    Text(context.state.endTime, style: .timer)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white)
                        .padding(.top, 2)
                }
            }

            Spacer()

            // Progress circle
            if !context.state.isCompleted {
                TimerProgressCircle(endTime: context.state.endTime, duration: context.state.duration)
                    .frame(width: 60, height: 60)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.14, blue: 0.18),
                    Color(red: 0.08, green: 0.10, blue: 0.13)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .cornerRadius(16)
    }
}

// MARK: - Timer Progress Bar (for Dynamic Island)
struct TimerProgressBar: View {
    let endTime: Date
    let duration: TimeInterval

    var progress: Double {
        let elapsed = duration - max(0, endTime.timeIntervalSinceNow)
        return min(1.0, max(0.0, elapsed / duration))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.2))
                
                // Progress fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.42, blue: 0.21),
                                Color(red: 0.97, green: 0.58, blue: 0.12)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress)
            }
        }
    }
}

// MARK: - Timer Progress Circle
struct TimerProgressCircle: View {
    let endTime: Date
    let duration: TimeInterval

    var progress: Double {
        let elapsed = duration - max(0, endTime.timeIntervalSinceNow)
        return min(1.0, max(0.0, elapsed / duration))
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 6)

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.42, blue: 0.21),
                            Color(red: 0.97, green: 0.58, blue: 0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
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
