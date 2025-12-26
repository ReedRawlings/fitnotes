//
//  PremiumFeatureGate.swift
//  FitNotes
//
//  View modifier and utilities for gating premium features
//

import SwiftUI
import StoreKit

// MARK: - Premium Feature Check
struct PremiumFeatureGate<PremiumContent: View, FreeContent: View>: View {
    @ObservedObject private var storeManager = StoreKitManager.shared

    let premiumContent: () -> PremiumContent
    let freeContent: () -> FreeContent

    init(
        @ViewBuilder premium: @escaping () -> PremiumContent,
        @ViewBuilder free: @escaping () -> FreeContent
    ) {
        self.premiumContent = premium
        self.freeContent = free
    }

    var body: some View {
        if storeManager.isPremium {
            premiumContent()
        } else {
            freeContent()
        }
    }
}

// MARK: - Premium Lock Overlay
struct PremiumLockOverlay: View {
    let featureName: String
    let onUpgrade: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 32))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.accentPrimary, .accentSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Premium Feature")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.textPrimary)

            Text("\(featureName) is available with Premium")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)

            Button(action: onUpgrade) {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14))
                    Text("Upgrade to Premium")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.textInverse)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [.accentPrimary, .accentSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
        }
        .padding(24)
        .background(Color.secondaryBg)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - View Modifier for Premium Gating
struct PremiumGatedModifier: ViewModifier {
    @ObservedObject private var storeManager = StoreKitManager.shared
    @State private var showingUpgradeSheet: Bool = false

    let featureName: String
    let requiresPremium: Bool

    func body(content: Content) -> some View {
        Group {
            if requiresPremium && !storeManager.isPremium {
                content
                    .disabled(true)
                    .overlay {
                        Color.primaryBg.opacity(0.8)
                            .ignoresSafeArea()
                    }
                    .overlay {
                        PremiumLockOverlay(featureName: featureName) {
                            showingUpgradeSheet = true
                        }
                    }
            } else {
                content
            }
        }
        .sheet(isPresented: $showingUpgradeSheet) {
            UpgradeSheet()
        }
    }
}

// MARK: - Upgrade Sheet
struct UpgradeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storeManager = StoreKitManager.shared
    @State private var selectedProductId: String?
    @State private var isPurchasing: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.primaryBg
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.accentPrimary, .accentSecondary],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )

                            Text("Unlock Premium")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.textPrimary)

                            Text("Get unlimited access to all features")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.top, 24)

                        // Features
                        VStack(alignment: .leading, spacing: 12) {
                            premiumFeature("Unlimited routines")
                            premiumFeature("Unlimited progressive overload tracking")
                            premiumFeature("Full insights history (3 months, YTD, all time)")
                            premiumFeature("Priority support")
                        }
                        .padding(20)
                        .background(Color.secondaryBg)
                        .cornerRadius(16)
                        .padding(.horizontal, 20)

                        // Plans
                        VStack(spacing: 12) {
                            if let yearly = storeManager.yearlyProduct {
                                UpgradePlanOption(
                                    product: yearly,
                                    isSelected: selectedProductId == yearly.id,
                                    badge: "Best Value",
                                    onTap: { selectedProductId = yearly.id }
                                )
                            }

                            if let monthly = storeManager.monthlyProduct {
                                UpgradePlanOption(
                                    product: monthly,
                                    isSelected: selectedProductId == monthly.id,
                                    badge: nil,
                                    onTap: { selectedProductId = monthly.id }
                                )
                            }
                        }
                        .padding(.horizontal, 20)

                        // Purchase Button
                        Button(action: purchase) {
                            HStack {
                                if isPurchasing {
                                    ProgressView()
                                        .tint(.textInverse)
                                } else {
                                    Text("Continue")
                                        .font(.buttonFont)
                                }
                            }
                            .foregroundColor(.textInverse)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [.accentPrimary, .accentSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                        }
                        .disabled(selectedProductId == nil || isPurchasing)
                        .padding(.horizontal, 20)

                        // Restore
                        Button("Restore Purchases") {
                            Task {
                                await storeManager.restorePurchases()
                                if storeManager.isPremium {
                                    dismiss()
                                }
                            }
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textSecondary)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.textSecondary)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if let yearly = storeManager.yearlyProduct {
                selectedProductId = yearly.id
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func premiumFeature(_ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.accentSuccess)
            Text(text)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.textPrimary)
        }
    }

    private func purchase() {
        guard let productId = selectedProductId,
              let product = storeManager.products.first(where: { $0.id == productId }) else {
            return
        }

        Task {
            isPurchasing = true
            do {
                _ = try await storeManager.purchase(product)
                isPurchasing = false
                dismiss()
            } catch StoreError.userCancelled {
                isPurchasing = false
            } catch {
                isPurchasing = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Upgrade Plan Option
struct UpgradePlanOption: View {
    let product: Product
    let isSelected: Bool
    let badge: String?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(product.displayName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.textPrimary)

                        if let badge = badge {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.textInverse)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentSuccess)
                                .cornerRadius(4)
                        }
                    }

                    Text(product.displayPrice + periodText)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.accentPrimary : Color.textTertiary, lineWidth: 2)
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(Color.accentPrimary)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(16)
            .background(isSelected ? Color.accentPrimary.opacity(0.1) : Color.secondaryBg)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentPrimary : Color.white.opacity(0.06), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var periodText: String {
        guard let subscription = product.subscription else { return "" }
        switch subscription.subscriptionPeriod.unit {
        case .month: return "/month"
        case .year: return "/year"
        default: return ""
        }
    }
}

