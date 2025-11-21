import SwiftUI
import UIKit

/// A TextField wrapper that suppresses the system keyboard
/// Use this when you want to show a custom keyboard instead of the iOS system keyboard
struct NoKeyboardTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var keyboardType: UIKeyboardType = .default
    var textAlignment: NSTextAlignment = .center
    var font: UIFont = .systemFont(ofSize: 24, weight: .medium)
    var textColor: UIColor = .white
    var shouldBecomeFirstResponder: Bool = false
    var onFocusChange: ((Bool) -> Void)?

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator

        // Key part: Suppress the system keyboard by setting a zero-height input view
        // This prevents AutoLayout conflicts by explicitly setting the height to 0
        let emptyView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        emptyView.translatesAutoresizingMaskIntoConstraints = true
        textField.inputView = emptyView

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

        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text

        // Manually trigger becomeFirstResponder when flag is set
        if shouldBecomeFirstResponder && !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        } else if !shouldBecomeFirstResponder && uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: NoKeyboardTextField

        init(_ parent: NoKeyboardTextField) {
            self.parent = parent
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.onFocusChange?(true)
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.onFocusChange?(false)
        }

        func textField(_ textField: UITextField,
                      shouldChangeCharactersIn range: NSRange,
                      replacementString string: String) -> Bool {
            // Allow all changes - the binding will handle validation
            return true
        }
    }
}
