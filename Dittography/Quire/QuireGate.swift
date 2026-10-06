import Foundation

/// Shared seam for App Intents and custom URLs. Views still call QuireStore.
@MainActor
enum QuireGate {
    static weak var store: QuireStore?
    static var present: ((QuireRoute) -> Void)?

    static func handle(_ route: QuireRoute) {
        switch route {
        case .echo:
            store?.echoQuire()
        case .quiz:
            present?(.quiz)
        case .explore, .saved, .settings:
            present?(route)
        }
    }
}
