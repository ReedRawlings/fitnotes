import SwiftUI

// MARK: - Plate math

/// Works out which plates to load on each side of a barbell for a target weight.
enum PlateCalculator {

    struct Result: Equatable {
        /// Plates for ONE side, heaviest first.
        let perSide: [Double]
        /// Weight that could not be made with the available plates (total across both sides).
        let remainder: Double
        /// Bar + plates actually loaded.
        let loadedWeight: Double
    }

    static func standardPlates(unit: String) -> [Double] {
        unit.lowercased() == "lbs" ? [45, 35, 25, 10, 5, 2.5] : [25, 20, 15, 10, 5, 2.5, 1.25]
    }

    static func barOptions(unit: String) -> [Double] {
        unit.lowercased() == "lbs" ? [45, 35, 15] : [20, 15, 10]
    }

    /// Greedy fill per side, which is exact for standard plate sets. Weights below the bar load nothing.
    static func plates(target: Double, bar: Double, available: [Double]) -> Result {
        guard target > bar else {
            return Result(perSide: [], remainder: max(0, target - bar), loadedWeight: bar)
        }
        // Work in hundredths so 2.5 / 1.25 plates don't accumulate floating point error
        var remainingPerSide = Int(((target - bar) / 2 * 100).rounded())
        var perSide: [Double] = []
        for plate in available.sorted(by: >) {
            let plateUnits = Int((plate * 100).rounded())
            guard plateUnits > 0 else { continue }
            while remainingPerSide >= plateUnits {
                perSide.append(plate)
                remainingPerSide -= plateUnits
            }
        }
        let loaded = bar + perSide.reduce(0, +) * 2
        return Result(perSide: perSide, remainder: Double(remainingPerSide) * 2 / 100, loadedWeight: loaded)
    }
}

// MARK: - Plate calculator sheet

struct PlateCalculatorView: View {
    let unit: String
    @Environment(\.dismiss) private var dismiss
    @State private var targetText: String
    @State private var bar: Double
    @FocusState private var targetFocused: Bool

    init(unit: String, initialWeight: Double?) {
        self.unit = unit
        _targetText = State(initialValue: initialWeight.map { WeightTextFormatter.format($0) } ?? "")
        _bar = State(initialValue: PlateCalculator.barOptions(unit: unit)[0])
    }

    private var target: Double? {
        Double(targetText.replacingOccurrences(of: ",", with: "."))
    }

    private var result: PlateCalculator.Result? {
        guard let target else { return nil }
        return PlateCalculator.plates(target: target, bar: bar, available: PlateCalculator.standardPlates(unit: unit))
    }

    var body: some View {
        ZStack {
            Color.primaryBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    FormSectionCard(title: "Target Weight") {
                        HStack {
                            TextField("0", text: $targetText)
                                .keyboardType(.decimalPad)
                                .focused($targetFocused)
                                .font(.system(size: 28, weight: .semibold, design: .monospaced))
                                .foregroundColor(.textPrimary)
                            Text(unit)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.textSecondary)
                        }
                        .padding(12)
                        .background(Color.tertiaryBg)
                        .cornerRadius(10)
                    }

                    FormSectionCard(title: "Bar") {
                        HStack(spacing: 0) {
                            ForEach(PlateCalculator.barOptions(unit: unit), id: \.self) { option in
                                Button(action: { withAnimation(.standardSpring) { bar = option } }) {
                                    Text("\(WeightTextFormatter.format(option)) \(unit)")
                                        .font(.system(size: 15, weight: bar == option ? .semibold : .medium))
                                        .foregroundColor(bar == option ? .textPrimary : .textSecondary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(bar == option ? Color.tertiaryBg : Color.clear)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .accessibilityAddTraits(bar == option ? .isSelected : [])
                            }
                        }
                        .padding(4)
                        .background(Color.secondaryBg)
                        .cornerRadius(12)
                    }

                    FormSectionCard(title: "Each Side") {
                        resultContent
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .navigationTitle("Plate Calculator")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
                    .foregroundColor(.accentPrimary)
            }
        }
        .onAppear {
            if targetText.isEmpty { targetFocused = true }
        }
    }

    @ViewBuilder
    private var resultContent: some View {
        if let result, let target {
            VStack(alignment: .leading, spacing: 12) {
                if result.perSide.isEmpty {
                    Text(target <= bar ? "Just the bar" : "No plates fit")
                        .font(.bodyFont)
                        .foregroundColor(.textSecondary)
                } else {
                    // Group identical plates: "45 × 2"
                    ForEach(groupedPlates(result.perSide), id: \.plate) { group in
                        HStack {
                            Text("\(WeightTextFormatter.format(group.plate)) \(unit)")
                                .font(.system(size: 17, weight: .semibold, design: .monospaced))
                                .foregroundColor(.textPrimary)
                            Spacer()
                            Text("× \(group.count)")
                                .font(.system(size: 17, weight: .medium, design: .monospaced))
                                .foregroundColor(.textSecondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }

                if result.remainder > 0.001 {
                    Text("Closest you can load is \(WeightTextFormatter.format(result.loadedWeight)) \(unit) (\(WeightTextFormatter.format(result.remainder)) \(unit) short).")
                        .font(.system(size: 13))
                        .foregroundColor(.accentSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text("Enter a weight to see the plates.")
                .font(.bodyFont)
                .foregroundColor(.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func groupedPlates(_ plates: [Double]) -> [(plate: Double, count: Int)] {
        var groups: [(plate: Double, count: Int)] = []
        for plate in plates {
            if let last = groups.last, last.plate == plate {
                groups[groups.count - 1].count += 1
            } else {
                groups.append((plate, 1))
            }
        }
        return groups
    }
}
