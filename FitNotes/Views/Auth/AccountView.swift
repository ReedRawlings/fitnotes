//
//  AccountView.swift
//  FitNotes
//
//  Account management view for Settings
//

import SwiftUI

struct AccountView: View {
    @ObservedObject private var authService = AuthService.shared
    @State private var showSignIn = false
    @State private var showSignOutConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            if authService.isSignedIn {
                signedInContent
            } else {
                signedOutContent
            }
        }
    }

    // MARK: - Signed Out Content

    private var signedOutContent: some View {
        Button(action: {
            showSignIn = true
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.accentPrimary, .accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "person.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Sign In")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    Text("Sync your data across devices")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textTertiary)
            }
            .padding()
            .background(Color.secondaryBg)
            .cornerRadius(16)
        }
        .sheet(isPresented: $showSignIn) {
            SignInView()
        }
    }

    // MARK: - Signed In Content

    private var signedInContent: some View {
        VStack(spacing: 12) {
            // User Info Card
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.accentPrimary, .accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "person.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Signed In")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    if let email = authService.currentUser?.email {
                        Text(email)
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer()

                // Sync Status
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.icloud.fill")
                        .font(.system(size: 14))
                    Text("Synced")
                        .font(.caption)
                }
                .foregroundColor(.green)
            }
            .padding()
            .background(Color.secondaryBg)
            .cornerRadius(16)

            // Sign Out Button
            Button(action: {
                showSignOutConfirmation = true
            }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 16))
                    Text("Sign Out")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.errorRed)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.secondaryBg)
                .cornerRadius(12)
            }
            .alert("Sign Out", isPresented: $showSignOutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        try? await authService.signOut()
                    }
                }
            } message: {
                Text("Your data will remain on this device but won't sync until you sign in again.")
            }
        }
    }
}

// MARK: - Compact Account Row (for Settings list)

struct AccountSettingsRow: View {
    @ObservedObject private var authService = AuthService.shared
    @State private var showSignIn = false
    @State private var showAccount = false

    var body: some View {
        Button(action: {
            if authService.isSignedIn {
                showAccount = true
            } else {
                showSignIn = true
            }
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.accentPrimary, .accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)

                    Image(systemName: authService.isSignedIn ? "person.fill.checkmark" : "person.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(authService.isSignedIn ? "Account" : "Sign In")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)

                    if authService.isSignedIn, let email = authService.currentUser?.email {
                        Text(email)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                            .lineLimit(1)
                    } else {
                        Text("Sync across devices")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.textTertiary)
            }
            .padding(.vertical, 8)
        }
        .sheet(isPresented: $showSignIn) {
            SignInView()
        }
        .sheet(isPresented: $showAccount) {
            NavigationStack {
                AccountDetailView()
            }
        }
    }
}

// MARK: - Account Detail View

struct AccountDetailView: View {
    @ObservedObject private var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showSignOutConfirmation = false

    var body: some View {
        ZStack {
            Color.primaryBg
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.accentPrimary, .accentSecondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)

                            Image(systemName: "person.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                        }

                        if let email = authService.currentUser?.email {
                            Text(email)
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                        }

                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                            Text("Syncing enabled")
                                .font(.subheadline)
                        }
                        .foregroundColor(.green)
                    }
                    .padding(.top, 20)

                    // Info Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("SYNC STATUS")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.textTertiary)
                            .kerning(0.5)

                        InfoRow(icon: "icloud.fill", title: "Cloud Backup", value: "Enabled")
                        InfoRow(icon: "clock.fill", title: "Last Synced", value: "Just now")
                    }
                    .padding(20)
                    .background(Color.secondaryBg)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)

                    // Sign Out Button
                    Button(action: {
                        showSignOutConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.errorRed)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.secondaryBg)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .foregroundColor(.accentPrimary)
            }
        }
        .alert("Sign Out", isPresented: $showSignOutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                Task {
                    try? await authService.signOut()
                    dismiss()
                }
            }
        } message: {
            Text("Your data will remain on this device but won't sync until you sign in again.")
        }
    }
}

private struct InfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.accentPrimary)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.textSecondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundColor(.textPrimary)
        }
    }
}

#Preview {
    AccountView()
}
