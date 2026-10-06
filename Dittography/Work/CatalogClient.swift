import Foundation

/// Typed failures from the SMK search wire. A decode miss is handled, never a crash.
enum CatalogError: Error, Sendable, Equatable {
    case notFound
    case transport
    case decoding
    case cancelled
    case emptyQuery
}

/// One client owns SMK search. cgi-search-pl fields (query, page, page_size)
/// map onto keys, offset, and rows. Never Open Food Facts. Never convertFromSnakeCase.
enum CatalogIdentity: Sendable {
    static let userAgent = "Dittography/1.0 (iOS; +https://dittography-quire.pro)"
    static let searchRoot = URL(string: "https://api.smk.dk/api/v1/art/search") ?? URL(fileURLWithPath: "/api/v1/art/search")
}

@MainActor
final class CatalogClient {
    static let userAgent = CatalogIdentity.userAgent
    static let searchRoot = CatalogIdentity.searchRoot

    private let session: CatalogSession
    private let debounce: Duration
    private var inFlight: Task<[Work], Error>?

    init(
        session: CatalogSession,
        debounce: Duration = .milliseconds(500)
    ) {
        self.session = session
        self.debounce = debounce
    }

    convenience init(urlSession: URLSession = CatalogSession.identifiedSession()) {
        self.init(
            session: CatalogSession(
                transport: .urlSession(urlSession),
                cacheURL: CatalogSession.defaultCacheURL()
            )
        )
    }

    func huntWorks(query: String) async throws -> [Work] {
        inFlight?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let session = self.session
        let delay = debounce
        let task = Task<[Work], Error> {
            if delay != .zero {
                try await Task.sleep(for: delay)
            }
            try Task.checkCancellation()
            return try await session.search(query: trimmed, page: 1, pageSize: 20)
        }
        inFlight = task
        do {
            return try await task.value
        } catch is CancellationError {
            throw CatalogError.cancelled
        }
    }

    func cancelHunt() {
        inFlight?.cancel()
        inFlight = nil
    }

    func lastResolvedWorks() async -> [Work] {
        await session.cachedWorks()
    }
}

/// Off-main SMK transport, one retry on transient failure, no retry on 404.
actor CatalogSession {
    private let transport: CatalogTransport
    private var memoryCache: [Work]
    private let cacheURL: URL?

    init(transport: CatalogTransport, cacheURL: URL? = nil) {
        self.transport = transport
        self.memoryCache = []
        self.cacheURL = cacheURL
    }

    func cachedWorks() -> [Work] {
        if !memoryCache.isEmpty { return memoryCache }
        guard let cacheURL,
              FileManager.default.fileExists(atPath: cacheURL.path),
              let data = try? Data(contentsOf: cacheURL),
              let envelope = try? CatalogDTOCodec.makeDecoder().decode(CachedWorksDTO.self, from: data)
        else { return [] }
        memoryCache = envelope.works.compactMap(\.asWork)
        return memoryCache
    }

    func search(query: String, page: Int, pageSize: Int) async throws -> [Work] {
        let request = try CatalogSession.makeRequest(query: query, page: page, pageSize: pageSize)
        let (data, status) = try await fetchWithRetry(request)
        if status == 404 {
            throw CatalogError.notFound
        }
        guard (200...299).contains(status) else {
            throw CatalogError.transport
        }
        let dto: SMKSearchDTO
        do {
            dto = try CatalogDTOCodec.makeDecoder().decode(SMKSearchDTO.self, from: data)
        } catch {
            throw CatalogError.decoding
        }
        let raw = dto.items ?? []
        let preferred = raw.filter { ($0.publicDomain ?? false) && !(($0.imageThumbnail ?? "").isEmpty) }
        let withThumb = raw.filter { !(($0.imageThumbnail ?? "").isEmpty) }
        let chosen = preferred.isEmpty ? (withThumb.isEmpty ? raw : withThumb) : preferred
        let works = chosen.compactMap { $0.asWork() }
        remember(works)
        return works
    }

    private func remember(_ works: [Work]) {
        memoryCache = works
        guard let cacheURL else { return }
        do {
            let folder = cacheURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            var excluded = URLResourceValues()
            excluded.isExcludedFromBackup = true
            var mutableFolder = folder
            try mutableFolder.setResourceValues(excluded)
            let envelope = CachedWorksDTO(works: works.map(CachedWorkDTO.init(work:)))
            let data = try CatalogDTOCodec.makeEncoder().encode(envelope)
            try data.write(to: cacheURL, options: .atomic)
        } catch {
            memoryCache = works
        }
    }

    private func fetchWithRetry(_ request: URLRequest) async throws -> (Data, Int) {
        do {
            return try await transport.send(request)
        } catch let error as CatalogError {
            if error == .notFound { throw error }
            return try await transport.send(request)
        } catch {
            do {
                return try await transport.send(request)
            } catch {
                throw CatalogError.transport
            }
        }
    }

    static func makeRequest(query: String, page: Int, pageSize: Int) throws -> URLRequest {
        var parts = URLComponents(url: CatalogIdentity.searchRoot, resolvingAgainstBaseURL: false)
        let offset = max(0, (page - 1) * pageSize)
        parts?.queryItems = [
            URLQueryItem(name: "keys", value: query),
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "rows", value: String(pageSize)),
            URLQueryItem(name: "filters", value: "[has_image:true],[public_domain:true]")
        ]
        guard let url = parts?.url else { throw CatalogError.transport }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.setValue(CatalogIdentity.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    static func identifiedSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 15
        configuration.httpAdditionalHeaders = [
            "User-Agent": CatalogIdentity.userAgent
        ]
        return URLSession(configuration: configuration)
    }

    static func defaultCacheURL() -> URL {
        let fileManager = FileManager.default
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return caches
            .appendingPathComponent("Tigorot", isDirectory: true)
            .appendingPathComponent("smk-works.json", isDirectory: false)
    }
}

