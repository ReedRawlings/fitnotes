import SwiftUI
import SwiftData

struct ExerciseDetailView: View {
    let exercise: Exercise
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // Dark charcoal background
            Color.primaryBg
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation Bar
                HStack {
                    Spacer()
                    
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.accentPrimary)
                    .accessibilityLabel("Done")
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .frame(height: 44)
                
                // Exercise Title Section
                VStack(spacing: 16) {
                    // Exercise Name
                    Text(exercise.name)
                        .font(.exerciseTitle)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                        .kerning(-0.5) // Tighter letter spacing for large display text
                    
                    // Settings Button (placeholder for now)
                    HStack {
                        Spacer()
                        Button(action: {
                            // TODO: Present exercise settings modal
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.textSecondary)
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("Exercise settings")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 16)
                
                // Custom Tab Bar
                CustomTabBar(selectedTab: $selectedTab)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                
                // Tab Content
                if selectedTab == 0 {
                    TrackTabView(exercise: exercise)
                } else {
                    HistoryTabView(exercise: exercise)
                }
            }
        }
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
        category: "Chest",
        type: "Strength"
    ))
    .modelContainer(for: [Exercise.self, Workout.self, WorkoutSet.self, WorkoutExercise.self], inMemory: true)
}
