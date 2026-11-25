import Foundation
import SwiftData

/// Exports the user's logged sets as CSV so their data can leave the device
/// (the app is local-only; this is the user's backup/portability path).
public final class DataExportService {
    public static let shared = DataExportService()
    private init() {}

    static let header = ["Date", "Time", "Exercise", "Category", "Set", "Weight", "Unit", "Reps", "RPE", "RIR", "Duration (s)", "Distance", "Completed", "Notes"]

    /// One row per logged set, oldest first.
    func makeCSV(modelContext: ModelContext) throws -> String {
        let sets = try modelContext.fetch(FetchDescriptor<WorkoutSet>(
            sortBy: [SortDescriptor(\.date), SortDescriptor(\.order)]
        ))
        let exercises = try modelContext.fetch(FetchDescriptor<Exercise>())
        let exerciseById = Dictionary(exercises.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return Self.csv(sets: sets, exerciseById: exerciseById)
    }

    static func csv(sets: [WorkoutSet], exerciseById: [UUID: Exercise]) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.dateFormat = "HH:mm"

        var lines = [header.map(escape).joined(separator: ",")]
        for set in sets {
            let exercise = exerciseById[set.exerciseId]
            let row: [String] = [
                dateFormatter.string(from: set.date),
                set.completedAt.map { timeFormatter.string(from: $0) } ?? "",
                exercise?.name ?? "Unknown exercise",
                exercise?.primaryCategory ?? "",
                String(set.order),
                set.weight.map(formatNumber) ?? "",
                set.unit,
                set.reps.map(String.init) ?? "",
                set.rpe.map(String.init) ?? "",
                set.rir.map(String.init) ?? "",
                set.duration.map(String.init) ?? "",
                set.distance.map(formatNumber) ?? "",
                set.isCompleted ? "Yes" : "No",
                set.notes ?? ""
            ]
            lines.append(row.map(escape).joined(separator: ","))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    /// Writes the CSV to a temporary file suitable for the share sheet.
    func exportFile(modelContext: ModelContext) throws -> URL {
        let csv = try makeCSV(modelContext: modelContext)
        let stamp = Date().formatted(.iso8601.year().month().day())
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(AppInfo.displayName.replacingOccurrences(of: " ", with: ""))-export-\(stamp).csv")
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    static func escape(_ field: String) -> String {
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" }) else {
            return field
        }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private static func formatNumber(_ value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(value)
    }
}
