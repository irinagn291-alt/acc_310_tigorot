import XCTest
@testable import Dittography

@MainActor
final class CatalogClientTests: XCTestCase {
    func test_userAgent_andQueryMapping() throws {
        let request = try CatalogSession.makeRequest(query: "kobke", page: 2, pageSize: 10)
        XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), CatalogClient.userAgent)
        XCTAssertEqual(request.timeoutInterval, 15)
        guard let url = request.url else {
            return XCTFail("missing search url")
        }
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        XCTAssertEqual(items.first(where: { $0.name == "keys" })?.value, "kobke")
        XCTAssertEqual(items.first(where: { $0.name == "offset" })?.value, "10")
        XCTAssertEqual(items.first(where: { $0.name == "rows" })?.value, "10")
        XCTAssertEqual(items.first(where: { $0.name == "filters" })?.value, "[has_image:true],[public_domain:true]")
    }

    func test_mapsDtoToWork_withoutSnakeCaseStrategy() async throws {
        let json = Data("""
        {"items":[{"id":"obj-1","object_number":"KMS1","titles":[{"title":"Lake Light View"}],"production":[{"creator":"Christen Kobke"}],"image_thumbnail":"https://example.test/t.jpg","public_domain":true}],"found":"1"}
        """.utf8)
        let wire = ScriptedWire(results: [.success((json, 200))])
        let client = CatalogClient(
            session: CatalogSession(transport: CatalogTransport { _ in try await wire.next() }),
            debounce: .zero
        )
        let works = try await client.huntWorks(query: "lake")
        XCTAssertEqual(works.count, 1)
        XCTAssertEqual(works.first?.objectId, "obj-1")
        XCTAssertEqual(works.first?.artist, "Christen Kobke")
        XCTAssertEqual(works.first?.title, "Lake Light View")
        let calls = await wire.callCount()
        XCTAssertEqual(calls, 1)
    }

    func test_emptyQuery_doesNotHitNetwork() async throws {
        let wire = ScriptedWire(results: [])
        let client = CatalogClient(
            session: CatalogSession(transport: CatalogTransport { _ in try await wire.next() }),
            debounce: .zero
        )
        let works = try await client.huntWorks(query: "   ")
        XCTAssertTrue(works.isEmpty)
        let calls = await wire.callCount()
        XCTAssertEqual(calls, 0)
    }

    func test_malformedJson_isTypedError() async throws {
        let wire = ScriptedWire(results: [.success((Data("nope".utf8), 200))])
        let client = CatalogClient(
            session: CatalogSession(transport: CatalogTransport { _ in try await wire.next() }),
            debounce: .zero
        )
        do {
            _ = try await client.huntWorks(query: "lake")
            XCTFail("expected decoding error")
        } catch {
            XCTAssertEqual(error as? CatalogError, .decoding)
        }
    }

    func test_404_isNotRetried() async throws {
        let wire = ScriptedWire(results: [.failure(CatalogError.notFound), .success((Data("{}".utf8), 200))])
        let client = CatalogClient(
            session: CatalogSession(transport: CatalogTransport { _ in try await wire.next() }),
            debounce: .zero
        )
        do {
            _ = try await client.huntWorks(query: "missing")
            XCTFail("expected notFound")
        } catch {
            XCTAssertEqual(error as? CatalogError, .notFound)
        }
        let calls = await wire.callCount()
        XCTAssertEqual(calls, 1)
    }

    func test_transientTransport_retriesOnce() async throws {
        let json = Data(#"{"items":[{"object_number":"KMS2","titles":[{"title":"Two Words"}],"production":[{"creator":"Two Names"}]}]}"#.utf8)
        let wire = ScriptedWire(results: [.failure(CatalogError.transport), .success((json, 200))])
        let client = CatalogClient(
            session: CatalogSession(transport: CatalogTransport { _ in try await wire.next() }),
            debounce: .zero
        )
        let works = try await client.huntWorks(query: "two")
        XCTAssertEqual(works.first?.objectId, "KMS2")
        let calls = await wire.callCount()
        XCTAssertEqual(calls, 2)
    }

    func test_changingQuery_cancelsInFlight() async throws {
        let json = Data(#"{"items":[{"object_number":"later","titles":[{"title":"Later Work Title"}],"production":[{"creator":"Later Maker Name"}]}]}"#.utf8)
        let gate = HuntGate()
        let wire = CatalogTransport { _ in
            await gate.wait()
            return (json, 200)
        }
        let client = CatalogClient(
            session: CatalogSession(transport: wire),
            debounce: .milliseconds(20)
        )
        async let first = client.huntWorks(query: "first")
        try await Task.sleep(for: .milliseconds(5))
        async let second = client.huntWorks(query: "second")
        await gate.open()
        do {
            _ = try await first
            XCTFail("stale hunt should cancel")
        } catch {
            XCTAssertEqual(error as? CatalogError, .cancelled)
        }
        let later = try await second
        XCTAssertEqual(later.first?.objectId, "later")
    }
}

actor ScriptedWire {
    private var results: [Result<(Data, Int), CatalogError>]
    private var calls = 0

    init(results: [Result<(Data, Int), CatalogError>]) {
        self.results = results
    }

    func callCount() -> Int { calls }

    func next() throws -> (Data, Int) {
        calls += 1
        guard !results.isEmpty else { throw CatalogError.transport }
        let next = results.removeFirst()
        switch next {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }
}

actor HuntGate {
    private var opened = false

    func wait() async {
        while !opened {
            await Task.yield()
        }
    }

    func open() {
        opened = true
    }
}
