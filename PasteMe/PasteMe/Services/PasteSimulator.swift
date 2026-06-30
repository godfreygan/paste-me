import AppKit
import ApplicationServices

enum PasteSimulator {
    private static let commandVKeyCode: CGKeyCode = 9
    private static let focusRestoreDelay: TimeInterval = 0.15

    private static var targetApp: NSRunningApplication?

    /// Remember the frontmost app before PasteMe takes keyboard focus.
    static func rememberTargetApp() {
        if let app = NSWorkspace.shared.frontmostApplication,
           app.bundleIdentifier != Bundle.main.bundleIdentifier {
            targetApp = app
        }
    }

    /// Restore focus to the target app, write clipboard, then simulate ⌘V.
    static func performPaste(copyAction: @escaping () -> Void) {
        if let app = targetApp {
            app.activate(options: [.activateIgnoringOtherApps])
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + focusRestoreDelay) {
            copyAction()
            simulateCommandV()
        }
    }

    static var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    static func simulateCommandV() {
        guard AXIsProcessTrusted() else { return }

        let source = CGEventSource(stateID: .hidSystemState)
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: commandVKeyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: commandVKeyCode, keyDown: false) else {
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
