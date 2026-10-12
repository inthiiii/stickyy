import AppKit
import SwiftUI

@MainActor
final class OnboardingController {
    private static var activePanel: NSPanel?

    func show() {
        if let panel = Self.activePanel { panel.makeKeyAndOrderFront(nil); return }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 420),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        panel.contentViewController = NSHostingController(
            rootView: OnboardingView {
                UserDefaults.standard.set(true, forKey: StickyyPreferences.hasCompletedOnboarding)
                Self.activePanel?.close()
                Self.activePanel = nil
            }
        )
        panel.center()
        Self.activePanel = panel
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }
}

private struct OnboardingPage {
    let icon: String
    let eyebrow: String
    let title: String
    let detail: String
    let accent: Color
}

private struct OnboardingView: View {
    let onFinish: () -> Void
    @State private var page = 0
    @AppStorage(StickyyPreferences.usesLiquidGlass) private var usesLiquidGlass = false

    private let pages = [
        OnboardingPage(
            icon: "sparkles", eyebrow: "WELCOME TO STICKYY",
            title: "Catch it before it fades.",
            detail: "A calm scratchpad that lives in your menu bar. Open it from anywhere with ⌃⌥Space.",
            accent: .orange
        ),
        OnboardingPage(
            icon: "rectangle.stack.fill", eyebrow: "CLIPBOARD PILLS",
            title: "Your last five copies, close by.",
            detail: "Text, links, images, and files float below the note—ready to reuse without breaking your flow.",
            accent: .blue
        ),
        OnboardingPage(
            icon: "hand.raised.fill", eyebrow: "YOURS, LOCALLY",
            title: "Simple by design. Private by default.",
            detail: "Your scratchpads stay on this Mac. Choose the original minimal surface or Liquid Glass anytime.",
            accent: .purple
        )
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [pages[page].accent.opacity(0.2), Color.clear],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .animation(.easeInOut(duration: 0.45), value: page)

            VStack(spacing: 0) {
                Spacer(minLength: 28)
                ZStack {
                    Circle().fill(pages[page].accent.opacity(0.16)).frame(width: 112, height: 112)
                    Image(systemName: pages[page].icon)
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(pages[page].accent)
                        .symbolEffect(.bounce, value: page)
                }

                Text(pages[page].eyebrow)
                    .font(.caption.weight(.bold)).tracking(1.6)
                    .foregroundStyle(pages[page].accent)
                    .padding(.top, 22)
                Text(pages[page].title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                Text(pages[page].detail)
                    .font(.body).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).lineSpacing(3)
                    .frame(maxWidth: 420).padding(.top, 10)

                if page == 2 {
                    Toggle("Use Liquid Glass", isOn: $usesLiquidGlass)
                        .toggleStyle(.switch).controlSize(.small).padding(.top, 14)
                } else if page == 1 {
                    HStack(spacing: 7) {
                        demoPill("link", "A useful link")
                        demoPill("photo", "Design.png")
                        demoPill("text.quote", "A thought")
                    }
                    .padding(.top, 14)
                }

                Spacer()
                HStack {
                    Button("Back") { withAnimation(.snappy) { page -= 1 } }
                        .buttonStyle(.plain).disabled(page == 0).opacity(page == 0 ? 0 : 1)
                    Spacer()
                    HStack(spacing: 7) {
                        ForEach(pages.indices, id: \.self) { index in
                            Capsule()
                                .fill(index == page ? pages[page].accent : Color.secondary.opacity(0.25))
                                .frame(width: index == page ? 22 : 7, height: 7)
                                .onTapGesture { withAnimation(.snappy) { page = index } }
                        }
                    }
                    Spacer()
                    Button(page == pages.count - 1 ? "Start catching thoughts" : "Continue") {
                        if page == pages.count - 1 { onFinish() }
                        else { withAnimation(.snappy) { page += 1 } }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(pages[page].accent)
                    .keyboardShortcut(.defaultAction)
                }
                .padding(24)
            }
        }
        .frame(width: 560, height: 420)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .animation(.easeInOut(duration: 0.3), value: page)
    }

    private func demoPill(_ icon: String, _ text: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption2).lineLimit(1).padding(.horizontal, 10).frame(height: 28)
            .background(.regularMaterial, in: .capsule)
            .overlay { Capsule().strokeBorder(.white.opacity(0.16)) }
            .shadow(color: .black.opacity(0.12), radius: 5, y: 2)
    }
}
