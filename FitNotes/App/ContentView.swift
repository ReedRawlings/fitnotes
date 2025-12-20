//
//  ContentView.swift
//  FitNotes
//
//  Created by Reed Rawlings on 10/14/25.
//

import SwiftUI
import SwiftData

// MARK: - UIColor Extension for Hex
extension UIColor {
    convenience init(hex: String) {
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
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

// MARK: - App State Management
@MainActor
public class AppState: ObservableObject {
    @Published var selectedExercise: Exercise?
    @Published var showWorkoutFinishedBanner: Bool = false
    private var _activeWorkout: ActiveWorkoutState?
    @Published var selectedTab: Int = 0
    @Published var weightUnit: String = "kg" // Global unit preference for set history display
    @Published var activeRestTimer: RestTimer?
    @Published var navigateToHistoryDate: Date? // Date to navigate to in WorkoutView

    // Rest timer manager for notification support
    lazy var restTimerManager: RestTimerManager = {
        RestTimerManager(appState: self)
    }()

    var activeWorkout: ActiveWorkoutState? {
        get {
            guard let workout = _activeWorkout,
                  Calendar.current.isDateInToday(workout.startDate) else {
                _activeWorkout = nil
                return nil
            }
            return workout
        }
        set {
            _activeWorkout = newValue
        }
    }
    
    init() {
        // Start with no active workout
        // WorkoutView or HomeView will set this on app launch if needed
        _activeWorkout = nil
    }
    
    func startWorkout(workoutId: UUID, routineId: UUID?, totalExercises: Int) {
        activeWorkout = ActiveWorkoutState(
            workoutId: workoutId,
            routineId: routineId,
            startDate: Date(),
            completedExercisesCount: 0,
            totalExercisesCount: totalExercises
        )
    }
    
    func updateWorkoutProgress(completedExercises: Int) {
        guard var workout = activeWorkout else { return }
        workout.completedExercisesCount = completedExercises
        activeWorkout = workout
    }
    
    func completeWorkout() {
        activeWorkout = nil
    }
    
    func startWorkoutAndNavigate(workoutId: UUID, routineId: UUID?, totalExercises: Int) {
        startWorkout(workoutId: workoutId, routineId: routineId, totalExercises: totalExercises)
        selectedTab = 2 // Switch to Workout tab (index 2)
    }
    
    func continueWorkoutAndNavigate() {
        selectedTab = 2 // Switch to Workout tab (index 2)
    }
    
    func syncActiveWorkoutFromSwiftData(modelContext: ModelContext) {
        // Query SwiftData for today's workout
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { workout in
                workout.date >= today && workout.date < tomorrow
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let workouts = try modelContext.fetch(descriptor)
            if let activeWorkout = workouts.first {
                // Set active workout state
                self.activeWorkout = ActiveWorkoutState(
                    workoutId: activeWorkout.id,
                    routineId: activeWorkout.routineTemplateId,
                    startDate: activeWorkout.date,
                    completedExercisesCount: 0, // This could be calculated from completed sets
                    totalExercisesCount: activeWorkout.exercises.count
                )
            }
        } catch {
            print("Error syncing active workout from SwiftData: \(error)")
        }
    }
    
    func syncWeightUnitFromPreferences(modelContext: ModelContext) {
        let defaultUnit = PreferencesService.shared.getDefaultWeightUnit(modelContext: modelContext)
        self.weightUnit = defaultUnit
    }
    
    // MARK: - Rest Timer Management
    func startRestTimer(exerciseId: UUID, exerciseName: String, setNumber: Int, duration: TimeInterval) {
        // Cancel existing timer if any
        cancelRestTimer()

        // Start new timer
        activeRestTimer = RestTimer(
            exerciseId: exerciseId,
            setNumber: setNumber,
            startTime: Date(),
            duration: duration
        )

        // Schedule notification for timer completion
        restTimerManager.startTimer(
            exerciseName: exerciseName,
            setNumber: setNumber,
            duration: duration
        )
    }

    func cancelRestTimer() {
        activeRestTimer = nil
        restTimerManager.endTimer()
    }
    
    func getTimeRemaining() -> TimeInterval? {
        guard let timer = activeRestTimer else { return nil }
        return timer.timeRemaining
    }
}

// MARK: - Active Workout State
public struct ActiveWorkoutState: Codable {
    let workoutId: UUID
    let routineId: UUID?
    let startDate: Date
    var completedExercisesCount: Int
    var totalExercisesCount: Int
    
    var progressText: String {
        "\(completedExercisesCount)/\(totalExercisesCount) exercises"
    }
}

// MARK: - Rest Timer State
public struct RestTimer: Identifiable {
    public let id: UUID
    public let exerciseId: UUID
    public let setNumber: Int
    public let startTime: Date
    public let duration: TimeInterval
    
    public init(exerciseId: UUID, setNumber: Int, startTime: Date, duration: TimeInterval) {
        self.id = UUID()
        self.exerciseId = exerciseId
        self.setNumber = setNumber
        self.startTime = startTime
        self.duration = duration
    }
    
    public var timeRemaining: TimeInterval {
        let elapsed = Date().timeIntervalSince(startTime)
        return max(0, duration - elapsed)
    }
    
    public var progress: Double {
        guard duration > 0 else { return 0 }
        let elapsed = Date().timeIntervalSince(startTime)
        return min(1.0, max(0.0, elapsed / duration))
    }
    
    public var isCompleted: Bool {
        timeRemaining <= 0
    }
}

// MARK: - Monthly Calendar View
struct MonthlyCalendarView: View {
    @Query private var workouts: [Workout]
    @Query private var exercises: [Exercise]
    @Query private var routines: [Routine]
    @Query private var allSets: [WorkoutSet]

    @State private var colorMode: CalendarColorMode = .routine
    @State private var currentDate = Date()
    @State private var selectedDayWorkout: (date: Date, workout: Workout)? = nil

    enum CalendarColorMode {
        case routine
        case category
    }

    private var calendar: Calendar {
        Calendar.current
    }

    private var monthDateRange: (start: Date, end: Date) {
        let components = calendar.dateComponents([.year, .month], from: currentDate)
        let start = calendar.date(from: components)!
        let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start)!
        return (start, end)
    }

    private var daysInMonth: [Date] {
        let range = monthDateRange
        let startOfMonth = range.start
        let endOfMonth = range.end

        var dates: [Date] = []
        var date = startOfMonth

        while date <= endOfMonth {
            dates.append(date)
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }

        // Add padding days for grid alignment
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let paddingDaysBefore = (firstWeekday - calendar.firstWeekday + 7) % 7

        for i in (1...paddingDaysBefore).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: startOfMonth) {
                dates.insert(date, at: 0)
            }
        }

        // Pad end to complete the last week
        while dates.count % 7 != 0 {
            if let lastDate = dates.last,
               let nextDate = calendar.date(byAdding: .day, value: 1, to: lastDate) {
                dates.append(nextDate)
            } else {
                break
            }
        }

