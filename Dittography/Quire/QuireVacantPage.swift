import SwiftUI

/// Full-page empty or Fair frame. Generated cutout, one headline, one line,
/// full-width CTA at the bottom.
struct QuireVacantPage: View {
    let art: String
    let headline: String
    let line: String
    let actionTitle: String
    let action: () -> Void
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: QuireSpace.x3) {
            Spacer(minLength: QuireSpace.x2)
            Image(art)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: QuireSpace.x5 * 5 + QuireSpace.x2, maxHeight: QuireSpace.x5 * 5 + QuireSpace.x2)
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)
            Text(headline)
                .font(QuireType.display(for: typeSize))
                .foregroundStyle(QuireColor.ink)
                .lineLimit(4)
                .minimumScaleFactor(0.7)
            Text(line)
                .font(QuireType.body)
                .foregroundStyle(QuireColor.muted)
            Spacer(minLength: QuireSpace.x2)
            Button(actionTitle, action: action)
                .buttonStyle(
                    EchoPillStyle(isEnabled: true, isLoading: false, reduceMotion: reduceMotion)
                )
        }
        .padding(QuireSpace.x3)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(QuireColor.background.ignoresSafeArea())
    }
}
