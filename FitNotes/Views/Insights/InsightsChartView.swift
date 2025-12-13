import SwiftUI
import Charts

// MARK: - VolumeChartView
/// Line chart component for displaying volume trends over time
struct VolumeChartView: View {
    let data: [(date: Date, volume: Double)]
    let periodType: PeriodType

    enum PeriodType {
        case week        // 7 days
        case month       // 4-5 weeks
        case threeMonths // 12 weeks
        case yearToDate  // Variable weeks since Jan 1
        case allTime     // All historical data
    }

    private var maxVolume: Double {
        data.map { $0.volume }.max() ?? 0
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        switch periodType {
        case .week:
            formatter.dateFormat = "EEE" // Mon, Tue, etc.
        case .month, .threeMonths:
            formatter.dateFormat = "MMM d" // Jan 1, Jan 8, etc.
        case .yearToDate:
            formatter.dateFormat = "MMM" // Jan, Feb, etc.
        case .allTime:
            formatter.dateFormat = "MMM yy" // Jan 24, Feb 24, etc.
        }
        return formatter
    }

    private var desiredAxisCount: Int {
        switch periodType {
        case .week: return 7
        case .month: return 5
        case .threeMonths: return 6
        case .yearToDate: return 6
        case .allTime: return 6
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Chart Title
            Text("Volume Trend")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.textPrimary)
                .padding(.horizontal, 16)

            if data.isEmpty || maxVolume == 0 {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 32))
                        .foregroundColor(.textTertiary.opacity(0.3))

                    Text("No data for this period")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
            } else {
                Chart {
                    ForEach(data.indices, id: \.self) { index in
                        let item = data[index]

                        // Area fill
                        AreaMark(
                            x: .value("Date", item.date),
                            y: .value("Volume", item.volume)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentPrimary.opacity(0.15), Color.accentPrimary.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        // Line
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Volume", item.volume)
                        )
                        .foregroundStyle(Color.accentPrimary)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))

                        // Points
                        PointMark(
                            x: .value("Date", item.date),
                            y: .value("Volume", item.volume)
                        )
                        .foregroundStyle(Color.accentPrimary)
                        .symbolSize(30)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: desiredAxisCount)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(dateFormatter.string(from: date))
                                    .font(.system(size: 10))
                                    .foregroundColor(.textSecondary)
                            }
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(Color.white.opacity(0.06))
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                        AxisValueLabel {
                            if let volume = value.as(Double.self) {
                                Text(StatsService.shared.formatVolume(volume))
                                    .font(.system(size: 10))
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(0.06))
                    }
                }
                .frame(height: 180)
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 16)
        .background(Color.secondaryBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - Preview
#Preview {
    let sampleData = [
        (date: Date().addingTimeInterval(-6 * 24 * 3600), volume: 1200.0),
        (date: Date().addingTimeInterval(-5 * 24 * 3600), volume: 1500.0),
        (date: Date().addingTimeInterval(-4 * 24 * 3600), volume: 1100.0),
        (date: Date().addingTimeInterval(-3 * 24 * 3600), volume: 1800.0),
        (date: Date().addingTimeInterval(-2 * 24 * 3600), volume: 1600.0),
        (date: Date().addingTimeInterval(-1 * 24 * 3600), volume: 1400.0),
        (date: Date(), volume: 2000.0)
    ]

    return ZStack {
        Color.primaryBg
            .ignoresSafeArea()

        VolumeChartView(data: sampleData, periodType: .week)
            .padding()
    }
}
