import SwiftUI

/// Sheet of Expunged works plus CancelMarks and DwellMarks.
struct SavedView: View {
    @ObservedObject var store: QuireStore
    var onClose: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        NavigationStack {
            Group {
                if store.decodeIssue == .startedEmpty && store.works.isEmpty {
                    errorPage
                } else if store.expungedWorks.isEmpty
                    && store.document.cancelMarks.isEmpty
                    && store.document.dwellMarks.isEmpty {
                    QuireVacantPage(
                        art: "dtg_EmptyList",
                        headline: "No marks yet.",
                        line: "File a surplus copy, then review cancels and dwells here.",
                        actionTitle: "Back to quire"
                    ) {
                        onClose()
                    }
                } else {
                    list
                }
            }
            .background(QuireColor.background.ignoresSafeArea())
            .navigationTitle("Saved")
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
                    .accessibilityLabel("Close saved")
                }
            }
        }
        .presentationBackground(QuireColor.background)
        .modifier(QuireSheetMotion())
    }

    private var list: some View {
        List {
            if !store.expungedWorks.isEmpty {
                Section("Expunged") {
                    ForEach(store.expungedWorks) { work in
                        VStack(alignment: .leading, spacing: QuireSpace.tight) {
                            Text(work.title)
                                .font(QuireType.body)
                                .foregroundStyle(QuireColor.ink)
                                .lineLimit(2)
                            Text(work.artist)
                                .font(QuireType.caption)
                                .foregroundStyle(QuireColor.muted)
                                .lineLimit(1)
                            Text(QuireFigures.dayLabel(work.dayKey))
                                .font(QuireType.micro)
                                .foregroundStyle(QuireColor.muted)
                                .monospacedDigit()
                        }
                        .padding(.vertical, QuireSpace.x1)
                        .listRowBackground(QuireColor.surface)
                    }
                }
            }
            if !store.document.cancelMarks.isEmpty {
                Section("CancelMarks") {
                    ForEach(store.document.cancelMarks) { mark in
                        markRow(
                            title: workTitle(mark.workId),
                            kind: "Cancel",
                            dayKey: mark.dayKey
                        )
                    }
                }
            }
            if !store.document.dwellMarks.isEmpty {
                Section("DwellMarks") {
                    ForEach(store.document.dwellMarks) { mark in
                        markRow(
                            title: workTitle(mark.workId),
                            kind: "Dwell",
                            dayKey: mark.dayKey
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private var errorPage: some View {
        VStack(alignment: .leading, spacing: QuireSpace.x3) {
            Spacer()
            Text("Ledger slipped.")
                .font(QuireType.display(for: typeSize))
                .foregroundStyle(QuireColor.ink)
            Text("The saved quire could not be read. Echo again after a reset, or peel a mark.")
                .font(QuireType.body)
                .foregroundStyle(QuireColor.muted)
            Spacer()
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
        .padding(QuireSpace.x3)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func markRow(title: String, kind: String, dayKey: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: QuireSpace.tight) {
                Text(title)
                    .font(QuireType.body)
                    .foregroundStyle(QuireColor.ink)
                    .lineLimit(1)
                Text(kind)
                    .font(QuireType.caption)
                    .foregroundStyle(QuireColor.muted)
            }
            Spacer()
            Text(QuireFigures.dayLabel(dayKey))
                .font(QuireType.caption)
                .foregroundStyle(QuireColor.muted)
                .monospacedDigit()
                .lineLimit(1)
        }
        .frame(minHeight: QuireSpace.hit)
        .listRowBackground(QuireColor.surface)
    }

    private func workTitle(_ id: UUID) -> String {
        store.works.first { $0.id == id }?.title ?? "Work"
    }
}
