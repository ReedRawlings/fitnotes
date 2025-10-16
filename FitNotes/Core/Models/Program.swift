import Foundation
import SwiftData

@Model
public final class Program {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var description: String?
    public var days: [String]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        days: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.days = days
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
