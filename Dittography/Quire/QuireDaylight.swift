import SwiftUI

/// Soft card daylight tokens. Views reach colour, type, space, and radius
/// only through these accessors. The fold itself stays on QuireStore.
enum QuireColor {
    static let background = Color("background") // #FAF7F5
    static let surface = Color("surface") // #FEFEFD
    static let ink = Color("ink") // #392818
    static let accent = Color("accent") // #CC6D19
    static let muted = Color("muted") // #816C5A
}

enum QuireType {
    static let display = Font.system(.title, design: .default).weight(.bold)
    static let title = Font.system(.title2, design: .default).weight(.semibold)
    static let headline = Font.system(.headline, design: .default).weight(.semibold)
    static let body = Font.system(.body, design: .default).weight(.regular)
    static let caption = Font.system(.caption, design: .default).weight(.medium)
    static let micro = Font.system(.caption2, design: .default).weight(.medium)

    static func display(for size: DynamicTypeSize) -> Font {
        if size >= .accessibility3 {
            return title
        }
        return display
    }
}

enum QuireSpace {
    static let unit: CGFloat = 4
    static let tight: CGFloat = 4
    static let x1: CGFloat = 8
    static let x2: CGFloat = 16
    static let x3: CGFloat = 24
    static let x4: CGFloat = 32
    static let x5: CGFloat = 40
    static let hit: CGFloat = 44
}

enum QuireRadius {
    static let card: CGFloat = 20
    static let chip: CGFloat = 12
}

enum QuireLift {
    static let hero = Color.black.opacity(0.12)
    static let radius: CGFloat = 18
    static let y: CGFloat = 10
}

enum QuireFigures {
    static let whole: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    static func count(_ value: Int) -> String {
        whole.string(from: NSNumber(value: value)) ?? String(value)
    }

    static func dayLabel(_ key: Int) -> String {
        let year = key / 10_000
        let month = (key / 100) % 100
        let day = key % 100
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = day
        guard let date = Calendar.current.date(from: parts) else {
            return count(key)
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct EchoPillStyle: ButtonStyle {
    var isEnabled: Bool
    var isLoading: Bool
    var reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed && isEnabled && !isLoading
        return configuration.label
            .font(QuireType.headline)
            .foregroundStyle(isEnabled ? QuireColor.surface : QuireColor.muted)
            .frame(maxWidth: .infinity, minHeight: QuireSpace.hit)
            .background(
                Capsule(style: .continuous)
                    .fill(isEnabled ? QuireColor.accent : QuireColor.surface)
            )
            .overlay {
                if isLoading {
                    ProgressView()
                        .tint(QuireColor.surface)
                }
            }
            .opacity(isLoading ? 0.72 : (pressed ? 0.92 : 1))
            .scaleEffect(reduceMotion ? 1 : (pressed ? 0.97 : 1))
            .animation(.easeOut(duration: 0.16), value: pressed)
            .contentShape(Capsule())
    }
}

struct PeelMarkStyle: ButtonStyle {
    var isEnabled: Bool
    var reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed && isEnabled
        return configuration.label
            .font(QuireType.headline)
            .foregroundStyle(isEnabled ? QuireColor.ink : QuireColor.muted)
            .frame(maxWidth: .infinity, minHeight: QuireSpace.hit)
            .background(
                RoundedRectangle(cornerRadius: QuireRadius.card, style: .continuous)
                    .fill(QuireColor.surface)
            )
            .opacity(pressed ? 0.88 : 1)
            .scaleEffect(reduceMotion ? 1 : (pressed ? 0.97 : 1))
            .animation(.easeOut(duration: 0.16), value: pressed)
            .contentShape(RoundedRectangle(cornerRadius: QuireRadius.card, style: .continuous))
    }
}

struct QuireChromePressStyle: ButtonStyle {
    var reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.88 : 1)
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.97 : 1))
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct ResetQuireStyle: ButtonStyle {
    var reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(QuireType.headline)
            .foregroundStyle(QuireColor.surface)
            .frame(maxWidth: .infinity, minHeight: QuireSpace.hit)
            .background(
                RoundedRectangle(cornerRadius: QuireRadius.card, style: .continuous)
                    .fill(QuireColor.ink)
            )
            .opacity(configuration.isPressed ? 0.88 : 1)
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.97 : 1))
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
            .contentShape(RoundedRectangle(cornerRadius: QuireRadius.card, style: .continuous))
    }
}

/// Rounded plate used only on the Quiz painting tile.
struct QuireHeroPlate: Shape {
    func path(in rect: CGRect) -> Path {
        RoundedRectangle(cornerRadius: QuireRadius.card, style: .continuous).path(in: rect)
    }
}

enum QuireSheet: String, Identifiable {
    case explore
    case saved
    case settings
    case folio

    var id: String { rawValue }
}
