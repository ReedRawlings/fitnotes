//
//  AuthService.swift
//  FitNotes
//
//  Handles authentication with Apple, Google, and Email via Supabase
//

import Foundation
import AuthenticationServices
import Supabase

// MARK: - Auth State

enum AuthState {
    case loading
    case signedOut
    case signedIn(User)
}

// MARK: - Auth Error

enum AuthError: LocalizedError {
    case invalidCredential
    case emailNotVerified
    case networkError
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid credentials. Please try again."
        case .emailNotVerified:
            return "Please verify your email address."
        case .networkError:
            return "Network error. Please check your connection."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - Auth Service

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published private(set) var authState: AuthState = .loading
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private var supabase: SupabaseClient { SupabaseConfig.client }

    private init() {
        Task {
            await checkSession()
        }
    }

    // MARK: - Session Management

    var isSignedIn: Bool {
        if case .signedIn = authState { return true }
        return false
    }

    var currentUser: User? {
        if case .signedIn(let user) = authState { return user }
        return nil
    }

    var userId: UUID? {
        currentUser?.id
    }

    func checkSession() async {
        do {
            let session = try await supabase.auth.session
            authState = .signedIn(session.user)
        } catch {
            authState = .signedOut
        }
    }

    // MARK: - Sign In with Apple

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.invalidCredential
        }

        isLoading = true
        errorMessage = nil

        do {
            let session = try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: tokenString
                )
            )
            authState = .signedIn(session.user)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw AuthError.unknown(error)
        }
    }

    // MARK: - Sign In with Google

    func signInWithGoogle() async throws {
        isLoading = true
        errorMessage = nil

        do {
            try await supabase.auth.signInWithOAuth(
                provider: .google,
                redirectTo: SupabaseConfig.redirectURL
            )
            // Session will be handled by URL callback
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw AuthError.unknown(error)
        }
    }

    // Handle OAuth callback URL
    func handleOAuthCallback(url: URL) async {
        do {
            let session = try await supabase.auth.session(from: url)
            authState = .signedIn(session.user)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Sign In with Email

    func signInWithEmail(email: String, password: String) async throws {
        guard !email.isEmpty, !password.isEmpty else {
            throw AuthError.invalidCredential
        }

        isLoading = true
        errorMessage = nil

        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            authState = .signedIn(session.user)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw AuthError.unknown(error)
        }
    }

    // MARK: - Sign Up with Email

    func signUpWithEmail(email: String, password: String) async throws {
        guard !email.isEmpty, !password.isEmpty else {
            throw AuthError.invalidCredential
        }

        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            throw AuthError.invalidCredential
        }

        isLoading = true
        errorMessage = nil

        do {
            let response = try await supabase.auth.signUp(
                email: email,
                password: password
            )

            // Check if email confirmation is required
            if let session = response.session {
                authState = .signedIn(session.user)
            } else {
                // Email confirmation required
                errorMessage = nil
                throw AuthError.emailNotVerified
            }
            isLoading = false
        } catch let error as AuthError {
            isLoading = false
            throw error
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw AuthError.unknown(error)
        }
    }

    // MARK: - Password Reset

    func sendPasswordReset(email: String) async throws {
        guard !email.isEmpty else {
            throw AuthError.invalidCredential
        }

        isLoading = true
        errorMessage = nil

        do {
            try await supabase.auth.resetPasswordForEmail(email)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw AuthError.unknown(error)
        }
    }

    // MARK: - Sign Out

    func signOut() async throws {
        isLoading = true

        do {
            try await supabase.auth.signOut()
            authState = .signedOut
            isLoading = false
        } catch {
            isLoading = false
            throw AuthError.unknown(error)
        }
    }
}