        return dates
    }

    private var monthYearText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentDate)
    }

    private func workout(for date: Date) -> Workout? {
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return workouts.first { workout in
            workout.date >= startOfDay && workout.date < endOfDay
        }
    }

    private func colorForDay(_ date: Date) -> Color? {
        guard let workout = workout(for: date) else { return nil }

        switch colorMode {
        case .routine:
            // Color by routine name
            if let routineId = workout.routineTemplateId {
                return colorForRoutine(routineId)
            }
            return .accentPrimary

        case .category:
            // Color by primary muscle group
            let exerciseIds = workout.exercises.map { $0.exerciseId }
            let workoutExercises = exercises.filter { exerciseIds.contains($0.id) }

            if let primaryExercise = workoutExercises.first {
                return colorForCategory(primaryExercise.primaryCategory)
            }
            return .accentPrimary
        }
    }

    private func colorForRoutine(_ routineId: UUID) -> Color {
        // Use the routine's actual color property
        if let routine = routines.first(where: { $0.id == routineId }) {
            return Color.forRoutineColor(routine.color)
        }
        return .accentPrimary
    }

    /// Get the scheduled routine for a future date (if any)
    private func scheduledRoutine(for date: Date) -> Routine? {
        let startOfDay = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: Date())

        // Only show scheduled indicator for future dates (not today, not past)
        guard startOfDay > today else { return nil }

        // Check if any routine is scheduled for this date
        return routines.first { $0.isScheduledFor(date: date) }
    }

    /// Get the color for a scheduled routine on a future date
    private func scheduledColorForDay(_ date: Date) -> Color? {
        guard let routine = scheduledRoutine(for: date) else { return nil }
        return Color.forRoutineColor(routine.color)
    }

    private func colorForCategory(_ category: String) -> Color {
        // Map muscle groups to colors
        switch category.lowercased() {
        case "chest":
            return Color(hex: "#FF6B35") // Coral
        case "back":
            return Color(hex: "#00D9A3") // Teal
        case "legs", "quads", "hamstrings", "glutes":
            return Color(hex: "#F7931E") // Amber
        case "shoulders":
            return Color(hex: "#5B9FFF") // Blue
        case "arms", "biceps", "triceps":
            return Color(hex: "#BA68C8") // Purple
        case "core", "abs":
            return Color(hex: "#FF7597") // Pink
        case "cardio":
            return Color(hex: "#FF9800") // Orange
        default:
            return .accentPrimary
        }
    }

    private func isCurrentMonth(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: currentDate, toGranularity: .month)
    }

    private func navigateToPreviousMonth() {
        withAnimation(.standardSpring) {
            if let newDate = calendar.date(byAdding: .month, value: -1, to: currentDate) {
                currentDate = newDate
            }
        }
    }

    private func navigateToNextMonth() {
        withAnimation(.standardSpring) {
            if let newDate = calendar.date(byAdding: .month, value: 1, to: currentDate) {
                currentDate = newDate
            }
        }
    }

    private func navigateToToday() {
        withAnimation(.standardSpring) {
            currentDate = Date()
        }
    }

    private func handleDayTap(_ date: Date) {
        if let workout = workout(for: date) {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()

            selectedDayWorkout = (date: date, workout: workout)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Header with month navigation
            HStack {
                // Previous month button
                Button(action: navigateToPreviousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textSecondary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()

                // Month/year label (tappable to go to today)
                Button(action: navigateToToday) {
                    Text(monthYearText)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()

                // Next month button
                Button(action: navigateToNextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textSecondary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Toggle between Routine and Category
            HStack(spacing: 0) {
                Button(action: {
                    withAnimation(.quickFeedback) {
                        colorMode = .routine
                    }
                }) {
                    Text("Routine")
                        .font(.system(size: 13, weight: colorMode == .routine ? .semibold : .medium))
                        .foregroundColor(colorMode == .routine ? .textPrimary : .textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(colorMode == .routine ? Color.tertiaryBg : Color.clear)
                        )
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: {
                    withAnimation(.quickFeedback) {
                        colorMode = .category
                    }
                }) {
                    Text("Category")
                        .font(.system(size: 13, weight: colorMode == .category ? .semibold : .medium))
                        .foregroundColor(colorMode == .category ? .textPrimary : .textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(colorMode == .category ? Color.tertiaryBg : Color.clear)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(4)
            .background(Color.secondaryBg)
            .cornerRadius(10)

            // Weekday headers
            HStack(spacing: 4) {
                ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { index, day in
                    Text(day)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(daysInMonth, id: \.self) { date in
                    DayCell(
                        date: date,
                        isCurrentMonth: isCurrentMonth(date),
                        isToday: calendar.isDateInToday(date),
                        color: colorForDay(date),
                        scheduledColor: scheduledColorForDay(date),
                        hasWorkout: workout(for: date) != nil,
                        onTap: { handleDayTap(date) }
                    )
                }
            }
        }
        .padding(16)
        .background(Color.secondaryBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .sheet(item: Binding(
            get: { selectedDayWorkout.map { DayWorkoutWrapper(date: $0.date, workout: $0.workout) } },
            set: { newValue in selectedDayWorkout = newValue.map { ($0.date, $0.workout) } }
        )) { wrapper in
            DayDetailSheet(date: wrapper.date, workout: wrapper.workout, exercises: exercises, allSets: allSets)
        }
    }
}

// MARK: - DayWorkoutWrapper (for sheet binding)
struct DayWorkoutWrapper: Identifiable {
    let id = UUID()
    let date: Date
    let workout: Workout
}

// MARK: - Day Cell Component
struct DayCell: View {
    let date: Date
    let isCurrentMonth: Bool
    let isToday: Bool
    let color: Color?              // Completed workout color
    let scheduledColor: Color?     // Scheduled future workout color (dotted outline)
    let hasWorkout: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    init(date: Date, isCurrentMonth: Bool, isToday: Bool, color: Color?, scheduledColor: Color? = nil, hasWorkout: Bool = false, onTap: @escaping () -> Void = {}) {
        self.date = date
        self.isCurrentMonth = isCurrentMonth
        self.isToday = isToday
        self.color = color
        self.scheduledColor = scheduledColor
        self.hasWorkout = hasWorkout
        self.onTap = onTap
    }

    private var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }

    var body: some View {
        ZStack {
            // Background color if workout exists
            if let color = color {
                Circle()
                    .fill(color.opacity(0.8))
            } else {
                Circle()
                    .fill(Color.tertiaryBg.opacity(isCurrentMonth ? 0.3 : 0.1))
            }

            // Scheduled future workout indicator (dotted outline)
            if color == nil, let scheduledColor = scheduledColor {
                Circle()
                    .strokeBorder(scheduledColor, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
            }

            // Today indicator ring
            if isToday {
                Circle()
                    .strokeBorder(Color.accentPrimary, lineWidth: 2)
            }

            // Day number
            Text("\(dayNumber)")
                .font(.system(size: 13, weight: color != nil ? .bold : .medium, design: .rounded))
                .foregroundColor(isCurrentMonth ? (color != nil ? .textInverse : .textPrimary) : .textTertiary)
        }
        .frame(height: 36)
        .aspectRatio(1, contentMode: .fit)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .opacity(isPressed ? 0.8 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            if hasWorkout {
                onTap()
            }
        }
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            if hasWorkout {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Day Detail Sheet
struct DayDetailSheet: View {
    let date: Date
    let workout: Workout
    let exercises: [Exercise]
    let allSets: [WorkoutSet]
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }

    private var workoutSets: [WorkoutSet] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return allSets.filter { set in
            set.date >= startOfDay && set.date < endOfDay && set.isCompleted
        }
    }

    private var totalVolume: Double {
        workoutSets.reduce(0) { total, set in
            guard let weight = set.weight, let reps = set.reps else { return total }
            return total + (weight * Double(reps))
        }
    }

    private var exerciseSummaries: [(exercise: Exercise, setCount: Int, bestSet: String)] {
        // Group sets by exercise
        var exerciseSetCounts: [UUID: [WorkoutSet]] = [:]
        for set in workoutSets {
            exerciseSetCounts[set.exerciseId, default: []].append(set)
        }

        // Build summaries
        var summaries: [(exercise: Exercise, setCount: Int, bestSet: String)] = []
        for workoutExercise in workout.exercises.sorted(by: { $0.order < $1.order }) {
            guard let exercise = exercises.first(where: { $0.id == workoutExercise.exerciseId }) else { continue }
            let sets = exerciseSetCounts[workoutExercise.exerciseId] ?? []

            // Find best set (highest volume)
            var bestSetString = "–"
            if let bestSet = sets.max(by: {
                let v1 = ($0.weight ?? 0) * Double($0.reps ?? 0)
                let v2 = ($1.weight ?? 0) * Double($1.reps ?? 0)
                return v1 < v2
            }) {
                if let weight = bestSet.weight, let reps = bestSet.reps {
                    let weightStr = weight.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(weight))" : String(format: "%.1f", weight)
                    bestSetString = "\(weightStr) \(bestSet.unit) × \(reps)"
                }
            }

            summaries.append((exercise: exercise, setCount: sets.count, bestSet: bestSetString))
        }

        return summaries
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.primaryBg
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Workout Summary Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Workout Summary")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.textSecondary)

                            HStack(spacing: 24) {
                                // Exercise count
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(workout.exercises.count)")
                                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                                        .foregroundColor(.accentPrimary)
                                    Text("Exercises")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(.textSecondary)
                                }

                                // Sets
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(workoutSets.count)")
                                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                                        .foregroundColor(.accentPrimary)
                                    Text("Sets")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(.textSecondary)
                                }

                                // Volume
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(StatsService.shared.formatVolume(totalVolume))
                                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                                        .foregroundColor(.accentPrimary)
                                    Text("Volume")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(.textSecondary)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.secondaryBg)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )

                        // Exercise List
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Exercises")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.textSecondary)

                            VStack(spacing: 8) {
                                ForEach(exerciseSummaries, id: \.exercise.id) { summary in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(summary.exercise.name)
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(.textPrimary)

                                            HStack(spacing: 8) {
                                                Text("\(summary.setCount) sets")
                                                    .font(.system(size: 13, weight: .regular))
                                                    .foregroundColor(.textSecondary)

                                                Text("Best: \(summary.bestSet)")
                                                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                                                    .foregroundColor(.textSecondary)
                                            }
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.textTertiary)
                                    }
                                    .padding(12)
                                    .background(Color.tertiaryBg)
                                    .cornerRadius(12)
                                    .onTapGesture {
                                        appState.selectedExercise = summary.exercise
                                        dismiss()
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.secondaryBg)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )

                        // View Full Workout Button
                        Button(action: {
                            appState.navigateToHistoryDate = date // Set the date to navigate to
                            appState.selectedTab = 2 // Switch to Workout tab
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "dumbbell.fill")
                                    .font(.system(size: 14))
                                Text("View Full Workout")
                                    .font(.buttonFont)
                            }
                            .foregroundColor(.accentPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.secondaryBg)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.accentPrimary.opacity(0.3), lineWidth: 2)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
            }
            .navigationTitle(dateString)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.accentPrimary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Color.primaryBg)
    }
}

// MARK: - Stats Header Component
struct StatsHeaderView: View {
    let weeksActive: Int
    let totalVolume: String
    let daysSinceLastLift: String

    var body: some View {
        HStack(spacing: 12) {
            // Weeks Active
            VStack(alignment: .leading, spacing: 4) {
                Text("\(weeksActive)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.accentPrimary)
                Text("Weeks Active")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)
                .overlay(Color.white.opacity(0.1))

            // Total Volume
            VStack(alignment: .leading, spacing: 4) {
                Text(totalVolume)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.accentPrimary)
                Text("Total Volume")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)
                .overlay(Color.white.opacity(0.1))

            // Days Since Last Lift
            VStack(alignment: .leading, spacing: 4) {
                Text(daysSinceLastLift)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.accentPrimary)
                Text("Last Workout")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.secondaryBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @Query(sort: \Routine.name) private var routines: [Routine]
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @Query private var allSets: [WorkoutSet]
    @Query(filter: #Predicate<FitnessGoal> { $0.isActive }) private var activeGoals: [FitnessGoal]
    @State private var expandedRoutineId: UUID?
    @State private var showingRoutineDetail: Routine?
    @State private var cachedStats: (weeksActive: Int?, totalVolume: String?, daysSince: String?) = (nil, nil, nil)
    @State private var dismissedScheduledRoutineId: UUID? // Track if user dismissed today's prompt
    @State private var showingAddGoal = false

    // Get the routine scheduled for today (if any and not already started)
    private var scheduledRoutineForToday: Routine? {
        // Don't show if user already has an active workout
        guard appState.activeWorkout == nil else { return nil }

        // Don't show if user dismissed this routine today
        let scheduled = RoutineService.shared.getScheduledRoutine(for: Date(), modelContext: modelContext)
        if let routine = scheduled, routine.id == dismissedScheduledRoutineId {
            return nil
        }

        return scheduled
    }
    
    private var weeksActive: Int {
        StatsService.shared.getWeeksActiveStreak(workouts: workouts)
    }
    
    private var totalVolumeFormatted: String {
        let volume = StatsService.shared.getTotalVolume(allSets: allSets)
        return StatsService.shared.formatVolume(volume)
    }
    
    private var daysSinceLastLiftText: String {
        StatsService.shared.getDaysSinceLastLift(workouts: workouts)
    }

    private var goalProgress: [InsightsService.GoalProgress] {
        InsightsService.shared.getGoalProgress(goals: activeGoals, modelContext: modelContext)
    }
    
    var body: some View {
        ZStack {
            // Dark theme background
            Color.primaryBg
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 12) {
                        // TODO: Missed days should trigger something here to remind users they may need to shift a routine
                        // This could show a banner like "You missed your scheduled workout yesterday. Would you like to shift your schedule?"

                        // Scheduled routine prompt (if applicable)
                        if let scheduledRoutine = scheduledRoutineForToday {
                            ScheduledRoutinePromptView(
                                routine: scheduledRoutine,
                                onStart: {
                                    // Start workout from the scheduled routine
                                    let workout = RoutineService.shared.createWorkoutFromTemplate(
                                        routine: scheduledRoutine,
                                        modelContext: modelContext
                                    )

                                    appState.startWorkoutAndNavigate(
                                        workoutId: workout.id,
                                        routineId: scheduledRoutine.id,
                                        totalExercises: scheduledRoutine.exercises.count
                                    )
                                },
                                onSkip: {
                                    // Dismiss the prompt for today
                                    dismissedScheduledRoutineId = scheduledRoutine.id
                                }
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                        }

                        // Monthly Calendar
                        MonthlyCalendarView()
                            .padding(.horizontal, 20)
                            .padding(.top, scheduledRoutineForToday == nil ? 12 : 0)

                        // Stats header
                        StatsHeaderView(
                            weeksActive: weeksActive,
                            totalVolume: totalVolumeFormatted,
                            daysSinceLastLift: daysSinceLastLiftText
                        )
                        .padding(.horizontal, 20)

                        // Goals & Targets
                        GoalsCardView(
                            goalProgress: goalProgress,
                            onAddGoal: { showingAddGoal = true },
                            onDeleteGoal: { goal in
                                InsightsService.shared.deleteGoal(goal, modelContext: modelContext)
                            }
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                        
                        // Routine cards
                        LazyVStack(spacing: 0) {
                            ForEach(routines) { routine in
                                RoutineCardView(
                                    routine: routine,
                                    isExpanded: expandedRoutineId == routine.id,
                                    isActiveWorkout: appState.activeWorkout != nil,
                                    lastDoneText: RoutineService.shared.getDaysSinceLastUsed(
                                        for: routine,
                                        modelContext: modelContext
                                    ),
                                    onTap: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            if expandedRoutineId == routine.id {
                                                expandedRoutineId = nil
                                            } else {
                                                expandedRoutineId = routine.id
                                            }
                                        }
                                    },
                                    onView: {
                                        showingRoutineDetail = routine
                                    },
                                    onStart: {
                                        // Start workout directly from routine
                                        let workout = RoutineService.shared.createWorkoutFromTemplate(
                                            routine: routine,
                                            modelContext: modelContext
                                        )
                                        
                                        appState.startWorkoutAndNavigate(
                                            workoutId: workout.id,
                                            routineId: routine.id,
                                            totalExercises: routine.exercises.count
                                        )
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        
                        Spacer(minLength: 100) // Space for tab bar
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(item: $showingRoutineDetail) { routine in
            RoutineDetailView(routine: routine)
        }
        .sheet(isPresented: $showingAddGoal) {
            AddGoalSheet()
                .environmentObject(appState)
        }
        .onAppear {
            // Invalidate cache on appear
            cachedStats = (nil, nil, nil)
        }
    }
    
}

// MARK: - UnifiedCardView Component
struct UnifiedCardView: View {
    let title: String
    let subtitle: String?
    let showChevron: Bool
    let onTap: () -> Void
    
    init(title: String, subtitle: String? = nil, showChevron: Bool = false, onTap: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.showChevron = showChevron
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Spacer()
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.secondaryBg)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: false)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                // Scale down effect on tap
            }
        }
    }
}

// MARK: - RoutineSettingsCardView Component (Settings > Routines specific)
struct RoutineSettingsCardView: View {
    let routine: Routine
    let subtitle: String?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                // Color indicator dot
                Circle()
                    .fill(Color.forRoutineColor(routine.color))
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(routine.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)

                        // Schedule badge
                        ScheduleBadge(routine: routine)
                    }

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.secondaryBg)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - RoutineCardView Component (Homepage specific)
struct RoutineCardView: View {
    let routine: Routine
    let isExpanded: Bool
    let isActiveWorkout: Bool
    let lastDoneText: String
    let onTap: () -> Void
    let onView: () -> Void
    let onStart: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                if isExpanded {
                    // Expanded state with buttons
                    VStack(spacing: 16) {
                        // Routine name
                            HStack {
                            Text(routine.name)
                                    .font(.headline)
                                .fontWeight(.bold)
                                    .foregroundColor(.textPrimary)
                                Spacer()
                            }
                            
                        // Action buttons
                        HStack(spacing: 12) {
                            if isActiveWorkout {
                                // Only View button when workout is active
                                Button(action: onView) {
                                    Text("View")
                                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                                        .foregroundColor(.accentPrimary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(Color.secondaryBg)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.accentPrimary.opacity(0.3), lineWidth: 2)
                                        )
                                }
                            } else {
                                // View and Start buttons when no active workout
                                Button(action: onView) {
                                    Text("View")
                                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                                        .foregroundColor(.accentPrimary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(Color.secondaryBg)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.accentPrimary.opacity(0.3), lineWidth: 2)
                                        )
                                }
                                
                                Button(action: onStart) {
                                    Text("Start")
                                        .font(.buttonFont)
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
                                        .cornerRadius(12)
                                        .shadow(
                                            color: .accentPrimary.opacity(0.3),
                                            radius: 12,
                                            x: 0,
                                            y: 4
                                        )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    } else {
                    // Default state with routine name and last done text
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(routine.name)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.textPrimary)

                                // Schedule badge
                                ScheduleBadge(routine: routine)
                            }

                            Text(lastDoneText)
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .background(Color.secondaryBg)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
    }
}


// MARK: - RoutinesView
struct RoutinesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Routine.name) private var routines: [Routine]
    @State private var showingAddRoutine = false
    @State private var selectedRoutine: Routine?
    @State private var addExerciseRoutine: Routine?
    
    var body: some View {
        ZStack {
            // Dark theme background
            Color.primaryBg
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if routines.isEmpty {
                    EmptyStateView(
                        icon: "list.bullet.rectangle",
                        title: "No routines yet",
                        subtitle: "Create reusable exercise routines that you can easily add to any day",
                        actionTitle: nil,
                        onAction: nil
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            LazyVStack(spacing: 0) {
                                ForEach(routines) { routine in
                                    RoutineSettingsCardView(
                                        routine: routine,
                                        subtitle: RoutineService.shared.getDaysSinceLastUsed(
                                            for: routine,
                                            modelContext: modelContext
                                        )
                                    ) {
                                        selectedRoutine = routine
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 12)

                            Spacer(minLength: 100) // Space for bottom button and tab bar
                        }
                    }
                }
            }
            
            // Fixed bottom button - overlay on top (always visible for consistency)
            VStack {
                Spacer()
                PrimaryActionButton(title: "New Routine") {
                    showingAddRoutine = true
                }
                .padding(.bottom, 8) // Small padding above tab bar
            }
        }
        .sheet(isPresented: $showingAddRoutine) {
            AddRoutineView()
        }
        .sheet(item: $selectedRoutine) { routine in
            RoutineDetailView(routine: routine)
        }
        .sheet(item: $addExerciseRoutine) { routine in
            AddExerciseToRoutineTemplateView(routine: routine)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShowAddExerciseForRoutine"))) { notification in
            if let routine = notification.object as? Routine {
                addExerciseRoutine = routine
            }
        }
    }
}




// MARK: - AddRoutineView
struct AddRoutineView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var description = ""

    // Schedule configuration state
    @State private var selectedColor: RoutineColor = .teal
    @State private var selectedScheduleType: RoutineScheduleType = .none
    @State private var selectedDays: Set<Int> = []
    @State private var intervalDays: Int = 2
    @State private var startDate: Date = Date()

    var body: some View {
        ZStack {
            Color.primaryBg
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Routine Details Card
                    FormSectionCard(title: "Routine Details") {
                        LabeledTextInput(
                            label: "Routine Name",
                            placeholder: "e.g., Upper Body Day",
                            text: $name
                        )

                        LabeledTextInput(
                            label: "Description (optional)",
                            placeholder: "Add a description...",
                            text: $description,
                            axis: .vertical,
                            lineLimit: 3...6
                        )
                    }

                    // Color Picker Card
                    FormSectionCard(title: "Color") {
                        RoutineColorPicker(selectedColor: $selectedColor)
                    }

                    // Schedule Type Card
                    FormSectionCard(title: "Schedule (optional)") {
                        ScheduleTypePicker(selectedType: $selectedScheduleType)
                    }

                    // Configuration based on schedule type
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
                    if selectedScheduleType != .none && isValidSchedule {
                        NextOccurrencePreview(
                            scheduleType: selectedScheduleType,
                            selectedDays: selectedDays,
                            intervalDays: intervalDays,
                            startDate: startDate
                        )
                        .padding(.horizontal, 0)
                    }

                    Spacer(minLength: 100) // Space for fixed button
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }

            // Fixed CTA at bottom
            FixedModalCTAButton(
                title: "Create Routine",
                icon: "checkmark",
                isEnabled: !name.isEmpty && isValidSchedule,
                action: createRoutine
            )
        }
        .navigationTitle("New Routine")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.accentPrimary)
            }
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

    private func createRoutine() {
        let routine = RoutineService.shared.createRoutine(
            name: name,
            description: description.isEmpty ? nil : description,
            modelContext: modelContext
        )

        // Set the routine color
        routine.color = selectedColor

        // Apply schedule configuration if set
        if selectedScheduleType != .none {
            RoutineService.shared.updateRoutineSchedule(
                routine: routine,
                scheduleType: selectedScheduleType,
                scheduleDays: selectedScheduleType == .weekly ? selectedDays : nil,
                intervalDays: selectedScheduleType == .interval ? intervalDays : nil,
                startDate: selectedScheduleType == .interval ? startDate : nil,
                modelContext: modelContext
            )
        }

        // Immediately present the Add Exercises picker for the new routine
        // Using sheet to keep consistent with modal add flows
        // Dismiss creation view and then show picker
        DispatchQueue.main.async {
            dismiss()
            // Present AddExerciseToRoutineTemplateView for the new routine
            // This relies on RoutinesView's sheet presentation when a routine is selected
            NotificationCenter.default.post(
                name: Notification.Name("ShowAddExerciseForRoutine"),
                object: routine
            )
        }
    }
}

