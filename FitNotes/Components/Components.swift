// MARK: - Components.swift
// Central export file for FitNotes Components

import SwiftUI
import UIKit

// MARK: - CardListView
struct CardListView<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content
    
    init(_ items: [Item], @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items
        self.content = content
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                LazyVStack(spacing: 0) {
                    ForEach(items) { item in
                        content(item)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                Spacer(minLength: 100)
            }
        }
    }
}

// MARK: - TrophyView
public struct TrophyView: View {
    public let frame: CGFloat
    public let primaryColor: Color
    public let secondaryColor: Color
    public let tertiaryColor: Color

    public init(frame: CGFloat, primaryColor: Color, secondaryColor: Color, tertiaryColor: Color) {
        self.frame = frame
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.tertiaryColor = tertiaryColor
    }

    public var body: some View {
        ZStack {
            Image(systemName: "trophy.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: frame, height: frame)
                .foregroundColor(primaryColor)
        }
    }
}

// MARK: - EmptyStateView
 struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String?
    let onAction: (() -> Void)?
    
 init(
        icon: String,
        title: String,
        subtitle: String,
        actionTitle: String? = nil,
        onAction: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.onAction = onAction
    }
    
 var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.textTertiary.opacity(0.3))
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            if let actionTitle = actionTitle, let onAction = onAction {
                Button(action: onAction) {
                    HStack {
                        Image(systemName: "plus")
                        Text(actionTitle)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.accentPrimary, .accentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.textInverse)
                    .cornerRadius(16)
                    .shadow(
                        color: .accentPrimary.opacity(0.3),
                        radius: 16,
                        x: 0,
                        y: 4
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .padding()
    }
}



// MARK: - PrimaryActionButton
 struct PrimaryActionButton: View {
    let title: String
    let icon: String
    let onTap: () -> Void
    
 init(title: String, icon: String = "plus", onTap: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.onTap = onTap
    }
    
 var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                
                Text(title)
                    .font(.buttonFont)
            }
            .foregroundColor(.textInverse)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [.accentPrimary, .accentSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .shadow(
                color: .accentPrimary.opacity(0.3),
                radius: 16,
                x: 0,
                y: 4
            )
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Modal Form Components
// Components specifically for modal forms (Add Exercise, Add Routine, etc.)

// MARK: - OptionalLineLimitModifier
struct OptionalLineLimitModifier: ViewModifier {
    let lineLimit: ClosedRange<Int>?
    
    func body(content: Content) -> some View {
        if let range = lineLimit {
            content.lineLimit(range)
        } else {
            content
        }
    }
}

// MARK: - FormSectionCard
struct FormSectionCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.sectionHeader)
                .foregroundColor(.textTertiary)
                .kerning(0.3)
            
            content
        }
        .padding(16)
        .background(Color.secondaryBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - ExpandableSettingsSection
struct ExpandableSettingsSection<Content: View>: View {
    let title: String
    let isExpanded: Bool
    let onToggle: () -> Void
    let content: Content
    
    init(
        title: String,
        isExpanded: Bool,
        onToggle: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.isExpanded = isExpanded
        self.onToggle = onToggle
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header - always visible and fully tappable
            Button(action: {
                withAnimation(.standardSpring) {
                    onToggle()
                }
            }) {
                HStack {
                    Text(title)
                        .font(.bodyFont)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .padding(16)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Content - only visible when expanded
            if isExpanded {
                VStack(spacing: 12) {
                    Divider()
                        .background(Color.white.opacity(0.06))
                        .padding(.horizontal, 16)
                    
                    content
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.secondaryBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - LabeledTextInput
struct LabeledTextInput: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var axis: Axis = .horizontal
    var lineLimit: ClosedRange<Int>? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.textSecondary)

            TextField(placeholder, text: $text, axis: axis)
                .font(.bodyFont)
                .foregroundColor(.textPrimary)
                .padding(12)
                .background(Color.tertiaryBg)
                .cornerRadius(10)
                .modifier(OptionalLineLimitModifier(lineLimit: lineLimit))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        }
    }
}

// MARK: - LabeledMenuPicker
struct LabeledMenuPicker: View {
    let label: String
    let options: [String]
    @Binding var selection: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.textSecondary)
            
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) {
                        selection = option
                    }
                }
            } label: {
                HStack {
                    Text(selection)
                        .font(.bodyFont)
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                .padding(12)
                .background(Color.tertiaryBg)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - StepperRow
struct StepperRow: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let suffix: String
    let step: Int
    
    init(
        label: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        suffix: String = "",
        step: Int = 1
    ) {
        self.label = label
        self._value = value
        self.range = range
        self.suffix = suffix
        self.step = step
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.bodyFont)
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: {
                    if value > range.lowerBound {
                        value -= step
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(value > range.lowerBound ? .accentPrimary : .textTertiary)
                }
                
                Text("\(value)\(suffix)")
                    .font(.system(size: 20, weight: .medium, design: .monospaced))
                    .foregroundColor(.textPrimary)
                    .frame(minWidth: suffix.isEmpty ? 40 : 80)
                
                Button(action: {
                    if value < range.upperBound {
                        value += step
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(value < range.upperBound ? .accentPrimary : .textTertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - DoubleStepperRow
struct DoubleStepperRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let suffix: String
    let step: Double
    
    var body: some View {
        HStack {
            Text(label)
                .font(.bodyFont)
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: {
                    if value > range.lowerBound {
                        value -= step
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(value > range.lowerBound ? .accentPrimary : .textTertiary)
                }
                
                Text(formatValue(value) + suffix)
                    .font(.system(size: 20, weight: .medium, design: .monospaced))
                    .foregroundColor(.textPrimary)
                    .frame(minWidth: 80)
                
                Button(action: {
                    if value < range.upperBound {
                        value += step
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(value < range.upperBound ? .accentPrimary : .textTertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatValue(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))"
        } else {
            return String(format: "%.1f", value)
        }
    }
}

// MARK: - FixedModalCTAButton
struct FixedModalCTAButton: View {
    let title: String
    let icon: String
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            Button(action: action) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                    Text(title)
                        .font(.buttonFont)
                }
                .foregroundColor(.textInverse)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    isEnabled ?
                    LinearGradient(
                        colors: [.accentPrimary, .accentSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(
                        colors: [.disabledOverlay, .disabledOverlay],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
                .shadow(
                    color: isEnabled ? .accentPrimary.opacity(0.3) : .clear,
                    radius: 16,
                    x: 0,
                    y: 4
                )
            }
            .disabled(!isEnabled)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
}

// MARK: - TimePickerModal
struct TimePickerModal: View {
    @Binding var selectedSeconds: Int
    @Binding var isPresented: Bool
    
    @State private var selectedMinutes: Int = 0
    @State private var selectedSecondsValue: Int = 30
    @State private var lastHapticTime: Date = Date()
    
    let minuteOptions = Array(0...10)
    let secondOptions = [0, 15, 30, 45]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .foregroundColor(.textSecondary)
                
                Spacer()
                
                Text("Select Rest Time")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Button("Done") {
                    selectedSeconds = selectedMinutes * 60 + selectedSecondsValue
                    isPresented = false
                }
                .foregroundColor(.accentPrimary)
                .fontWeight(.semibold)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Picker
            HStack(spacing: 0) {
                // Minutes Picker
                Picker("Minutes", selection: $selectedMinutes) {
                    ForEach(minuteOptions, id: \.self) { minute in
                        Text("\(minute)")
                            .tag(minute)
                            .foregroundStyle(.white)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .onChange(of: selectedMinutes) {
                    triggerHapticFeedback()
                }
                
                Text("min")
                    .font(.bodyFont)
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 8)
                
                // Seconds Picker
                Picker("Seconds", selection: $selectedSecondsValue) {
                    ForEach(secondOptions, id: \.self) { second in
                        Text(String(format: "%02d", second))
                            .tag(second)
                            .foregroundStyle(.white)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .onChange(of: selectedSecondsValue) {
                    triggerHapticFeedback()
                }
                
                Text("sec")
                    .font(.bodyFont)
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 8)
            }
            .frame(height: 200)
        }
        .onAppear {
            // Initialize picker values from selectedSeconds
            selectedMinutes = selectedSeconds / 60
            let remainingSeconds = selectedSeconds % 60
            // Round to nearest option
            selectedSecondsValue = secondOptions.min(by: { abs($0 - remainingSeconds) < abs($1 - remainingSeconds) }) ?? 30
        }
    }
    
    private func triggerHapticFeedback() {
        let now = Date()
        // Throttle haptics to avoid overwhelming
        if now.timeIntervalSince(lastHapticTime) > 0.1 {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            lastHapticTime = now
        }
    }
}

// MARK: - View Extension for Corner Radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Insights Components

// MARK: - InsightsPeriod Enum
/// Represents the available time period options for insights filtering
enum InsightsPeriod: Int, CaseIterable {
    case week = 0
    case month = 1
    case threeMonths = 2
    case yearToDate = 3
    case allTime = 4

    var title: String {
        switch self {
        case .week: return "7 Days"
        case .month: return "30 Days"
        case .threeMonths: return "90 Days"
        case .yearToDate: return "YTD"
        case .allTime: return "All Time"
        }
    }

    /// Returns the number of days for this period, or nil for all-time
    var days: Int? {
        let calendar = Calendar.current
        let today = Date()

        switch self {
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        case .yearToDate:
            // Days from January 1 of current year to today
            let yearStart = calendar.date(from: calendar.dateComponents([.year], from: today))!
            let components = calendar.dateComponents([.day], from: yearStart, to: today)
            return (components.day ?? 0) + 1 // +1 to include today
        case .allTime: return nil // Represents no date filter
        }
    }

    /// Returns the number of weeks for weekly aggregation
    var weeks: Int {
        switch self {
        case .week: return 1
        case .month: return 4
        case .threeMonths: return 12
        case .yearToDate:
            let calendar = Calendar.current
            let today = Date()
            let yearStart = calendar.date(from: calendar.dateComponents([.year], from: today))!
            let components = calendar.dateComponents([.weekOfYear], from: yearStart, to: today)
            return max(1, (components.weekOfYear ?? 0) + 1)
        case .allTime: return 52 // Show last 52 weeks for all-time weekly view
        }
    }
}

// MARK: - InsightsPeriodSelector
/// Segmented control for selecting time period in Insights tab
struct InsightsPeriodSelector: View {
    @Binding var selectedPeriod: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(InsightsPeriod.allCases, id: \.rawValue) { period in
                    Button(action: {
                        withAnimation(.standardSpring) {
                            selectedPeriod = period.rawValue
                        }
                    }) {
                        Text(period.title)
                            .font(selectedPeriod == period.rawValue ? .system(size: 14, weight: .semibold) : .system(size: 14, weight: .medium))
                            .foregroundColor(selectedPeriod == period.rawValue ? .textPrimary : .textSecondary)
                            .padding(.horizontal, 16)
                            .frame(height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedPeriod == period.rawValue ? Color.tertiaryBg : Color.clear)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(4)
        }
        .background(Color.secondaryBg)
        .cornerRadius(12)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - StatCardsGridView
/// 2x2 grid of stat cards for Insights dashboard
struct StatCardsGridView: View {
    let workouts: Int
    let sets: Int
    let totalVolume: String
    let prCount: Int

    // Optional comparison data
    var workoutsComparison: InsightsService.PeriodComparison?
    var setsComparison: InsightsService.PeriodComparison?
    var volumeComparison: InsightsService.PeriodComparison?
    var prsComparison: InsightsService.PeriodComparison?

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            // Workouts Card
            StatCardView(
                value: "\(workouts)",
                label: "Workouts",
                comparison: workoutsComparison
            )

            // Sets Card
            StatCardView(
                value: "\(sets)",
                label: "Sets",
                comparison: setsComparison
            )

            // Total Volume Card
            StatCardView(
                value: totalVolume,
                label: "Total Volume",
                comparison: volumeComparison
            )

            // PR Count Card
            StatCardView(
                value: "\(prCount)",
                label: "PRs",
                comparison: prsComparison
            )
        }
    }
}

// MARK: - StatCardView
struct StatCardView: View {
    let value: String
    let label: String
    var comparison: InsightsService.PeriodComparison?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.accentPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer()

                // Delta indicator
                if let comparison = comparison, comparison.hasData {
                    ComparisonDeltaIndicator(percentChange: comparison.percentChange)
                }
            }

            Text(label)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 70)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.secondaryBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - ComparisonDeltaIndicator
/// Shows the percentage change between current and previous period
struct ComparisonDeltaIndicator: View {
    let percentChange: Double?

    private var color: Color {
        guard let change = percentChange else { return .textTertiary }
        if change > 0.5 {
            return Color(hex: "#00D9A3") // Success green
        } else if change < -0.5 {
            return Color(hex: "#FF4444") // Error red
        } else {
            return .textTertiary // Neutral
        }
    }

    private var icon: String {
        guard let change = percentChange else { return "–" }
        if change > 0.5 {
            return "↑"
        } else if change < -0.5 {
            return "↓"
        } else {
            return "–"
        }
    }

    private var text: String {
        guard let change = percentChange else { return "–" }
        if abs(change) < 0.5 {
            return "–"
        }
        return String(format: "%+.0f%%", change)
    }

    var body: some View {
        HStack(spacing: 2) {
            Text(icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(color)

            if percentChange != nil && abs(percentChange!) >= 0.5 {
                Text(text)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(color)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.15))
        .cornerRadius(6)
    }
}

// MARK: - Progressive Overload Nudges
/// Component for displaying real-time volume comparison feedback during workouts
struct VolumeComparisonIndicatorView: View {
    let lastVolume: Double?
    let currentVolume: Double
    let percentChange: Double

    // MARK: - Computed Properties

    private var color: Color {
        if percentChange > 0.5 {
            return .accentSuccess // Green
        } else if percentChange < -0.5 {
            return .errorRed // Red
        } else {
            return .textSecondary.opacity(0.5) // Gray (neutral)
        }
    }

    private var displayPercent: String {
        String(format: "%+.1f%%", percentChange)
    }

    private var icon: String {
        if percentChange > 0.5 {
            return "↑"
        } else if percentChange < -0.5 {
            return "↓"
        } else {
            return "="
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Text(icon)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(color)

            Text(displayPercent)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.tertiaryBg)
        .cornerRadius(6)
    }
}

// MARK: - E1RM Comparison Indicator

struct E1RMComparisonIndicatorView: View {
    let lastE1RM: Double
    let currentE1RM: Double
    let percentChange: Double
    let unit: String

    // MARK: - Computed Properties

    private var color: Color {
        if percentChange > 0.5 {
            return .accentSuccess // Green
        } else if percentChange < -0.5 {
            return .errorRed // Red
        } else {
            return .textSecondary.opacity(0.5) // Gray (neutral)
        }
    }

    private var displayPercent: String {
        String(format: "%+.1f%%", percentChange)
    }

    private var icon: String {
        if percentChange > 0.5 {
            return "↑"
        } else if percentChange < -0.5 {
            return "↓"
        } else {
            return "="
        }
    }

    private var formattedE1RM: String {
        if currentE1RM.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(currentE1RM))"
        } else {
            return String(format: "%.1f", currentE1RM)
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Text("E1RM: ~\(formattedE1RM) \(unit)")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.textSecondary)

            Text(icon)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(color)

            Text(displayPercent)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.tertiaryBg)
        .cornerRadius(6)
    }
}