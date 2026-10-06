import SwiftUI

/// One-shot cover. Three pages explain Echo then Expunge. Skip still completes.
struct QuireOnboarding: View {
    let onFinish: () -> Void
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch page {
                case 1:
                    pageView(
                        art: "dtg_Onboarding2",
                        title: "Echo the line",
                        line: "Echo prints maker or picture, one field, with one word copied beside itself."
                    )
                case 2:
                    pageView(
                        art: "dtg_Onboarding3",
                        title: "Tap the copy",
                        line: "The surplus word files the work. A miss greys that word and stays on the quire."
                    )
                default:
                    pageView(
                        art: "dtg_Onboarding1",
                        title: "Save a painting",
                        line: "Gather works from Copenhagen. The quiz only sits on what you keep here."
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: QuireSpace.x2) {
                Button(page < 2 ? "Continue" : "Next") {
                    if page < 2 {
                        page += 1
                    } else {
                        onFinish()
                    }
                }
                .buttonStyle(
                    EchoPillStyle(isEnabled: true, isLoading: false, reduceMotion: reduceMotion)
                )
                Button("Skip") {
                    onFinish()
                }
                .font(QuireType.body)
                .foregroundStyle(QuireColor.muted)
                .frame(maxWidth: .infinity, minHeight: QuireSpace.hit)
                .contentShape(Rectangle())
                .buttonStyle(QuireChromePressStyle(reduceMotion: reduceMotion))
            }
            .padding(.horizontal, QuireSpace.x3)
            .padding(.bottom, QuireSpace.x3)
        }
        .background(QuireColor.background.ignoresSafeArea())
    }

    private func pageView(art: String, title: String, line: String) -> some View {
        VStack(alignment: .leading, spacing: QuireSpace.x2) {
            Spacer(minLength: QuireSpace.x2)
            Image(art)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: QuireSpace.x5 * 8)
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)
            Text(title)
                .font(QuireType.display(for: typeSize))
                .foregroundStyle(QuireColor.ink)
                .lineLimit(4)
                .minimumScaleFactor(0.7)
            Text(line)
                .font(QuireType.body)
                .foregroundStyle(QuireColor.muted)
            Spacer(minLength: QuireSpace.x4)
        }
        .padding(.horizontal, QuireSpace.x3)
    }
}
