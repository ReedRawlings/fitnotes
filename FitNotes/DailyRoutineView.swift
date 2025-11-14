import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @State private var showingAddExercise = false
    @State private var selectedDate = Date()
    
    // Track the last workout count to force refresh
    private var workoutCount: Int { workouts.count }
    
    var displayDate: Date {
        if let activeWorkout = appState.activeWorkout {
            return activeWorkout.startDate
        } else {
            return selectedDate
        }
    }
    
    var todaysWorkout: Workout? {
        let calendar = Calendar.current
        return workouts.first { workout in
            calendar.isDate(workout.date, inSameDayAs: Date())
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dark theme background
                Color.primaryBg
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if appState.showWorkoutFinishedBanner {
                        WorkoutFinishedBannerView()
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    appState.showWorkoutFinishedBanner = false
                                }
                            }
                    }
                    // Date header
                    HStack {
                        if Calendar.current.isDateInToday(displayDate) {
                            Text("Today")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.textPrimary)
                        } else {
                            HStack(spacing: 12) {
                                Button(action: { goToPreviousDay() }) {
                                    Image(systemName: "chevron.left")
                                        .font(.caption)
                                        .foregroundColor(.textSecondary)
                                }
                                
                                Text(displayDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.textPrimary)
                                
                                Button(action: { goToNextDay() }) {
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.textSecondary)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    
                    Divider()
                    
                    // Always use the same view for workouts
                    if let workout = getWorkoutForDate(displayDate) {
                        WorkoutDetailView(workout: workout, appState: appState)
                            .id(workout.id) // Force refresh when workout changes
                    } else {
                        EmptyWorkoutView(selectedDate: displayDate)
                    }
                    
                    Spacer()
                    
                    // V2 Gradient Add Exercise button
                    PrimaryActionButton(title: "Add Exercise") {
                        showingAddExercise = true
                    }
                    .padding(.bottom, 20) // 20pt from safe area
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAddExercise) {
            if let workout = getWorkoutForDate(displayDate) {
                // Workout exists - add exercises to it
                AddExerciseToWorkoutView(selectedDate: displayDate, workout: workout)
            } else {
                // No workout - create new one
                AddExerciseToWorkoutView(selectedDate: displayDate, workout: nil)
            }
        }
        .onAppear {
            // If active workout exists, set selectedDate to active workout's date
            if let activeWorkout = appState.activeWorkout {
                selectedDate = activeWorkout.startDate
            } else {
                selectedDate = Date()
            }
        }
    }
    
    private func goToPreviousDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
    }
    
    private func goToNextDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
    }
    
    private func getWorkoutForDate(_ date: Date) -> Workout? {
        let calendar = Calendar.current
        return workouts.first { workout in
            calendar.isDate(workout.date, inSameDayAs: date)
        }
    }
}

// MARK: - WorkoutDetailView
struct WorkoutDetailView: View {
    let workout: Workout
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @State private var showingRoutineTemplates = false
    @State private var cachedExercises: [WorkoutExercise] = []
    @State private var hasUncommittedChanges = false
    @StateObject private var timerManager: RestTimerManager

