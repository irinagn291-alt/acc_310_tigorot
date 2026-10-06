import Foundation

/// A saved painting on the quire. Explore writes Idle. Echo samples a Work
/// that is not Expunged. Identity is the SMK object id, not a list index.
struct Work: Codable, Sendable, Identifiable, Equatable, Hashable {
    let id: UUID
    let objectId: String
    var artist: String
    var title: String
    var thumbnail: String?
    var fold: WorkFold
    var dayKey: Int
    var chosenField: QuireField?

    func tokens(for field: QuireField) -> [String] {
        switch field {
        case .artist:
            QuireTokens.split(artist)
        case .title:
            QuireTokens.split(title)
        }
    }

    var usableFields: [QuireField] {
        [QuireField.title, .artist].filter { tokens(for: $0).count >= 2 }
    }

    var canEcho: Bool {
        fold != .expunged && !usableFields.isEmpty
    }
}
