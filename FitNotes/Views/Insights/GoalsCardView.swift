import SwiftUI
import SwiftData

// MARK: - GoalsCardView
/// Displays active fitness goals with progress bars
struct GoalsCardView: View {
    let goalProgress: [InsightsService.GoalProgress]
    let onAddGoal: () -> Void
    let onDeleteGoal: (FitnessGoal) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Goals")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.textPrimary)

                    Text("Max 3 active goals")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                if goalProgress.count < 3 {
                    Button(action: onAddGoal) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Add")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.accentPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentPrimary.opacity(0.15))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            // Goals List or Empty State
            if goalProgress.isEmpty {
                GoalsEmptyState(onAddGoal: onAddGoal)
            } else {
                VStack(spacing: 12) {
                    ForEach(goalProgress, id: \.goal.id) { progress in
                        GoalProgressRow(
                            progress: progress,
                            onDelete: { onDeleteGoal(progress.goal) }
                        )
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
    }
}

// MARK: - GoalsEmptyState
struct GoalsEmptyState: View {
    let onAddGoal: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "target")
                .font(.system(size: 32))
                .foregroundColor(.textTertiary.opacity(0.5))

            Text("Set your first goal")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.textSecondary)

            Text("Track weekly workouts, volume targets, or specific lifts")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.textTertiary)
                .multilineTextAlignment(.center)

            Button(action: onAddGoal) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Create Goal")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.accentPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.accentPrimary.opacity(0.15))
                .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

// MARK: - GoalProgressRow
struct GoalProgressRow: View {
    let progress: InsightsService.GoalProgress
    let onDelete: () -> Void

    @State private var showDeleteConfirmation = false

    private var goalTitle: String {
        switch progress.goal.goalType {
        case .weeklyWorkouts:
            return "Weekly Workouts"
        case .weeklyVolume:
            return "Weekly Volume"
        case .specificLift:
            return progress.goal.exerciseName ?? "Lift Target"
        }
    }

    private var progressColor: Color {
        if progress.isAchieved {
            return .accentSuccess
        } else if progress.progressPercentage >= 75 {
            return .accentPrimary
        } else if progress.progressPercentage >= 50 {
            return Color(hex: "#FFB84D")  // Amber
        } else {
            return .accentPrimary.opacity(0.6)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title row with delete button
            HStack {
                // Icon
                Image(systemName: progress.goal.goalType.icon)
                    .font(.system(size: 14))
                    .foregroundColor(progressColor)
                    .frame(width: 24, height: 24)
                    .background(progressColor.opacity(0.15))
                    .cornerRadius(6)

                VStack(alignment: .leading, spacing: 2) {
                    Text(goalTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.textPrimary)

                    // Progress text
                    HStack(spacing: 4) {
                        Text(progress.displayCurrentValue)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(progressColor)

                        Text("/")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.textTertiary)

                        Text(progress.displayTargetValue)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer()

                // Achievement badge or percentage
                if progress.isAchieved {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                        Text("Done!")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.accentSuccess)
                } else {
                    Text("\(Int(progress.progressPercentage))%")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(progressColor)
                }

                // Delete button
                Button(action: { showDeleteConfirmation = true }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.textTertiary)
                        .frame(width: 20, height: 20)
                        .background(Color.tertiaryBg)
                        .cornerRadius(4)
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.tertiaryBg)
                        .frame(height: 8)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [progressColor, progressColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * min(1, progress.progressPercentage / 100), height: 8)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress.progressPercentage)
                }
            }
            .frame(height: 8)
        }
        .padding(12)
        .background(Color.tertiaryBg)
        .cornerRadius(12)
        .confirmationDialog("Delete Goal?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove this goal.")
        }
    }
}

