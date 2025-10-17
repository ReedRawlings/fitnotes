import Foundation

public final class HealthKitService {
    public init() {}
    public func requestAuthorization() async throws {}
}

public final class WatchSyncService {
    public init() {}
    public func send(payload: Data) {}
}

public final class CSVImportExportService {
    public init() {}
    public func exportAll() -> Data { Data() }
}

public final class SettingsManager: ObservableObject {
    @Published public var isCloudSyncEnabled: Bool = false
    public init() {}
}

// Re-export the new services
public typealias ExerciseDBService = ExerciseDatabaseService
public typealias RoutineService = DailyRoutineService