// MARK: - View Extension
extension View {
    func premiumGated(featureName: String, requiresPremium: Bool = true) -> some View {
        modifier(PremiumGatedModifier(featureName: featureName, requiresPremium: requiresPremium))
    }
}

// MARK: - Usage Counter Badge
/// Displays usage count for freemium limits (e.g., "2/2 Routines")
struct UsageCounterBadge: View {
    let current: Int
    let max: Int
    let label: String
    let isPremium: Bool

    private var isAtLimit: Bool { current >= max && !isPremium }

    var body: some View {
        HStack(spacing: 6) {
            if isPremium {
                // Premium: show count only without limit
                Text("\(current) \(label)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textSecondary)
            } else {
                // Free: show X/Y format
                Text("\(current)/\(max) \(label)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isAtLimit ? .accentSecondary : .textSecondary)

                if isAtLimit {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.accentSecondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.secondaryBg)
        .cornerRadius(8)
    }
}

// MARK: - Freemium Limit Reached Sheet
/// Bottom sheet shown when user hits a freemium limit
struct FreemiumLimitReachedSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingUpgradeSheet = false

    let featureName: String
    let currentCount: Int
    let maxCount: Int

    var body: some View {
        VStack(spacing: 24) {
            // Lock icon with gradient
            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.accentPrimary, .accentSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Title
            Text("Free Limit Reached")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.textPrimary)

            // Usage indicator
            Text("\(currentCount)/\(maxCount) \(featureName) used")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.textSecondary)

            // Description
            Text("Upgrade to Premium for unlimited \(featureName.lowercased()) and more features.")
                .font(.system(size: 15))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            // Upgrade button
            Button(action: { showingUpgradeSheet = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                    Text("Upgrade to Premium")
                }
                .font(.buttonFont)
                .foregroundColor(.textInverse)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [.accentPrimary, .accentSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            .padding(.horizontal, 20)

            // Maybe later button
            Button("Maybe Later") {
                dismiss()
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.textSecondary)
        }
        .padding(.vertical, 32)
        .presentationDetents([.height(400)])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showingUpgradeSheet) {
            UpgradeSheet()
        }
    }
}

// MARK: - Environment Key for Premium Status
struct IsPremiumKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var isPremium: Bool {
        get { self[IsPremiumKey.self] }
        set { self[IsPremiumKey.self] = newValue }
    }
}

// MARK: - Preview
#Preview("Upgrade Sheet") {
    UpgradeSheet()
}

#Preview("Premium Lock Overlay") {
    ZStack {
        Color.primaryBg.ignoresSafeArea()
        PremiumLockOverlay(featureName: "Advanced Analytics") {}
    }
}
