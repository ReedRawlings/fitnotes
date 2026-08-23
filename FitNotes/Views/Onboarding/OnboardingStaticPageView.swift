//
//  OnboardingStaticPageView.swift
//  FitNotes
//
//  Static informational screens for onboarding
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
    private var iconView: some View {
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

    // MARK: - Description View
    private func descriptionView(_ description: String) -> some View {
        Text(description)
            .font(.system(size: 17, weight: .regular))
            .foregroundColor(.textSecondary)
            .multilineTextAlignment(.center)
            .lineSpacing(6)
    }

    // MARK: - Helpers
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

