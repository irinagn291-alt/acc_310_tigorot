import Foundation

/// Bundled Copenhagen shelf. Empty or failed SMK search hangs from these
/// Idle Works so the quire still has something to Echo.
enum CopenhagenShelf: Sendable {
    static func echoableWorks(dayKey: Int) -> [Work] {
        allWorks(dayKey: dayKey).filter(\.canEcho)
    }

    static func allWorks(dayKey: Int) -> [Work] {
        fixtures.map { row in
            Work(
                id: row.id,
                objectId: row.objectId,
                artist: row.artist,
                title: row.title,
                thumbnail: row.thumbnail,
                fold: .idle,
                dayKey: dayKey,
                chosenField: nil
            )
        }
    }

    private struct ShelfRow: Sendable {
        let id: UUID
        let objectId: String
        let artist: String
        let title: String
        let thumbnail: String?
    }

    private static let fixtures: [ShelfRow] = [
        ShelfRow(
            id: UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567001") ?? UUID(),
            objectId: "KMS1",
            artist: "Christen Kobke",
            title: "View from Dosseringen near the Sortedam Lake",
            thumbnail: "https://iip.smk.dk/iiif/jp2/kms1.tif.jp2/full/!400,/0/default.jpg"
        ),
        ShelfRow(
            id: UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567002") ?? UUID(),
            objectId: "KMS365",
            artist: "Arnold Bocklin",
            title: "The Isle of the Dead",
            thumbnail: "https://iip.smk.dk/iiif/jp2/kms365.tif.jp2/full/!400,/0/default.jpg"
        ),
        ShelfRow(
            id: UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567003") ?? UUID(),
            objectId: "KMS1310",
            artist: "Vilhelm Hammershoi",
            title: "Interior with a young woman seen from the back",
            thumbnail: "https://iip.smk.dk/iiif/jp2/kms1310.tif.jp2/full/!400,/0/default.jpg"
        ),
        ShelfRow(
            id: UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567004") ?? UUID(),
            objectId: "KMS887",
            artist: "C W Eckersberg",
            title: "A View through Three of the North Western Arches",
            thumbnail: "https://iip.smk.dk/iiif/jp2/kms887.tif.jp2/full/!400,/0/default.jpg"
        ),
        ShelfRow(
            id: UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567005") ?? UUID(),
            objectId: "KMS8",
            artist: "OneName",
            title: "Solo",
            thumbnail: nil
        )
    ]
}
