import Foundation

/// One printable token on the Dittograph line. Every Word can be hit.
/// A Dwell greys the Word; identity is a stable UUID.
struct Word: Codable, Sendable, Identifiable, Equatable, Hashable {
    let id: UUID
    let text: String
    var isDimmed: Bool
}
