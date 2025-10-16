import Foundation
import SwiftData

@Model
public final class Exercise {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var category: String
    public var type: String
    public var notes: String?
    public var mediaURL: String?
    public var unit: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        category: String,
        type: String,
        notes: String? = nil,
        mediaURL: String? = nil,
        unit: String = "kg",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.type = type
        self.notes = notes
        self.mediaURL = mediaURL
        self.unit = unit
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
