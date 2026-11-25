import Foundation

/// App identity and external links in one place. Fill these in before submitting to the App Store.
enum AppInfo {
    /// Name shown in-app (privacy policy, export filenames). Keep in sync with
    /// `INFOPLIST_KEY_CFBundleDisplayName` in the project build settings.
    static let displayName = "Progressive Lift"

    /// Support page or `mailto:` address. Apple requires a working support contact.
    /// While nil, the "Contact Support" row is hidden in Settings.
    static let supportURL: URL? = URL(string: "mailto:Operations@yourfutureself.is")

    /// Public privacy policy page (the same text as `PrivacyPolicyView`). App Store Connect needs
    /// this URL; while nil, Settings still shows the full policy in-app.
    static let privacyPolicyURL: URL? = nil

    static var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }
}