    init(workout: Workout, appState: AppState) {
        self.workout = workout
        // Initialize cached exercises immediately from workout
        _cachedExercises = State(initialValue: workout.exercises.sorted { $0.order < $1.order })
        _timerManager = StateObject(wrappedValue: RestTimerManager(appState: appState))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Timer banner
            if let timer = appState.activeRestTimer {
                RestTimerBannerView(
                    timer: timer,
                    showCompletionState: $timerManager.showCompletionState,
                    celebrationScale: $timerManager.celebrationScale,
                    onSkip: {
                        timerManager.skipTimer()
                    }
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
                .onAppear {
                    timerManager.startTimerUpdates()
                }
                .onDisappear {
                    timerManager.stopTimerUpdates()
                }
                .onChange(of: timer.isCompleted) { _, isCompleted in
                    if isCompleted && !timerManager.showCompletionState {
                        timerManager.handleTimerCompletion()
                    }
                }
            }
            
            Group {
                if workout.exercises.isEmpty {
                VStack(spacing: 24) {
                    EmptyStateView(
                        icon: "dumbbell",
                        title: "No exercises",
                        subtitle: "Choose how to get started",
                        actionTitle: nil,
                        onAction: nil
                    )
                    
                    VStack(spacing: 12) {
                        // Use Routine Template button
                        Button(action: { showingRoutineTemplates = true }) {
                            HStack {
                                Image(systemName: "list.bullet")
                                Text("Use Routine Template")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.secondaryBg)
                            .foregroundColor(.textPrimary)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            } else {
                List {
                    ForEach(cachedExercises, id: \.id) { workoutExercise in
                        WorkoutExerciseRowView(workoutExercise: workoutExercise, workout: workout)
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
                    // Initialize cache from workout exercises
                    if cachedExercises.isEmpty || !hasUncommittedChanges {
                        cachedExercises = workout.exercises.sorted { $0.order < $1.order }
                    }
                }
                .onChange(of: workout.exercises) { _, newExercises in
                    let newIds = Set(newExercises.map { $0.id })
                    let cachedIds = Set(cachedExercises.map { $0.id })

                    // Always sync when exercise IDs change (add/delete)
                    // This works independently of reorder state
                    if newIds != cachedIds {
                        cachedExercises = newExercises.sorted { $0.order < $1.order }
                        hasUncommittedChanges = false  // Reset after any structural change
                    }
                }
                .onDisappear {
                    if hasUncommittedChanges {
                        commitReorder()
                    }
                }
            }
            }
        }
        .sheet(isPresented: $showingRoutineTemplates) {
            RoutineTemplateSelectorView(selectedDate: workout.date, existingWorkout: workout)
        }
    }

    private func commitReorder() {
        // Update order values in the actual workout.exercises array
        for (index, cachedExercise) in cachedExercises.enumerated() {
            if let actualExercise = workout.exercises.first(where: { $0.id == cachedExercise.id }) {
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

struct WorkoutExerciseRowView: View {
    let workoutExercise: WorkoutExercise
    let workout: Workout
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @Query private var exercises: [Exercise]
    @Query private var allSets: [WorkoutSet]

    // Custom initializer to filter sets by exercise ID at the database level
    init(workoutExercise: WorkoutExercise, workout: Workout) {
        self.workoutExercise = workoutExercise
        self.workout = workout

        // Filter sets by exercise ID at the database level instead of fetching all sets
        let exerciseId = workoutExercise.exerciseId
        _allSets = Query(filter: #Predicate<WorkoutSet> { set in
            set.exerciseId == exerciseId
        })
    }
    
    private var exercise: Exercise? {
        exercises.first { $0.id == workoutExercise.exerciseId }
    }
    
    private var sortedSets: [WorkoutSet] {
        let calendar = Calendar.current
        let workoutStart = calendar.startOfDay(for: workout.date)
        let workoutEnd = calendar.date(byAdding: .day, value: 1, to: workoutStart)!

        // Exercise ID already filtered at database level
        let exerciseSets = allSets.filter { set in
            set.date >= workoutStart &&
            set.date < workoutEnd
        }
        return exerciseSets.sorted { $0.order < $1.order }
    }

    // ✅ Calculate ONCE per exercise, not per set
    private var bestPreviousSet: (weight: Double, reps: Int)? {
        // Get all completed historical sets for this exercise (excluding today's)
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: workout.date)

        // Exercise ID already filtered at database level
        let historicalSets = allSets.filter {
            $0.isCompleted &&
            $0.date < todayStart &&  // Only sets BEFORE today
            $0.weight != nil &&
            $0.reps != nil
        }

        guard !historicalSets.isEmpty else { return nil }

        // Find the best historical set
        let best = historicalSets.max { a, b in
            guard let aWeight = a.weight, let aReps = a.reps,
                  let bWeight = b.weight, let bReps = b.reps else {
                return false
            }
            if aWeight != bWeight {
                return aWeight < bWeight
            } else {
                return aReps < bReps
            }
        }

        guard let best = best,
              let weight = best.weight,
              let reps = best.reps else {
            return nil
        }

        return (weight: weight, reps: reps)
    }

    // MARK: - Volume Comparison Computed Properties

    private var currentSessionVolume: Double {
        ExerciseService.shared.calculateVolumeFromSets(sortedSets)
    }

    private var lastSessionVolume: Double? {
        guard let lastSession = ExerciseService.shared.getLastSessionForExerciseExcludingDate(
            exerciseId: workoutExercise.exerciseId,
            excludeDate: workout.date,
            modelContext: modelContext
        ) else { return nil }

        return ExerciseService.shared.calculateVolumeFromSets(lastSession)
    }

    private var volumeChangePercent: Double? {
        guard let lastVol = lastSessionVolume, lastVol > 0 else { return nil }
        return ((currentSessionVolume - lastVol) / lastVol) * 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with exercise name and delete
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise?.name ?? "Unknown Exercise")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                        .onAppear {
                            if exercise == nil {
                                print("\u{26A0}\u{FE0F} Exercise not found for ID: \(workoutExercise.exerciseId)")
                            }
                            print("\u{1F4CA} Exercise: \(exercise?.name ?? "nil") | Sets count: \(sortedSets.count)")
                        }
                }

                Spacer()

                Button(action: { deleteExercise() }) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.errorRed)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Volume Comparison Indicator
            if let lastVol = lastSessionVolume, let percentChange = volumeChangePercent {
                VolumeComparisonIndicatorView(
                    lastVolume: lastVol,
                    currentVolume: currentSessionVolume,
                    percentChange: percentChange
                )
            }

            // Set history - grid layout (2 columns)
            if !sortedSets.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.flexible(), alignment: .leading),
                    GridItem(.flexible(), alignment: .leading)
                ], spacing: 8) {
                    ForEach(sortedSets, id: \.id) { set in
                        HStack(spacing: 6) {
                            if set.isCompleted {
                                // ✅ OPTIMIZED: Just compare against cached value
                                if isPR(set: set, bestPrevious: bestPreviousSet) {
                                    PRBadge()
                                } else {
                                    SetCompletionBadge()
                                }
                            }
                            Text(formatSetDisplay(set: set))
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
            } else {
                Text("Tap to add sets")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.textTertiary)
                    .padding(.top, 2)
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
        .onTapGesture {
            if let exercise = exercise {
                appState.selectedExercise = exercise
            }
        }
    }
    
    private func formatSetDisplay(set: WorkoutSet) -> String {
        if let weight = set.weight, let reps = set.reps {
            return "\(reps)\u{00D7}\(formattedWeight(for: weight)) \(appState.weightUnit)"
        } else if let weight = set.weight {
            return "\(formattedWeight(for: weight)) \(appState.weightUnit)"
        } else if let reps = set.reps {
            return "\(reps) reps"
        } else {
            return "—"
        }
    }
    
    private func formattedWeight(for weight: Double) -> String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(weight))"
        } else {
            return String(format: "%.1f", weight)
        }
    }
    
    private func deleteExercise() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        print("Attempting to delete exercise: \(exercise?.name ?? "Unknown")")
        
        withAnimation(.deleteAnimation) {
            WorkoutService.shared.removeExerciseFromWorkout(
                workoutExercise: workoutExercise,
                modelContext: modelContext
            )
        }
        print("Delete operation completed")
    }

    // ✅ OPTIMIZED: Simple comparison, no database queries
    private func isPR(set: WorkoutSet, bestPrevious: (weight: Double, reps: Int)?) -> Bool {
        guard let currentWeight = set.weight,
              let currentReps = set.reps,
              let best = bestPrevious else {
            return false
        }

        // A PR is achieved if current set is strictly better than best previous
        return currentWeight > best.weight ||
               (currentWeight == best.weight && currentReps > best.reps)
    }
}

