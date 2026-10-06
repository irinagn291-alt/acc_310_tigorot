import Foundation

/// QuizCard for this lexicon: artist XOR title with one Token written twice
/// in a row. The surplus copy is the only hit that files a CancelMark.
struct Dittograph: Codable, Sendable, Equatable, Hashable {
    let workId: UUID
    let field: QuireField
    var words: [Word]
    let surplusWordId: UUID

    static func printed(from work: Work, field: QuireField, copyAt tokenIndex: Int = 0) -> Dittograph? {
        let tokens = work.tokens(for: field)
        guard tokens.count >= 2, tokens.indices.contains(tokenIndex) else { return nil }
        var words: [Word] = []
        var surplusId = UUID()
        for (index, token) in tokens.enumerated() {
            words.append(Word(id: UUID(), text: token, isDimmed: false))
            if index == tokenIndex {
                surplusId = UUID()
                words.append(Word(id: surplusId, text: token, isDimmed: false))
            }
        }
        return Dittograph(workId: work.id, field: field, words: words, surplusWordId: surplusId)
    }

    func word(id: UUID) -> Word? {
        words.first { $0.id == id }
    }

    var isSurplus: (UUID) -> Bool {
        { $0 == surplusWordId }
    }
}