// MARK: - AddGoalSheet
struct AddGoalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @State private var selectedGoalType: GoalType = .weeklyWorkouts
    @State private var targetValue: String = ""
    @State private var selectedExercise: Exercise?
    @State private var showExercisePicker = false

    private var isValid: Bool {
        guard let value = Double(targetValue), value > 0 else { return false }

        if selectedGoalType == .specificLift {
            return selectedExercise != nil
        }

        return true
    }

    private var placeholderText: String {
        switch selectedGoalType {
        case .weeklyWorkouts:
            return "e.g., 4"
        case .weeklyVolume:
            return "e.g., 50000"
        case .specificLift:
            return "e.g., 100"
        }
    }

    private var unitText: String {
        switch selectedGoalType {
        case .weeklyWorkouts:
            return "workouts/week"
        case .weeklyVolume:
            return "kg/week"
        case .specificLift:
            return appState.weightUnit
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.primaryBg
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Goal Type Selection
                        FormSectionCard(title: "Goal Type") {
                            VStack(spacing: 8) {
                                ForEach(GoalType.allCases, id: \.self) { type in
                                    GoalTypeOption(
                                        type: type,
                                        isSelected: selectedGoalType == type,
                                        onSelect: {
                                            withAnimation(.quickFeedback) {
                                                selectedGoalType = type
                                                // Reset exercise selection when changing type
                                                if type != .specificLift {
                                                    selectedExercise = nil
                                                }
                                            }
                                        }
                                    )
                                }
                            }
                        }

                        // Exercise Selection (for specific lift only)
                        if selectedGoalType == .specificLift {
                            FormSectionCard(title: "Exercise") {
                                Button(action: { showExercisePicker = true }) {
                                    HStack {
                                        if let exercise = selectedExercise {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(exercise.name)
                                                    .font(.system(size: 15, weight: .medium))
                                                    .foregroundColor(.textPrimary)
                                                Text(exercise.primaryCategory)
                                                    .font(.system(size: 12, weight: .regular))
                                                    .foregroundColor(.textSecondary)
                                            }
                                        } else {
                                            Text("Select an exercise")
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(.textTertiary)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.textTertiary)
                                    }
                                    .padding(12)
                                    .background(Color.tertiaryBg)
                                    .cornerRadius(10)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }

                        // Target Value
                        FormSectionCard(title: "Target") {
                            HStack(spacing: 12) {
                                TextField(placeholderText, text: $targetValue)
                                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                                    .keyboardType(.decimalPad)
                                    .foregroundColor(.textPrimary)
                                    .padding(12)
                                    .background(Color.tertiaryBg)
                                    .cornerRadius(10)

                                Text(unitText)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.textSecondary)
                            }

                            // Helper text
                            Text(helperText)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.textTertiary)
                                .padding(.top, 4)
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }

                // Fixed CTA at bottom
                FixedModalCTAButton(
                    title: "Create Goal",
                    icon: "target",
                    isEnabled: isValid,
                    action: createGoal
                )
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.accentPrimary)
                }
            }
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerForGoal(
                    exercises: exercises,
                    selectedExercise: $selectedExercise
                )
            }
        }
        .presentationBackground(Color.primaryBg)
    }

    private var helperText: String {
        switch selectedGoalType {
        case .weeklyWorkouts:
            return "How many workout sessions per week?"
        case .weeklyVolume:
            return "Total volume (weight × reps) per week in kg"
        case .specificLift:
            return "Target weight to lift for this exercise"
        }
    }

    private func createGoal() {
        guard let value = Double(targetValue), value > 0 else { return }

        let exerciseId = selectedGoalType == .specificLift ? selectedExercise?.id : nil
        let exerciseName = selectedGoalType == .specificLift ? selectedExercise?.name : nil
        let weightUnit = selectedGoalType == .specificLift ? appState.weightUnit : nil

        _ = InsightsService.shared.createGoal(
            type: selectedGoalType,
            targetValue: value,
            exerciseId: exerciseId,
            exerciseName: exerciseName,
            weightUnit: weightUnit,
            modelContext: modelContext
        )

        dismiss()
    }
}

// MARK: - GoalTypeOption
struct GoalTypeOption: View {
    let type: GoalType
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .accentPrimary : .textSecondary)
                    .frame(width: 32, height: 32)
                    .background(isSelected ? Color.accentPrimary.opacity(0.15) : Color.tertiaryBg)
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(type.displayName)
                        .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? .textPrimary : .textSecondary)

                    Text(typeDescription(for: type))
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.textTertiary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.accentPrimary)
                }
            }
            .padding(12)
            .background(isSelected ? Color.accentPrimary.opacity(0.08) : Color.tertiaryBg)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentPrimary.opacity(0.3) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func typeDescription(for type: GoalType) -> String {
        switch type {
        case .weeklyWorkouts:
            return "Target number of workout sessions per week"
        case .weeklyVolume:
            return "Target total volume (weight × reps) per week"
        case .specificLift:
            return "Target weight for a specific exercise"
        }
    }
}

// MARK: - ExercisePickerForGoal
struct ExercisePickerForGoal: View {
    let exercises: [Exercise]
    @Binding var selectedExercise: Exercise?
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return exercises
        }
        return exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.primaryBg
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.textSecondary)
                        TextField("Search exercises...", text: $searchText)
                            .foregroundColor(.textPrimary)
                    }
                    .padding(12)
                    .background(Color.secondaryBg)
                    .cornerRadius(10)
                    .padding()

                    // Exercise list
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredExercises) { exercise in
                                Button(action: {
                                    selectedExercise = exercise
                                    dismiss()
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(exercise.name)
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(.textPrimary)

                                            Text(exercise.primaryCategory)
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(.textSecondary)
                                        }

                                        Spacer()

                                        if selectedExercise?.id == exercise.id {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.accentPrimary)
                                        }
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 20)
                                }
                                .buttonStyle(PlainButtonStyle())

                                Divider()
                                    .background(Color.white.opacity(0.06))
                                    .padding(.leading, 20)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Exercise")
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
        .presentationBackground(Color.primaryBg)
    }
}

// MARK: - Preview
#Preview {
    let sampleProgress = [
        InsightsService.GoalProgress(
            goal: FitnessGoal(type: .weeklyWorkouts, targetValue: 4),
            currentValue: 3,
            targetValue: 4,
            displayCurrent: "3",
            displayTarget: "4"
        ),
        InsightsService.GoalProgress(
            goal: FitnessGoal(type: .weeklyVolume, targetValue: 50000),
            currentValue: 35000,
            targetValue: 50000,
            displayCurrent: "35k kg",
            displayTarget: "50k kg"
        ),
        InsightsService.GoalProgress(
            goal: FitnessGoal(type: .specificLift, targetValue: 100, exerciseId: UUID(), exerciseName: "Bench Press", weightUnit: "kg"),
            currentValue: 85,
            targetValue: 100,
            displayCurrent: "85 kg",
            displayTarget: "100 kg"
        )
    ]

    return ZStack {
        Color.primaryBg
            .ignoresSafeArea()

        GoalsCardView(
            goalProgress: sampleProgress,
            onAddGoal: {},
            onDeleteGoal: { _ in }
        )
        .padding()
    }
}
