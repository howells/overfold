import AppKit
import ServiceManagement

/// Three status items, right to left: the arrow, the Hidden divider and the Always hidden divider.
/// A divider at `expanded` length pushes every icon to its left off screen.
final class Overfold: NSObject {
    enum Reveal { case none, hidden, everything }

    private static let expanded: CGFloat = 10_000
    private static let idleLimit: TimeInterval = 15
    private static let arrangedKey = "arranged"

    private let arrow = NSStatusBar.system.statusItem(withLength: 28)
    private let hiddenDivider = NSStatusBar.system.statusItem(withLength: 0)
    private let alwaysDivider = NSStatusBar.system.statusItem(withLength: 0)

    private var reveal = Reveal.none
    private var lastActivity = Date()
    private var tick: Timer?
    private var hotKey: HotKey?
    private var mouseMonitor: Any?

    /// Until the arrow is first clicked, everything stays shown so icons can be arranged.
    private var arranged: Bool {
        get { UserDefaults.standard.bool(forKey: Self.arrangedKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.arrangedKey) }
    }

    override init() {
        super.init()
        arrow.autosaveName = "overfold-arrow"
        hiddenDivider.autosaveName = "overfold-hidden"
        alwaysDivider.autosaveName = "overfold-always-hidden"

        if let button = arrow.button {
            button.target = self
            button.action = #selector(arrowClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        for divider in [hiddenDivider, alwaysDivider] {
            (divider.button?.cell as? NSButtonCell)?.highlightsBy = []
        }

        hotKey = HotKey(keyCode: 31, modifiers: [.control, .option]) { [weak self] in
            self?.arranged = true
            self?.toggle(everything: false)
        }
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.clickedElsewhere()
        }

        apply(arranged ? .none : .everything)
        if !arranged {
            // Let the status items settle so the guide's lines are already on screen.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { Self.showGuide() }
        }
    }

    /// First launch: explain the lines, and offer to open at login.
    private static func showGuide() {
        let alert = NSAlert()
        alert.messageText = "Arrange your menu bar"
        alert.informativeText = """
            Hold ⌘ and drag icons around the two lines next to the arrow.

            Right of grey: always shown.
            Grey to blue: shown when you click the arrow.
            Left of blue: shown when you ⌥-click it.

            Click the arrow when you're done. ⌥-click it to see the lines again.
            """
        alert.addButton(withTitle: "OK")
        alert.showsSuppressionButton = true
        alert.suppressionButton?.title = "Open Overfold at login"
        alert.suppressionButton?.state = .on
        NSApp.activate()
        alert.runModal()
        if alert.suppressionButton?.state == .on {
            try? SMAppService.mainApp.register()
        }
    }

    // MARK: Actions

    @objc private func arrowClicked() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            showMenu()
            return
        }
        arranged = true
        toggle(everything: event.modifierFlags.contains(.option))
    }

    private func toggle(everything: Bool) {
        switch (reveal, everything) {
        case (.none, false): apply(.hidden)
        case (.none, true), (.hidden, true): apply(.everything)
        default: apply(.none)
        }
    }

    private func clickedElsewhere() {
        guard reveal != .none, arranged, !Self.pointIsInMenuBar(NSEvent.mouseLocation), !Self.menuIsOpen() else { return }
        apply(.none)
    }

    // MARK: State

    private func apply(_ next: Reveal) {
        reveal = next
        // When everything is shown, both dividers draw a line so icons can be ⌘-dragged into the right section.
        switch next {
        case .none: hiddenDivider.length = Self.expanded
        case .hidden: hiddenDivider.length = 0
        case .everything: hiddenDivider.length = 12
        }
        hiddenDivider.button?.image = next == .everything ? Self.line(.tertiaryLabelColor) : nil
        alwaysDivider.length = next == .everything ? 12 : Self.expanded
        alwaysDivider.button?.image = next == .everything ? Self.line(.controlAccentColor) : nil

        let symbol = next == .none ? "chevron.left" : "chevron.right"
        arrow.button?.image = NSImage(systemSymbolName: symbol, accessibilityDescription: "Overfold")

        tick?.invalidate()
        tick = nil
        guard next != .none, arranged else { return }
        lastActivity = Date()
        tick = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.checkIdle() }
    }

    private func checkIdle() {
        if Self.menuIsOpen() || Self.pointIsInMenuBar(NSEvent.mouseLocation) {
            lastActivity = Date()
        } else if Date().timeIntervalSince(lastActivity) >= Self.idleLimit {
            apply(.none)
        }
    }

    // MARK: Menu

    private func showMenu() {
        let menu = NSMenu()
        let show = menu.addItem(withTitle: "Show hidden icons", action: #selector(showHidden), keyEquivalent: "o")
        show.keyEquivalentModifierMask = [.control, .option]
        menu.addItem(.separator())
        let login = menu.addItem(withTitle: "Open at login", action: #selector(toggleLogin), keyEquivalent: "")
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Overfold", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        for item in menu.items where item.action != #selector(NSApplication.terminate(_:)) { item.target = self }

        guard let button = arrow.button else { return }
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 6), in: button)
    }

    @objc private func showHidden() {
        arranged = true
        apply(.hidden)
    }

    @objc private func toggleLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled { try service.unregister() } else { try service.register() }
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    // MARK: Environment

    private static func line(_ color: NSColor) -> NSImage {
        NSImage(size: NSSize(width: 2, height: 16), flipped: false) { rect in
            color.setFill()
            NSBezierPath(roundedRect: rect, xRadius: 1, yRadius: 1).fill()
            return true
        }
    }

    private static func pointIsInMenuBar(_ point: NSPoint) -> Bool {
        NSScreen.screens.contains { screen in
            let height = max(screen.frame.maxY - screen.visibleFrame.maxY, NSStatusBar.system.thickness)
            let strip = NSRect(x: screen.frame.minX, y: screen.frame.maxY - height, width: screen.frame.width, height: height)
            return strip.contains(point)
        }
    }

    /// True while any app has a menu open, including menus from menu bar icons.
    private static func menuIsOpen() -> Bool {
        guard let windows = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] else { return false }
        let menuLayer = Int(CGWindowLevelForKey(.popUpMenuWindow))
        return windows.contains { ($0[kCGWindowLayer as String] as? Int) == menuLayer }
    }
}
