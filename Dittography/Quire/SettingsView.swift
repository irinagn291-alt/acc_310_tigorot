import SwiftUI

/// Collection credit, Undo, contact, onboarding, and resetAllData.
struct SettingsView: View {
    @ObservedObject var store: QuireStore
    var onClose: () -> Void
    var onRerunOnboarding: () -> Void
    @State private var confirmReset = false

    private var cancelCount: String {
        QuireFigures.count(store.document.cancelMarks.count)
    }

    private var dwellCount: String {
        QuireFigures.count(store.document.dwellMarks.count)
    }

    var body: some View {
        NavigationStack {
            Form {
                if store.persistFailed {
                    Section {
                        Text("A write missed the vault. Peel a mark or reset if the quire stays stale.")
                            .font(QuireType.body)
                            .foregroundStyle(QuireColor.ink)
                    }
                } else if store.works.isEmpty && store.document.cancelMarks.isEmpty {
                    Section {
                        Text("No marks sit on this device yet. Echo a painting from home first.")
                            .font(QuireType.body)
                            .foregroundStyle(QuireColor.muted)
                    }
                }

                Section("Collection") {
                    if let smk = URL(string: "https://www.smk.dk") {
                        Link("Statens Museum for Kunst", destination: smk)
                    }
                    if let open = URL(string: "https://www.smk.dk/en/article/smk-open/") {
                        Link("SMK Open", destination: open)
                    }
                }

                Section("Marks") {
                    Button("Undo") {
                        store.peelNewestMark()
                    }
                    .disabled(store.document.newestMark == nil)
                    Text("Cancels \(cancelCount). Dwells \(dwellCount).")
                    .font(QuireType.caption)
                    .foregroundStyle(QuireColor.muted)
                    .monospacedDigit()
                }

                Section("Help") {
                    if let contact = URL(string: "https://dittography-quire.pro/contact-us") {
                        Link("Contact us", destination: contact)
                    }
                    Button("Re-run onboarding") {
                        store.reopenOnboarding()
                        onRerunOnboarding()
                    }
                }

                Section {
                    Button("Reset all data") {
                        confirmReset = true
                    }
                    .foregroundStyle(QuireColor.ink)
                }
            }
            .scrollContentBackground(.hidden)
            .background(QuireColor.background.ignoresSafeArea())
            .navigationTitle("Settings")
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
                    .accessibilityLabel("Close settings")
                }
            }
            .confirmationDialog(
                "Reset all saved paintings, marks, and the live line on this device?",
                isPresented: $confirmReset,
                titleVisibility: .visible
            ) {
                Button("Reset all data", role: .destructive) {
                    store.resetAllData()
                }
                Button("Keep quire", role: .cancel) {}
            }
        }
        .presentationBackground(QuireColor.background)
        .modifier(QuireSheetMotion())
    }
}
