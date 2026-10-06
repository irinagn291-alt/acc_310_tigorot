import SwiftUI

/// Live verb on the Dittograph. A Dwell greys the Word and names the dwell.
struct WordChip: View {
    let word: Word
    let reduceMotion: Bool
    let onHit: () -> Void

    var body: some View {
        Button(action: onHit) {
            VStack(spacing: 0) {
                Text(word.text)
                    .font(QuireType.body)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if word.isDimmed {
                    Text("Dwell")
                        .font(QuireType.micro)
                }
            }
            .foregroundStyle(word.isDimmed ? QuireColor.muted : QuireColor.surface)
            .padding(.horizontal, QuireSpace.x2)
            .frame(minWidth: QuireSpace.hit, minHeight: QuireSpace.hit)
            .background(
                RoundedRectangle(cornerRadius: QuireRadius.chip, style: .continuous)
                    .fill(word.isDimmed ? QuireColor.surface : QuireColor.accent)
            )
            .contentShape(RoundedRectangle(cornerRadius: QuireRadius.chip, style: .continuous))
        }
        .buttonStyle(WordChipPressStyle(reduceMotion: reduceMotion))
        .disabled(word.isDimmed)
        .accessibilityLabel(word.isDimmed ? "\(word.text), dwell" : word.text)
    }
}

private struct WordChipPressStyle: ButtonStyle {
    var reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.88 : 1)
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.97 : 1))
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}
