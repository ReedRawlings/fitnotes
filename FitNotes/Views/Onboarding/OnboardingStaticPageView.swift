//
//  OnboardingStaticPageView.swift
//  FitNotes
//
//  Static informational screens for onboarding (Screens 1-7, 13, 14)
//

import SwiftUI

struct OnboardingStaticPageView: View {
    let page: OnboardingPage

    // Animation state
    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: CGFloat = 0
    @State private var titleOpacity: CGFloat = 0
    @State private var subtitleOpacity: CGFloat = 0
    @State private var descriptionOpacity: CGFloat = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 60)

                // Icon
                iconView
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)

                Spacer()
                    .frame(height: 32)

                // Title
                Text(page.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(titleOpacity)

                // Subtitle
                if let subtitle = page.subtitle {
                    Text(subtitle)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.accentPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                        .opacity(subtitleOpacity)
                }

                // Description
                if let description = page.description {
                    descriptionView(description)
                        .padding(.top, 24)
                        .opacity(descriptionOpacity)
                }

                Spacer()
                    .frame(height: 120)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            animateContent()
        }
    }

    // MARK: - Icon View
    @ViewBuilder
    private var iconView: some View {
        // Special styling for quote screen (screen 6)
        if page.order == 6 {
            ZStack {
                Circle()
                    .fill(Color.secondaryBg)
                    .frame(width: 120, height: 120)

                Image(systemName: page.systemImage)
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.accentPrimary, .accentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        } else {
            ZStack {
                // Gradient background circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.accentPrimary.opacity(0.15),
                                Color.accentSecondary.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                // Icon
                Image(systemName: page.systemImage)
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.accentPrimary, .accentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
    }

    // MARK: - Description View
    @ViewBuilder
    private func descriptionView(_ description: String) -> some View {
        // Check if this is the quote screen (screen 6)
        if page.order == 6 {
            VStack(spacing: 16) {
                // Quote marks
                HStack {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 24))
                        .foregroundColor(.accentPrimary.opacity(0.5))
                    Spacer()
                }

                Text(description)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .italic()

                HStack {
                    Spacer()
                    Image(systemName: "quote.closing")
                        .font(.system(size: 24))
                        .foregroundColor(.accentPrimary.opacity(0.5))
                }
            }
            .padding(24)
            .background(Color.secondaryBg)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.accentPrimary.opacity(0.2), lineWidth: 1)
            )
        }
        // Check if this is the benefits screen (screen 3) with bullet points
        else if description.contains("•") {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(parseBulletPoints(description), id: \.self) { point in
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(Color.accentPrimary)
                            .frame(width: 8, height: 8)
                            .padding(.top, 6)

                        Text(point)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(.textSecondary)
                            .lineSpacing(4)
                    }
                }
            }
            .padding(20)
            .background(Color.secondaryBg)
            .cornerRadius(16)
        }
        // Standard description
        else {
            Text(description)
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
        }
    }

    // MARK: - Helpers
    private func parseBulletPoints(_ text: String) -> [String] {
        text.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { $0.replacingOccurrences(of: "• ", with: "") }
    }

    private func animateContent() {
        // Reset state
        iconScale = 0.5
        iconOpacity = 0
        titleOpacity = 0
        subtitleOpacity = 0
        descriptionOpacity = 0

        // Staggered animations
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
            titleOpacity = 1.0
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
            subtitleOpacity = 1.0
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.4)) {
            descriptionOpacity = 1.0
        }
    }
}

// MARK: - Research & Quotes View
/// Combined scrolling view with research points and expert quotes
struct OnboardingResearchView: View {
    @ObservedObject var state: OnboardingState

