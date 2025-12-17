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
