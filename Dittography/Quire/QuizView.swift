import SwiftUI

/// Locked quire. Echo and Expunge fuse here. Home is the doubled line,
/// not a list of records.
struct QuizView: View {
    @ObservedObject var store: QuireStore
    var openSheet: (QuireSheet) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var cancelPulse = 0

    var body: some View {
        VStack(spacing: QuireSpace.x2) {
            chrome
            if store.fold == .fair || (store.echoPool.isEmpty && store.dittograph == nil) {
                QuireVacantPage(
                    art: "dtg_EmptyHome",
                    headline: "Quire is fair.",
                    line: "Save a work, then sit the quiz.",
                    actionTitle: "Explore"
                ) {
                    openSheet(.explore)
                }
            } else {
                quizBody
            }
        }
        .padding(.horizontal, QuireSpace.x2)
        .padding(.bottom, QuireSpace.x2)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(QuireColor.background.ignoresSafeArea())
        .sensoryFeedback(.success, trigger: cancelPulse)
        .onChange(of: store.document.cancelMarks.count) { old, new in
            if new > old {
                cancelPulse += 1
            }
        }
    }

    private var chrome: some View {
        HStack(spacing: QuireSpace.x1) {
            Image("dtg_HeaderDecor")
                .resizable()
                .scaledToFit()
                .frame(width: QuireSpace.x1 * 7, height: QuireSpace.x1 * 3 + QuireSpace.tight)
                .accessibilityHidden(true)
            Text(foldTitle)
                .font(QuireType.display(for: typeSize))
                .foregroundStyle(QuireColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: QuireSpace.x1)
            iconButton("square.and.pencil", label: "Explore") { openSheet(.explore) }
            iconButton("tray", label: "Saved") { openSheet(.saved) }
            iconButton("slider.horizontal.3", label: "Settings") { openSheet(.settings) }
        }
        .frame(minHeight: QuireSpace.hit)
    }

