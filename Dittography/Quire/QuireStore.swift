import Foundation
import SwiftUI

/// Observable fold over Works. Views call echoQuire, expungeWord, dwellWord,
/// and peelNewestMark. They never keep a second status enum or touch storage.
@MainActor
final class QuireStore: ObservableObject {
    @Published private(set) var document: QuireDocument
    @Published private(set) var decodeIssue: QuireDocument.DecodeIssue
    @Published private(set) var isWriting: Bool
    @Published private(set) var persistFailed: Bool

    private let vault: QuireVault
    private let defaults: UserDefaults
    private let now: () -> Date
    private let calendar: Calendar
    private var persistTask: Task<Void, Never>?
    private var wipeTask: Task<Void, Never>?
    private var persistGeneration = 0

    init(
        vault: QuireVault,
        defaults: UserDefaults = .standard,
        now: @escaping () -> Date = Date.init,
        calendar: Calendar = .current,
        seedSimulator: Bool = true
    ) {
        self.vault = vault
        self.defaults = defaults
        self.now = now
        self.calendar = calendar
        self.document = .empty
        self.decodeIssue = .none
        self.isWriting = false
        self.persistFailed = false
        if seedSimulator {
            applySimulatorSeedIfNeeded()
        }
    }

    var fold: QuireFold { document.fold }
    var works: [Work] { document.works }
    var dittograph: Dittograph? { document.dittograph }
    var echoPool: [Work] { document.works.filter(\.canEcho) }
    var expungedWorks: [Work] { document.works.filter { $0.fold == .expunged } }
    var canEcho: Bool { document.fold != .echoed && !echoPool.isEmpty }

    func loadFromVault() async {
        let loaded = await vault.load()
        if document == .empty || document.works.isEmpty {
            document = loaded.0
            decodeIssue = loaded.1
        }
    }

    func echoQuire() {
        guard document.fold != .echoed else { return }
        guard let work = echoPool.sorted(by: { $0.objectId < $1.objectId }).first,
              let field = work.usableFields.first,
              let card = Dittograph.printed(from: work, field: field)
        else {
            document.fold = .fair
            document.dittograph = nil
            schedulePersist()
            return
        }
        guard let index = document.works.firstIndex(where: { $0.id == work.id }) else { return }
        document.works[index].fold = .echoed
        document.works[index].chosenField = field
        document.dittograph = card
        document.fold = .echoed
        schedulePersist()
    }

    func expungeWord(_ wordId: UUID) {
        guard document.fold == .echoed, let card = document.dittograph else { return }
        guard card.surplusWordId == wordId else { return }
        let stamp = now()
        let mark = CancelMark(
            id: UUID(),
            workId: card.workId,
            wordId: wordId,
            dayKey: DayKey.from(stamp, calendar: calendar),
            stampedAt: stamp
        )
        document.cancelMarks.append(mark)
        if let index = document.works.firstIndex(where: { $0.id == card.workId }) {
            document.works[index].fold = .expunged
        }
        document.fold = .expunged
        schedulePersist(immediate: true)
    }

    func dwellWord(_ wordId: UUID) {
        guard document.fold == .echoed, var card = document.dittograph else { return }
        guard card.surplusWordId != wordId, card.word(id: wordId) != nil else { return }
        if let index = card.words.firstIndex(where: { $0.id == wordId }) {
            card.words[index].isDimmed = true
        }
        document.dittograph = card
        let stamp = now()
        document.dwellMarks.append(
            DwellMark(
                id: UUID(),
                workId: card.workId,
                wordId: wordId,
                dayKey: DayKey.from(stamp, calendar: calendar),
                stampedAt: stamp
            )
        )
        schedulePersist()
    }

    func hitWord(_ wordId: UUID) {
        guard let card = document.dittograph else { return }
        if card.surplusWordId == wordId {
            expungeWord(wordId)
        } else {
            dwellWord(wordId)
        }
    }

    func peelNewestMark() {
        guard let mark = document.newestMark else { return }
        switch mark {
        case .cancel(let cancel):
            document.cancelMarks.removeAll { $0.id == cancel.id }
            if let index = document.works.firstIndex(where: { $0.id == cancel.workId }) {
                document.works[index].fold = .echoed
            }
            document.fold = .echoed
        case .dwell(let dwell):
            document.dwellMarks.removeAll { $0.id == dwell.id }
            if var card = document.dittograph, card.workId == dwell.workId,
               let index = card.words.firstIndex(where: { $0.id == dwell.wordId }) {
                card.words[index].isDimmed = false
                document.dittograph = card
            }
        }
        schedulePersist(immediate: true)
    }

    func adoptWork(_ incoming: Work) {
        if let existing = document.works.first(where: { $0.objectId == incoming.objectId }) {
            document.focusedObjectId = existing.objectId
            schedulePersist()
            return
        }
        var work = incoming
        work.fold = .idle
        work.dayKey = DayKey.from(now(), calendar: calendar)
        document.works.append(work)
        document.focusedObjectId = work.objectId
        if document.fold == .fair {
            document.fold = .idle
        }
        schedulePersist()
    }

    func resetAllData() {
        persistGeneration += 1
        persistTask?.cancel()
        persistTask = nil
        wipeTask?.cancel()
        document = .empty
        decodeIssue = .none
        persistFailed = false
        let generation = persistGeneration
        wipeTask = Task { [vault] in
            do {
                try await vault.wipe()
            } catch {
                if generation == persistGeneration {
                    decodeIssue = .startedEmpty
                }
            }
        }
    }

    func flushForScenePhase(_ phase: ScenePhase) {
        if phase == .inactive || phase == .background {
            schedulePersist(immediate: true)
        }
    }

    func replaceDocument(_ next: QuireDocument) {
        document = next
    }

    func markOnboardingComplete() {
        document.onboardingComplete = true
        schedulePersist()
    }

    func reopenOnboarding() {
        document.onboardingComplete = false
        schedulePersist()
    }

    private func schedulePersist(immediate: Bool = false) {
        persistTask?.cancel()
        persistGeneration += 1
        let generation = persistGeneration
        let snapshot = document
        persistTask = Task { [vault] in
            if !immediate {
                do {
                    try await Task.sleep(for: .milliseconds(350))
                } catch {
                    return
                }
            }
            if Task.isCancelled || generation != persistGeneration { return }
            isWriting = true
            defer { isWriting = false }
            do {
                try await vault.persist(snapshot)
                if generation == persistGeneration {
                    persistFailed = false
                }
            } catch is CancellationError {
                return
            } catch {
                if generation == persistGeneration {
                    persistFailed = true
                }
            }
        }
    }

    private func applySimulatorSeedIfNeeded() {
        #if targetEnvironment(simulator)
        guard !defaults.bool(forKey: QuireDocument.demoKey) else { return }
        let shelf = CopenhagenShelf.echoableWorks(dayKey: DayKey.from(now(), calendar: calendar))
        document.works = Array(shelf.prefix(4))
        document.onboardingComplete = true
        defaults.set(true, forKey: QuireDocument.demoKey)
        echoQuire()
        #endif
    }
}
