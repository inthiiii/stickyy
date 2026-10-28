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
            if #available(macOS 26.0, *) {
                content
                    .background {
                        // Host Liquid Glass on a stable sibling layer instead
                        // of the dynamic editor content. This preserves the
                        // native glass appearance while section overlays change
                        // without stacking a second material underneath it.
                        Rectangle()
                            .fill(.clear)
                            .glassEffect(.regular, in: Rectangle())
                            .allowsHitTesting(false)
                    }
            } else {
                content.background {
                    Rectangle().fill(.regularMaterial)
                }
            }
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

    func stickyyPillSurface<S: Shape>(_ shape: S) -> some View {
        modifier(StickyyPillSurfaceModifier(shape: shape))
    }
}

private struct StickyyPillSurfaceModifier<S: Shape>: ViewModifier {
    @AppStorage(StickyyPreferences.usesLiquidGlass) private var usesLiquidGlass = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let shape: S

    @ViewBuilder
    func body(content: Content) -> some View {
        if reduceTransparency {
            content.background(Color(nsColor: .windowBackgroundColor), in: shape)
        } else if usesLiquidGlass {
            if #available(macOS 26.0, *) {
                content
                    .background {
                        shape
                            .fill(.clear)
                            .glassEffect(.regular, in: shape)
                            .allowsHitTesting(false)
                    }
            } else {
                content.background(.regularMaterial, in: shape)
            }
        } else {
            content.background(.regularMaterial, in: shape)
        }
    }
}
