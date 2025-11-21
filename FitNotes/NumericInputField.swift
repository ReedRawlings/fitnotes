import SwiftUI

/// A tappable view that looks like a TextField but doesn't trigger the system keyboard
/// Instead, it updates focus state to show a custom keyboard
struct NumericInputField: View {
    @Binding var text: String
    let placeholder: String
    let isActive: Bool
    let onTap: () -> Void

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
                onTap()
            }
    }
}
