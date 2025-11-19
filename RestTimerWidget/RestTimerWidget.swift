import ActivityKit
import WidgetKit
import SwiftUI

@main
struct RestTimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        RestTimerStaticWidget()
        RestTimerLiveActivityWidget()
    }
}

// MARK: - Static Widget (Required for proper bundle registration)
struct RestTimerStaticWidget: Widget {
    let kind: String = "RestTimerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RestTimerProvider()) { entry in
            RestTimerStaticView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Rest Timer")
        .description("Shows your active rest timer")
        .supportedFamilies([.systemSmall])
    }
}

struct RestTimerEntry: TimelineEntry {
    let date: Date
    let timerEndTime: Date?
    let exerciseName: String?
}

struct RestTimerProvider: TimelineProvider {
    func placeholder(in context: Context) -> RestTimerEntry {
        RestTimerEntry(date: Date(), timerEndTime: nil, exerciseName: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (RestTimerEntry) -> ()) {
        let entry = RestTimerEntry(date: Date(), timerEndTime: nil, exerciseName: nil)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RestTimerEntry>) -> ()) {
        let entry = RestTimerEntry(date: Date(), timerEndTime: nil, exerciseName: nil)
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct RestTimerStaticView: View {
    let entry: RestTimerEntry

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "timer")
                .font(.system(size: 32))
                .foregroundColor(Color(red: 1.0, green: 0.42, blue: 0.21))

            Text("FitNotes")
                .font(.caption.weight(.semibold))
                .foregroundColor(.white)

            if let exerciseName = entry.exerciseName, let endTime = entry.timerEndTime {
                Text(exerciseName)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))

                Text(endTime, style: .timer)
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.white)
            } else {
                Text("No active timer")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding()
    }
}

// MARK: - Live Activity Widget
struct RestTimerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestTimerAttributes.self) { context in
            // Lock screen UI
            RestTimerLockScreenView(context: context)
                .activityBackgroundTint(Color(red: 0.1, green: 0.12, blue: 0.15))
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
                        HStack {
                            Spacer()
                            Link(destination: URL(string: "fitnotes://skip-timer")!) {
                                Text("Skip Rest")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color(red: 1.0, green: 0.42, blue: 0.21)) // accentPrimary
                                    .cornerRadius(12)
                            }
                            Spacer()
                        }
                        .padding(.top, 8)
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    if !context.state.isCompleted {
                        TimerProgressBar(endTime: context.state.endTime, duration: context.state.duration)
                            .frame(height: 8)
                            .padding(.horizontal, 20)
                    }
                }
                
            } compactLeading: {
                // Compact leading
                Image(systemName: "timer")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 1.0, green: 0.42, blue: 0.21))
            } compactTrailing: {
                // Compact trailing - timer text
                if context.state.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                } else {
                    Text(context.state.endTime, style: .timer)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white)
                }
            } minimal: {
                // Minimal view
                Image(systemName: context.state.isCompleted ? "checkmark.circle.fill" : "timer")
                    .font(.system(size: 12))
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
        .padding()
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