    // Animation state
    @State private var contentOpacity: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            // Top navigation with back chevron and progress bar
            HStack(spacing: 12) {
                // Back chevron
                Button(action: {
                    state.previousPage()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textSecondary)
                        .frame(width: 32, height: 32)
                }

                // Progress bar showing total screens
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.tertiaryBg)
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [.accentPrimary, .accentSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * state.progress, height: 4)
                            .animation(.standardSpring, value: state.progress)
                    }
                }
                .frame(height: 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    Spacer()
                        .frame(height: 12)

                    // Header
                    VStack(spacing: 6) {
                        Text("The Science Behind It")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("Research-backed results")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.accentPrimary)
                    }

                    // Research Point 1
                    ResearchCard(
                        icon: "brain.head.profile",
                        title: "Backed by Science",
                        description: "A study in the Journal of Strength and Conditioning Research found that lifters who followed progressive overload principles gained 25% more strength over 12 weeks compared to those who trained without a structured progression plan."
                    )

                    // Research Point 2
                    ResearchCard(
                        icon: "checkmark.seal.fill",
                        title: "Built for Longevity",
                        description: "Research from the American College of Sports Medicine shows that progressive resistance training not only builds strength but also reduces injury risk by 30% and improves joint health over time."
                    )

                    // Quotes Section Header
                    Text("From the Experts")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.textPrimary)
                        .padding(.top, 8)

                    // Quote 1 - Greg Doucette
                    QuoteCard(
                        quote: "Train harder than last time.",
                        author: "Greg Doucette",
                        credential: "IFBB Pro & Coach"
                    )

                    // Quote 2 - Jeff Nippard
                    QuoteCard(
                        quote: "You need progressive overload to keep driving gains.",
                        author: "Jeff Nippard",
                        credential: "Natural Bodybuilder & Science Communicator"
                    )

                    Spacer()
                        .frame(height: 16)
                }
                .padding(.horizontal, 24)
                .opacity(contentOpacity)
            }

            // Bottom Continue Button
            Button(action: {
                state.nextPage()
            }) {
                HStack(spacing: 8) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))

                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
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
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
                contentOpacity = 1.0
            }
        }
    }
}

// MARK: - Research Card Component
struct ResearchCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.accentPrimary.opacity(0.15),
                                    Color.accentSecondary.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.accentPrimary, .accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.textPrimary)
            }

            Text(description)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.textSecondary)
                .lineSpacing(4)
        }
        .padding(20)
        .background(Color.secondaryBg)
        .cornerRadius(16)
    }
}

// MARK: - Quote Card Component
struct QuoteCard: View {
    let quote: String
    let author: String
    let credential: String

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "quote.opening")
                    .font(.system(size: 20))
                    .foregroundColor(.accentPrimary.opacity(0.5))
                Spacer()
            }

            Text(quote)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
                .italic()
                .padding(.horizontal, 8)

            HStack {
                Spacer()
                Image(systemName: "quote.closing")
                    .font(.system(size: 20))
                    .foregroundColor(.accentPrimary.opacity(0.5))
            }

            VStack(spacing: 2) {
                Text("— \(author)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPrimary)

                Text(credential)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.textTertiary)
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(Color.secondaryBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.accentPrimary.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview
#Preview("Welcome") {
    ZStack {
        Color.primaryBg.ignoresSafeArea()
        OnboardingStaticPageView(
            page: OnboardingPage(
                type: .static,
                title: "Welcome to FitNotes",
                subtitle: "Your journey starts here",
                description: "Every great transformation begins with a single step. You're not just downloading an app—you're investing in a stronger, more capable version of yourself.",
                systemImage: "figure.walk",
                order: 1
            )
        )
    }
}

#Preview("Benefits") {
    ZStack {
        Color.primaryBg.ignoresSafeArea()
        OnboardingStaticPageView(
            page: OnboardingPage(
                type: .static,
                title: "Why It Works",
                subtitle: "The benefits are undeniable",
                description: "• Consistent strength gains week after week\n• Visible muscle growth you can measure\n• Clear progress you can track and celebrate",
                systemImage: "trophy.fill",
                order: 3
            )
        )
    }
}

#Preview("Quote") {
    ZStack {
        Color.primaryBg.ignoresSafeArea()
        OnboardingStaticPageView(
            page: OnboardingPage(
                type: .static,
                title: "From the Experts",
                subtitle: nil,
                description: "\"Progressive overload is the number one driver of muscle growth. If you're not progressively challenging your muscles, you're leaving gains on the table.\"\n\n— Greg Doucette, IFBB Pro",
                systemImage: "quote.bubble.fill",
                order: 6
            )
        )
    }
}
