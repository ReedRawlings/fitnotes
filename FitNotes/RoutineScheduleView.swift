import SwiftUI
import SwiftData

// MARK: - RoutineScheduleView
/// Main view for configuring routine repeat schedules
struct RoutineScheduleView: View {
    let routine: Routine
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedScheduleType: RoutineScheduleType
    @State private var selectedDays: Set<Int> = []
    @State private var intervalDays: Int = 2
    @State private var startDate: Date = Date()
    @State private var showingConflictAlert = false
    @State private var conflictingRoutines: [(date: Date, conflictingRoutine: Routine)] = []

    init(routine: Routine) {
        self.routine = routine
        _selectedScheduleType = State(initialValue: routine.scheduleType)
        _selectedDays = State(initialValue: routine.scheduleDays)
        _intervalDays = State(initialValue: routine.scheduleIntervalDays ?? 2)
        _startDate = State(initialValue: routine.scheduleStartDate ?? Date())
    }

    var body: some View {
        ZStack {
            Color.primaryBg
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Schedule Type Selector
                    FormSectionCard(title: "Schedule Type") {
                        ScheduleTypePicker(selectedType: $selectedScheduleType)
                    }

                    // Configuration based on type
                    if selectedScheduleType == .weekly {
                        FormSectionCard(title: "Repeat Days") {
                            DayOfWeekSelector(selectedDays: $selectedDays)
                        }
                    } else if selectedScheduleType == .interval {
                        FormSectionCard(title: "Repeat Interval") {
                            IntervalSchedulePicker(
                                intervalDays: $intervalDays,
                                startDate: $startDate
                            )
                        }
                    }

                    // Next occurrence preview (if schedule is configured)
                    if selectedScheduleType != .none {
                        NextOccurrencePreview(
                            scheduleType: selectedScheduleType,
                            selectedDays: selectedDays,
                            intervalDays: intervalDays,
                            startDate: startDate
                        )
                    }

                    // Shift controls (only for interval schedules that are already saved)
                    if routine.scheduleType == .interval && routine.scheduleStartDate != nil {
                        ScheduleShiftControls(routine: routine)
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }

            // Save button
            FixedModalCTAButton(
                title: "Save Schedule",
                icon: "checkmark",
                isEnabled: isValidSchedule,
                action: saveSchedule
            )
        }
        .navigationTitle("Schedule")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.accentPrimary)
            }
        }
        .alert("Schedule Conflict", isPresented: $showingConflictAlert) {
            Button("Save Anyway", role: .destructive) {
                performSave()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            let routineNames = Set(conflictingRoutines.map { $0.conflictingRoutine.name }).joined(separator: ", ")
            Text("This schedule overlaps with \(routineNames) on some days. Are you sure you want to save?")
        }
    }

    private var isValidSchedule: Bool {
        switch selectedScheduleType {
        case .none:
            return true
        case .weekly:
            return !selectedDays.isEmpty
        case .interval:
            return intervalDays >= 1
        }
    }

    private func saveSchedule() {
        // Check for conflicts first
        let conflicts = RoutineService.shared.getScheduleConflicts(
            for: routine,
            scheduleType: selectedScheduleType,
            scheduleDays: selectedDays,
            intervalDays: intervalDays,
            startDate: startDate,
            modelContext: modelContext
        )

        if !conflicts.isEmpty {
            conflictingRoutines = conflicts
            showingConflictAlert = true
        } else {
            performSave()
        }
    }

    private func performSave() {
        RoutineService.shared.updateRoutineSchedule(
            routine: routine,
            scheduleType: selectedScheduleType,
            scheduleDays: selectedDays,
            intervalDays: intervalDays,
            startDate: startDate,
            modelContext: modelContext
        )
        dismiss()
    }
}

// MARK: - Schedule Type Picker
struct ScheduleTypePicker: View {
    @Binding var selectedType: RoutineScheduleType

    var body: some View {
        VStack(spacing: 12) {
            // No Schedule
            ScheduleTypeOption(
                title: "No Schedule",
                subtitle: "Start manually when you want",
                icon: "calendar.badge.minus",
                isSelected: selectedType == .none,
                onTap: { selectedType = .none }
            )

            // Weekly
            ScheduleTypeOption(
                title: "Weekly",
                subtitle: "Repeat on specific days of the week",
                icon: "calendar",
                isSelected: selectedType == .weekly,
                onTap: { selectedType = .weekly }
            )

            // Interval
            ScheduleTypeOption(
                title: "Every X Days",
                subtitle: "Repeat at a fixed interval",
                icon: "arrow.triangle.2.circlepath",
                isSelected: selectedType == .interval,
                onTap: { selectedType = .interval }
            )
        }
    }
}

