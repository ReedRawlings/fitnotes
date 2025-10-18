import Foundation
import SwiftData

// MARK: - BodyMetric Model
@Model
public final class BodyMetric {
    @Attribute(.unique) public var id: UUID
    public var date: Date
    public var type: String
    public var value: Double
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        type: String,
        value: Double,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.type = type
        self.value = value
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
