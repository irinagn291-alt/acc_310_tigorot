import SwiftUI

/// Twist screen for echo-then-expunge. The live Dittograph on Quiz is the
/// home surface. This folio names the job without a second fold enum.
struct EchoFolioView: View {
    var onClose: () -> Void
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: QuireSpace.x3) {
                Image("dtg_TwistHero")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: QuireSpace.x5 * 7)
                    .accessibilityHidden(true)
                Text("Echo then expunge")
                    .font(QuireType.display(for: typeSize))
                    .foregroundStyle(QuireColor.ink)
                    .lineLimit(4)
                    .minimumScaleFactor(0.7)
                Text("Echo copies one native word beside itself. Only that surplus copy files the painting. A miss greys the word and keeps the line up.")
                    .font(QuireType.body)
                    .foregroundStyle(QuireColor.muted)
                Spacer(minLength: QuireSpace.x2)
                Button("Back to quire", action: onClose)
                    .buttonStyle(
                        EchoPillStyle(isEnabled: true, isLoading: false, reduceMotion: reduceMotion)
                    )
            }
            .padding(QuireSpace.x3)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(QuireColor.background.ignoresSafeArea())
            .navigationTitle("The extra copy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .frame(width: QuireSpace.hit, height: QuireSpace.hit)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Close the extra copy")
                }
            }
        }
        .presentationBackground(QuireColor.background)
        .modifier(QuireSheetMotion())
    }
}
