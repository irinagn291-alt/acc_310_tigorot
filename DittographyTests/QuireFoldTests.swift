import XCTest
@testable import Dittography

@MainActor
final class QuireFoldTests: XCTestCase {
    func test_familyInvariant_quizDrawsFromSavedWorks_andMissesStayReviewable() async throws {
        let store = try makeStore()
        let work = fixtureWork(objectId: "K1", artist: "Vilhelm Hammershoi", title: "Sunlit dust in a quiet room")
        store.adoptWork(work)
        store.echoQuire()
        XCTAssertEqual(store.fold, .echoed)
        XCTAssertEqual(store.dittograph?.workId, store.works.first?.id)
        guard let missId = store.dittograph?.words.first(where: { $0.id != store.dittograph?.surplusWordId })?.id else {
            return XCTFail("expected a non-surplus word")
        }
        store.dwellWord(missId)
        XCTAssertEqual(store.fold, .echoed)
        XCTAssertEqual(store.document.dwellMarks.count, 1)
        XCTAssertTrue(store.document.dwellMarks.contains { $0.wordId == missId })
    }

    func test_echo_samplesOnlyNotExpungedWorks() async throws {
        let store = try makeStore()
        let kept = fixtureWork(objectId: "A-keep", artist: "Christen Kobke", title: "Lake light on two banks")
        var filed = fixtureWork(objectId: "B-gone", artist: "Arnold Bocklin", title: "Isle of the Dead")
        filed.fold = .expunged
        store.replaceDocument(
            QuireDocument(
                schemaVersion: 1,
                works: [filed, kept],
                dittograph: nil,
                cancelMarks: [],
                dwellMarks: [],
                fold: .idle,
                onboardingComplete: true,
                focusedObjectId: nil
            )
        )
        store.echoQuire()
        XCTAssertEqual(store.dittograph?.workId, kept.id)
        XCTAssertFalse(store.echoPool.contains { $0.fold == .expunged })
    }

    func test_echo_refusesFewerThanTwoTokens_andWritesFair() async throws {
        let store = try makeStore()
        store.adoptWork(fixtureWork(objectId: "short", artist: "Solo", title: "One"))
        store.echoQuire()
        XCTAssertEqual(store.fold, .fair)
        XCTAssertNil(store.dittograph)
    }

    func test_expunge_onIdleIsRefused() async throws {
        let store = try makeStore()
        store.adoptWork(fixtureWork(objectId: "idle", artist: "Two Words", title: "More than one"))
        XCTAssertEqual(store.fold, .idle)
        store.expungeWord(UUID())
        XCTAssertEqual(store.fold, .idle)
        XCTAssertTrue(store.document.cancelMarks.isEmpty)
    }

    func test_secondEcho_whileEchoedIsRefused() async throws {
        let store = try makeStore()
        store.adoptWork(fixtureWork(objectId: "one", artist: "First Maker Name", title: "First picture line"))
        store.adoptWork(fixtureWork(objectId: "two", artist: "Second Maker Name", title: "Second picture line"))
        store.echoQuire()
        let firstCard = store.dittograph
        store.echoQuire()
        XCTAssertEqual(store.dittograph, firstCard)
        XCTAssertEqual(store.works.filter { $0.fold == .echoed }.count, 1)
    }

    func test_surplusCopy_onlyWritesCancelMark_andFoldsExpunged() async throws {
        let store = try makeStore()
        store.adoptWork(fixtureWork(objectId: "hit", artist: "Quiet Room Painter", title: "Dust in morning light"))
        store.echoQuire()
        guard let surplus = store.dittograph?.surplusWordId else {
            return XCTFail("missing surplus")
        }
        store.expungeWord(surplus)
        XCTAssertEqual(store.fold, .expunged)
        XCTAssertEqual(store.document.cancelMarks.count, 1)
        XCTAssertEqual(store.works.first?.fold, .expunged)
        XCTAssertTrue(store.echoPool.isEmpty)
    }

    func test_miss_writesDwell_andKeepsDittograph() async throws {
        let store = try makeStore()
        store.adoptWork(fixtureWork(objectId: "miss", artist: "Quiet Room Painter", title: "Dust in morning light"))
        store.echoQuire()
        let card = store.dittograph
        guard let miss = card?.words.first(where: { $0.id != card?.surplusWordId })?.id else {
            return XCTFail("missing miss word")
        }
        store.dwellWord(miss)
        XCTAssertEqual(store.fold, .echoed)
        XCTAssertEqual(store.dittograph?.workId, card?.workId)
        XCTAssertEqual(store.dittograph?.words.first(where: { $0.id == miss })?.isDimmed, true)
        XCTAssertEqual(store.document.dwellMarks.count, 1)
    }

    func test_peelNewestMark_undoesCancelThenDwell() async throws {
        let store = try makeStore()
        store.adoptWork(fixtureWork(objectId: "undo", artist: "Quiet Room Painter", title: "Dust in morning light"))
        store.echoQuire()
        guard let card = store.dittograph,
              let miss = card.words.first(where: { $0.id != card.surplusWordId })?.id
        else { return XCTFail("card") }
        store.dwellWord(miss)
        store.expungeWord(card.surplusWordId)
        XCTAssertEqual(store.fold, .expunged)
        store.peelNewestMark()
        XCTAssertEqual(store.fold, .echoed)
        XCTAssertEqual(store.works.first?.fold, .echoed)
        XCTAssertTrue(store.echoPool.contains { $0.id == card.workId })
        store.peelNewestMark()
        XCTAssertEqual(store.document.dwellMarks.count, 0)
        XCTAssertEqual(store.dittograph?.words.first(where: { $0.id == miss })?.isDimmed, false)
    }

    func test_duplicateObjectId_focusesExisting_andDoesNotResetFold() async throws {
        let store = try makeStore()
        let first = fixtureWork(objectId: "same", artist: "Quiet Room Painter", title: "Dust in morning light")
        store.adoptWork(first)
        store.echoQuire()
        XCTAssertEqual(store.fold, .echoed)
        var copy = first
        copy.artist = "Changed Later"
        store.adoptWork(copy)
        XCTAssertEqual(store.works.count, 1)
        XCTAssertEqual(store.document.focusedObjectId, "same")
        XCTAssertEqual(store.fold, .echoed)
        XCTAssertEqual(store.works.first?.artist, "Quiet Room Painter")
    }

    func test_dittograph_isArtistXorTitle_withOneTokenWrittenTwice() {
        let work = fixtureWork(objectId: "xor", artist: "One Two", title: "Alpha Beta Gamma")
        let card = Dittograph.printed(from: work, field: .title, copyAt: 1)
        XCTAssertEqual(card?.field, .title)
        XCTAssertEqual(card?.words.map(\.text), ["Alpha", "Beta", "Beta", "Gamma"])
        let surplus = card?.words.filter { $0.id == card?.surplusWordId }
        XCTAssertEqual(surplus?.map(\.text), ["Beta"])
    }
}

@MainActor
private func makeStore() throws -> QuireStore {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    let defaults = UserDefaults(suiteName: folder.lastPathComponent) ?? UserDefaults()
    defaults.removePersistentDomain(forName: folder.lastPathComponent)
    let vault = QuireVault(defaultsSuite: folder.lastPathComponent, directory: folder)
    return QuireStore(vault: vault, defaults: defaults, seedSimulator: false)
}

private func fixtureWork(objectId: String, artist: String, title: String) -> Work {
    Work(
        id: UUID(),
        objectId: objectId,
        artist: artist,
        title: title,
        thumbnail: nil,
        fold: .idle,
        dayKey: 202_609_21,
        chosenField: nil
    )
}
