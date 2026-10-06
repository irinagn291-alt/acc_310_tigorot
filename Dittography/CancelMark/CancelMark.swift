import Foundation

/// Filed when the surplus copy is tapped. Folds Echoed to Expunged.
struct CancelMark: Codable, Sendable, Identifiable, Equatable, Hashable {
    let id: UUID
    let workId: UUID
    let wordId: UUID
    let dayKey: Int
    let stampedAt: Date
}
