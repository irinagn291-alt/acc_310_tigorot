import Foundation

/// Storage seam. Views never touch UserDefaults or files. IO stays off the
/// main thread. The in-memory document in QuireStore is the source of truth;
/// this actor writes a projection.
actor QuireVault {
    private let defaultsSuite: String?
    private let fileURL: URL
    private let backupURL: URL

    init(
        defaultsSuite: String? = nil,
        directory: URL? = nil
    ) {
        self.defaultsSuite = defaultsSuite
        let root = directory ?? Self.applicationSupportDirectory()
        fileURL = root.appendingPathComponent("quire.json", isDirectory: false)
        backupURL = root.appendingPathComponent("quire.json.backup", isDirectory: false)
    }

    func load() async -> (QuireDocument, QuireDocument.DecodeIssue) {
        let fileManager = FileManager.default
        let primaryExists = fileManager.fileExists(atPath: fileURL.path)
        let backupExists = fileManager.fileExists(atPath: backupURL.path)
        let defaultsData = defaults().data(forKey: QuireDocument.defaultsKey)
        if let data = Self.readFile(fileURL),
           let document = try? QuireDocumentCodec.decode(data) {
            return (document, .none)
        }
        if let data = Self.readFile(backupURL),
           let document = try? QuireDocumentCodec.decode(data) {
            return (document, .recoveredFromBackup)
        }
        if let data = defaultsData,
           let document = try? QuireDocumentCodec.decode(data) {
            return (document, primaryExists || backupExists ? .recoveredFromBackup : .none)
        }
        if primaryExists || backupExists || defaultsData != nil {
            return (.empty, .startedEmpty)
        }
        return (.empty, .none)
    }

    func persist(_ document: QuireDocument) async throws {
        try Task.checkCancellation()
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try QuireDocumentCodec.encode(document)
        if fileManager.fileExists(atPath: fileURL.path) {
            if fileManager.fileExists(atPath: backupURL.path) {
                try fileManager.removeItem(at: backupURL)
            }
            try fileManager.copyItem(at: fileURL, to: backupURL)
        }
        try data.write(to: fileURL, options: .atomic)
        defaults().set(data, forKey: QuireDocument.defaultsKey)
    }

    func wipe() async throws {
        let fileManager = FileManager.default
        defaults().removeObject(forKey: QuireDocument.defaultsKey)
        defaults().removeObject(forKey: QuireDocument.demoKey)
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
        if fileManager.fileExists(atPath: backupURL.path) {
            try fileManager.removeItem(at: backupURL)
        }
    }

    func replaceFileWithCorruptData(_ data: Data) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
    }

    private static func readFile(_ url: URL) -> Data? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try? Data(contentsOf: url)
    }

    private func defaults() -> UserDefaults {
        if let defaultsSuite {
            return UserDefaults(suiteName: defaultsSuite) ?? .standard
        }
        return .standard
    }

    private static func applicationSupportDirectory() -> URL {
        let fileManager = FileManager.default
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return base.appendingPathComponent("Tigorot", isDirectory: true)
    }
}