struct ScheduleTypeOption: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .accentPrimary : .textSecondary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? .textPrimary : .textSecondary)

                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.textTertiary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.accentPrimary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.tertiaryBg : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentPrimary.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Day of Week Selector
struct DayOfWeekSelector: View {
    @Binding var selectedDays: Set<Int>

    private let days = [
        (0, "S", "Sun"),
        (1, "M", "Mon"),
        (2, "T", "Tue"),
        (3, "W", "Wed"),
        (4, "T", "Thu"),
        (5, "F", "Fri"),
        (6, "S", "Sat")
    ]

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(days, id: \.0) { day in
                    DayButton(
                        shortLabel: day.1,
                        fullLabel: day.2,
                        isSelected: selectedDays.contains(day.0),
                        onTap: {
                            if selectedDays.contains(day.0) {
                                selectedDays.remove(day.0)
                            } else {
                                selectedDays.insert(day.0)
                            }
                        }
                    )
                }
            }

            // Selected days summary
            if !selectedDays.isEmpty {
                let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                let selectedDayNames = selectedDays.sorted().compactMap { dayNames[safe: $0] }
                Text("Every \(selectedDayNames.joined(separator: ", "))")
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
            }
        }
    }
}

struct DayButton: View {
    let shortLabel: String
    let fullLabel: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(shortLabel)
                .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .textInverse : .textSecondary)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(isSelected ? Color.accentPrimary : Color.tertiaryBg)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(fullLabel)
    }
}

// MARK: - Interval Schedule Picker
struct IntervalSchedulePicker: View {
    @Binding var intervalDays: Int
    @Binding var startDate: Date

    var body: some View {
        VStack(spacing: 16) {
            // Interval stepper
            HStack {
                Text("Repeat every")
                    .font(.bodyFont)
                    .foregroundColor(.textPrimary)

                Spacer()

                HStack(spacing: 12) {
                    Button(action: {
                        if intervalDays > 1 {
                            intervalDays -= 1
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(intervalDays > 1 ? .accentPrimary : .textTertiary)
                    }

                    Text("\(intervalDays)")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(.textPrimary)
                        .frame(minWidth: 50)

                    Button(action: {
                        if intervalDays < 30 {
                            intervalDays += 1
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(intervalDays < 30 ? .accentPrimary : .textTertiary)
                    }
                }

                Text(intervalDays == 1 ? "day" : "days")
                    .font(.bodyFont)
                    .foregroundColor(.textSecondary)
            }

            Divider()
                .background(Color.white.opacity(0.06))

            // Start date picker
            HStack {
                Text("Starting")
                    .font(.bodyFont)
                    .foregroundColor(.textPrimary)

                Spacer()

                DatePicker(
                    "",
                    selection: $startDate,
                    displayedComponents: .date
                )
                .labelsHidden()
                .colorScheme(.dark)
                .tint(.accentPrimary)
            }

            // Interval description
            Text(intervalDescription)
                .font(.system(size: 13))
                .foregroundColor(.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var intervalDescription: String {
        if intervalDays == 1 {
            return "Every day"
        } else if intervalDays == 7 {
            return "Once a week"
        } else if intervalDays == 14 {
            return "Every two weeks"
        } else {
            return "Every \(intervalDays) days"
        }
    }
}

// MARK: - Next Occurrence Preview
struct NextOccurrencePreview: View {
    let scheduleType: RoutineScheduleType
    let selectedDays: Set<Int>
    let intervalDays: Int
    let startDate: Date

    private var nextDate: Date? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        switch scheduleType {
        case .none:
            return nil

        case .weekly:
            guard !selectedDays.isEmpty else { return nil }

            for dayOffset in 0..<7 {
                if let checkDate = calendar.date(byAdding: .day, value: dayOffset, to: today) {
                    let weekday = calendar.component(.weekday, from: checkDate) - 1
                    if selectedDays.contains(weekday) {
                        return checkDate
                    }
                }
            }
            return nil

        case .interval:
            guard intervalDays > 0 else { return nil }

            let startOfStartDate = calendar.startOfDay(for: startDate)

            if today < startOfStartDate {
                return startOfStartDate
            }

            let daysSinceStart = calendar.dateComponents([.day], from: startOfStartDate, to: today).day ?? 0
            let daysUntilNext = intervalDays - (daysSinceStart % intervalDays)

            if daysUntilNext == intervalDays {
                return today
            }

            return calendar.date(byAdding: .day, value: daysUntilNext, to: today)
        }
    }

    private var formattedNextDate: String {
        guard let date = nextDate else { return "Not scheduled" }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if calendar.isDate(date, inSameDayAs: today) {
            return "Today"
        }

        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        if calendar.isDate(date, inSameDayAs: tomorrow) {
            return "Tomorrow"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("NEXT WORKOUT")
                    .font(.sectionHeader)
                    .foregroundColor(.textTertiary)
                    .kerning(0.3)

                Text(formattedNextDate)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.accentPrimary)
            }

            Spacer()

            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 24))
                .foregroundColor(.accentPrimary.opacity(0.5))
        }
        .padding(16)
        .background(Color.secondaryBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.accentPrimary.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Schedule Shift Controls
struct ScheduleShiftControls: View {
    let routine: Routine
    @Environment(\.modelContext) private var modelContext
    @State private var nextDateText: String = ""

    var body: some View {
        VStack(spacing: 12) {
            Text("SHIFT SCHEDULE")
                .font(.sectionHeader)
                .foregroundColor(.textTertiary)
                .kerning(0.3)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                // Shift backward button
                Button(action: shiftBackward) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Earlier")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.accentPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.secondaryBg)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.accentPrimary.opacity(0.3), lineWidth: 1)
                    )
                }

                // Next occurrence display
                VStack(spacing: 2) {
                    Text("Next")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.textTertiary)

                    Text(nextDateText)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textPrimary)
                }
                .frame(minWidth: 80)

                // Shift forward button
                Button(action: shiftForward) {
                    HStack(spacing: 6) {
                        Text("Later")
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.accentPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.secondaryBg)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.accentPrimary.opacity(0.3), lineWidth: 1)
                    )
                }
            }

