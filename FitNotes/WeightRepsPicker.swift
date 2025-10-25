import SwiftUI
import UIKit

// MARK: - Weight/Reps Picker
// Native iOS picker component for one-handed weight and reps input

struct WeightRepsPicker: View {
    let pickerType: PickerType
    let currentValue: Double
    let onValueChanged: (Double) -> Void
    let onDismiss: () -> Void
    
    enum PickerType {
        case weight
        case reps
        
        var title: String {
            switch self {
            case .weight: return "Select Weight"
            case .reps: return "Select Reps"
            }
        }
        
        var values: [Double] {
            switch self {
            case .weight:
                return Array(stride(from: 0, through: 200, by: 2.5))
            case .reps:
                return Array(1...20).map { Double($0) }
            }
        }
        
        var unit: String {
            switch self {
            case .weight: return "kg"
            case .reps: return ""
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            VStack(spacing: 0) {
                Spacer()
                
                // Picker Sheet
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text(pickerType.title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        Spacer()
                        
                        Button("Done") {
                            onDismiss()
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.accentPrimary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.secondaryBg)
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color.white.opacity(0.06)),
                        alignment: .bottom
                    )
                    
                    // Picker Content
                    PickerView(
                        pickerType: pickerType,
                        currentValue: currentValue,
                        onValueChanged: onValueChanged
                    )
                    .frame(height: 260)
                }
                .background(Color.secondaryBg)
                .cornerRadius(20, corners: [.topLeft, .topRight])
            }
        }
    }
}


// MARK: - Native Picker View
struct PickerView: UIViewRepresentable {
    let pickerType: WeightRepsPicker.PickerType
    let currentValue: Double
    let onValueChanged: (Double) -> Void
    
    func makeUIView(context: Context) -> UIPickerView {
        let picker = UIPickerView()
        picker.delegate = context.coordinator
        picker.dataSource = context.coordinator
        picker.backgroundColor = UIColor.clear
        
        // Set initial selection
        let values = pickerType.values
        if let index = values.firstIndex(of: currentValue) {
            picker.selectRow(index, inComponent: 0, animated: false)
        }
        
        return picker
    }
    
    func updateUIView(_ uiView: UIPickerView, context: Context) {
        // Update selection if needed
        let values = pickerType.values
        if let index = values.firstIndex(of: currentValue) {
            uiView.selectRow(index, inComponent: 0, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
        let parent: PickerView
        
        init(_ parent: PickerView) {
            self.parent = parent
        }
        
        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return 1
        }
        
        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            return parent.pickerType.values.count
        }
        
        func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
            let label = UILabel()
            let value = parent.pickerType.values[row]
            
            if parent.pickerType == .weight {
                let text = value.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(value)) kg" : "\(value) kg"
                label.text = text
            } else {
                label.text = "\(Int(value))"
            }
            
            label.font = UIFont.monospacedSystemFont(ofSize: 22, weight: .medium)
            label.textAlignment = .center
            label.textColor = UIColor.white
            
            return label
        }
        
        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            let value = parent.pickerType.values[row]
            parent.onValueChanged(value)
        }
        
        func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
            return 44
        }
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    VStack(spacing: 20) {
        WeightRepsPicker(
            pickerType: .weight,
            currentValue: 60.0,
            onValueChanged: { _ in },
            onDismiss: { }
        )
        
        WeightRepsPicker(
            pickerType: .reps,
            currentValue: 10,
            onValueChanged: { _ in },
            onDismiss: { }
        )
    }
    .padding()
    .background(Color.primaryBg)
}
