import SwiftUI

// MARK: - Custom Numeric Keyboard
struct CustomNumericKeyboard: View {
    @Binding var text: String
    let increment: Double
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            // Top row: [-X] [Dismiss] [+X]
            HStack(spacing: 8) {
                // Decrement button
                KeyboardButton(
                    label: "-\(formatIncrement(increment))",
                    backgroundColor: Color.tertiaryBg,
                    action: {
                        decrementValue()
                    }
                )

                // Dismiss keyboard button
                KeyboardButton(
                    label: nil,
                    icon: "chevron.down",
                    backgroundColor: Color.accentSuccess,
                    action: onDismiss
                )

                // Increment button
                KeyboardButton(
                    label: "+\(formatIncrement(increment))",
                    backgroundColor: Color.tertiaryBg,
                    action: {
                        incrementValue()
                    }
                )
            }

            // Number rows
            HStack(spacing: 8) {
                KeyboardButton(label: "1", action: { appendDigit("1") })
                KeyboardButton(label: "2", action: { appendDigit("2") })
                KeyboardButton(label: "3", action: { appendDigit("3") })
            }

            HStack(spacing: 8) {
                KeyboardButton(label: "4", action: { appendDigit("4") })
                KeyboardButton(label: "5", action: { appendDigit("5") })
                KeyboardButton(label: "6", action: { appendDigit("6") })
            }

            HStack(spacing: 8) {
                KeyboardButton(label: "7", action: { appendDigit("7") })
                KeyboardButton(label: "8", action: { appendDigit("8") })
                KeyboardButton(label: "9", action: { appendDigit("9") })
            }

            // Bottom row: [•] [0] [⌫]
            HStack(spacing: 8) {
                KeyboardButton(
                    label: "•",
                    action: { appendDigit(".") }
                )
                KeyboardButton(
                    label: "0",
                    action: { appendDigit("0") }
                )
                KeyboardButton(
                    label: nil,
                    icon: "delete.left.fill",
                    action: deleteLastDigit
                )
            }
        }
        .padding(12)
        .background(Color.secondaryBg)
    }

    // MARK: - Helper Functions

    private func formatIncrement(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))"
        } else {
            return String(format: "%.1f", value)
        }
    }

    private func appendDigit(_ digit: String) {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        // Prevent multiple decimal points
        if digit == "." && text.contains(".") {
            return
        }

        // Prevent leading zeros (except for 0.X)
        if text == "0" && digit != "." {
            text = digit
            return
        }

        text += digit
    }

    private func deleteLastDigit() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        if !text.isEmpty {
            text.removeLast()
        }
    }

    private func incrementValue() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        let currentValue = Double(text) ?? 0
        let newValue = currentValue + increment

        // Format the result
        if newValue.truncatingRemainder(dividingBy: 1) == 0 {
            text = "\(Int(newValue))"
        } else {
            text = String(format: "%.1f", newValue)
        }
    }

    private func decrementValue() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        let currentValue = Double(text) ?? 0
        let newValue = max(0, currentValue - increment) // Don't go below 0

        // Format the result
        if newValue.truncatingRemainder(dividingBy: 1) == 0 {
            text = "\(Int(newValue))"
        } else {
            text = String(format: "%.1f", newValue)
        }
    }
}

// MARK: - Keyboard Button Component
struct KeyboardButton: View {
    let label: String?
    let icon: String?
    let backgroundColor: Color
    let action: () -> Void

    init(label: String? = nil, icon: String? = nil, backgroundColor: Color = Color.tertiaryBg, action: @escaping () -> Void) {
        self.label = label
        self.icon = icon
        self.backgroundColor = backgroundColor
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Group {
                if let label = label {
                    Text(label)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.textPrimary)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.textPrimary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(backgroundColor)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    VStack {
        Spacer()
        CustomNumericKeyboard(
            text: .constant("90"),
            increment: 5.0,
            onDismiss: {}
        )
    }
    .background(Color.primaryBg)
}
