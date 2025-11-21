import SwiftUI
import os.log

/// A tappable view that looks like a TextField but doesn't trigger the system keyboard
/// Instead, it updates focus state to show a custom keyboard
struct NumericInputField: View {
    @Binding var text: String
    let placeholder: String
    let isActive: Bool
    let onTap: () -> Void

    private let logger = Logger(subsystem: "com.fitnotes.app", category: "NumericInputField")

    var body: some View {
        Text(text.isEmpty ? placeholder : text)
            .font(.system(size: 24, weight: .medium))
            .foregroundColor(text.isEmpty ? .white.opacity(0.3) : .textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(
                                isActive ? Color.accentSuccess : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
            .contentShape(Rectangle())
            .onTapGesture {
                logger.info("NumericInputField tapped - current text: '\(self.text)', placeholder: '\(self.placeholder)', isActive: \(self.isActive)")
                onTap()
                logger.info("NumericInputField onTap() callback executed")
            }
            .onAppear {
                logger.debug("NumericInputField appeared - text: '\(self.text)', isActive: \(self.isActive)")
            }
            .onChange(of: text) { oldValue, newValue in
                logger.info("NumericInputField text changed from '\(oldValue)' to '\(newValue)'")
            }
            .onChange(of: isActive) { oldValue, newValue in
                logger.info("NumericInputField isActive changed from \(oldValue) to \(newValue)")
            }
    }
}
