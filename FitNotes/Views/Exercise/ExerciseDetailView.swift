import SwiftUI
import SwiftData

struct ExerciseDetailView: View {
    @Bindable var exercise: Exercise
    var workout: Workout?
    var workoutExercise: WorkoutExercise?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var appState: AppState

    @State private var selectedTab = 0
    @State private var showSettings = false
    @State private var showPlateCalculator = false
    // Observes the single shared manager on AppState — a per-view instance would
    // split completion state from the Live Activity owner
    @ObservedObject private var timerManager: RestTimerManager

    init(exercise: Exercise, workout: Workout? = nil, workoutExercise: WorkoutExercise? = nil, appState: AppState) {
        self.exercise = exercise
        self.workout = workout
        self.workoutExercise = workoutExercise
        _timerManager = ObservedObject(wrappedValue: appState.restTimerManager)
    }

    // MARK: - Stats Computed Properties

    /// The date this detail view is scoped to. Matches TrackTabView's convention:
    /// the workout's date if one was resolved, else the date context set by the tap
    /// site (`appState.selectedExerciseDate`), else today.
    private var targetDate: Date {
        workout?.date ?? appState.selectedExerciseDate ?? Date()
    }

    private var todaySets: [WorkoutSet] {
        ExerciseService.shared.getSetsByDate(
            exerciseId: exercise.id,
            date: targetDate,
            modelContext: modelContext
        )
    }

    private var lastSession: [WorkoutSet]? {
        ExerciseService.shared.getLastSessionForExerciseExcludingDate(
            exerciseId: exercise.id,
            excludeDate: targetDate,
            modelContext: modelContext
        )
    }

    /// Header stats, cached so they aren't refetched on every render. Refreshed on appear and
    /// whenever the Track tab saves a change. Values are in the exercise's display unit (or reps
    /// for reps-only exercises), counting checked sets only.
    @State private var stats = SessionStats()

    struct SessionStats {
        var currentVolume: Double = 0
        var lastVolume: Double?
        var currentE1RM: Double?
        var lastE1RM: Double?
    }

    private func refreshStats() {
        let today = todaySets.filter(\.isCompleted)
        let last = lastSession
        if exercise.isRepsOnly {
            let totalReps: ([WorkoutSet]) -> Double = { Double($0.compactMap(\.reps).reduce(0, +)) }
            let bestReps: ([WorkoutSet]) -> Double? = { $0.compactMap(\.reps).max().map(Double.init) }
            stats = SessionStats(
                currentVolume: totalReps(today),
                lastVolume: last.map(totalReps),
                currentE1RM: bestReps(today),
                lastE1RM: last.flatMap(bestReps)
            )
        } else {
            // calculateVolumeFromSets works in kg; show it in the exercise's unit
            let volume: ([WorkoutSet]) -> Double = {
                WeightUnitConverter.fromKg(ExerciseService.shared.calculateVolumeFromSets($0), to: exercise.unit)
            }
            stats = SessionStats(
                currentVolume: volume(today),
                lastVolume: last.map(volume),
                currentE1RM: E1RMCalculator.fromSession(today),
                lastE1RM: last.flatMap { E1RMCalculator.fromSession($0) }
            )
        }
    }

    /// Exercises whose rest timer belongs on this screen: this one, plus the rest of its superset
    /// (the round's rest is started by the last exercise but taken before the first one).
    private var restTimerExerciseIds: Set<UUID> {
        guard let workout, let workoutExercise,
              let run = SupersetLayout.run(
                containing: workoutExercise.id,
                in: workout.exercises.sorted { $0.order < $1.order }
              ) else {
            return [exercise.id]
        }
        return Set(run.map(\.exerciseId))
    }

