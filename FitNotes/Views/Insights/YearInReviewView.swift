import SwiftUI
import Charts

// MARK: - YearInReviewCard
/// A card that shows Year in Review link when available
struct YearInReviewCard: View {
    let currentYear: Int
    let hasData: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.accentPrimary, .accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.textInverse)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(currentYear) Year in Review")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.textPrimary)

                    Text(hasData ? "See your fitness journey highlights" : "Complete workouts to unlock")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textTertiary)
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Color.accentPrimary.opacity(0.08), Color.accentSecondary.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.accentPrimary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!hasData)
        .opacity(hasData ? 1 : 0.6)
    }
}

// MARK: - YearInReviewSheet
/// Full year in review presentation (Spotify Wrapped style)
struct YearInReviewSheet: View {
    let data: InsightsService.YearInReviewData
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    @State private var animateContent = false

    private let totalPages = 6

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: backgroundColors(for: currentPage),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentPage)

            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(18)
                    }

                    Spacer()

                    // Page indicators
                    HStack(spacing: 6) {
                        ForEach(0..<totalPages, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Color.white : Color.white.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }

                    Spacer()

                    // Placeholder for symmetry
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // Content
                TabView(selection: $currentPage) {
                    // Page 1: Overview
                    OverviewPage(data: data, animate: animateContent)
                        .tag(0)

                    // Page 2: Top Exercises
                    TopExercisesPage(data: data, animate: animateContent)
                        .tag(1)

                    // Page 3: Volume Stats
                    VolumeStatsPage(data: data, animate: animateContent)
                        .tag(2)

                    // Page 4: Streaks & Consistency
                    ConsistencyPage(data: data, animate: animateContent)
                        .tag(3)

                    // Page 5: Monthly Activity
                    MonthlyActivityPage(data: data, animate: animateContent)
                        .tag(4)

                    // Page 6: Summary
                    SummaryPage(data: data, animate: animateContent)
                        .tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Navigation hint
                Text("Swipe to continue")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                animateContent = true
            }
        }
        .onChange(of: currentPage) { _, _ in
            animateContent = false
            withAnimation(.easeOut(duration: 0.4)) {
                animateContent = true
            }
        }
    }

    private func backgroundColors(for page: Int) -> [Color] {
        switch page {
        case 0: return [Color(hex: "#FF6B35"), Color(hex: "#F7931E")]
        case 1: return [Color(hex: "#5B9FFF"), Color(hex: "#BA68C8")]
        case 2: return [Color(hex: "#00D9A3"), Color(hex: "#5B9FFF")]
        case 3: return [Color(hex: "#FF7597"), Color(hex: "#FF6B35")]
        case 4: return [Color(hex: "#F7931E"), Color(hex: "#00D9A3")]
        case 5: return [Color(hex: "#BA68C8"), Color(hex: "#FF6B35")]
        default: return [Color(hex: "#FF6B35"), Color(hex: "#F7931E")]
        }
    }
}

// MARK: - Page Components

struct OverviewPage: View {
    let data: InsightsService.YearInReviewData
    let animate: Bool

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("\(data.year)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .scaleEffect(animate ? 1 : 0.8)
                .opacity(animate ? 1 : 0)

            Text("Your Year in Review")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white.opacity(0.9))
                .opacity(animate ? 1 : 0)

            VStack(spacing: 16) {
                StatHighlight(value: "\(data.totalWorkouts)", label: "Workouts")
                StatHighlight(value: "\(data.totalSets)", label: "Sets Completed")
                StatHighlight(value: formatVolume(data.totalVolume), label: "Total Volume")
            }
            .opacity(animate ? 1 : 0)
            .offset(y: animate ? 0 : 20)

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000000 {
            return String(format: "%.1fM kg", volume / 1000000)
        } else if volume >= 1000 {
            return String(format: "%.0fk kg", volume / 1000)
        } else {
            return String(format: "%.0f kg", volume)
        }
    }
}

struct TopExercisesPage: View {
    let data: InsightsService.YearInReviewData
    let animate: Bool

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Your Top Exercises")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .opacity(animate ? 1 : 0)

            if let favorite = data.favoriteExercise {
                VStack(spacing: 8) {
                    Text("#1")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))

