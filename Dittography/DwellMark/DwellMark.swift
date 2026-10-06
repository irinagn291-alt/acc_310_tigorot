import Foundation

/// Filed on a miss. Greys that Word and keeps the Dittograph.
struct DwellMark: Codable, Sendable, Identifiable, Equatable, Hashable {
    let id: UUID
    let workId: UUID
    let wordId: UUID
    let dayKey: Int
    let stampedAt: Date
}

/// Newest CancelMark or DwellMark on one peel stack.
enum QuireMark: Sendable, Equatable {
    case cancel(CancelMark)
    case dwell(DwellMark)

    var stampedAt: Date {
        switch self {
        case .cancel(let mark): mark.stampedAt
        case .dwell(let mark): mark.stampedAt
        }
    }
}
