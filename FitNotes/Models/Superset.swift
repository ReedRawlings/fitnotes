import Foundation

// MARK: - Supersets
//
// A superset is a run of ADJACENT exercises (sorted by `order`) that share a non-nil
// `supersetGroupId`. Adjacency is what matters: a lone exercise with a group id, or two runs that
// happen to share an id but are separated by another exercise, are treated as separate. That keeps
// supersets robust to reordering and deletion without any cleanup pass being required.

/// Anything that can sit in a superset: workout exercises and routine template exercises.
protocol SupersetMember: AnyObject {
    var id: UUID { get }
    var supersetGroupId: UUID? { get set }
}

extension WorkoutExercise: SupersetMember {}
extension RoutineExercise: SupersetMember {}

/// Where an exercise sits within its superset, for drawing the bracket and the "A1" label.
struct SupersetSlot: Equatable {
    enum Position: Equatable { case first, middle, last }

    let position: Position
    /// Zero-based index of the superset within the list (0 = "A").
    let groupIndex: Int
    /// Zero-based index within the superset (0 = "A1").
    let memberIndex: Int

    var label: String {
        let letters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        let letter = groupIndex < letters.count ? String(letters[groupIndex]) : "#\(groupIndex + 1)"
        return "\(letter)\(memberIndex + 1)"
    }
}

enum SupersetLayout {

    /// Index ranges of every superset (runs of 2 or more) in `items`, which must already be sorted by order.
    static func runs(in items: [some SupersetMember]) -> [Range<Int>] {
        var result: [Range<Int>] = []
        var start = 0
        while start < items.count {
            let block = blockRange(at: start, in: items)
            if block.count >= 2 { result.append(block) }
            start = block.upperBound
        }
        return result
    }

    /// Slot for every exercise that is in a superset, keyed by the exercise's id.
    static func slots(for items: [some SupersetMember]) -> [UUID: SupersetSlot] {
        var result: [UUID: SupersetSlot] = [:]
        for (groupIndex, run) in runs(in: items).enumerated() {
            for (memberIndex, index) in run.enumerated() {
                let position: SupersetSlot.Position =
                    index == run.lowerBound ? .first : (index == run.upperBound - 1 ? .last : .middle)
                result[items[index].id] = SupersetSlot(position: position, groupIndex: groupIndex, memberIndex: memberIndex)
            }
        }
        return result
    }

    /// The superset containing the exercise with `id`, or nil when it isn't in one.
    static func run<T: SupersetMember>(containing id: UUID, in items: [T]) -> [T]? {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return nil }
        let block = blockRange(at: index, in: items)
        return block.count >= 2 ? Array(items[block]) : nil
    }

    /// True when the exercise at `index` is supersetted with the one after it.
    static func isLinkedToNext(at index: Int, in items: [some SupersetMember]) -> Bool {
        guard index + 1 < items.count, let group = items[index].supersetGroupId else { return false }
        return items[index + 1].supersetGroupId == group
    }

    /// Links the exercise at `index` with the next one (merging any supersets either is already in),
    /// or, if they are already linked, splits the superset between them.
    static func toggleLink(at index: Int, in items: [some SupersetMember]) {
        guard index >= 0, index + 1 < items.count else { return }
        if isLinkedToNext(at: index, in: items) {
            split(after: index, in: items)
        } else {
            merge(index, index + 1, in: items)
        }
    }

    /// Clears group ids on exercises that are no longer next to another member of their superset
    /// (e.g. after reordering or deleting). Purely tidy-up: `runs` already ignores them.
    static func normalize(_ items: [some SupersetMember]) {
        var start = 0
        while start < items.count {
            let block = blockRange(at: start, in: items)
            if block.count == 1 { items[block.lowerBound].supersetGroupId = nil }
            start = block.upperBound
        }
    }

    // MARK: - Private

    /// The maximal run of adjacent items around `index` sharing its group id (just `index` if it has none).
    private static func blockRange(at index: Int, in items: [some SupersetMember]) -> Range<Int> {
        guard let group = items[index].supersetGroupId else { return index..<(index + 1) }
        var lower = index
        while lower > 0, items[lower - 1].supersetGroupId == group { lower -= 1 }
        var upper = index + 1
        while upper < items.count, items[upper].supersetGroupId == group { upper += 1 }
        return lower..<upper
    }

    private static func merge(_ left: Int, _ right: Int, in items: [some SupersetMember]) {
        let target = items[left].supersetGroupId ?? items[right].supersetGroupId ?? UUID()
        let leftBlock = blockRange(at: left, in: items)
        let rightBlock = blockRange(at: right, in: items)
        for index in leftBlock { items[index].supersetGroupId = target }
        for index in rightBlock { items[index].supersetGroupId = target }
    }

    private static func split(after index: Int, in items: [some SupersetMember]) {
        let block = blockRange(at: index, in: items)
        let leftPart = block.lowerBound...index
        let rightPart = (index + 1)..<block.upperBound
        // The right half becomes its own superset (fresh id) or a plain exercise if it's alone
        let rightGroup: UUID? = rightPart.count >= 2 ? UUID() : nil
        for i in rightPart { items[i].supersetGroupId = rightGroup }
        if leftPart.count < 2 { items[index].supersetGroupId = nil }
    }
}
