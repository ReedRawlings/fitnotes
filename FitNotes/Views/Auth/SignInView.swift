//
//  SignInView.swift
//  FitNotes
//
//  Sign in view with Apple, Google, and Email options
//

import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @ObservedObject private var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showEmailSignIn = false
    @State private var showSignUpSuccess = false

    var body: some View {
        ZStack {
            Color.primaryBg
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "icloud.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.accentPrimary, .accentSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("Sign In")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)

                        Text("Sync your data across devices and never lose your progress")
                            .font(.body)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 40)

                    // Sign In Buttons
                    VStack(spacing: 16) {
                        // Sign in with Apple
                        SignInWithAppleButton(.continue) { request in
                            request.requestedScopes = [.email, .fullName]
                        } onCompletion: { result in
                            handleAppleSignIn(result)
                        }
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 56)
                        .cornerRadius(16)

                        // Sign in with Google
                        Button(action: {
                            Task {
                                try? await authService.signInWithGoogle()
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "g.circle.fill")
                                    .font(.system(size: 20))
                                Text("Continue with Google")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.secondaryBg)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }

                        // Sign in with Email
                        Button(action: {
                            showEmailSignIn = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 18))
                                Text("Continue with Email")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.secondaryBg)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 24)

                    // Error Message
                    if let error = authService.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(.errorRed)
                            .padding(.horizontal, 24)
                    }

                    // Skip Button
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Skip for now")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.top, 8)

                    // Benefits
                    VStack(alignment: .leading, spacing: 16) {
                        Text("WHY SIGN IN?")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.textTertiary)
                            .kerning(0.5)

                        BenefitRow(icon: "icloud.and.arrow.up", text: "Sync across all your devices")
                        BenefitRow(icon: "arrow.clockwise", text: "Restore data on new phones")
                        BenefitRow(icon: "chart.bar.xaxis", text: "Access your unified dashboard")
                        BenefitRow(icon: "lock.shield", text: "Your data stays private and secure")
                    }
                    .padding(20)
                    .background(Color.secondaryBg)
                    .cornerRadius(16)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    Spacer(minLength: 40)
                }
            }

            // Loading overlay
            if authService.isLoading {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }
        }
        .sheet(isPresented: $showEmailSignIn) {
            EmailSignInView(showSignUpSuccess: $showSignUpSuccess)
        }
        .alert("Check Your Email", isPresented: $showSignUpSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("We've sent you a verification link. Please check your email to complete sign up.")
        }
        .onChange(of: authService.isSignedIn) { _, isSignedIn in
            if isSignedIn {
                dismiss()
            }
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                Task {
                    try? await authService.signInWithApple(credential: credential)
                }
            }
        case .failure(let error):
            authService.errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Benefit Row

private struct BenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.accentPrimary)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.textSecondary)
        }
    }
}

// MARK: - Email Sign In View

struct EmailSignInView: View {
    @ObservedObject private var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    @Binding var showSignUpSuccess: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var showForgotPassword = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.primaryBg
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Toggle between Sign In and Sign Up
                        Picker("Mode", selection: $isSignUp) {
                            Text("Sign In").tag(false)
                            Text("Sign Up").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 24)
                        .padding(.top, 20)

                        // Form Fields
                        VStack(spacing: 16) {
                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.textSecondary)

                                TextField("Enter your email", text: $email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                    .padding()
                                    .background(Color.secondaryBg)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            }

                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.textSecondary)

                                SecureField("Enter your password", text: $password)
                                    .textContentType(isSignUp ? .newPassword : .password)
                                    .padding()
                                    .background(Color.secondaryBg)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                                    )

                                if isSignUp {
                                    Text("Must be at least 6 characters")
                                        .font(.caption)
                                        .foregroundColor(.textTertiary)
                                }
                            }

                            // Forgot Password (Sign In only)
                            if !isSignUp {
                                HStack {
                                    Spacer()
                                    Button("Forgot Password?") {
                                        showForgotPassword = true
                                    }
                                    .font(.footnote)
                                    .foregroundColor(.accentPrimary)
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        // Error Message
                        if let error = authService.errorMessage {
                            Text(error)
                                .font(.footnote)
                                .foregroundColor(.errorRed)
                                .padding(.horizontal, 24)
                        }

                        // Submit Button
                        Button(action: {
                            Task {
                                await submitForm()
                            }
                        }) {
                            HStack {
                                if authService.isLoading {
                                    ProgressView()
                                        .tint(.textInverse)
                                } else {
                                    Text(isSignUp ? "Create Account" : "Sign In")
                                        .font(.system(size: 17, weight: .semibold))
                                }
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
                        }
                        .disabled(email.isEmpty || password.isEmpty || authService.isLoading)
                        .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1)
                        .padding(.horizontal, 24)

                        Spacer()
                    }
                }
            }
            .navigationTitle(isSignUp ? "Create Account" : "Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.textSecondary)
                }
            }
            .alert("Reset Password", isPresented: $showForgotPassword) {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                Button("Cancel", role: .cancel) { }
                Button("Send Reset Link") {
                    Task {
                        try? await authService.sendPasswordReset(email: email)
                    }
                }
            } message: {
                Text("Enter your email and we'll send you a link to reset your password.")
            }
            .onChange(of: authService.isSignedIn) { _, isSignedIn in
                if isSignedIn {
                    dismiss()
                }
            }
        }
    }

    private func submitForm() async {
        do {
            if isSignUp {
                try await authService.signUpWithEmail(email: email, password: password)
            } else {
                try await authService.signInWithEmail(email: email, password: password)
            }
        } catch AuthError.emailNotVerified {
            dismiss()
            showSignUpSuccess = true
        } catch {
            // Error is shown via authService.errorMessage
        }
    }
}

// MARK: - Preview

#Preview {
    SignInView()
}
