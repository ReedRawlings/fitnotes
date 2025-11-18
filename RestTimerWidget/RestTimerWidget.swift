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
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view
                DynamicIslandExpandedRegion(.leading) {
                    Text("Set \(context.state.setNumber)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TimerText(endTime: context.state.endTime, isCompleted: context.state.isCompleted)
                        .font(.title2.monospacedDigit().weight(.semibold))
                        .multilineTextAlignment(.trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Spacer()
                        Link(destination: URL(string: "fitnotes://skip-timer")!) {
                            Text("Skip")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        Spacer()
                    }
                    .padding(.top, 8)
                }
            } compactLeading: {
                // Compact leading (minimal state)
                Image(systemName: "timer")
                    .foregroundColor(.blue)
            } compactTrailing: {
                // Compact trailing - just the timer
                TimerText(endTime: context.state.endTime, isCompleted: context.state.isCompleted)
                    .font(.caption2.monospacedDigit().weight(.medium))
            } minimal: {
                // Minimal view - just an icon
                Image(systemName: "timer")
                    .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - Lock Screen View
struct RestTimerLockScreenView: View {
    let context: ActivityViewContext<RestTimerAttributes>

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Set \(context.state.setNumber)")
                    .font(.headline)
                    .foregroundColor(.primary)

                if context.state.isCompleted {
                    Text("Rest Complete!")
                        .font(.subheadline)
                        .foregroundColor(.green)
                } else {
                    TimerText(endTime: context.state.endTime, isCompleted: context.state.isCompleted)
                        .font(.title.monospacedDigit().weight(.bold))
                        .foregroundColor(.blue)
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
        .padding()
        .activityBackgroundTint(Color(white: 0.1))
    }
}

// MARK: - Timer Text Component
struct TimerText: View {
    let endTime: Date
    let isCompleted: Bool

    var body: some View {
        if isCompleted {
            Text("0:00")
        } else {
            Text(timerInterval: endTime, countsDown: true)
        }
    }
}

// MARK: - Timer Progress Circle
struct TimerProgressCircle: View {
    let endTime: Date
    let duration: TimeInterval

    @State private var progress: Double = 0

    private var timeRemaining: TimeInterval {
        max(0, endTime.timeIntervalSinceNow)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 6)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: progress)
        }
        .onAppear {
            updateProgress()
        }
        .onChange(of: endTime) { _, _ in
            updateProgress()
        }
    }

    private func updateProgress() {
        let elapsed = duration - timeRemaining
        progress = min(1.0, max(0.0, elapsed / duration))
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
