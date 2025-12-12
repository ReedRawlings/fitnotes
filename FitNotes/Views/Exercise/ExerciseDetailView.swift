import SwiftUI
import SwiftData

struct ExerciseDetailView: View {
    @Bindable var exercise: Exercise
    var workout: Workout?
    var workoutExercise: WorkoutExercise?
    var shouldDismissOnSave: Bool = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    
    @State private var selectedTab = 0
    @State private var showSettings = false
    @StateObject private var timerManager: RestTimerManager

    init(exercise: Exercise, workout: Workout? = nil, workoutExercise: WorkoutExercise? = nil, shouldDismissOnSave: Bool = false, appState: AppState) {
        self.exercise = exercise
        self.workout = workout
        self.workoutExercise = workoutExercise
        self.shouldDismissOnSave = shouldDismissOnSave
        _timerManager = StateObject(wrappedValue: RestTimerManager(appState: appState, filterExerciseId: exercise.id))
    }

    // MARK: - Stats Computed Properties

    private var todaySets: [WorkoutSet] {
        ExerciseService.shared.getSetsByDate(
            exerciseId: exercise.id,
            date: Date(),
            modelContext: modelContext
        )
    }

    private var lastSession: [WorkoutSet]? {
        ExerciseService.shared.getLastSessionForExerciseExcludingDate(
            exerciseId: exercise.id,
            excludeDate: Date(),
            modelContext: modelContext
        )
    }

    private var currentVolume: Double {
        ExerciseService.shared.calculateVolumeFromSets(todaySets)
    }

    private var lastVolume: Double? {
        guard let lastSession = lastSession else { return nil }
        return ExerciseService.shared.calculateVolumeFromSets(lastSession)
    }

    private var currentE1RM: Double? {
        E1RMCalculator.fromSession(todaySets)
    }

    private var lastE1RM: Double? {
        guard let lastSession = lastSession else { return nil }
        return E1RMCalculator.fromSession(lastSession)
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
                if let timer = appState.activeRestTimer, timer.exerciseId == exercise.id {
                    RestTimerBannerView(
                        timer: timer,
                        showCompletionState: $timerManager.showCompletionState,
                        celebrationScale: $timerManager.celebrationScale,
                        onSkip: {
                            timerManager.skipTimer()
                        }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
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

                // Progression Banner
                ProgressionBannerView(exercise: exercise, modelContext: modelContext)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)

                // Custom Tab Bar
                CustomTabBar(selectedTab: $selectedTab)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)  // Reduced from 16

                // Exercise Stats View
                ExerciseStatsView(
                    exercise: exercise,
                    currentVolume: currentVolume,
                    lastVolume: lastVolume,
                    currentE1RM: currentE1RM,
                    lastE1RM: lastE1RM,
                    unit: exercise.unit
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                // Tab Content
                if selectedTab == 0 {
                    TrackTabView(exercise: exercise, workout: workout, workoutExercise: workoutExercise, onSaveSuccess: shouldDismissOnSave ? {
                        dismiss()
                    } : nil)
                } else {
                    HistoryTabView(exercise: exercise)
                }
            }
        }
    }
}

// MARK: - Progression Banner View
struct ProgressionBannerView: View {
    let exercise: Exercise
    let modelContext: ModelContext

    private var progressionStatus: ProgressionStatus {
        ProgressionService.analyzeProgressionStatus(exercise: exercise, modelContext: modelContext)
    }

    private var shouldShowBanner: Bool {
        switch progressionStatus {
        case .insufficientData, .maintainingBelowTarget:
            return false
        default:
            return true
        }
    }

    var body: some View {
        if shouldShowBanner {
            HStack(spacing: 10) {
                // Icon
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(bannerColor)

                // Message
                VStack(alignment: .leading, spacing: 2) {
                    Text(progressionStatus.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.textPrimary)

                    Text(progressionStatus.getMessage(unit: exercise.unit))
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(bannerColor.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private var iconName: String {
        switch progressionStatus {
        case .readyToIncreaseReps, .readyToIncreaseWeight:
            return "arrow.up.circle.fill"
        case .progressingTowardTarget:
            return "chart.line.uptrend.xyaxis"
        case .decliningPerformance:
            return "exclamationmark.triangle.fill"
        case .recentlyRegressed:
            return "arrow.uturn.backward.circle.fill"
        default:
            return "info.circle.fill"
        }
    }

    private var bannerColor: Color {
        switch progressionStatus {
        case .readyToIncreaseReps, .readyToIncreaseWeight:
            return .green
        case .progressingTowardTarget:
            return .blue
        case .decliningPerformance:
            return .orange
        case .recentlyRegressed:
            return .yellow
        default:
            return .gray
        }
    }

    private var backgroundColor: Color {
        switch progressionStatus {
        case .readyToIncreaseReps, .readyToIncreaseWeight:
            return Color.green.opacity(0.15)
        case .progressingTowardTarget:
            return Color.blue.opacity(0.10)
        case .decliningPerformance:
            return Color.orange.opacity(0.15)
        case .recentlyRegressed:
            return Color.yellow.opacity(0.15)
        default:
            return Color.gray.opacity(0.10)
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
            timeRemaining = timer.timeRemaining
            updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                timeRemaining = timer.timeRemaining
            }
        }
        .onDisappear {
            updateTimer?.invalidate()
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