// MARK: - RoutineDetailView
struct RoutineDetailView: View {
    let routine: Routine
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var exercises: [Exercise]
    @State private var showingAddExercise = false
    @State private var showingScheduleView = false
    @State private var cachedExercises: [RoutineExercise] = []
    @State private var hasUncommittedChanges = false

    private var scheduleDescription: String {
        switch routine.scheduleType {
        case .none:
            return "No schedule set"
        case .weekly:
            let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            let selectedDayNames = routine.scheduleDays.sorted().compactMap { dayNames[safe: $0] }
            return selectedDayNames.isEmpty ? "No days selected" : "Every \(selectedDayNames.joined(separator: ", "))"
        case .interval:
            if let interval = routine.scheduleIntervalDays {
                return interval == 1 ? "Every day" : "Every \(interval) days"
            }
            return "Interval not set"
        }
    }

    private var nextScheduledText: String? {
        RoutineService.shared.formatNextScheduledDate(for: routine)
    }

    var body: some View {
        ZStack {
            Color.primaryBg
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if routine.exercises.isEmpty {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Routine Header Card
                            VStack(alignment: .leading, spacing: 8) {
                                Text(routine.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.textPrimary)

                                if let description = routine.routineDescription, !description.isEmpty {
                                    Text(description)
                                        .font(.body)
                                        .foregroundColor(.textSecondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.secondaryBg)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            )

                            // Schedule Card (tappable to edit)
                            RoutineScheduleCard(
                                routine: routine,
                                scheduleDescription: scheduleDescription,
                                nextScheduledText: nextScheduledText,
                                onTap: { showingScheduleView = true }
                            )

                            EmptyStateView(
                                icon: "dumbbell",
                                title: "No exercises added",
                                subtitle: "Add exercises to build your routine",
                                actionTitle: nil,
                                onAction: nil
                            )

                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    }
                } else {
                    List {
                        // Routine Header Card as first row
                        VStack(alignment: .leading, spacing: 8) {
                            Text(routine.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.textPrimary)

                            if let description = routine.routineDescription, !description.isEmpty {
                                Text(description)
                                    .font(.body)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        .padding()
                        .background(Color.secondaryBg)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())

                        // Schedule Card (tappable to edit)
                        RoutineScheduleCard(
                            routine: routine,
                            scheduleDescription: scheduleDescription,
                            nextScheduledText: nextScheduledText,
                            onTap: { showingScheduleView = true }
                        )
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                        .padding(.top, 8)

                        // Exercises section header
                        Text("EXERCISES")
                            .font(.sectionHeader)
                            .foregroundColor(.textTertiary)
                            .kerning(0.3)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                            .padding(.top, 16)
                            .padding(.bottom, 4)

                        // Exercises List with reordering support
                        ForEach(cachedExercises, id: \.id) { routineExercise in
                            RoutineTemplateExerciseRowView(routineExercise: routineExercise)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets())
                        }
                        .onMove { indices, newOffset in
                            // Update UI immediately with animation
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                cachedExercises.move(fromOffsets: indices, toOffset: newOffset)
                            }

                            // Haptic feedback
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()

                            // Mark as having uncommitted changes
                            hasUncommittedChanges = true
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .onAppear {
                        cachedExercises = routine.exercises.sorted { $0.order < $1.order }
                    }
                    .onChange(of: routine.exercises) { _, newExercises in
                        // Update cache when exercises are added/removed (but preserve reordering)
                        if !hasUncommittedChanges {
                            let newIds = Set(newExercises.map { $0.id })
                            let cachedIds = Set(cachedExercises.map { $0.id })
                            // Only update if the IDs actually changed (added/removed exercises)
                            if newIds != cachedIds {
                                cachedExercises = newExercises.sorted { $0.order < $1.order }
                            }
                        }
                    }
                    .onDisappear {
                        if hasUncommittedChanges {
                            commitReorder()
                        }
                    }
                }
            }
            .navigationTitle("Routine Details")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(
                // Fixed bottom button - overlay on top
                VStack {
                    Spacer()
                    PrimaryActionButton(title: "Add Exercise") {
                        showingAddExercise = true
                    }
                    .padding(.bottom, 8) // Small padding above safe area
                }
            )
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseToRoutineTemplateView(routine: routine)
        }
        .sheet(isPresented: $showingScheduleView) {
            NavigationStack {
                RoutineScheduleView(routine: routine)
            }
        }
    }
    
