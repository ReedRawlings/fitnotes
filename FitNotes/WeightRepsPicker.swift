import SwiftUI
import UIKit

// MARK: - Weight/Reps Picker
// Native iOS picker component for one-handed weight and reps input

struct WeightRepsPicker: View {
    let pickerType: PickerType
    let currentValue: Double
    let onValueChanged: (Double) -> Void
    let onDismiss: () -> Void
    
    // Removed commitNearest storage to avoid state mutation during updates
    
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
            
            // Centered Popover
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
                    onValueChanged: onValueChanged,
                    onProvideCommit: { _ in }
                )
                .frame(height: 200)
            }
            .background(Color.secondaryBg)
            .cornerRadius(16)
            .frame(width: 280)
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        }
    }
}


// MARK: - Native Picker View
struct PickerView: UIViewRepresentable {
    let pickerType: WeightRepsPicker.PickerType
    let currentValue: Double
    let onValueChanged: (Double) -> Void
    let onProvideCommit: (((@escaping () -> Void)) -> Void)?
    
    func makeUIView(context: Context) -> UIPickerView {
        let picker = UIPickerView()
        picker.delegate = context.coordinator
        picker.dataSource = context.coordinator
        picker.backgroundColor = UIColor.clear
        context.coordinator.pickerView = picker
        
        // Disable sound effects (showsSelectionIndicator is deprecated)
        
        // Set initial selection
        let values = pickerType.values
        if let index = values.firstIndex(of: currentValue) {
            picker.selectRow(index, inComponent: 0, animated: false)
        }
        
        // Configure underlying scroll behavior to reduce lag and enable snapping
        func findScrollView(in view: UIView) -> UIScrollView? {
            if let sv = view as? UIScrollView { return sv }
            for sub in view.subviews {
                if let found = findScrollView(in: sub) { return found }
            }
            return nil
        }
        if let scrollView = findScrollView(in: picker) {
            scrollView.decelerationRate = .fast
            scrollView.delegate = context.coordinator
            context.coordinator.scrollView = scrollView
        }
        
        // Provide a commit closure back to SwiftUI parent
        if let provide = onProvideCommit {
            provide { [weak coordinator = context.coordinator] in
                coordinator?.commitNearestNow()
            }
        }
        
        return picker
    }
    
    func updateUIView(_ uiView: UIPickerView, context: Context) {
        // Update selection if needed
        let values = pickerType.values
        if let index = values.firstIndex(of: currentValue) {
            uiView.selectRow(index, inComponent: 0, animated: false)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIPickerViewDelegate, UIPickerViewDataSource, UIScrollViewDelegate {
        let parent: PickerView
        weak var pickerView: UIPickerView?
        weak var scrollView: UIScrollView?
        private var lastReportedRow: Int?
        
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
    
    // MARK: - UIScrollViewDelegate snapping
    private func rowHeight() -> CGFloat { 44 }
    
    private func snapToNearestRowAndNotify(animated: Bool) {
        guard let picker = pickerView, let scroll = scrollView else { return }
        let height = rowHeight()
        if height <= 0 { return }
        let rawRow = (scroll.contentOffset.y / height).rounded()
        var nearest = max(0, Int(rawRow))
        let maxIndex = max(0, parent.pickerType.values.count - 1)
        if nearest > maxIndex { nearest = maxIndex }
        picker.selectRow(nearest, inComponent: 0, animated: animated)
        let value = parent.pickerType.values[nearest]
        parent.onValueChanged(value)
        lastReportedRow = nearest
    }
    
    // Expose an explicit commit for dismissal
    func commitNearestNow() {
        guard let picker = pickerView, let scroll = scrollView else { return }
        let height = rowHeight()
        if height <= 0 { return }
        let rawRow = (scroll.contentOffset.y / height).rounded()
        var nearest = max(0, Int(rawRow))
        let maxIndex = max(0, parent.pickerType.values.count - 1)
        if nearest > maxIndex { nearest = maxIndex }
        picker.selectRow(nearest, inComponent: 0, animated: false)
        let value = parent.pickerType.values[nearest]
        parent.onValueChanged(value)
        lastReportedRow = nearest
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let height = rowHeight()
        if height <= 0 { return }
        let rawRow = (scrollView.contentOffset.y / height).rounded()
        var nearest = max(0, Int(rawRow))
        let maxIndex = max(0, parent.pickerType.values.count - 1)
        if nearest > maxIndex { nearest = maxIndex }
        if nearest != lastReportedRow {
            let value = parent.pickerType.values[nearest]
            parent.onValueChanged(value)
            lastReportedRow = nearest
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let height = rowHeight()
        if height <= 0 { return }
        let projected = targetContentOffset.pointee.y / height
        let nearest = (projected.rounded()) * height
        targetContentOffset.pointee.y = nearest
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { snapToNearestRowAndNotify(animated: true) }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        snapToNearestRowAndNotify(animated: true)
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