            Text("Shift your schedule if you missed a day or need to adjust")
                .font(.system(size: 12))
                .foregroundColor(.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .background(Color.secondaryBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .onAppear {
            updateNextDateText()
        }
    }

    private func shiftBackward() {
        RoutineService.shared.shiftRoutineSchedule(
            routine: routine,
            forward: false,
            modelContext: modelContext
        )
        updateNextDateText()

        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }

    private func shiftForward() {
        RoutineService.shared.shiftRoutineSchedule(
            routine: routine,
            forward: true,
            modelContext: modelContext
        )
        updateNextDateText()

        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }

    private func updateNextDateText() {
        nextDateText = RoutineService.shared.formatNextScheduledDate(for: routine) ?? "Not set"
    }
}

// MARK: - Scheduled Routine Prompt View
/// Shows a prompt when a routine is scheduled for today
struct ScheduledRoutinePromptView: View {
    let routine: Routine
    let onStart: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SCHEDULED FOR TODAY")
                        .font(.sectionHeader)
                        .foregroundColor(.textTertiary)
                        .kerning(0.3)

                    Text(routine.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.textPrimary)
                }

                Spacer()

                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 28))
                    .foregroundColor(.accentPrimary)
            }

            // Schedule info
            if let scheduleDesc = RoutineService.shared.getScheduleDescription(for: routine) {
                Text(scheduleDesc)
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Exercise count
            Text("\(routine.exercises.count) exercises")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Action buttons
            HStack(spacing: 12) {
                // Skip button
                Button(action: onSkip) {
                    Text("Skip Today")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.tertiaryBg)
                        .cornerRadius(10)
                }

                // Start button
                Button(action: onStart) {
                    Text("Start Routine")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.textInverse)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            LinearGradient(
                                colors: [.accentPrimary, .accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(10)
                        .shadow(
                            color: .accentPrimary.opacity(0.3),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                }
            }
        }
        .padding(16)
        .background(Color.secondaryBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.accentPrimary.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Schedule Badge for Routine Cards
struct ScheduleBadge: View {
    let routine: Routine

    private var badgeText: String? {
        guard routine.scheduleType != .none else { return nil }

        if routine.isScheduledFor(date: Date()) {
            return "Today"
        }

        return RoutineService.shared.formatNextScheduledDate(for: routine)
    }

    var body: some View {
        if let text = badgeText {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.system(size: 10))

                Text(text)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(routine.isScheduledFor(date: Date()) ? .accentPrimary : .textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(routine.isScheduledFor(date: Date()) ? Color.accentPrimary.opacity(0.15) : Color.tertiaryBg)
            )
        }
    }
}

#Preview {
    NavigationStack {
        RoutineScheduleView(routine: Routine(name: "Push Day"))
    }
    .modelContainer(for: [Routine.self], inMemory: true)
}