    private func commitReorder() {
        // Update order values in the actual routine.exercises array
        for (index, cachedExercise) in cachedExercises.enumerated() {
            if let actualExercise = routine.exercises.first(where: { $0.id == cachedExercise.id }) {
                actualExercise.order = index + 1
            }
        }
        
        // Single database save
        do {
            try modelContext.save()
            hasUncommittedChanges = false
        } catch {
            print("Error saving reordered exercises: \(error)")
        }
    }
}

struct RoutineTemplateExerciseRowView: View {
    let routineExercise: RoutineExercise
    @Environment(\.modelContext) private var modelContext
    @Query private var exercises: [Exercise]
    
    private var exercise: Exercise? {
        exercises.first { $0.id == routineExercise.exerciseId }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Exercise Info
            Text(exercise?.name ?? "Unknown Exercise")
                .font(.headline)
                .foregroundColor(.textPrimary)
                
            Spacer()
            
            // Delete Button
            Button(action: {
                RoutineService.shared.removeExerciseFromRoutine(
                    routineExercise: routineExercise,
                    modelContext: modelContext
                )
            }) {
                Image(systemName: "trash")
                    .font(.subheadline)
                    .foregroundColor(.errorRed)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondaryBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

// MARK: - AddExerciseToRoutineTemplateView
struct AddExerciseToRoutineTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let routine: Routine
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var searchText = ""
    @State private var selectedMuscleGroup: String = ""
    @State private var selectedEquipment: String = ""
    @State private var selectedIds: Set<UUID> = []
    
    private var filteredExercises: [Exercise] {
        ExerciseSearchService.shared.searchExercises(
            query: searchText,
            category: selectedMuscleGroup.isEmpty ? nil : selectedMuscleGroup,
            equipment: selectedEquipment.isEmpty ? nil : selectedEquipment,
            exercises: exercises
        )
    }
    
    var body: some View {
        ZStack {
            Color.primaryBg
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.textSecondary)
                    TextField("Search exercises...", text: $searchText)
                        .foregroundColor(.textPrimary)
                        .padding(8)
                        .background(Color.tertiaryBg)
                        .cornerRadius(10)
                }
                .padding()
                
                // Filters
                VStack(spacing: 8) {
                    // Equipment chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(ExerciseDatabaseService.equipmentTypes, id: \.self) { equipment in
                                Button(action: {
                                    selectedEquipment = selectedEquipment == equipment ? "" : equipment
                                }) {
                                    Text(equipment)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedEquipment == equipment ? Color.accentPrimary : Color.tertiaryBg)
                                        .foregroundColor(selectedEquipment == equipment ? .textInverse : .textPrimary)
                                        .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    // Muscle group chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(ExerciseDatabaseService.muscleGroups, id: \.self) { group in
                                Button(action: {
                                    selectedMuscleGroup = selectedMuscleGroup == group ? "" : group
                                }) {
                                    Text(group)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedMuscleGroup == group ? Color.accentPrimary : Color.tertiaryBg)
                                        .foregroundColor(selectedMuscleGroup == group ? .textInverse : .textPrimary)
                                        .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Exercise List with multi-select support
                ExerciseListView(
                    exercises: filteredExercises,
                    searchText: $searchText,
                    onExerciseSelected: { exercise in
                        // Fallback single add (should not trigger when selectedIds is provided)
                        addExercisesToRoutine(ids: [exercise.id])
                    },
                    context: .picker,
                    selectedIds: $selectedIds
                )
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.accentPrimary)
                }
            }
            // Fixed CTA at bottom
            FixedModalCTAButton(
                title: selectedIds.isEmpty ? "Select exercises" : "Add \(selectedIds.count) Exercise\(selectedIds.count == 1 ? "" : "s")",
                icon: "checkmark",
                isEnabled: !selectedIds.isEmpty,
                action: {
                    addExercisesToRoutine(ids: Array(selectedIds))
                }
            )
        }
    }
    
    private func addExercisesToRoutine(ids: [UUID]) {
        for id in ids {
            _ = RoutineService.shared.addExerciseToRoutine(
                routine: routine,
                exerciseId: id,
                modelContext: modelContext
            )
        }
        dismiss()
    }
}

