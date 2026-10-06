import XCTest
@testable import Dittography

@MainActor
final class QuireVaultTests: XCTestCase {
    func test_roundTrip_writeReloadMatchesInMemory() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let suite = folder.lastPathComponent
        let defaults = UserDefaults(suiteName: suite) ?? UserDefaults()
        defaults.removePersistentDomain(forName: suite)
        let vault = QuireVault(defaultsSuite: suite, directory: folder)
        let store = QuireStore(vault: vault, defaults: defaults, seedSimulator: false)
        store.adoptWork(
            Work(
                id: UUID(),
                objectId: "KMS1",
                artist: "Christen Kobke",
                title: "View from Dosseringen near the lake",
                thumbnail: nil,
                fold: .idle,
                dayKey: 202_609_21,
                chosenField: nil
            )
        )
        store.echoQuire()
        store.flushForScenePhase(.inactive)
        try await Task.sleep(for: .milliseconds(80))

        let reopened = QuireStore(vault: vault, defaults: defaults, seedSimulator: false)
        await reopened.loadFromVault()
        XCTAssertEqual(reopened.works.map(\.objectId), store.works.map(\.objectId))
        XCTAssertEqual(reopened.fold, store.fold)
        XCTAssertEqual(reopened.dittograph?.field, store.dittograph?.field)
        XCTAssertEqual(reopened.dittograph?.surplusWordId, store.dittograph?.surplusWordId)
    }

    func test_corruptFile_fallsBackToBackup_thenEmpty() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let suite = folder.lastPathComponent
        let defaults = UserDefaults(suiteName: suite) ?? UserDefaults()
        defaults.removePersistentDomain(forName: suite)
        let vault = QuireVault(defaultsSuite: suite, directory: folder)
        var document = QuireDocument.empty
        document.works = [
            Work(
                id: UUID(),
                objectId: "good",
                artist: "Two Tokens",
                title: "Also two tokens",
                thumbnail: nil,
                fold: .idle,
                dayKey: 202_609_21,
                chosenField: nil
            )
        ]
        try await vault.persist(document)
        try await vault.replaceFileWithCorruptData(Data("not-json".utf8))
        let recovered = await vault.load()
        XCTAssertEqual(recovered.1, .recoveredFromBackup)
        XCTAssertEqual(recovered.0.works.first?.objectId, "good")

        try await vault.replaceFileWithCorruptData(Data("{".utf8))
        let backup = folder.appendingPathComponent("quire.json.backup")
        try Data("{".utf8).write(to: backup, options: .atomic)
        defaults.removeObject(forKey: QuireDocument.defaultsKey)
        let empty = await vault.load()
        XCTAssertEqual(empty.1, .startedEmpty)
        XCTAssertEqual(empty.0, .empty)
    }

    func test_resetAllData_clearsDocument() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let suite = folder.lastPathComponent
        let defaults = UserDefaults(suiteName: suite) ?? UserDefaults()
        defaults.removePersistentDomain(forName: suite)
        let vault = QuireVault(defaultsSuite: suite, directory: folder)
        let store = QuireStore(vault: vault, defaults: defaults, seedSimulator: false)
        store.adoptWork(
            Work(
                id: UUID(),
                objectId: "gone",
                artist: "Two Tokens",
                title: "Also two tokens",
                thumbnail: nil,
                fold: .idle,
                dayKey: 202_609_21,
                chosenField: nil
            )
        )
        store.resetAllData()
        XCTAssertEqual(store.document, .empty)
        try await Task.sleep(for: .milliseconds(80))
        let loaded = await vault.load()
        XCTAssertTrue(loaded.0.works.isEmpty)
    }

    func test_schemaSwitch_rejectsUnknownVersion() throws {
        let payload = Data(#"{"schemaVersion":99}"#.utf8)
        XCTAssertThrowsError(try QuireDocumentCodec.decode(payload))
    }

    func test_copenhagenShelf_hasFourEchoableWorks() {
        let works = CopenhagenShelf.echoableWorks(dayKey: 202_609_21)
        XCTAssertGreaterThanOrEqual(works.count, 4)
        XCTAssertTrue(works.prefix(4).allSatisfy(\.canEcho))
        XCTAssertTrue(works.prefix(4).allSatisfy { $0.fold == .idle })
    }
}