private struct SetCompletionBadge: View {
    var body: some View {
        Circle()
            .fill(Color.accentSuccess)
            .frame(width: 16, height: 16)
            .overlay(
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
            )
            .accessibilityHidden(true)
    }
}

private struct PRBadge: View {
    var body: some View {
        TrophyView(
            frame: 16,
            primaryColor: .accentSecondary,
            secondaryColor: .accentSecondary,
            tertiaryColor: .accentSecondary
        )
        .accessibilityHidden(true)
    }
}

struct EmptyWorkoutView: View {
    let selectedDate: Date
    @State private var showingRoutineTemplates = false
    
    var body: some View {
        VStack(spacing: 24) {
            EmptyStateView(
                icon: "dumbbell",
                title: "No workout for this day",
                subtitle: "Choose how to get started",
                actionTitle: nil,
                onAction: nil
            )
            
            VStack(spacing: 12) {
                // Use Routine Template button
                Button(action: { showingRoutineTemplates = true }) {
                    HStack {
                        Image(systemName: "list.bullet")
                        Text("Use Routine Template")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondaryBg)
                    .foregroundColor(.textPrimary)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding()
        .sheet(isPresented: $showingRoutineTemplates) {
            RoutineTemplateSelectorView(selectedDate: selectedDate)
        }
    }
}

// MARK: - AddExerciseToWorkoutView
struct AddExerciseToWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let selectedDate: Date
    var workout: Workout?
    
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var searchText = ""
    @State private var selectedMuscleGroup: String = ""
    @State private var selectedEquipment: String = ""
    @State private var showingDuplicateAlert = false
    @State private var duplicateExerciseName = ""
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
                            let groups = Array(Set(exercises.map { $0.primaryCategory })).sorted()
                            ForEach(groups, id: \.self) { group in
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
                    addExercises(selected: [exercise.id])
                },
                context: .picker,
                selectedIds: $selectedIds
            )
        }
        // Fixed CTA at bottom (overlayed, not affecting list layout)
        FixedModalCTAButton(
            title: selectedIds.isEmpty ? "Select exercises" : "Add \(selectedIds.count) Exercise\(selectedIds.count == 1 ? "" : "s")",
            icon: "checkmark",
            isEnabled: !selectedIds.isEmpty,
            action: {
                addExercises(selected: Array(selectedIds))
            }
        )
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
        }
        .alert("Exercise already exists", isPresented: $showingDuplicateAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("\(duplicateExerciseName) is already in this workout.")
        }
        .onAppear {
            // Ensure the exercise library is seeded the first time this view is opened
            if exercises.isEmpty {
                ExerciseDatabaseService.shared.createDefaultExercises(modelContext: modelContext)
            }
        }
    }
    
    private func addExercises(selected: [UUID]) {
        // Fetch or create workout for selectedDate
        let targetWorkout: Workout
        if let existing = workout {
            targetWorkout = existing
        } else {
            targetWorkout = WorkoutService.shared.createWorkout(
                name: "Workout - \(selectedDate.formatted(date: .abbreviated, time: .omitted))",
                date: selectedDate,
                modelContext: modelContext
            )
        }

        // Add each selected exercise, skipping duplicates
        for exerciseId in selected {
            if WorkoutService.shared.exerciseExistsInWorkout(workout: targetWorkout, exerciseId: exerciseId) {
                continue
            }
            _ = WorkoutService.shared.addExerciseToWorkout(
                workout: targetWorkout,
                exerciseId: exerciseId,
                sets: 0,
                reps: nil,
                weight: nil,
                duration: nil,
                distance: nil,
                notes: nil,
                modelContext: modelContext
            )

            // Auto-persist last session's sets to today so volume comparison shows immediately
            if let lastSession = ExerciseService.shared.getLastSessionForExercise(
                exerciseId: exerciseId,
                modelContext: modelContext
            ), !lastSession.isEmpty {
                let setData = lastSession.map { (weight: $0.weight, reps: $0.reps, rpe: Int?(nil), rir: Int?(nil), isCompleted: false) }
                _ = ExerciseService.shared.saveSets(
                    exerciseId: exerciseId,
                    date: selectedDate,
                    sets: setData,
                    modelContext: modelContext
                )
            }
        }

        dismiss()
    }
}