// MARK: - SettingsView
struct SettingsView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.primaryBg
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Segmented Control for Settings Sections
                    HStack(spacing: 0) {
                        // Preferences Tab
                        Button(action: {
                            withAnimation(.standardSpring) {
                                selectedTab = 0
                            }
                        }) {
                            Text("Preferences")
                                .font(selectedTab == 0 ? .system(size: 15, weight: .semibold) : .tabFont)
                                .foregroundColor(selectedTab == 0 ? .textPrimary : .textSecondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedTab == 0 ? Color.tertiaryBg : Color.clear)
                                )
                                .scaleEffect(selectedTab == 0 ? 1.02 : 1.0)
                                .animation(.easeInOut(duration: 0.15), value: selectedTab)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Routines Tab
                        Button(action: {
                            withAnimation(.standardSpring) {
                                selectedTab = 1
                            }
                        }) {
                            Text("Routines")
                                .font(selectedTab == 1 ? .system(size: 15, weight: .semibold) : .tabFont)
                                .foregroundColor(selectedTab == 1 ? .textPrimary : .textSecondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedTab == 1 ? Color.tertiaryBg : Color.clear)
                                )
                                .scaleEffect(selectedTab == 1 ? 1.02 : 1.0)
                                .animation(.easeInOut(duration: 0.15), value: selectedTab)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Exercises Tab
                        Button(action: {
                            withAnimation(.standardSpring) {
                                selectedTab = 2
                            }
                        }) {
                            Text("Exercises")
                                .font(selectedTab == 2 ? .system(size: 15, weight: .semibold) : .tabFont)
                                .foregroundColor(selectedTab == 2 ? .textPrimary : .textSecondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedTab == 2 ? Color.tertiaryBg : Color.clear)
                                )
                                .scaleEffect(selectedTab == 2 ? 1.02 : 1.0)
                                .animation(.easeInOut(duration: 0.15), value: selectedTab)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(4)
                    .background(Color.secondaryBg)
                    .cornerRadius(12)
                    .padding()
                    
                    Divider()
                        .background(Color.white.opacity(0.06))
                    
                    // Content based on selected tab
                    if selectedTab == 0 {
                        PreferencesView()
                    } else if selectedTab == 1 {
                        RoutinesView()
                    } else {
                        ExercisesView()
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - PreferencesView
struct PreferencesView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @Query private var preferencesQuery: [UserPreferences]
    
    @State private var showingTimePicker = false
    @State private var tempSelectedSeconds: Int = 90
    
    // Expandable section states
    @State private var isWeightUnitExpanded = false
    @State private var isRestTimerExpanded = false
    @State private var isStatsDisplayExpanded = false
    
    private var preferences: UserPreferences {
        if let existing = preferencesQuery.first {
            return existing
        } else {
            // Create if doesn't exist
            let newPrefs = PreferencesService.shared.getOrCreatePreferences(modelContext: modelContext)
            return newPrefs
        }
    }
    
    var body: some View {
        ZStack {
            Color.primaryBg
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 12) {
                    // Weight Unit Section
                    ExpandableSettingsSection(
                        title: "Lbs or KGs",
                        isExpanded: isWeightUnitExpanded,
                        onToggle: { isWeightUnitExpanded.toggle() }
                    ) {
                        VStack(spacing: 12) {
                            HStack(spacing: 0) {
                                ForEach(["kg", "lbs"], id: \.self) { unit in
                                    Button(action: {
                                        withAnimation(.standardSpring) {
                                            preferences.defaultWeightUnit = unit
                                            appState.weightUnit = unit
                                            savePreferences()
                                        }
                                    }) {
                                        Text(unit)
                                            .font(.system(size: 15, weight: preferences.defaultWeightUnit == unit ? .semibold : .medium))
                                            .foregroundColor(preferences.defaultWeightUnit == unit ? .textPrimary : .textSecondary)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 44)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(preferences.defaultWeightUnit == unit ? Color.tertiaryBg : Color.clear)
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(4)
                            .background(Color.secondaryBg)
                            .cornerRadius(12)
                            
                            Text("Default weight unit for new exercises. Individual exercises can override this.")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.textTertiary)
                                .multilineTextAlignment(.center)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    // Default Rest Timer Section
                    ExpandableSettingsSection(
                        title: "Default Rest Timer",
                        isExpanded: isRestTimerExpanded,
                        onToggle: { isRestTimerExpanded.toggle() }
                    ) {
                        VStack(spacing: 12) {
                            Button(action: {
                                tempSelectedSeconds = preferences.defaultRestSeconds
                                showingTimePicker = true
                            }) {
                                HStack {
                                    Text(formatTime(preferences.defaultRestSeconds))
                                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                                        .foregroundColor(.textPrimary)
                                    Spacer()
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(Color.tertiaryBg)
                                .cornerRadius(10)
                            }
                            
                            Text("Default rest time between sets for new exercises. Individual exercises can override this.")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.textTertiary)
                                .multilineTextAlignment(.center)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Default Stats Display Section
                    ExpandableSettingsSection(
                        title: "Default Stats Display",
                        isExpanded: isStatsDisplayExpanded,
                        onToggle: { isStatsDisplayExpanded.toggle() }
                    ) {
                        VStack(spacing: 12) {
                            Text("Control how the volume and E1RM comparison stats are displayed in the exercise detail view.")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.textTertiary)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: 8) {
                                Button(action: {
                                    withAnimation(.standardSpring) {
                                        preferences.defaultStatsDisplayPreference = .alwaysCollapsed
                                        savePreferences()
                                    }
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Always Collapsed")
                                                .font(.system(size: 15, weight: preferences.defaultStatsDisplayPreference == .alwaysCollapsed ? .semibold : .medium))
                                                .foregroundColor(preferences.defaultStatsDisplayPreference == .alwaysCollapsed ? .textPrimary : .textSecondary)
                                            
                                            Text("Stats shown in compact form only")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.textTertiary)
                                        }
                                        
                                        Spacer()
                                        
                                        if preferences.defaultStatsDisplayPreference == .alwaysCollapsed {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.accentPrimary)
                                        }
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(preferences.defaultStatsDisplayPreference == .alwaysCollapsed ? Color.tertiaryBg : Color.clear)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: {
                                    withAnimation(.standardSpring) {
                                        preferences.defaultStatsDisplayPreference = .alwaysExpanded
                                        savePreferences()
                                    }
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Always Expanded")
                                                .font(.system(size: 15, weight: preferences.defaultStatsDisplayPreference == .alwaysExpanded ? .semibold : .medium))
                                                .foregroundColor(preferences.defaultStatsDisplayPreference == .alwaysExpanded ? .textPrimary : .textSecondary)
                                            
                                            Text("Stats shown in detailed form")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.textTertiary)
                                        }
                                        
                                        Spacer()
                                        
                                        if preferences.defaultStatsDisplayPreference == .alwaysExpanded {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.accentPrimary)
                                        }
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(preferences.defaultStatsDisplayPreference == .alwaysExpanded ? Color.tertiaryBg : Color.clear)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: {
                                    withAnimation(.standardSpring) {
                                        preferences.defaultStatsDisplayPreference = .rememberLastState
                                        savePreferences()
                                    }
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Remember State")
                                                .font(.system(size: 15, weight: preferences.defaultStatsDisplayPreference == .rememberLastState ? .semibold : .medium))
                                                .foregroundColor(preferences.defaultStatsDisplayPreference == .rememberLastState ? .textPrimary : .textSecondary)
                                            
                                            Text("Tap to expand/collapse, state is saved")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.textTertiary)
                                        }
                                        
                                        Spacer()
                                        
                                        if preferences.defaultStatsDisplayPreference == .rememberLastState {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.accentPrimary)
                                        }
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(preferences.defaultStatsDisplayPreference == .rememberLastState ? Color.tertiaryBg : Color.clear)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 100)
                }
            }
        }
        .sheet(isPresented: $showingTimePicker) {
            TimePickerModal(selectedSeconds: $tempSelectedSeconds, isPresented: $showingTimePicker)
                .presentationDetents([.height(300)])
                .presentationBackground(.clear)
                .onDisappear {
                    preferences.defaultRestSeconds = tempSelectedSeconds
                    savePreferences()
                }
        }
    }
    
    private func savePreferences() {
        PreferencesService.shared.savePreferences(preferences, modelContext: modelContext)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - InsightsView
struct InsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @Query private var workouts: [Workout]
    @Query private var exercises: [Exercise]
    @Query(filter: #Predicate<FitnessGoal> { $0.isActive }) private var activeGoals: [FitnessGoal]

    @State private var selectedPeriod: Int = 0 // Uses InsightsPeriod raw values
    @State private var showingAddGoal = false
    @State private var showingYearInReview = false

    private var currentPeriod: InsightsPeriod {
        InsightsPeriod(rawValue: selectedPeriod) ?? .week
    }

    private var periodDays: Int? {
        currentPeriod.days
    }

    private var periodWeeks: Int {
        currentPeriod.weeks
    }

    private var isAllTime: Bool {
        currentPeriod == .allTime
    }

    private var chartPeriodType: VolumeChartView.PeriodType {
        switch currentPeriod {
        case .week: return .week
        case .month: return .month
        case .threeMonths: return .threeMonths
        case .yearToDate: return .yearToDate
        case .allTime: return .allTime
        }
    }

    private var volumeData: [(date: Date, volume: Double)] {
        if currentPeriod == .week {
            // Week view: daily data
            return InsightsService.shared.getVolumeTrendForPeriod(days: periodDays, modelContext: modelContext)
        } else {
            // All other views: weekly aggregates
            return InsightsService.shared.getWeeklyVolumeTrendForPeriod(weeks: periodWeeks, isAllTime: isAllTime, modelContext: modelContext)
        }
    }

    private var workoutCount: Int {
        InsightsService.shared.getWorkoutCount(days: periodDays, modelContext: modelContext)
    }

    private var setCount: Int {
        InsightsService.shared.getSetCount(days: periodDays, modelContext: modelContext)
    }

    private var totalVolume: String {
        let volume = InsightsService.shared.getTotalVolume(days: periodDays, modelContext: modelContext)
        return StatsService.shared.formatVolume(volume)
    }

    private var prCount: Int {
        InsightsService.shared.getPRCount(days: periodDays, modelContext: modelContext)
    }

    private var muscleBreakdown: [(category: String, volume: Double, percentage: Double)] {
        InsightsService.shared.getMuscleGroupBreakdown(days: periodDays, modelContext: modelContext)
    }

    private var recentPRs: [(exercise: Exercise, weight: Double, reps: Int, date: Date, oneRM: Double)] {
        InsightsService.shared.getRecentPRs(limit: 10, modelContext: modelContext)
    }

    private var muscleRecoveryStatus: [String: InsightsService.MuscleRecoveryStatus] {
        InsightsService.shared.getMuscleRecoveryStatus(modelContext: modelContext)
    }

    private var topExercises: [(exercise: Exercise, setCount: Int)] {
        InsightsService.shared.getTopExercises(limit: 5, modelContext: modelContext)
    }

    private var streakData: InsightsService.StreakData {
        InsightsService.shared.getStreakData(modelContext: modelContext)
    }

    private var goalProgress: [InsightsService.GoalProgress] {
        InsightsService.shared.getGoalProgress(goals: activeGoals, modelContext: modelContext)
    }

    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    private var yearInReviewData: InsightsService.YearInReviewData {
        InsightsService.shared.getYearInReview(year: currentYear, modelContext: modelContext)
    }

    private var hasYearData: Bool {
        yearInReviewData.totalWorkouts > 0
    }

    private var comparisonStats: (
        workouts: InsightsService.PeriodComparison,
        sets: InsightsService.PeriodComparison,
        volume: InsightsService.PeriodComparison,
        prs: InsightsService.PeriodComparison
    ) {
        InsightsService.shared.getComparisonStats(days: periodDays, modelContext: modelContext)
    }

    var body: some View {
        ZStack {
            // Dark theme background
            Color.primaryBg
                .ignoresSafeArea()

            if workouts.isEmpty {
                // Empty state
                EmptyStateView(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "No workouts yet",
                    subtitle: "Complete your first workout to see insights",
                    actionTitle: nil,
                    onAction: nil
                )
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        // Year in Review Card
                        YearInReviewCard(
                            currentYear: currentYear,
                            hasData: hasYearData,
                            onTap: { showingYearInReview = true }
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        // Period Selector
                        InsightsPeriodSelector(selectedPeriod: $selectedPeriod)

                        // Muscle Recovery Heatmap
                        MuscleRecoveryHeatmapView(recoveryStatus: muscleRecoveryStatus)
                            .padding(.horizontal, 20)

                        // Volume Chart
                        VolumeChartView(data: volumeData, periodType: chartPeriodType)
                            .padding(.horizontal, 20)

                        // Stat Cards Grid with comparison data
                        StatCardsGridView(
                            workouts: workoutCount,
                            sets: setCount,
                            totalVolume: totalVolume,
                            prCount: prCount,
                            workoutsComparison: isAllTime ? nil : comparisonStats.workouts,
                            setsComparison: isAllTime ? nil : comparisonStats.sets,
                            volumeComparison: isAllTime ? nil : comparisonStats.volume,
                            prsComparison: isAllTime ? nil : comparisonStats.prs
                        )
                        .padding(.horizontal, 20)

                        // Muscle Group Breakdown
                        MuscleGroupBreakdownView(breakdown: muscleBreakdown)
                            .padding(.horizontal, 20)

                        // Top Exercises
                        TopExercisesView(topExercises: topExercises)
                            .padding(.horizontal, 20)

                        // Streak & Consistency
                        StreakConsistencyView(streakData: streakData)
                            .padding(.horizontal, 20)

                        // Recent PRs
                        RecentPRsListView(prs: recentPRs, unit: appState.weightUnit)
                            .padding(.horizontal, 20)

                        Spacer(minLength: 100) // Space for tab bar
                    }
                    .padding(.bottom, 20)
                }
                .sheet(isPresented: $showingAddGoal) {
                    AddGoalSheet()
                        .environmentObject(appState)
                }
                .fullScreenCover(isPresented: $showingYearInReview) {
                    YearInReviewSheet(data: yearInReviewData)
                }
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var appState = AppState()
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem { 
                    VStack {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                }
                .tag(0)
            InsightsView()
                .tabItem { 
                    VStack {
                        Image(systemName: "chart.xyaxis.line")
                        Text("Insights")
                    }
                }
                .tag(1)
            WorkoutView()
                .tabItem { 
                    VStack {
                        Image(systemName: "dumbbell.fill")
                        Text("Workout")
                    }
                }
                .tag(2)
            SettingsView()
                .tabItem { 
                    VStack {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
                }
                .tag(3)
        }
        .tint(.accentPrimary)
        .environmentObject(appState)
        .sheet(item: $appState.selectedExercise) { exercise in
            let todaysWorkout = workouts.first { Calendar.current.isDateInToday($0.date) }
            let workoutExercise = todaysWorkout?.exercises.first { $0.exerciseId == exercise.id }

            NavigationStack {
                ExerciseDetailView(exercise: exercise, workout: todaysWorkout, workoutExercise: workoutExercise, shouldDismissOnSave: true, appState: appState)
                    .environmentObject(appState)
            }
        }
        .onAppear {
            // Sync active workout state from SwiftData on app launch
            appState.syncActiveWorkoutFromSwiftData(modelContext: modelContext)
            // Sync weight unit from preferences
            appState.syncWeightUnitFromPreferences(modelContext: modelContext)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Exercise.self, Workout.self, BodyMetric.self, WorkoutExercise.self, RoutineExercise.self, Routine.self, FitnessGoal.self], inMemory: true)
}

