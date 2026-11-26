import SwiftUI
import SwiftData
import StoreKit

struct WorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview
    @EnvironmentObject private var appState: AppState
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @State private var showingAddExercise = false
    @State private var selectedDate = Date()
    @State private var showingSaveRoutineDialog = false
    @State private var showingUpdateRoutineDialog = false
    @State private var routineName = ""
    @State private var routineDescription = ""
    @State private var dismissedScheduledRoutineId: UUID? // Track if user dismissed today's prompt
    @State private var showingFinishConfirmation = false
    @State private var pendingFinishWorkout: Workout?
    @State private var uncheckedSetCount = 0

    // Track the last workout count to force refresh
    private var workoutCount: Int { workouts.count }

    // Get the routine scheduled for today (if any and no workout exists)
    private var scheduledRoutineForToday: Routine? {
        // Only show on today's view
        guard Calendar.current.isDateInToday(displayDate) else { return nil }

        // Don't show if user already has an active workout
        guard appState.activeWorkout == nil else { return nil }

        // Don't show if there's already a workout for today
        if todaysWorkout != nil { return nil }

        // Don't show if user dismissed this routine today
        let scheduled = RoutineService.shared.getScheduledRoutine(for: Date(), modelContext: modelContext)
        if let routine = scheduled, routine.id == dismissedScheduledRoutineId {
            return nil
        }

        return scheduled
    }
    
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
                                    // Just finished a workout: a good moment to ask for a rating
                                    if ReviewPrompt.consumeRequestIfDue(workoutCount: workouts.count) {
                                        requestReview()
                                    }
                                }
                            }
                    }
                    // Date header
                    HStack {
                        Spacer()
                        
                        // Centered date navigation
                        HStack(spacing: 12) {
                            Button(action: { goToPreviousDay() }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.textSecondary)
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(PlainButtonStyle())

                            if Calendar.current.isDateInToday(displayDate) {
                                Text("Today")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.textPrimary)
                            } else {
                                Text(displayDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.textPrimary)
                            }

                            // Only show right arrow if not at today
                            if !Calendar.current.isDateInToday(displayDate) {
                                Button(action: { goToNextDay() }) {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.textSecondary)
                                        .frame(width: 44, height: 44)
                                }
                                .buttonStyle(PlainButtonStyle())
                            } else {
                                // Invisible spacer to maintain centering when at today
                                Color.clear
                                    .frame(width: 44, height: 44)
                            }
                        }

                        Spacer()

                        // Routine buttons - only show if workout has exercises
                        if let workout = getWorkoutForDate(displayDate), !workout.exercises.isEmpty {
                            // One menu keeps the header on one line on every iPhone size
                            Menu {
                                Button(action: { showingSaveRoutineDialog = true }) {
                                    Label("Save as New Routine", systemImage: "plus.square.on.square")
                                }
                                Button(action: { showingUpdateRoutineDialog = true }) {
                                    Label("Update Existing Routine", systemImage: "arrow.triangle.2.circlepath")
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text("Routine")
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.accentColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.accentColor.opacity(0.1))
                                )
                            }
                            .accessibilityLabel("Routine options")
                        } else {
                            // Invisible spacer to maintain centering when button is hidden
                            Color.clear
                                .frame(width: 120, height: 32)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    
                    Divider()
                    
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

                    // Always use the same view for workouts
                    if let workout = getWorkoutForDate(displayDate) {
                        WorkoutDetailView(workout: workout, appState: appState)
                            .id(workout.id) // Force refresh when workout changes
                    } else if scheduledRoutineForToday == nil {
                        // Only show empty state if there's no scheduled routine prompt
                        EmptyWorkoutView(selectedDate: displayDate)
                    }
                    
                    Spacer()
                    
                    // Finishing is the user's call: today's workout gets a Finish button once it
                    // has exercises, and Add Exercise steps back to a secondary button beside it.
                    if let workout = finishableWorkout {
                        HStack(spacing: 12) {
                            Button(action: { showingAddExercise = true }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.textPrimary)
                                    .frame(width: 56, height: 56)
                                    .background(Color.secondaryBg)
                                    .cornerRadius(16)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .accessibilityLabel("Add Exercise")

                            Button(action: { requestFinish(workout) }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Finish Workout")
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
                                .shadow(color: .accentPrimary.opacity(0.3), radius: 16, x: 0, y: 4)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    } else {
                        if let finishedAt = getWorkoutForDate(displayDate)?.finishedAt {
                            Label("Finished at \(finishedAt.formatted(date: .omitted, time: .shortened))",
                                  systemImage: "checkmark.circle.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.textSecondary)
                                .padding(.bottom, 8)
                        }
                        PrimaryActionButton(title: "Add Exercise") {
                            showingAddExercise = true
                        }
                        .padding(.bottom, 20) // 20pt from safe area
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .alert("Finish workout?", isPresented: $showingFinishConfirmation, presenting: pendingFinishWorkout) { workout in
            Button("Finish") { finish(workout) }
            Button("Keep Going", role: .cancel) { }
        } message: { _ in
            Text(uncheckedSetCount == 1
                 ? "1 set isn't checked off. It won't count toward your stats."
                 : "\(uncheckedSetCount) sets aren't checked off. They won't count toward your stats.")
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
        .sheet(isPresented: $showingSaveRoutineDialog) {
            SaveWorkoutAsRoutineView(
                isPresented: $showingSaveRoutineDialog,
                workout: getWorkoutForDate(displayDate),
                modelContext: modelContext,
                onComplete: { }
            )
        }
        .sheet(isPresented: $showingUpdateRoutineDialog) {
            UpdateRoutineFromWorkoutView(
                isPresented: $showingUpdateRoutineDialog,
                workout: getWorkoutForDate(displayDate),
                modelContext: modelContext
            )
        }
        .onAppear {
            // If active workout exists, set selectedDate to active workout's date
            if let activeWorkout = appState.activeWorkout {
                selectedDate = activeWorkout.startDate
            } else {
                selectedDate = Date()
            }
        }
        .onChange(of: appState.navigateToHistoryDate) { _, newDate in
            // Navigate to the specified history date when set
            if let date = newDate {
                selectedDate = date
                appState.navigateToHistoryDate = nil // Reset after navigating
            }
        }
    }
    
    /// Today's workout, when it has exercises and hasn't been finished yet.
    private var finishableWorkout: Workout? {
        guard Calendar.current.isDateInToday(displayDate),
              let workout = getWorkoutForDate(displayDate),
              !workout.exercises.isEmpty,
              !workout.isFinished else { return nil }
        return workout
    }

    /// Finishes straight away when every set is checked; otherwise asks first.
    private func requestFinish(_ workout: Workout) {
        let unchecked = workout.exercises.reduce(0) { count, workoutExercise in
            let sets = ExerciseService.shared.getSetsByDate(
                exerciseId: workoutExercise.exerciseId,
                date: workout.date,
                modelContext: modelContext
            )
            return count + sets.filter { !$0.isCompleted }.count
        }
        if unchecked == 0 {
            finish(workout)
        } else {
            uncheckedSetCount = unchecked
            pendingFinishWorkout = workout
            showingFinishConfirmation = true
        }
    }

    private func finish(_ workout: Workout) {
        workout.finishedAt = Date()
        workout.updatedAt = Date()
        try? modelContext.save()
        appState.cancelRestTimer()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.standardSpring) {
            appState.showWorkoutFinishedBanner = true
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
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var appState: AppState
    @State private var showingRoutineTemplates = false
    @State private var cachedExercises: [WorkoutExercise] = []
    @State private var hasUncommittedChanges = false
    // Observes the single shared manager on AppState — a per-view instance would
    // split completion state from the Live Activity owner
    @ObservedObject private var timerManager: RestTimerManager

    init(workout: Workout, appState: AppState) {
        self.workout = workout
        // Initialize cached exercises immediately from workout
        _cachedExercises = State(initialValue: workout.exercises.sorted { $0.order < $1.order })
        _timerManager = ObservedObject(wrappedValue: appState.restTimerManager)
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
                    let supersetSlots = SupersetLayout.slots(for: cachedExercises)
                    ForEach(Array(cachedExercises.enumerated()), id: \.element.id) { index, workoutExercise in
                        WorkoutExerciseRowView(
                            workoutExercise: workoutExercise,
                            workout: workout,
                            supersetSlot: supersetSlots[workoutExercise.id],
                            linkToNext: index < cachedExercises.count - 1
                                ? SupersetLinkButton.LinkState(isLinked: SupersetLayout.isLinkedToNext(at: index, in: cachedExercises))
                                : nil,
                            onToggleLink: { toggleSuperset(at: index) }
                        )
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
                .onChange(of: appState.selectedExercise) { _, newExercise in
                    // Commit any pending reorder changes when an exercise sheet is about to open
                    // This ensures navigation respects the current sort order
                    if newExercise != nil && hasUncommittedChanges {
                        commitReorder()
                    }
                }
            }
            }
        }
        .sheet(isPresented: $showingRoutineTemplates) {
            RoutineTemplateSelectorView(selectedDate: workout.date, existingWorkout: workout)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // When app becomes active (e.g., from notification tap), dismiss completed timers
                timerManager.handleAppBecameActive()
            }
        }
    }

    /// Links or unlinks the exercise at `index` with the one below it (in the on-screen order).
    private func toggleSuperset(at index: Int) {
        withAnimation(.standardSpring) {
            SupersetLayout.toggleLink(at: index, in: cachedExercises)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        // Persist the current on-screen order along with the link so they can't disagree
        commitReorder()
    }

    private func commitReorder() {
        // Reordering can strand a superset member away from its partners; clear those
        SupersetLayout.normalize(cachedExercises)
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
    var supersetSlot: SupersetSlot? = nil
    /// nil hides the link button (last exercise in the list)
    var linkToNext: SupersetLinkButton.LinkState? = nil
    var onToggleLink: () -> Void = {}
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @Query private var exercises: [Exercise]
    @Query private var allSets: [WorkoutSet]

    // Custom initializer to filter sets by exercise ID at the database level
    init(
        workoutExercise: WorkoutExercise,
        workout: Workout,
        supersetSlot: SupersetSlot? = nil,
        linkToNext: SupersetLinkButton.LinkState? = nil,
        onToggleLink: @escaping () -> Void = {}
    ) {
        self.workoutExercise = workoutExercise
        self.workout = workout
        self.supersetSlot = supersetSlot
        self.linkToNext = linkToNext
        self.onToggleLink = onToggleLink

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

    // MARK: - PR detection
    // A PR is a new best WEIGHT (kg-normalized), not set volume: 225×2 outranks 150×20.
    // Reps-only exercises have no weight, so their PR is a new best rep count.

    private func prScore(_ set: WorkoutSet) -> Double? {
        if exercise?.isRepsOnly == true {
            return set.reps.map(Double.init)
        }
        guard let weight = set.weight, weight > 0, (set.reps ?? 0) > 0 else { return nil }
        return WeightUnitConverter.toKg(weight, from: set.unit)
    }

    /// Best score from completed sets before this workout's day. Calculated once per row.
    private var bestPreviousScore: Double? {
        let todayStart = Calendar.current.startOfDay(for: workout.date)
        return allSets
            .filter { $0.isCompleted && $0.date < todayStart }
            .compactMap(prScore)
            .max()
    }

    /// The single best completed set today (first one wins ties, so only one trophy shows).
    private var todaysBestSet: WorkoutSet? {
        var best: (set: WorkoutSet, score: Double)?
        for set in sortedSets where set.isCompleted {
            guard let score = prScore(set) else { continue }
            if best == nil || score > best!.score { best = (set, score) }
        }
        return best?.set
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

    // MARK: - E1RM Comparison Computed Properties

    private var currentSessionE1RM: Double? {
        E1RMCalculator.fromSession(sortedSets)
    }

    private var lastSessionE1RM: Double? {
        guard let lastSession = ExerciseService.shared.getLastSessionForExerciseExcludingDate(
            exerciseId: workoutExercise.exerciseId,
            excludeDate: workout.date,
            modelContext: modelContext
        ) else { return nil }

        return E1RMCalculator.fromSession(lastSession)
    }

    private var e1rmChangePercent: Double? {
        guard let currentE1RM = currentSessionE1RM,
              let lastE1RM = lastSessionE1RM,
              lastE1RM > 0 else { return nil }
        return ((currentE1RM - lastE1RM) / lastE1RM) * 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with exercise name and delete
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    if let supersetSlot {
                        SupersetBadge(slot: supersetSlot)
                    }
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

                if let linkToNext {
                    SupersetLinkButton(state: linkToNext, action: onToggleLink)
                }

                Button(action: { deleteExercise() }) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.errorRed)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Stats indicator (shows volume and E1RM changes)
            SimplifiedStatsIndicator(
                volumeChange: volumeChangePercent,
                e1rmChange: e1rmChangePercent
            )

            // Set history - grid layout (2 columns)
            if !sortedSets.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.flexible(), alignment: .leading),
                    GridItem(.flexible(), alignment: .leading)
                ], spacing: 8) {
                    let todaysBest = todaysBestSet
                    let previousBest = bestPreviousScore
                    ForEach(sortedSets, id: \.id) { set in
                        HStack(spacing: 6) {
                            if set.isCompleted {
                                if isPR(set: set, todaysBest: todaysBest, previousBest: previousBest) {
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
        .overlay(alignment: .leading) {
            if supersetSlot != nil {
                SupersetStripe()
            }
        }
        .onTapGesture {
            if let exercise = exercise {
                appState.selectedExerciseDate = workout.date
                appState.selectedExercise = exercise
            }
        }
    }
    
    private func formatSetDisplay(set: WorkoutSet) -> String {
        if let weight = set.weight, let reps = set.reps {
            return "\(reps)\u{00D7}\(formattedWeight(for: weight)) \(set.unit)"
        } else if let weight = set.weight {
            return "\(formattedWeight(for: weight)) \(set.unit)"
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

    private func isPR(set: WorkoutSet, todaysBest: WorkoutSet?, previousBest: Double?) -> Bool {
        guard let todaysBest, todaysBest.id == set.id,
              let previousBest, let score = prScore(set) else {
            return false
        }
        return score > previousBest
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

            // Auto-persist last session's sets so volume comparison shows immediately
            // Skip if sets already exist for this exercise on this date (e.g., from routine hydration)
            let existingSets = ExerciseService.shared.getSetsByDate(
                exerciseId: exerciseId,
                date: targetWorkout.date,
                modelContext: modelContext
            )
            if existingSets.isEmpty,
               let lastSession = ExerciseService.shared.getLastSessionForExercise(
                exerciseId: exerciseId,
                modelContext: modelContext
            ), !lastSession.isEmpty {
                let setData = lastSession.map { (weight: $0.weight, reps: $0.reps, rpe: Int?(nil), rir: Int?(nil), isCompleted: false) }
                // Get exercise to retrieve its unit
                let exercise = ExerciseService.shared.getExercise(by: exerciseId, modelContext: modelContext)
                _ = ExerciseService.shared.saveSets(
                    exerciseId: exerciseId,
                    date: targetWorkout.date,
                    unit: exercise?.unit ?? "kg",
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

// MARK: - Save Workout as Routine Dialog
struct SaveWorkoutAsRoutineView: View {
    @Binding var isPresented: Bool
    let workout: Workout?
    let modelContext: ModelContext
    let onComplete: () -> Void

    @State private var routineName = ""
    @State private var routineDescription = ""
    @FocusState private var isNameFieldFocused: Bool
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]

    // Schedule configuration state
    @State private var selectedColor: RoutineColor = .teal
    @State private var selectedScheduleType: RoutineScheduleType = .none
    @State private var selectedDays: Set<Int> = []
    @State private var intervalDays: Int = 2
    @State private var startDate: Date = Date()

    var body: some View {
        NavigationStack {
                ZStack {
                    Color.primaryBg
                        .ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: 16) {
                            // Routine Details Card
                            FormSectionCard(title: "Routine Details") {
                                LabeledTextInput(
                                    label: "Routine Name",
                                    placeholder: "e.g., Push Day, Leg Day",
                                    text: $routineName
                                )

                                LabeledTextInput(
                                    label: "Description (optional)",
                                    placeholder: "e.g., Chest, Shoulders, Triceps",
                                    text: $routineDescription,
                                    axis: .vertical,
                                    lineLimit: 3...6
                                )
                            }

                        // Exercises Preview Card
                        if let workout = workout, !workout.exercises.isEmpty {
                            FormSectionCard(title: "Exercises to Include") {
                                VStack(spacing: 8) {
                                    ForEach(workout.exercises.sorted { $0.order < $1.order }, id: \.id) { workoutExercise in
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.accentSuccess)
                                                .font(.system(size: 16))

                                            if let exercise = allExercises.first(where: { $0.id == workoutExercise.exerciseId }) {
                                                Text(exercise.name)
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.textPrimary)
                                            }

                                            Spacer()
                                        }
                                        .padding(12)
                                        .background(Color.tertiaryBg)
                                        .cornerRadius(8)
                                    }
                                }
                            }
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
                        }

                        Spacer(minLength: 100) // Space for fixed button
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }

                    // Fixed CTA at bottom
                    FixedModalCTAButton(
                        title: "Save Routine",
                        icon: "checkmark",
                        isEnabled: !routineName.isEmpty && isValidSchedule,
                        action: saveRoutine
                    )
                }
                .navigationTitle("Save as Routine")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            isPresented = false
                        }
                        .foregroundColor(.accentPrimary)
                    }
                }
                .onAppear {
                    isNameFieldFocused = true
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

    private func saveRoutine() {
        guard let workout = workout else {
            isPresented = false
            return
        }

        // Create the routine
        let routine = RoutineService.shared.createRoutine(
            name: routineName,
            description: routineDescription.isEmpty ? nil : routineDescription,
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

        // Copy exercises from workout to routine
        let sortedExercises = workout.exercises.sorted { $0.order < $1.order }
        for workoutExercise in sortedExercises {
            let routineExercise = RoutineService.shared.addExerciseToRoutine(
                routine: routine,
                exerciseId: workoutExercise.exerciseId,
                notes: workoutExercise.notes,
                modelContext: modelContext
            )
            routineExercise.supersetGroupId = workoutExercise.supersetGroupId
        }

        // Save to database
        do {
            try modelContext.save()
        } catch {
            print("Error saving routine: \(error)")
        }

        isPresented = false
        onComplete()
    }
}

// MARK: - Update Routine From Workout View
struct UpdateRoutineFromWorkoutView: View {
    @Binding var isPresented: Bool
    let workout: Workout?
    let modelContext: ModelContext

    @Query(sort: \Routine.name) private var routines: [Routine]
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]
    @State private var showingConfirmation = false
    @State private var selectedRoutine: Routine?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.primaryBg
                    .ignoresSafeArea()

                if routines.isEmpty {
                    EmptyStateView(
                        icon: "list.bullet.rectangle",
                        title: "No routines",
                        subtitle: "Create a routine first to update it",
                        actionTitle: nil,
                        onAction: nil
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(routines) { routine in
                                UpdateRoutineCardView(routine: routine) {
                                    selectedRoutine = routine
                                    showingConfirmation = true
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    }
                }
            }
            .navigationTitle("Update Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.accentPrimary)
                }
            }
            .alert("Update Routine", isPresented: $showingConfirmation) {
                Button("Cancel", role: .cancel) {
                    selectedRoutine = nil
                }
                Button("Update", role: .destructive) {
                    if let routine = selectedRoutine {
                        updateRoutine(routine)
                    }
                }
            } message: {
                if let routine = selectedRoutine {
                    Text("Replace all exercises in \"\(routine.name)\" with exercises from this workout?")
                }
            }
        }
    }

    private func updateRoutine(_ routine: Routine) {
        guard let workout = workout else {
            isPresented = false
            return
        }

        // Remove all existing exercises from the routine
        for exercise in routine.exercises {
            modelContext.delete(exercise)
        }
        routine.exercises.removeAll()

        // Add exercises from workout to routine
        let sortedExercises = workout.exercises.sorted { $0.order < $1.order }
        for (index, workoutExercise) in sortedExercises.enumerated() {
            let routineExercise = RoutineExercise(
                exerciseId: workoutExercise.exerciseId,
                order: index + 1,
                notes: workoutExercise.notes
            )
            routineExercise.supersetGroupId = workoutExercise.supersetGroupId
            routine.exercises.append(routineExercise)
            modelContext.insert(routineExercise)
        }

        // Save to database
        do {
            try modelContext.save()
        } catch {
            print("Error updating routine: \(error)")
        }

        isPresented = false
    }
}

// MARK: - Update Routine Card View
struct UpdateRoutineCardView: View {
    let routine: Routine
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Color indicator
                Circle()
                    .fill(Color.forRoutineColor(routine.color))
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.name)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)

                    Text("\(routine.exercises.count) exercises")
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textTertiary)
            }
            .padding(16)
            .background(Color.secondaryBg)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
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