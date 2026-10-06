import SwiftUI

/// Quire-locked chrome. Quiz never leaves. Explore, Saved, Settings, and
/// the twist folio arrive as sheets. ReviewScreen keys fire after onboarding.
struct ContentView: View {
    @ObservedObject var store: QuireStore
    @State private var sheet: QuireSheet?
    @State private var didReadReview = false

    var body: some View {
        QuizView(store: store, openSheet: present)
            .sheet(item: $sheet) { item in
                switch item {
                case .explore:
                    ExploreView(store: store, onClose: { sheet = nil })
                case .saved:
                    SavedView(store: store, onClose: { sheet = nil })
                case .settings:
                    SettingsView(
                        store: store,
                        onClose: { sheet = nil },
                        onRerunOnboarding: { sheet = nil }
                    )
                case .folio:
                    EchoFolioView(onClose: { sheet = nil })
                }
            }
            .fullScreenCover(isPresented: onboardingBinding) {
                QuireOnboarding {
                    store.markOnboardingComplete()
                }
            }
            .onAppear {
                QuireGate.store = store
                QuireGate.present = { route in
                    apply(route)
                }
                applyReviewHook()
            }
            .onChange(of: store.document.onboardingComplete) { _, done in
                if done {
                    applyReviewHook()
                }
            }
    }

    private var onboardingBinding: Binding<Bool> {
        Binding(
            get: { !store.document.onboardingComplete },
            set: { showing in
                if !showing {
                    store.markOnboardingComplete()
                }
            }
        )
    }

    private func present(_ item: QuireSheet) {
        sheet = item
    }

    private func applyReviewHook() {
        guard store.document.onboardingComplete, !didReadReview else { return }
        didReadReview = true
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-ReviewScreen"),
           let route = QuireLinks.route(fromArguments: arguments) {
            apply(route)
        }
    }

    private func apply(_ route: QuireRoute) {
        switch route {
        case .quiz:
            sheet = nil
        case .explore:
            sheet = .explore
        case .saved:
            sheet = .saved
        case .settings:
            sheet = .settings
        case .echo:
            store.echoQuire()
        }
    }
}