    private var quizBody: some View {
        VStack(alignment: .leading, spacing: QuireSpace.x2) {
            hero
            caption
            wordLine
            echoCard
            railAndStat
            undoRow
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private var hero: some View {
        let work = currentWork
        ZStack {
            QuireHeroPlate()
                .fill(QuireColor.surface)
            if let url = work.flatMap({ $0.thumbnail }).flatMap(URL.init(string:)) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Image("dtg_CardBackdrop")
                            .resizable()
                            .scaledToFill()
                    }
                }
            } else {
                Image("dtg_CardBackdrop")
                    .resizable()
                    .scaledToFill()
            }
            QuireHeroPlate()
                .fill(.ultraThinMaterial)
                .opacity(0.18)
            if store.fold == .expunged {
                Image("dtg_SuccessMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(QuireHeroPlate())
        .shadow(color: QuireLift.hero, radius: QuireLift.radius, x: 0, y: QuireLift.y)
        .accessibilityHidden(true)
    }

    private var caption: some View {
        VStack(alignment: .leading, spacing: QuireSpace.tight) {
            Text(currentWork?.title ?? "Echo a saved painting")
                .font(QuireType.headline)
                .foregroundStyle(QuireColor.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Text(fieldLine)
                .font(QuireType.caption)
                .foregroundStyle(QuireColor.muted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var wordLine: some View {
        if let card = store.dittograph {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: QuireSpace.x1) {
                    ForEach(card.words) { word in
                        WordChip(word: word, reduceMotion: reduceMotion) {
                            store.hitWord(word.id)
                        }
                        .disabled(store.fold != .echoed)
                    }
                }
                .padding(.vertical, QuireSpace.tight)
            }
            .frame(minHeight: QuireSpace.hit)
            Text("Tap the copied word.")
                .font(QuireType.caption)
                .foregroundStyle(QuireColor.muted)
        } else {
            Text("Echo prints the doubled line here.")
                .font(QuireType.body)
                .foregroundStyle(QuireColor.muted)
                .frame(minHeight: QuireSpace.hit, alignment: .leading)
        }
    }

    private var echoCard: some View {
        VStack(spacing: QuireSpace.x1) {
            if store.fold != .echoed {
                Button("Echo") {
                    store.echoQuire()
                }
                .buttonStyle(
                    EchoPillStyle(
                        isEnabled: store.canEcho && !store.isWriting,
                        isLoading: store.isWriting,
                        reduceMotion: reduceMotion
                    )
                )
                .disabled(!store.canEcho || store.isWriting)
            }
            Button {
                openSheet(.folio)
            } label: {
                HStack {
                    Image("dtg_ControlFace")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .accessibilityHidden(true)
                    Text("The extra copy")
                        .font(QuireType.body)
                    Spacer()
                }
                .foregroundStyle(QuireColor.ink)
                .padding(.horizontal, QuireSpace.x2)
                .frame(maxWidth: .infinity, minHeight: QuireSpace.hit)
                .background(
                    RoundedRectangle(cornerRadius: QuireRadius.card, style: .continuous)
                        .fill(QuireColor.surface)
                )
                .contentShape(RoundedRectangle(cornerRadius: QuireRadius.card, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("The extra copy")
        }
        .padding(QuireSpace.x2)
        .background(
            RoundedRectangle(cornerRadius: QuireRadius.card, style: .continuous)
                .fill(QuireColor.surface)
        )
    }

    private var railAndStat: some View {
        HStack(alignment: .center, spacing: QuireSpace.x2) {
            ForEach(store.works.prefix(2)) { work in
                ZStack {
                    RoundedRectangle(cornerRadius: QuireRadius.chip, style: .continuous)
                        .fill(QuireColor.surface)
                    if let url = work.thumbnail.flatMap(URL.init(string:)) {
                        AsyncImage(url: url) { phase in
                            if case .success(let image) = phase {
                                image.resizable().scaledToFill()
                            }
                        }
                    }
                }
                .frame(width: QuireSpace.x1 * 9, height: QuireSpace.x1 * 7)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: QuireRadius.chip, style: .continuous))
                .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(QuireFigures.count(store.document.cancelMarks.count))
                    .font(QuireType.title)
                    .foregroundStyle(QuireColor.ink)
                    .monospacedDigit()
                Text("Filed paintings")
                    .font(QuireType.micro)
                    .foregroundStyle(QuireColor.muted)
            }
            Spacer(minLength: 0)
        }
        .frame(minHeight: QuireSpace.hit)
    }

    private var undoRow: some View {
        Button("Undo") {
            store.peelNewestMark()
        }
        .buttonStyle(
            PeelMarkStyle(
                isEnabled: store.document.newestMark != nil,
                reduceMotion: reduceMotion
            )
        )
        .disabled(store.document.newestMark == nil)
    }

    private var currentWork: Work? {
        if let id = store.dittograph?.workId {
            return store.works.first { $0.id == id }
        }
        if let focused = store.document.focusedObjectId {
            return store.works.first { $0.objectId == focused }
        }
        return store.works.first
    }

    private var foldTitle: String {
        switch store.fold {
        case .idle: "Echo a work"
        case .echoed: "Tap the copy"
        case .expunged: "Painting filed"
        case .fair: "Quire is fair"
        }
    }

    private var fieldLine: String {
        guard let work = currentWork else { return "Save a work, then sit the quiz." }
        switch store.dittograph?.field {
        case .artist:
            return work.artist
        case .title:
            return work.artist
        case nil:
            return work.artist
        }
    }

    private func iconButton(_ system: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(QuireType.headline)
                .foregroundStyle(QuireColor.ink)
                .frame(width: QuireSpace.hit, height: QuireSpace.hit)
                .contentShape(Rectangle())
        }
        .buttonStyle(QuireChromePressStyle(reduceMotion: reduceMotion))
        .accessibilityLabel(label)
    }
}
