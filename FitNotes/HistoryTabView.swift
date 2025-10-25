import SwiftUI
import SwiftData

struct HistoryTabView: View {
    let exercise: Exercise
    @Environment(\.modelContext) private var modelContext
    
    @Query private var allSets: [WorkoutSet]
    
    private var groupedSets: [(Date, [WorkoutSet])] {
        let filteredSets = allSets.filter { $0.exerciseId == exercise.id }
        let grouped = Dictionary(grouping: filteredSets) { Calendar.current.startOfDay(for: $0.date) }
        return grouped.sorted { $0.key > $1.key }
    }
    
    var body: some View {
        ZStack {
            // Dark background
            Color.primaryBg
                .ignoresSafeArea()
            
            if groupedSets.isEmpty {
                EmptyHistoryState()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(groupedSets, id: \.0) { date, sets in
                            VStack(spacing: 0) {
                                // Sticky Date Header
                                DateHeaderView(date: date)
                                    .background(Color.primaryBg)
                                
                                // Session Cards
                                VStack(spacing: 8) {
                                    ForEach(sets.sorted { $0.order < $1.order }) { set in
                                        SessionCardView(set: set)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.bottom, 20)
                            }
                        }
                    }
                    .padding(.top, 20)
                }
            }
        }
    }
}

// MARK: - Date Header View
struct DateHeaderView: View {
    let date: Date
    
    private var relativeTime: String {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: date, to: Date()).day ?? 0
        
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "1 day ago"
        } else {
            return "\(days) days ago"
        }
    }
    
    var body: some View {
        HStack {
            Text(date.formatted(.dateTime.weekday(.wide).month(.wide).day(.twoDigits)))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            Text(relativeTime)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.primaryBg)
    }
}

// MARK: - Session Card View
struct SessionCardView: View {
    let set: WorkoutSet
    
    var body: some View {
        HStack {
            Text("Set \(set.order):")
                .font(.bodyFont)
                .foregroundColor(.textSecondary)
            
            Text("\(formatWeight(set.weight))kg × \(set.reps) reps")
                .font(.historySetData)
                .foregroundColor(.textPrimary)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.secondaryBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
    
    private func formatWeight(_ weight: Double) -> String {
        if weight.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(weight))"
        } else {
            return String(format: "%.1f", weight)
        }
    }
}

// MARK: - Empty History State
struct EmptyHistoryState: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.textTertiary.opacity(0.3))
            
            VStack(spacing: 8) {
                Text("No history yet")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.textSecondary)
                
                Text("Complete your first workout to see it here")
                    .font(.bodyFont)
                    .foregroundColor(.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
    }
}

#Preview {
    HistoryTabView(exercise: Exercise(
        name: "Bench Press",
        category: "Chest",
        type: "Strength"
    ))
    .modelContainer(for: [Exercise.self, Workout.self, WorkoutSet.self, WorkoutExercise.self], inMemory: true)
}