struct CatalogTransport: Sendable {
    var send: @Sendable (URLRequest) async throws -> (Data, Int)

    static func urlSession(_ session: URLSession) -> CatalogTransport {
        CatalogTransport { request in
            do {
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    throw CatalogError.transport
                }
                if http.statusCode == 404 {
                    throw CatalogError.notFound
                }
                return (data, http.statusCode)
            } catch let error as CatalogError {
                throw error
            } catch {
                throw CatalogError.transport
            }
        }
    }
}

enum CatalogDTOCodec {
    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        return decoder
    }

    static func makeEncoder() -> JSONEncoder {
        JSONEncoder()
    }
}

struct SMKSearchDTO: Decodable, Sendable {
    let items: [SMKItemDTO]?
    let offset: Int?
    let rows: Int?
    let found: FlexibleInt?
}

struct SMKItemDTO: Decodable, Sendable {
    let id: String?
    let objectNumber: String?
    let titles: [SMKTitleDTO]?
    let production: [SMKProductionDTO]?
    let imageThumbnail: String?
    let publicDomain: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case objectNumber = "object_number"
        case titles
        case production
        case imageThumbnail = "image_thumbnail"
        case publicDomain = "public_domain"
    }

    func asWork() -> Work? {
        let objectId = (id?.isEmpty == false ? id : nil) ?? objectNumber
        guard let objectId, !objectId.isEmpty else { return nil }
        let title = titles?.compactMap(\.title).first { !$0.isEmpty } ?? ""
        let artist = production?.compactMap(\.creator).first { !$0.isEmpty } ?? ""
        return Work(
            id: UUID(),
            objectId: objectId,
            artist: artist,
            title: title,
            thumbnail: imageThumbnail,
            fold: .idle,
            dayKey: 0,
            chosenField: nil
        )
    }
}

/// Disk cache envelope. DTOs stay off the domain Work type.
struct CachedWorksDTO: Codable, Sendable {
    var works: [CachedWorkDTO]
}

struct CachedWorkDTO: Codable, Sendable {
    var objectId: String
    var artist: String
    var title: String
    var thumbnail: String?

    init(work: Work) {
        objectId = work.objectId
        artist = work.artist
        title = work.title
        thumbnail = work.thumbnail
    }

    var asWork: Work? {
        guard !objectId.isEmpty else { return nil }
        return Work(
            id: UUID(),
            objectId: objectId,
            artist: artist,
            title: title,
            thumbnail: thumbnail,
            fold: .idle,
            dayKey: 0,
            chosenField: nil
        )
    }
}

struct SMKTitleDTO: Decodable, Sendable {
    let title: String?
}

struct SMKProductionDTO: Decodable, Sendable {
    let creator: String?
}

/// SMK sometimes sends found as a number and sometimes as a numeric string.
struct FlexibleInt: Decodable, Sendable, Equatable {
    let value: Int?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = nil
            return
        }
        if let number = try? container.decode(Int.self) {
            value = number
            return
        }
        if let double = try? container.decode(Double.self) {
            value = Int(double)
            return
        }
        if let text = try? container.decode(String.self) {
            value = Int(text)
            return
        }
        value = nil
    }
}
