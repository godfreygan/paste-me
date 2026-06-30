import AppKit
import ApplicationServices

enum PasteSimulator {
    private static let commandVKeyCode: CGKeyCode = 9
    private static let activationDelay: TimeInterval = 0.28
    private static let pasteKeystrokeDelay: TimeInterval = 0.06

    private static var targetApp: NSRunningApplication?

    /// Remember the frontmost app before PasteMe takes keyboard focus.
    static func rememberTargetApp() {
        if let app = NSWorkspace.shared.frontmostApplication,
           app.bundleIdentifier != Bundle.main.bundleIdentifier {
            targetApp = app
        }
    }

    /// Hide PasteMe, restore target-app focus, write clipboard, then simulate ⌘V.
    static func performPaste(copyAction: @escaping () -> Void) {
        guard AXIsProcessTrusted() else {
            copyAction()
            promptForAccessibility()
            return
        }

        NSApp.hide(nil)

        let appToActivate = targetApp
        appToActivate?.activate(options: [.activateIgnoringOtherApps])

        DispatchQueue.main.asyncAfter(deadline: .now() + activationDelay) {
            copyAction()

            DispatchQueue.main.asyncAfter(deadline: .now() + pasteKeystrokeDelay) {
                if simulateCommandV() {
                    return
                }
                pasteViaAppleScript()
            }
        }
    }

    static var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    static func promptForAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    static func openAccessibilitySettings() {
        promptForAccessibility()
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    @discardableResult
    private static func simulateCommandV() -> Bool {
        guard AXIsProcessTrusted() else { return false }

        let source = CGEventSource(stateID: .combinedSessionState)
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: commandVKeyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: commandVKeyCode, keyDown: false) else {
            return false
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cgSessionEventTap)
        keyUp.post(tap: .cgSessionEventTap)
        return true
    }

    private static func pasteViaAppleScript() {
        guard AXIsProcessTrusted() else { return }

        let script = """
        tell application "System Events"
            keystroke "v" using command down
        end tell
        """
        var error: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&error)
    }
}
