import SwiftUI
import UIKit
import os.log

/// A TextField wrapper that suppresses the system keyboard
/// Use this when you want to show a custom keyboard instead of the iOS system keyboard
struct NoKeyboardTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var keyboardType: UIKeyboardType = .default
    var textAlignment: NSTextAlignment = .center
    var font: UIFont = .systemFont(ofSize: 24, weight: .medium)
    var textColor: UIColor = .white
    var onFocusChange: ((Bool) -> Void)?

    private static let logger = Logger(subsystem: "com.fitnotes.app", category: "NoKeyboardTextField")

    func makeUIView(context: Context) -> UITextField {
        Self.logger.info("makeUIView called - creating NoKeyboardTextField with placeholder: '\(self.placeholder)'")

        let textField = UITextField()
        textField.delegate = context.coordinator

        // Key part: Suppress the system keyboard by setting a zero-height input view
        // This prevents AutoLayout conflicts by explicitly setting the height to 0
        let emptyView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        emptyView.translatesAutoresizingMaskIntoConstraints = true
        textField.inputView = emptyView
        Self.logger.debug("Set empty inputView to suppress system keyboard")

        // Configuration
        textField.placeholder = placeholder
        textField.textAlignment = textAlignment
        textField.font = font
        textField.textColor = textColor
        textField.tintColor = textColor // Cursor color

        // Make placeholder match the style
        if let placeholder = textField.placeholder {
            textField.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [
                    .foregroundColor: UIColor.white.withAlphaComponent(0.3),
                    .font: font
                ]
            )
        }

        Self.logger.info("NoKeyboardTextField UIView created successfully")
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            Self.logger.debug("updateUIView: updating text from '\(uiView.text ?? "")' to '\(self.text)'")
            uiView.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: NoKeyboardTextField
        private let logger = Logger(subsystem: "com.fitnotes.app", category: "NoKeyboardTextField.Coordinator")

        init(_ parent: NoKeyboardTextField) {
            self.parent = parent
            super.init()
            logger.debug("Coordinator initialized")
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            let newText = textField.text ?? ""
            logger.debug("textFieldDidChangeSelection: text is '\(newText)'")
            if parent.text != newText {
                logger.info("Text changed via selection, updating binding from '\(self.parent.text)' to '\(newText)'")
                parent.text = newText
            }
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            logger.info("textFieldDidBeginEditing: TextField gained focus")
            parent.onFocusChange?(true)
            logger.debug("Called onFocusChange with true")
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            logger.info("textFieldDidEndEditing: TextField lost focus")
            parent.onFocusChange?(false)
            logger.debug("Called onFocusChange with false")
        }

        func textField(_ textField: UITextField,
                      shouldChangeCharactersIn range: NSRange,
                      replacementString string: String) -> Bool {
            logger.debug("shouldChangeCharactersIn: range=\(range), replacementString='\(string)'")
            // Allow all changes - the binding will handle validation
            return true
        }
    }
}
