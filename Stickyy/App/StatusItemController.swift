import AppKit
import QuartzCore

@MainActor
final class StatusItemController: NSObject {
    private let statusItem: NSStatusItem
    private let popoverController: PopoverController
    private let floatingPanelController: FloatingPanelController
    private let timer: StickyyTimerController
    private let liquidTimerBackground = CAShapeLayer()
    private var appearanceObservers: [NSObjectProtocol] = []
    private var isShowingTimerPill = false
    private var isPreparingScratchpadPresentation = false
    private var reservedPopoverAnchorWidth: CGFloat?
    private lazy var contextMenu = makeContextMenu()
    private lazy var settingsWindowController =
        StickyySettingsWindowController()

    init(
        popoverController: PopoverController,
        floatingPanelController: FloatingPanelController,
        timer: StickyyTimerController
    ) {
        self.popoverController = popoverController
        self.floatingPanelController = floatingPanelController
        self.timer = timer
        statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength
        )
        super.init()

        guard let button = statusItem.button else {
            assertionFailure("Stickyy could not create its menu-bar button.")
            return
        }

        button.toolTip = AppEnvironment.productName
        button.setAccessibilityLabel(AppEnvironment.productName)
        button.wantsLayer = true
        liquidTimerBackground.opacity = 0
        liquidTimerBackground.fillColor = NSColor.controlAccentColor
            .withAlphaComponent(0.22)
            .cgColor
        liquidTimerBackground.strokeColor = NSColor.controlAccentColor
            .withAlphaComponent(0.3)
            .cgColor
        liquidTimerBackground.lineWidth = 0.75
        button.layer?.insertSublayer(liquidTimerBackground, at: 0)
        button.target = self
        button.action = #selector(statusItemClicked(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])

