import Foundation

/// Launch and URL routes into Quiz, Explore, Saved, Settings, or an in-place Echo.
/// `-ReviewScreen today|log|goals|explore` are keys, not tabs.
enum QuireRoute: String, Sendable, Equatable {
    case quiz
    case explore
    case saved
    case settings
    case echo
}

enum QuireLinks {
    static func route(fromArguments arguments: [String]) -> QuireRoute? {
        guard let flag = arguments.firstIndex(of: "-ReviewScreen"),
              arguments.indices.contains(flag + 1)
        else { return nil }
        return route(fromKey: arguments[flag + 1])
    }

    static func route(fromKey key: String) -> QuireRoute? {
        switch key {
        case "today": .quiz
        case "log": .saved
        case "goals": .settings
        case "explore": .explore
        default: nil
        }
    }

    static func route(from url: URL) -> QuireRoute? {
        let host = url.host?.lowercased() ?? ""
        let path = url.path.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let token = path.isEmpty ? host : path
        switch token {
        case "quiz": return .quiz
        case "explore": return .explore
        case "saved": return .saved
        case "settings": return .settings
        case "echo": return .echo
        default: return nil
        }
    }
}