// MARK: - RoutineTemplateSelectorView
struct RoutineTemplateSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Routine.name) private var routines: [Routine]
    
    let selectedDate: Date
    let existingWorkout: Workout?
    
    init(selectedDate: Date, existingWorkout: Workout? = nil) {
        self.selectedDate = selectedDate
        self.existingWorkout = existingWorkout
    }
    
    var body: some View {
        ZStack {
            // Dark theme background
            Color.primaryBg
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom header
                HStack {
                    Text("Use Template")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.accentPrimary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                Divider()
                
                // Content
                if routines.isEmpty {
                    EmptyStateView(
                        icon: "list.bullet.rectangle",
                        title: "No routine templates",
                        subtitle: "Create routine templates in the Routines tab first",
                        actionTitle: nil,
                        onAction: nil
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(routines) { routine in
                                RoutineTemplateCardView(routine: routine) {
                                    useRoutineTemplate(routine)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func useRoutineTemplate(_ routine: Routine) {
        if let existingWorkout = existingWorkout {
            // Add exercises to existing workout
            _ = RoutineService.shared.addExercisesFromRoutineToWorkout(
                workout: existingWorkout,
                routine: routine,
                modelContext: modelContext
            )
        } else {
            // Create new workout
            _ = RoutineService.shared.createWorkoutFromTemplate(
                routine: routine,
                date: selectedDate,
                modelContext: modelContext
            )
        }
        
        dismiss()
    }
}

// MARK: - RoutineTemplateCardView
struct RoutineTemplateCardView: View {
    let routine: Routine
    let onAdd: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(routine.name)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                
                if let description = routine.routineDescription, !description.isEmpty {
                    Text(description)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.textSecondary)
                        .lineLimit(2)
                }
                
                Text("\(routine.exercises.count) exercises")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.accentPrimary, Color.accentSecondary]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: Color.accentPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding(14)
        .cardStyle()
    }
}

#Preview {
    WorkoutView()
        .modelContainer(for: [Exercise.self, Workout.self, BodyMetric.self, WorkoutExercise.self, WorkoutSet.self, RoutineExercise.self, Routine.self], inMemory: true)
}

struct WorkoutFinishedBannerView: View {
    var body: some View {
        Text("Workout Finished!")
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.green)
            .cornerRadius(10)
            .padding()
    }
}