        for name in [
            Notification.Name.stickyyTimerDidChange,
            .stickyyNoteVisibilityDidChange,
        ] {
            appearanceObservers.append(
                NotificationCenter.default.addObserver(
                    forName: name,
                    object: nil,
                    queue: .main
                ) { [weak self] _ in
                    Task { @MainActor [weak self] in
                        self?.updateMenuBarAppearance()
                    }
                }
            )
        }
        updateMenuBarAppearance()
    }

    func showScratchpad() {
        guard let button = statusItem.button else { return }
        presentScratchpad(relativeTo: button)
    }

    private func presentScratchpad(relativeTo button: NSStatusBarButton) {
        reservedPopoverAnchorWidth = max(
            button.bounds.width,
            NSStatusBar.system.thickness
        )
        isPreparingScratchpadPresentation = true
        floatingPanelController.close()
        updateMenuBarAppearance()

        // Let the status bar finish returning the timer pill to its square
        // icon before the popover calculates its arrow anchor.
        DispatchQueue.main.async { [weak self, weak button] in
            guard let self, let button else { return }
            self.popoverController.show(relativeTo: button)
            self.isPreparingScratchpadPresentation = false
            self.updateMenuBarAppearance()
        }
    }

    private func updateMenuBarAppearance() {
        guard let button = statusItem.button else { return }
        let preservesPopoverAnchor = isPreparingScratchpadPresentation
            || popoverController.isShown
        if !preservesPopoverAnchor {
            reservedPopoverAnchorWidth = nil
        }
        let shouldShowTimer = timer.isExpanded
            && !popoverController.isShown
            && !floatingPanelController.isShown
            && !isPreparingScratchpadPresentation
        let changesPresentation = shouldShowTimer != isShowingTimerPill

        if shouldShowTimer {
            statusItem.length = NSStatusItem.variableLength
            button.image = NSImage(
                systemSymbolName: timer.phase == .finished
                    ? "timer.circle.fill"
                    : "timer",
                accessibilityDescription: "Stickyy Timer"
            )
            button.image?.isTemplate = true
            button.imagePosition = .imageLeft
            button.title = timer.displayText
            button.font = .monospacedDigitSystemFont(
                ofSize: 11,
                weight: .semibold
            )
            button.toolTip = timer.phase == .finished
                ? "Stickyy Timer finished"
                : "Stickyy Timer · \(timer.displayText) remaining"
            button.setAccessibilityLabel(button.toolTip ?? "Stickyy Timer")
        } else {
            statusItem.length = preservesPopoverAnchor
                ? reservedPopoverAnchorWidth ?? NSStatusItem.squareLength
                : NSStatusItem.squareLength
            button.image = NSImage(
                systemSymbolName: "note.text",
                accessibilityDescription: AppEnvironment.productName
            )
            button.image?.isTemplate = true
            button.imagePosition = .imageOnly
            button.title = ""
            button.toolTip = AppEnvironment.productName
            button.setAccessibilityLabel(AppEnvironment.productName)
        }

        styleMenuBarButton(
            button,
            asTimerPill: shouldShowTimer,
            animated: changesPresentation
        )
        isShowingTimerPill = shouldShowTimer
    }

    private func styleMenuBarButton(
        _ button: NSStatusBarButton,
        asTimerPill: Bool,
        animated: Bool
    ) {
        guard let layer = button.layer else { return }
        let bounds = button.bounds
        liquidTimerBackground.frame = bounds
        let targetPath = liquidBackgroundPath(
            in: bounds,
            expanded: asTimerPill
        )
        let targetOpacity: Float = asTimerPill ? 1 : 0

        guard animated,
              !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            liquidTimerBackground.path = targetPath
            liquidTimerBackground.opacity = targetOpacity
            CATransaction.commit()
            return
        }

        let previousPath = liquidTimerBackground.presentation()?.path
            ?? liquidTimerBackground.path
            ?? liquidBackgroundPath(in: bounds, expanded: !asTimerPill)
        let previousOpacity = liquidTimerBackground.presentation()?.opacity
            ?? liquidTimerBackground.opacity

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        liquidTimerBackground.path = targetPath
        liquidTimerBackground.opacity = targetOpacity
        CATransaction.commit()

        let pathMorph = CABasicAnimation(keyPath: "path")
        pathMorph.fromValue = previousPath
        pathMorph.toValue = targetPath
        pathMorph.duration = 0.34
        pathMorph.timingFunction = CAMediaTimingFunction(
            name: .easeInEaseOut
        )
        liquidTimerBackground.add(pathMorph, forKey: "stickyy.liquid.path")

        let liquidFade = CABasicAnimation(keyPath: "opacity")
        liquidFade.fromValue = previousOpacity
        liquidFade.toValue = targetOpacity
        liquidFade.duration = 0.24
        liquidFade.timingFunction = CAMediaTimingFunction(
            name: .easeInEaseOut
        )
        liquidTimerBackground.add(
            liquidFade,
            forKey: "stickyy.liquid.opacity"
        )

        let spring = CASpringAnimation(keyPath: "transform.scale")
        spring.fromValue = asTimerPill ? 0.9 : 1.04
        spring.toValue = 1
        spring.mass = 0.7
        spring.stiffness = 210
        spring.damping = 18
        spring.initialVelocity = 0.25
        spring.duration = min(spring.settlingDuration, 0.42)
        layer.add(spring, forKey: "stickyy.timer.spring")
    }

    private func liquidBackgroundPath(
        in bounds: CGRect,
        expanded: Bool
    ) -> CGPath {
        let verticalInset: CGFloat = 2
        let availableHeight = max(0, bounds.height - verticalInset * 2)
        let width = expanded
            ? max(availableHeight, bounds.width - 4)
            : availableHeight
        let rect = CGRect(
            x: bounds.midX - width / 2,
            y: bounds.minY + verticalInset,
            width: width,
            height: availableHeight
        )
        return CGPath(
            roundedRect: rect,
            cornerWidth: availableHeight / 2,
            cornerHeight: availableHeight / 2,
            transform: nil
        )
    }

    @objc
    private func statusItemClicked(_ sender: NSStatusBarButton) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showContextMenu(from: sender)
        } else if popoverController.isShown {
            popoverController.close()
        } else {
            presentScratchpad(relativeTo: sender)
        }
    }

    private func showContextMenu(from button: NSStatusBarButton) {
        popoverController.close()
        floatingPanelController.close()
        statusItem.menu = contextMenu
        button.performClick(nil)
        statusItem.menu = nil
    }

    private func makeContextMenu() -> NSMenu {
        let menu = NSMenu()
        let phaseLabel = NSMenuItem(
            title: "Stickyy — \(AppEnvironment.version)",
            action: nil,
            keyEquivalent: ""
        )
        phaseLabel.isEnabled = false
        menu.addItem(phaseLabel)
        menu.addItem(.separator())

        let settingsItem = NSMenuItem(
            title: String(localized: "Settings…"),
            action: #selector(showSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: String(localized: "Quit Stickyy"),
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = NSApp
        menu.addItem(quitItem)
        return menu
    }

    @objc
    func showSettings() {
        popoverController.close()
        floatingPanelController.close()
        // A status-item menu is still tracking while its action runs. Opening
        // Settings on the next main-loop pass lets the menu finish closing
        // before the settings window becomes key.
        DispatchQueue.main.async {
            self.settingsWindowController.show()
        }
    }
}