                    Text(favorite.name)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("\(favorite.count) sets")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .scaleEffect(animate ? 1 : 0.8)
                .opacity(animate ? 1 : 0)
            }

            VStack(spacing: 12) {
                ForEach(Array(data.topThreeExercises.dropFirst().enumerated()), id: \.offset) { index, exercise in
                    HStack {
                        Text("#\(index + 2)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 40)

                        Text(exercise.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)

                        Spacer()

                        Text("\(exercise.count) sets")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .opacity(animate ? 1 : 0)
            .offset(y: animate ? 0 : 20)

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

struct VolumeStatsPage: View {
    let data: InsightsService.YearInReviewData
    let animate: Bool

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("You Moved")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
                .opacity(animate ? 1 : 0)

            Text(formatVolume(data.totalVolume))
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .scaleEffect(animate ? 1 : 0.8)
                .opacity(animate ? 1 : 0)

            if let growth = data.volumeGrowth {
                HStack(spacing: 8) {
                    Image(systemName: growth >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 18, weight: .bold))
                    Text("\(String(format: "%.0f", abs(growth)))% vs last year")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.15))
                .cornerRadius(20)
                .opacity(animate ? 1 : 0)
            }

            if let muscle = data.mostTrainedMuscle {
                VStack(spacing: 8) {
                    Text("Most Trained")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))

                    Text(muscle.name)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("\(String(format: "%.0f", muscle.percentage))% of total volume")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 20)
                .opacity(animate ? 1 : 0)
                .offset(y: animate ? 0 : 20)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000000 {
            return String(format: "%.1fM kg", volume / 1000000)
        } else if volume >= 1000 {
            return String(format: "%.0fk kg", volume / 1000)
        } else {
            return String(format: "%.0f kg", volume)
        }
    }
}

struct ConsistencyPage: View {
    let data: InsightsService.YearInReviewData
    let animate: Bool

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("Consistency King")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .opacity(animate ? 1 : 0)

            HStack(spacing: 40) {
                VStack(spacing: 8) {
                    Text("\(data.longestStreak)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Day Streak")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .scaleEffect(animate ? 1 : 0.8)
                .opacity(animate ? 1 : 0)

                VStack(spacing: 8) {
                    Text("\(data.activeWeeks)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Active Weeks")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .scaleEffect(animate ? 1 : 0.8)
                .opacity(animate ? 1 : 0)
            }

            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 20))
                    Text("\(data.personalRecords) Personal Records")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.15))
                .cornerRadius(12)

                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 20))
                    Text("\(String(format: "%.1f", data.avgWorkoutsPerWeek)) avg workouts/week")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.15))
                .cornerRadius(12)
            }
            .opacity(animate ? 1 : 0)
            .offset(y: animate ? 0 : 20)

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

struct MonthlyActivityPage: View {
    let data: InsightsService.YearInReviewData
    let animate: Bool

    private let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Your Year by Month")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .opacity(animate ? 1 : 0)

            // Monthly bar chart
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(data.monthlyWorkouts, id: \.month) { monthData in
                    VStack(spacing: 4) {
                        if monthData.count > 0 {
                            Text("\(monthData.count)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.8))
                        }

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(monthData.count > 0 ? 0.8 : 0.2))
                            .frame(height: CGFloat(monthData.count * 8 + 4))

                        Text(monthNames[monthData.month - 1])
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 200)
            .scaleEffect(x: 1, y: animate ? 1 : 0, anchor: .bottom)
            .opacity(animate ? 1 : 0)

            if let bestMonth = data.bestMonth {
                VStack(spacing: 4) {
                    Text("Best Month")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))

                    Text(monthNames[bestMonth.month - 1])
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    Text("\(bestMonth.workouts) workouts")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.top, 16)
                .opacity(animate ? 1 : 0)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
    }
}

struct SummaryPage: View {
    let data: InsightsService.YearInReviewData
    let animate: Bool

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("That's a Wrap!")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
                .scaleEffect(animate ? 1 : 0.8)
                .opacity(animate ? 1 : 0)

            Image(systemName: "trophy.fill")
                .font(.system(size: 64))
                .foregroundColor(.white.opacity(0.9))
                .padding()
                .scaleEffect(animate ? 1 : 0.5)
                .opacity(animate ? 1 : 0)

            VStack(spacing: 16) {
                SummaryRow(icon: "dumbbell.fill", text: "\(data.totalWorkouts) workouts completed")
                SummaryRow(icon: "flame.fill", text: "\(data.personalRecords) personal records")
                SummaryRow(icon: "chart.line.uptrend.xyaxis", text: "\(data.uniqueExercises) unique exercises")
                if data.longestStreak > 1 {
                    SummaryRow(icon: "calendar.badge.checkmark", text: "\(data.longestStreak)-day longest streak")
                }
            }
            .opacity(animate ? 1 : 0)
            .offset(y: animate ? 0 : 20)

            Text("Keep crushing it in \(data.year + 1)!")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
                .padding(.top, 24)
                .opacity(animate ? 1 : 0)

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

struct SummaryRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .frame(width: 24)

            Text(text)
                .font(.system(size: 17, weight: .medium))

            Spacer()
        }
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.12))
        .cornerRadius(12)
    }
}

struct StatHighlight: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.primaryBg
            .ignoresSafeArea()

        YearInReviewCard(currentYear: 2024, hasData: true, onTap: {})
            .padding()
    }
}
