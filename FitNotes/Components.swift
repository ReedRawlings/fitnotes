// MARK: - Components.swift
// Central export file for FitNotes Components

import SwiftUI

// MARK: - CardListView
struct CardListView<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content
    
    init(_ items: [Item], @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items
        self.content = content
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                LazyVStack(spacing: 0) {
                    ForEach(items) { item in
                        content(item)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                Spacer(minLength: 100)
            }
        }
    }
}

// MARK: - EmptyStateView
 struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String?
    let onAction: (() -> Void)?
    
 init(
        icon: String,
        title: String,
        subtitle: String,
        actionTitle: String? = nil,
        onAction: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.onAction = onAction
    }
    
 var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.textTertiary.opacity(0.3))
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            if let actionTitle = actionTitle, let onAction = onAction {
                Button(action: onAction) {
                    HStack {
                        Image(systemName: "plus")
                        Text(actionTitle)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.accentPrimary, .accentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.textInverse)
                    .cornerRadius(16)
                    .shadow(
                        color: .accentPrimary.opacity(0.3),
                        radius: 16,
                        x: 0,
                        y: 4
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .padding()
    }
}



// MARK: - PrimaryActionButton
 struct PrimaryActionButton: View {
    let title: String
    let icon: String
    let onTap: () -> Void
    
 init(title: String, icon: String = "plus", onTap: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.onTap = onTap
    }
    
 var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                
                Text(title)
                    .font(.buttonFont)
            }
            .foregroundColor(.textInverse)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [.accentPrimary, .accentSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .shadow(
                color: .accentPrimary.opacity(0.3),
                radius: 16,
                x: 0,
                y: 4
            )
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Modal Form Components
// Components specifically for modal forms (Add Exercise, Add Routine, etc.)

// MARK: - OptionalLineLimitModifier
struct OptionalLineLimitModifier: ViewModifier {
    let lineLimit: ClosedRange<Int>?
    
    func body(content: Content) -> some View {
        if let range = lineLimit {
            content.lineLimit(range)
        } else {
            content
        }
    }
}

// MARK: - FormSectionCard
struct FormSectionCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.sectionHeader)
                .foregroundColor(.textTertiary)
                .kerning(0.3)
            
            content
        }
        .padding(16)
        .background(Color.secondaryBg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - LabeledTextInput
struct LabeledTextInput: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var axis: Axis = .horizontal
    var lineLimit: ClosedRange<Int>? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.textSecondary)
            
            TextField(placeholder, text: $text, axis: axis)
                .font(.bodyFont)
                .foregroundColor(.textPrimary)
                .padding(12)
                .background(Color.tertiaryBg)
                .cornerRadius(10)
                .modifier(OptionalLineLimitModifier(lineLimit: lineLimit))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        }
    }
}

// MARK: - LabeledMenuPicker
struct LabeledMenuPicker: View {
    let label: String
    let options: [String]
    @Binding var selection: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.textSecondary)
            
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) {
                        selection = option
                    }
                }
            } label: {
                HStack {
                    Text(selection)
                        .font(.bodyFont)
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                .padding(12)
                .background(Color.tertiaryBg)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - StepperRow
struct StepperRow: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let suffix: String
    let step: Int
    
    init(
        label: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        suffix: String = "",
        step: Int = 1
    ) {
        self.label = label
        self._value = value
        self.range = range
        self.suffix = suffix
        self.step = step
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.bodyFont)
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: {
                    if value > range.lowerBound {
                        value -= step
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(value > range.lowerBound ? .accentPrimary : .textTertiary)
                }
                
                Text("\(value)\(suffix)")
                    .font(.system(size: 20, weight: .medium, design: .monospaced))
                    .foregroundColor(.textPrimary)
                    .frame(minWidth: suffix.isEmpty ? 40 : 80)
                
                Button(action: {
                    if value < range.upperBound {
                        value += step
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(value < range.upperBound ? .accentPrimary : .textTertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - DoubleStepperRow
struct DoubleStepperRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let suffix: String
    let step: Double
    
    var body: some View {
        HStack {
            Text(label)
                .font(.bodyFont)
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: {
                    if value > range.lowerBound {
                        value -= step
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(value > range.lowerBound ? .accentPrimary : .textTertiary)
                }
                
                Text(formatValue(value) + suffix)
                    .font(.system(size: 20, weight: .medium, design: .monospaced))
                    .foregroundColor(.textPrimary)
                    .frame(minWidth: 80)
                
                Button(action: {
                    if value < range.upperBound {
                        value += step
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(value < range.upperBound ? .accentPrimary : .textTertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatValue(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))"
        } else {
            return String(format: "%.1f", value)
        }
    }
}

// MARK: - FixedModalCTAButton
struct FixedModalCTAButton: View {
    let title: String
    let icon: String
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            Button(action: action) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                    Text(title)
                        .font(.buttonFont)
                }
                .foregroundColor(.textInverse)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    isEnabled ?
                    LinearGradient(
                        colors: [.accentPrimary, .accentSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(
                        colors: [.disabledOverlay, .disabledOverlay],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
                .shadow(
                    color: isEnabled ? .accentPrimary.opacity(0.3) : .clear,
                    radius: 16,
                    x: 0,
                    y: 4
                )
            }
            .disabled(!isEnabled)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
}