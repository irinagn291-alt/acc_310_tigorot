import AppIntents

/// App Intents open Quiz, Explore, Saved, or Settings, or fire echoQuire.
struct OpenQuizIntent: AppIntent {
    static var title: LocalizedStringResource { "Open quiz" }

    @MainActor
    func perform() async throws -> some IntentResult {
        QuireGate.handle(.quiz)
        return .result()
    }
}

struct OpenExploreIntent: AppIntent {
    static var title: LocalizedStringResource { "Open explore" }

    @MainActor
    func perform() async throws -> some IntentResult {
        QuireGate.handle(.explore)
        return .result()
    }
}

struct OpenSavedIntent: AppIntent {
    static var title: LocalizedStringResource { "Open saved" }

    @MainActor
    func perform() async throws -> some IntentResult {
        QuireGate.handle(.saved)
        return .result()
    }
}

struct OpenSettingsIntent: AppIntent {
    static var title: LocalizedStringResource { "Open settings" }

    @MainActor
    func perform() async throws -> some IntentResult {
        QuireGate.handle(.settings)
        return .result()
    }
}

struct EchoQuireIntent: AppIntent {
    static var title: LocalizedStringResource { "Echo quire" }

    @MainActor
    func perform() async throws -> some IntentResult {
        QuireGate.handle(.echo)
        return .result()
    }
}
