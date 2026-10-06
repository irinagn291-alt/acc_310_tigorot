import Foundation

/// Closed algebraic fold for the quire: Idle | Echoed | Expunged, plus Fair
/// when Echo finds no usable Work. Views pattern-match this; they never invent
/// a second status enum.
enum QuireFold: String, Codable, Sendable, Equatable {
    case idle
    case echoed
    case expunged
    case fair
}

/// Per-Work fold. A fourth case is a defect.
enum WorkFold: String, Codable, Sendable, Equatable {
    case idle
    case echoed
    case expunged
}

/// Artist XOR title: Echo prints exactly one of these fields.
enum QuireField: String, Codable, Sendable, Equatable {
    case artist
    case title
}

/// Day edges fold Calendar.startOfDay into Int YYYYMMDD. Never stored as a
/// formatted string; counts stay computed at the display seam.
enum DayKey: Sendable {
    static func from(_ date: Date, calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: date)
        let parts = calendar.dateComponents([.year, .month, .day], from: start)
        let year = parts.year ?? 0
        let month = parts.month ?? 0
        let day = parts.day ?? 0
        return year * 10_000 + month * 100 + day
    }
}

enum QuireTokens {
    static func split(_ text: String) -> [String] {
        text.split { $0.isWhitespace || $0.isNewline }.map(String.init).filter { !$0.isEmpty }
    }
}
