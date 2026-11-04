import AppKit
import SwiftUI

@MainActor
final class OnboardingController {
    private static var activePanel: NSPanel?

    func show() {
        if let panel = Self.activePanel { panel.makeKeyAndOrderFront(nil); return }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 480),
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
                NotificationCenter.default.post(
                    name: .onboardingDidFinish,
                    object: nil
                )
            }
        )
        panel.center()
        Self.activePanel = panel
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }
}

private enum OnboardingPageKind {
    case welcome
    case clipboard
    case floatingNote
    case timer
    case privacy
    case featureGrid
}

private struct OnboardingPage {
    let kind: OnboardingPageKind
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
            kind: .welcome,
            icon: "sparkles", eyebrow: "WELCOME TO STICKYY",
            title: "Catch it before it fades.",
            detail: "A calm scratchpad that lives in your menu bar. Open it from anywhere with ⌃⌥Space.",
            accent: .orange
        ),
        OnboardingPage(
            kind: .clipboard,
            icon: "rectangle.stack.fill", eyebrow: "CLIPBOARD PILLS",
            title: "Your recent copies, close by.",
            detail: "Keep five or seven text, link, image, and file pills below the note. Double-click any pill to copy it again.",
            accent: .blue
        ),
        OnboardingPage(
            kind: .floatingNote,
            icon: "macwindow.on.rectangle", eyebrow: "FLOATING NOTE",
            title: "Stay with the thought you are in.",
            detail: "Press ⌃⌥Space for a focused, movable note above every app—even while you are working in full screen.",
            accent: .mint
        ),
        OnboardingPage(
            kind: .timer,
            icon: "timer", eyebrow: "STICKYY TIMER",
            title: "Focus without leaving the thought.",
            detail: "Set up to 60 minutes from either note. When the note closes, its Liquid Timer continues counting down right in your menu bar.",
            accent: .cyan
        ),
        OnboardingPage(
            kind: .privacy,
            icon: "hand.raised.fill", eyebrow: "YOURS, LOCALLY",
            title: "Simple by design. Private by default.",
            detail: "Your scratchpads stay on this Mac. Choose the original minimal surface or Liquid Glass anytime.",
            accent: .purple
        ),
        OnboardingPage(
            kind: .featureGrid,
            icon: "square.grid.2x2.fill", eyebrow: "MORE IN EVERY THOUGHT",
            title: "Small tools. A complete scratchpad.",
            detail: "Organize, format, and move through longer thoughts without turning Stickyy into a heavy notes app.",
            accent: .indigo
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

                if pages[page].kind == .privacy {
                    if #available(macOS 26.0, *) {
                        Toggle("Use Liquid Glass", isOn: $usesLiquidGlass)
                            .toggleStyle(.switch).controlSize(.small).padding(.top, 14)
                    }
                } else if pages[page].kind == .clipboard {
                    HStack(spacing: 7) {
                        demoPill("link", "A useful link")
                        demoPill("photo", "Design.png")
                        demoPill("text.quote", "A thought")
                    }
                    .padding(.top, 14)
                } else if pages[page].kind == .floatingNote {
                    floatingPanelPreview
                        .padding(.top, 12)
                } else if pages[page].kind == .timer {
                    liquidTimerPreview
                        .padding(.top, 14)
                } else if pages[page].kind == .featureGrid {
                    featureGridPreview
                        .padding(.top, 12)
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
        .frame(width: 560, height: 480)
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

    private var floatingPanelPreview: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("A thought worth keeping")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
            RoundedRectangle(cornerRadius: 2)
                .fill(.secondary.opacity(0.28))
                .frame(width: 154, height: 4)
            RoundedRectangle(cornerRadius: 2)
                .fill(.secondary.opacity(0.18))
                .frame(width: 112, height: 4)
        }
        .padding(16)
        .frame(width: 224, height: 88, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .strokeBorder(.white.opacity(0.18))
        }
        .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Floating note preview")
        .accessibilityIdentifier("onboardingFloatingPreview")
    }

    private var liquidTimerPreview: some View {
        HStack(spacing: 7) {
            Image(systemName: "timer")
            Text("25:00")
                .monospacedDigit()
        }
        .font(.system(size: 14, weight: .semibold, design: .rounded))
        .padding(.horizontal, 15)
        .frame(height: 38)
        .background(.regularMaterial, in: Capsule())
        .overlay {
            Capsule().strokeBorder(.white.opacity(0.2))
        }
        .shadow(color: pages[page].accent.opacity(0.3), radius: 12, y: 5)
        .symbolEffect(.pulse, options: .repeating)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Liquid Timer preview, 25 minutes")
        .accessibilityIdentifier("onboardingTimerPreview")
    }

    private var featureGridPreview: some View {
        LazyVGrid(
            columns: [
                GridItem(.fixed(162), spacing: 8),
                GridItem(.fixed(162), spacing: 8),
            ],
            spacing: 8
        ) {
            featureCard("note.text.badge.plus", "Multiple Notes")
            featureCard("pin.fill", "Pin Notes")
            featureCard("bold.italic.underline", "Text Formatting")
            featureCard("circle.grid.3x3.fill", "Chapter Sections")
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("More Stickyy features")
        .accessibilityIdentifier("onboardingFeatureGrid")
    }

    private func featureCard(_ icon: String, _ title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(pages[page].accent)
                .frame(width: 22)
            Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .frame(height: 40)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 11))
        .overlay {
            RoundedRectangle(cornerRadius: 11)
                .strokeBorder(.white.opacity(0.14))
        }
    }
}