    var body: some View {
        ZStack {
            // Dark charcoal background
            Color.primaryBg
                .ignoresSafeArea(.container, edges: .all)

            VStack(spacing: 0) {
                // Exercise Title Section
                HStack {
                    // Exercise Name
                    Text(exercise.name)
                        .font(.exerciseTitle)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                        .kerning(-0.5) // Tighter letter spacing for large display text
                    
                    Spacer()

                    // Plate calculator for barbell-style lifts
                    if exercise.equipment == "Free Weight" && !exercise.isRepsOnly {
                        Button(action: { showPlateCalculator = true }) {
                            Image(systemName: "scalemass.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.textSecondary)
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("Plate calculator")
                        .sheet(isPresented: $showPlateCalculator) {
                            NavigationStack {
                                PlateCalculatorView(
                                    unit: exercise.unit,
                                    initialWeight: (todaySets + (lastSession ?? [])).compactMap(\.weight).max()
                                )
                            }
                            .presentationDetents([.medium, .large])
                        }
                    }

                    // Settings Button (inline with title)
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.textSecondary)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Exercise settings")
                    .sheet(isPresented: $showSettings) {
                        NavigationStack {
                            ExerciseSettingsView(exercise: exercise)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)
                
                // Rest Timer Banner
                if let timer = appState.activeRestTimer, restTimerExerciseIds.contains(timer.exerciseId) {
                    RestTimerBannerView(
                        timer: timer,
                        showCompletionState: $timerManager.showCompletionState,
                        celebrationScale: $timerManager.celebrationScale,
                        onSkip: {
                            timerManager.skipTimer()
                        }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onChange(of: timer.isCompleted) { _, isCompleted in
                        if isCompleted && !timerManager.showCompletionState {
                            timerManager.handleTimerCompletion()
                        }
                    }
                }

                // Custom Tab Bar
                CustomTabBar(selectedTab: $selectedTab)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)  // Reduced from 16

                // Exercise Stats View
                ExerciseStatsView(
                    exercise: exercise,
                    currentVolume: stats.currentVolume,
                    lastVolume: stats.lastVolume,
                    currentE1RM: stats.currentE1RM,
                    lastE1RM: stats.lastE1RM,
                    unit: exercise.isRepsOnly ? "reps" : exercise.unit
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                // Tab Content
                if selectedTab == 0 {
                    TrackTabView(exercise: exercise, workout: workout, workoutExercise: workoutExercise, onSetsChanged: refreshStats)
                } else {
                    HistoryTabView(exercise: exercise)
                }
            }
        }
        .onAppear(perform: refreshStats)
        .onChange(of: exercise.trackingTypeRaw) { _, _ in refreshStats() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // When app becomes active (e.g., from notification tap), dismiss completed timers
                timerManager.handleAppBecameActive()
            }
        }
    }
}

// MARK: - Rest Timer Banner View
struct RestTimerBannerView: View {
    let timer: RestTimer
    @Binding var showCompletionState: Bool
    @Binding var celebrationScale: CGFloat
    let onSkip: () -> Void
    
    @State private var timeRemaining: TimeInterval = 0
    @State private var updateTimer: Timer?
    
    var body: some View {
        VStack(spacing: 0) {
            if showCompletionState || timer.isCompleted {
                // Completed State
                HStack {
                    Text("Rest Complete! 🎉")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Button("Dismiss") {
                        onSkip()
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.accentPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .frame(height: 60)
                .background(Color.tertiaryBg)
                .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
                .scaleEffect(celebrationScale)
            } else {
                // Active State
                VStack(spacing: 10) {
                    HStack {
                        Text("Rest: \(formatTime(timeRemaining)) remaining")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button("Skip Rest") {
                            onSkip()
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.textSecondary)
                    }
                    
                    // Progress Bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background track
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 6)
                            
                            // Progress fill
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [.accentPrimary, .accentSecondary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * CGFloat(timer.progress), height: 6)
                                .animation(.linear(duration: 0.1), value: timer.progress)
                        }
                    }
                    .frame(height: 6)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .frame(height: 60)
                .background(Color.tertiaryBg)
                .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
            }
        }
        .onAppear {
            startLocalTimer()
        }
        .onDisappear {
            updateTimer?.invalidate()
        }
        .onChange(of: timer.id) { _, _ in
            // Timer was restarted - reset local state
            startLocalTimer()
        }
    }

    private func startLocalTimer() {
        updateTimer?.invalidate()
        timeRemaining = timer.timeRemaining
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            timeRemaining = timer.timeRemaining
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(max(0, seconds))
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            // Track Tab
            TabButton(
                title: "Track",
                isSelected: selectedTab == 0,
                action: {
                    withAnimation(.standardSpring) {
                        selectedTab = 0
                    }
                }
            )
            
            // History Tab
            TabButton(
                title: "History",
                isSelected: selectedTab == 1,
                action: {
                    withAnimation(.standardSpring) {
                        selectedTab = 1
                    }
                }
            )
        }
        .padding(4)
        .background(Color.secondaryBg)
        .cornerRadius(12)
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(isSelected ? .system(size: 15, weight: .semibold) : .tabFont)
                .foregroundColor(isSelected ? .textPrimary : .textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.tertiaryBg : Color.clear)
                )
                .scaleEffect(isSelected ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .accessibilityLabel("\(title) tab")
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    let appState = AppState()
    return ExerciseDetailView(
        exercise: Exercise(
            name: "Bench Press",
            primaryCategory: "Chest",
            secondaryCategories: ["Triceps", "Shoulders"],
            equipment: "Machine"
        ),
        appState: appState
    )
    .modelContainer(for: [Exercise.self, Workout.self, WorkoutSet.self, WorkoutExercise.self], inMemory: true)
    .environmentObject(appState)
}
