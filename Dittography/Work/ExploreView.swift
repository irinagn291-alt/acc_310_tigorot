import SwiftUI

/// Sheet that hunts Statens Museum for Kunst and writes Idle Works.
/// Empty or failed search hangs from the Copenhagen shelf.
struct ExploreView: View {
    @ObservedObject var store: QuireStore
    var onClose: () -> Void
    @State private var client = CatalogClient()
    @State private var query = ""
    @State private var rows: [Work] = []
    @State private var huntError: CatalogError?
    @State private var isHunting = false
    @State private var showSpinner = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        NavigationStack {
            Group {
                if rows.isEmpty && !isHunting {
                    if let huntError, huntError != .cancelled, huntError != .emptyQuery {
                        errorPage
                    } else {
                        QuireVacantPage(
                            art: "dtg_EmptyList",
                            headline: "Shelf is quiet.",
                            line: "Search Copenhagen, or keep a local painting.",
                            actionTitle: "Show shelf"
                        ) {
                            rows = CopenhagenShelf.echoableWorks(dayKey: DayKey.from(Date()))
                            huntError = nil
                        }
                    }
                } else {
                    list
                }
            }
            .background(QuireColor.background.ignoresSafeArea())
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onClose()
                    } label: {
                        Image(systemName: "xmark")
                            .frame(width: QuireSpace.hit, height: QuireSpace.hit)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Close explore")
                }
            }
            .searchable(text: $query, prompt: "Search the catalog")
            .onChange(of: query) { _, next in
                Task { await hunt(next) }
            }
            .task {
                let cached = await client.lastResolvedWorks()
                if rows.isEmpty {
                    rows = cached.isEmpty
                        ? CopenhagenShelf.echoableWorks(dayKey: DayKey.from(Date()))
                        : cached
                }
            }
            .overlay {
                if showSpinner {
                    ProgressView()
                        .tint(QuireColor.accent)
                }
            }
        }
        .presentationBackground(QuireColor.background)
        .modifier(QuireSheetMotion())
    }

    private var list: some View {
        List {
            ForEach(rows) { work in
                Button {
                    store.adoptWork(work)
                    onClose()
                } label: {
                    HStack(spacing: QuireSpace.x2) {
                        thumb(work)
                        VStack(alignment: .leading, spacing: QuireSpace.tight) {
                            Text(work.title)
                                .font(QuireType.body)
                                .foregroundStyle(QuireColor.ink)
                                .lineLimit(2)
                            Text(work.artist)
                                .font(QuireType.caption)
                                .foregroundStyle(QuireColor.muted)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(minHeight: QuireSpace.hit)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowBackground(QuireColor.surface)
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var errorPage: some View {
        VStack(alignment: .leading, spacing: QuireSpace.x3) {
            Spacer()
            Text("Hunt missed.")
                .font(QuireType.display(for: typeSize))
                .foregroundStyle(QuireColor.ink)
            Text("The catalog did not answer. Keep a local painting or try again.")
                .font(QuireType.body)
                .foregroundStyle(QuireColor.muted)
            Spacer()
            Button("Try again") {
                Task { await hunt(query) }
            }
            .buttonStyle(
                EchoPillStyle(isEnabled: true, isLoading: false, reduceMotion: reduceMotion)
            )
        }
        .padding(QuireSpace.x3)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func thumb(_ work: Work) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: QuireRadius.chip, style: .continuous)
                .fill(QuireColor.background)
            if let url = work.thumbnail.flatMap(URL.init(string:)) {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill()
                    }
                }
            }
        }
        .frame(width: 56, height: 56)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: QuireRadius.chip, style: .continuous))
        .accessibilityHidden(true)
    }

    private func hunt(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            client.cancelHunt()
            isHunting = false
            showSpinner = false
            huntError = nil
            let cached = await client.lastResolvedWorks()
            rows = cached.isEmpty
                ? CopenhagenShelf.echoableWorks(dayKey: DayKey.from(Date()))
                : cached
            return
        }
        isHunting = true
        huntError = nil
        let spinner = Task {
            try? await Task.sleep(for: .milliseconds(150))
            if !Task.isCancelled { showSpinner = true }
        }
        defer {
            spinner.cancel()
            showSpinner = false
            isHunting = false
        }
        do {
            let found = try await client.huntWorks(query: trimmed)
            rows = found.isEmpty
                ? (await fallbackRows())
                : found
        } catch let error as CatalogError where error == .cancelled {
            return
        } catch let error as CatalogError {
            huntError = error
            rows = await fallbackRows()
        } catch {
            huntError = .transport
            rows = await fallbackRows()
        }
    }

    private func fallbackRows() async -> [Work] {
        let cached = await client.lastResolvedWorks()
        if cached.isEmpty {
            return CopenhagenShelf.echoableWorks(dayKey: DayKey.from(Date()))
        }
        return cached
    }
}

struct QuireSheetMotion: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : (reduceMotion ? 0 : 1))
            .scaleEffect(reduceMotion ? 1 : (appeared ? 1 : 0.96))
            .onAppear {
                withAnimation(.easeOut(duration: 0.18)) {
                    appeared = true
                }
            }
    }
}
