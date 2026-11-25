import SwiftUI
import SwiftData
import UIKit

/// "Your Data" + "About" cards at the bottom of Settings → Preferences:
/// CSV export, in-app privacy policy, support contact, and version.
struct AboutSettingsSection: View {
    @Environment(\.modelContext) private var modelContext

    @State private var exportURL: URL?
    @State private var exportError: String?
    @State private var showingPrivacyPolicy = false

    var body: some View {
        VStack(spacing: 12) {
            card(title: "Your Data") {
                row(icon: "square.and.arrow.up", title: "Export Workouts (CSV)") { export() }
                Text("Your workouts are stored only on this device. Export a CSV to back them up or move them to another app.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.textTertiary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
            }

            card(title: "About") {
                row(icon: "hand.raised", title: "Privacy Policy") { showingPrivacyPolicy = true }
                if let supportURL = AppInfo.supportURL {
                    Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 16)
                    row(icon: "envelope", title: "Contact Support") { UIApplication.shared.open(supportURL) }
                }
                Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 16)
                HStack {
                    Text("Version")
                        .font(.bodyFont)
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Text(AppInfo.version)
                        .font(.system(size: 15, design: .monospaced))
                        .foregroundColor(.textSecondary)
                }
                .padding(16)
            }
        }
        .sheet(isPresented: Binding(get: { exportURL != nil }, set: { if !$0 { exportURL = nil } })) {
            if let exportURL {
                ShareSheet(items: [exportURL])
            }
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .alert("Export Failed", isPresented: Binding(get: { exportError != nil }, set: { if !$0 { exportError = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportError ?? "")
        }
    }

    private func export() {
        do {
            exportURL = try DataExportService.shared.exportFile(modelContext: modelContext)
        } catch {
            exportError = error.localizedDescription
        }
    }

    private func card<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.textSecondary)
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 4)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondaryBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private func row(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.accentPrimary)
                    .frame(width: 24)
                Text(title)
                    .font(.bodyFont)
                    .foregroundColor(.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textTertiary)
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Wraps UIActivityViewController so the export can go to Files, AirDrop, Mail, etc.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

/// Full privacy policy, readable in-app (App Store guideline 5.1.1 requires in-app access).
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    private let sections: [(String, String)] = [
        ("Summary", "\(AppInfo.displayName) does not collect, transmit, or sell any personal data. There are no accounts, ads, analytics, or tracking."),
        ("Data stored on your device", "Your workouts, exercises, routines, goals, and preferences are stored only on your device. They never leave it unless you choose to export them."),
        ("Exports", "If you use Export Workouts, a CSV file is created and handed to the iOS share sheet. Where it goes next (Files, AirDrop, email, another app) is entirely your choice."),
        ("Notifications and Live Activities", "Rest timer alerts are scheduled locally on your device. No push notification service or server is involved."),
        ("Backups", "Your data may be included in your own iCloud or computer device backups, which are controlled by your Apple settings, not by this app."),
        ("Deleting your data", "Deleting the app removes all of its data from your device."),
        ("Children", "The app does not knowingly collect information from anyone, including children."),
        ("Changes", "If this policy changes, the updated version will appear in the app and on the App Store listing."),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Effective November 25, 2026")
                        .font(.system(size: 13))
                        .foregroundColor(.textTertiary)
                    ForEach(sections, id: \.0) { title, body in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(title)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.textPrimary)
                            Text(body)
                                .font(.system(size: 15))
                                .foregroundColor(.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    if let supportURL = AppInfo.supportURL {
                        Link("Questions? Contact support", destination: supportURL)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.accentPrimary)
                    }
                }
                .padding(20)
            }
            .background(Color.primaryBg.ignoresSafeArea())
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
