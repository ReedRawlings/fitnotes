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
    @State private var timerUpdateTimer: Timer?
    @State private var showCompletionState = false
    @State private var celebrationScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Dark charcoal background
            Color.primaryBg
                .ignoresSafeArea()
            
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
                        showCompletionState: $showCompletionState,
                        celebrationScale: $celebrationScale,
                        onSkip: {
                            appState.cancelRestTimer()
                            showCompletionState = false
                            celebrationScale = 1.0
                        }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        startTimerUpdates()
                    }
                    .onDisappear {
                        stopTimerUpdates()
                    }
                    .onChange(of: timer.isCompleted) { _, isCompleted in
                        if isCompleted && !showCompletionState {
                            handleTimerCompletion()
                        }
                    }
                }
                
                // Custom Tab Bar
                CustomTabBar(selectedTab: $selectedTab)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)  // Reduced from 16
                
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
    
    private func startTimerUpdates() {
        timerUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            // Force view update by checking timer state
            if let timer = appState.activeRestTimer, timer.exerciseId == exercise.id {
                if timer.isCompleted && !showCompletionState {
                    handleTimerCompletion()
                }
            }
        }
    }
    
    private func stopTimerUpdates() {
        timerUpdateTimer?.invalidate()
        timerUpdateTimer = nil
    }
    
    private func handleTimerCompletion() {
        showCompletionState = true
        
        // Success haptic
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        // Celebration animation: scale 1.0 -> 1.05 -> 1.0
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            celebrationScale = 1.05
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                celebrationScale = 1.0
            }
        }
        
        // Auto-dismiss after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            appState.cancelRestTimer()
            showCompletionState = false
            celebrationScale = 1.0
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
                            .foregroundColor(.textPrimary)
                        
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
    ExerciseDetailView(exercise: Exercise(
        name: "Bench Press",
        primaryCategory: "Chest",
        secondaryCategories: ["Triceps", "Shoulders"],
        equipment: "Machine"
    ))
    .modelContainer(for: [Exercise.self, Workout.self, WorkoutSet.self, WorkoutExercise.self], inMemory: true)
    .environmentObject(AppState())
}
