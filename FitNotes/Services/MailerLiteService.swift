//
//  MailerLiteService.swift
//  FitNotes
//
//  Service for adding subscribers to MailerLite email list
//

import Foundation

/// Service for managing MailerLite email subscriptions
actor MailerLiteService {
    static let shared = MailerLiteService()

    private let baseURL = "https://connect.mailerlite.com/api"

    private init() {}

    // MARK: - Subscriber Management

    /// Add a subscriber to the FitNotes mailing list
    /// - Parameters:
    ///   - email: Subscriber's email address
    ///   - experienceLevel: User's fitness experience level (optional)
    ///   - selectedPlan: Whether user selected free or premium (optional)
    /// - Returns: True if successful, false otherwise
    @discardableResult
    func addSubscriber(
        email: String,
        experienceLevel: String? = nil,
        selectedPlan: String? = nil
    ) async -> Bool {
        guard !email.isEmpty else { return false }

        // Build request body
        var fields: [String: Any] = [:]
        if let level = experienceLevel {
            fields["experience_level"] = level
        }
        if let plan = selectedPlan {
            fields["selected_plan"] = plan
        }

        var body: [String: Any] = [
            "email": email,
            "groups": [Secrets.mailerLiteGroupId]
        ]

        if !fields.isEmpty {
            body["fields"] = fields
        }

        // Create request
        guard let url = URL(string: "\(baseURL)/subscribers") else {
            print("[MailerLite] Invalid URL")
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Secrets.mailerLiteAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("[MailerLite] Failed to serialize request body: \(error)")
            return false
        }

        // Send request
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("[MailerLite] Invalid response type")
                return false
            }

            switch httpResponse.statusCode {
            case 200, 201:
                print("[MailerLite] Subscriber added successfully: \(email)")
                return true
            case 422:
                // Subscriber already exists - this is okay
                print("[MailerLite] Subscriber already exists: \(email)")
                return true
            default:
                if let errorBody = String(data: data, encoding: .utf8) {
                    print("[MailerLite] Error \(httpResponse.statusCode): \(errorBody)")
                }
                return false
            }
        } catch {
            print("[MailerLite] Network error: \(error.localizedDescription)")
            return false
        }
    }
}
