import SwiftUI

private struct StickyySurfaceModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency)
    private var reduceTransparency

    @Environment(\.colorScheme)
    private var colorScheme

    @ViewBuilder
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(
            cornerRadius: StickyyMetrics.surfaceCornerRadius,
            style: .continuous
        )

        if reduceTransparency {
            content
                .background(
                    Color(nsColor: .windowBackgroundColor),
                    in: shape
                )
                .overlay {
                    shape.strokeBorder(
                        Color.primary.opacity(
                            colorScheme == .dark ? 0.18 : 0.10
                        )
                    )
                }
        } else {
            content.glassEffect(
                .regular.tint(Color.accentColor.opacity(0.025)),
                in: shape
            )
        }
    }
}

extension View {
    func stickyySurface() -> some View {
        modifier(StickyySurfaceModifier())
    }
}
