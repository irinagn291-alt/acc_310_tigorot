import Foundation

/// Codable projection of the in-memory quire. schemaVersion starts at 1.
/// UserDefaults key dtg.quire.v1 and the Application Support file hold the same JSON.
struct QuireDocument: Codable, Sendable, Equatable {
    var schemaVersion: Int
    var works: [Work]
    var dittograph: Dittograph?
    var cancelMarks: [CancelMark]
    var dwellMarks: [DwellMark]
    var fold: QuireFold
    var onboardingComplete: Bool
    var focusedObjectId: String?

    static let currentSchema = 1
    static let defaultsKey = "dtg.quire.v1"
    static let demoKey = "dtg.demo.v1"

    static var empty: QuireDocument {
        QuireDocument(
            schemaVersion: currentSchema,
            works: [],
            dittograph: nil,
            cancelMarks: [],
            dwellMarks: [],
            fold: .idle,
            onboardingComplete: false,
            focusedObjectId: nil
        )
    }

    var newestMark: QuireMark? {
        let cancels = cancelMarks.map(QuireMark.cancel)
        let dwells = dwellMarks.map(QuireMark.dwell)
        return (cancels + dwells).max { $0.stampedAt < $1.stampedAt }
    }

    enum DecodeIssue: Sendable, Equatable {
        case none
        case recoveredFromBackup
        case startedEmpty
    }
}

enum QuireDocumentCodec {
    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    static func encode(_ document: QuireDocument) throws -> Data {
        try makeEncoder().encode(document)
    }

    static func decode(_ data: Data) throws -> QuireDocument {
        let decoder = makeDecoder()
        let envelope = try decoder.decode(SchemaEnvelope.self, from: data)
        switch envelope.schemaVersion {
        case 1:
            return try decoder.decode(QuireDocument.self, from: data)
        default:
            throw QuireVaultError.unsupportedSchema(envelope.schemaVersion)
        }
    }
}

private struct SchemaEnvelope: Decodable {
    let schemaVersion: Int
}

enum QuireVaultError: Error, Sendable, Equatable {
    case unsupportedSchema(Int)
}
