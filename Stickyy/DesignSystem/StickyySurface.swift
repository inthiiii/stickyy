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
                    // Keep a real material layer beneath Liquid Glass. Dynamic
                    // overlays (such as the section navigator) can cause the
                    // glass compositor to rebuild; this prevents that rebuild
                    // from briefly exposing a clear window.
                    .background {
                        Rectangle().fill(.regularMaterial)
                    }
                    .glassEffect(.regular, in: Rectangle())
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
                    .background(.regularMaterial, in: shape)
                    .glassEffect(.regular, in: shape)
            } else {
                content.background(.regularMaterial, in: shape)
            }
        } else {
            content.background(.regularMaterial, in: shape)
        }
    }
}
