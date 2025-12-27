//
//  SupabaseConfig.swift
//  FitNotes
//
//  Supabase configuration - replace with your project values
//

import Foundation
import Supabase

enum SupabaseConfig {
    // MARK: - Project Configuration
    // Get these from: https://supabase.com/dashboard/project/YOUR_PROJECT/settings/api

    static let projectURL = URL(string: "https://pxflereyoqujtgafjzmg.supabase.co")!
    static let anonKey = "sb_secret_EJzv0O0H0-15Cpawcdf_Pw_tN07wuQW"

    // MARK: - OAuth Redirect URL
    // Used for Google Sign-In callback
    static let redirectURL = URL(string: "com.fitnotes.app://auth-callback")!

    // MARK: - Shared Client
    static let client = SupabaseClient(
        supabaseURL: projectURL,
        supabaseKey: anonKey,
        options: SupabaseClientOptions(
            auth: .init(
                redirectToURL: redirectURL
            )
        )
    )
}
