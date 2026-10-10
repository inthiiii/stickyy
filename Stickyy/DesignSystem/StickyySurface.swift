import SwiftUI

private struct StickyySurfaceModifier: ViewModifier {
    @AppStorage(StickyyPreferences.usesLiquidGlass)
    private var usesLiquidGlass = false

    @Environment(\.accessibilityReduceTransparency)
    private var reduceTransparency

    @ViewBuilder
    func body(content: Content) -> some View {
        if reduceTransparency {
            content
                .background(Color(nsColor: .windowBackgroundColor))
        } else if usesLiquidGlass {
            content.glassEffect(.regular, in: Rectangle())
        } else {
            content
                .background {
                    Rectangle().fill(.regularMaterial)
                }
        }
    }
}

extension View {
    func stickyySurface() -> some View {
        modifier(StickyySurfaceModifier())
    }
}
