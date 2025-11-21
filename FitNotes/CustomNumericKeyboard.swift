import SwiftUI
import os.log

// MARK: - Custom Numeric Keyboard
struct CustomNumericKeyboard: View {
    @Binding var text: String
    let increment: Double
    let onDismiss: () -> Void

    private let logger = Logger(subsystem: "com.fitnotes.app", category: "CustomNumericKeyboard")

    var body: some View {
        VStack(spacing: 8) {
            // Top row: [-X] [Dismiss] [+X]
            HStack(spacing: 8) {
                // Decrement button
                KeyboardButton(
                    label: "-\(formatIncrement(increment))",
                    backgroundColor: Color.tertiaryBg,
                    action: {
                        logger.info("Decrement button tapped - current text: '\(self.text)', increment: \(self.increment)")
                        decrementValue()
                    }
                )

                // Dismiss keyboard button
                KeyboardButton(
                    label: nil,
                    icon: "chevron.down",
                    backgroundColor: Color.accentSuccess,
                    action: {
                        logger.info("Dismiss button tapped - closing keyboard")
                        onDismiss()
                    }
                )

                // Increment button
                KeyboardButton(
                    label: "+\(formatIncrement(increment))",
                    backgroundColor: Color.tertiaryBg,
                    action: {
                        logger.info("Increment button tapped - current text: '\(self.text)', increment: \(self.increment)")
                        incrementValue()
                    }
                )
            }

            // Number rows
            HStack(spacing: 8) {
                KeyboardButton(label: "1", action: { logger.info("Digit '1' tapped"); appendDigit("1") })
                KeyboardButton(label: "2", action: { logger.info("Digit '2' tapped"); appendDigit("2") })
                KeyboardButton(label: "3", action: { logger.info("Digit '3' tapped"); appendDigit("3") })
            }

            HStack(spacing: 8) {
                KeyboardButton(label: "4", action: { logger.info("Digit '4' tapped"); appendDigit("4") })
                KeyboardButton(label: "5", action: { logger.info("Digit '5' tapped"); appendDigit("5") })
                KeyboardButton(label: "6", action: { logger.info("Digit '6' tapped"); appendDigit("6") })
            }

            HStack(spacing: 8) {
                KeyboardButton(label: "7", action: { logger.info("Digit '7' tapped"); appendDigit("7") })
                KeyboardButton(label: "8", action: { logger.info("Digit '8' tapped"); appendDigit("8") })
                KeyboardButton(label: "9", action: { logger.info("Digit '9' tapped"); appendDigit("9") })
            }

            // Bottom row: [•] [0] [⌫]
            HStack(spacing: 8) {
                KeyboardButton(
                    label: "•",
                    action: { logger.info("Decimal point tapped"); appendDigit(".") }
                )
                KeyboardButton(
                    label: "0",
                    action: { logger.info("Digit '0' tapped"); appendDigit("0") }
                )
                KeyboardButton(
                    label: nil,
                    icon: "delete.left.fill",
                    action: { logger.info("Delete button tapped"); deleteLastDigit() }
                )
            }
        }
        .padding(12)
        .background(Color.secondaryBg)
        .onAppear {
            logger.info("CustomNumericKeyboard appeared - initial text: '\(self.text)', increment: \(self.increment)")
        }
        .onChange(of: text) { oldValue, newValue in
            logger.info("CustomNumericKeyboard text binding changed from '\(oldValue)' to '\(newValue)'")
        }
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
        logger.debug("appendDigit called with '\(digit)' - current text: '\(self.text)'")

        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        // Prevent multiple decimal points
        if digit == "." && text.contains(".") {
            logger.warning("Prevented duplicate decimal point")
            return
        }

        // Prevent leading zeros (except for 0.X)
        if text == "0" && digit != "." {
            logger.debug("Replacing leading zero with '\(digit)'")
            text = digit
            return
        }

        text += digit
        logger.info("After appendDigit: text is now '\(self.text)'")
    }

    private func deleteLastDigit() {
        logger.debug("deleteLastDigit called - current text: '\(self.text)'")

        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        if !text.isEmpty {
            text.removeLast()
            logger.info("After delete: text is now '\(self.text)'")
        } else {
            logger.warning("Delete called but text is already empty")
        }
    }

    private func incrementValue() {
        logger.debug("incrementValue called - current text: '\(self.text)'")

        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        let currentValue = Double(text) ?? 0
        logger.debug("Parsed current value: \(currentValue)")

        let newValue = currentValue + increment
        logger.debug("New value after increment: \(newValue)")

        // Format the result
        if newValue.truncatingRemainder(dividingBy: 1) == 0 {
            text = "\(Int(newValue))"
        } else {
            text = String(format: "%.1f", newValue)
        }
        logger.info("After increment: text is now '\(self.text)'")
    }

    private func decrementValue() {
        logger.debug("decrementValue called - current text: '\(self.text)'")

        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        let currentValue = Double(text) ?? 0
        logger.debug("Parsed current value: \(currentValue)")

        let newValue = max(0, currentValue - increment) // Don't go below 0
        logger.debug("New value after decrement (clamped to >= 0): \(newValue)")

        // Format the result
        if newValue.truncatingRemainder(dividingBy: 1) == 0 {
            text = "\(Int(newValue))"
        } else {
            text = String(format: "%.1f", newValue)
        }
        logger.info("After decrement: text is now '\(self.text)'")
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
