import AppKit
import ApplicationServices

enum PasteSimulator {
    private static let commandVKeyCode: CGKeyCode = 9
    private static let uiSettleDelay: TimeInterval = 0.12
    private static let activationDelay: TimeInterval = 0.22
    private static let pasteKeystrokeDelay: TimeInterval = 0.08

    private static var targetApp: NSRunningApplication?

    /// Remember the frontmost app before PasteMe takes keyboard focus.
    static func rememberTargetApp() {
        if let app = NSWorkspace.shared.frontmostApplication,
           app.bundleIdentifier != Bundle.main.bundleIdentifier {
            targetApp = app
        }
    }

    /// Close UI first, restore target-app focus, write clipboard, then simulate ⌘V.
    static func performPaste(copyAction: @escaping () -> Void) {
        DispatchQueue.main.async {
            performPasteOnMain(copyAction: copyAction)
        }
    }

    private static func performPasteOnMain(copyAction: @escaping () -> Void) {
        guard AXIsProcessTrusted() else {
            copyAction()
            promptForAccessibility()
            return
        }

        let appToActivate = targetApp

        DispatchQueue.main.asyncAfter(deadline: .now() + uiSettleDelay) {
            appToActivate?.activate(options: [.activateIgnoringOtherApps])

            DispatchQueue.main.asyncAfter(deadline: .now() + activationDelay) {
                copyAction()

                DispatchQueue.main.asyncAfter(deadline: .now() + pasteKeystrokeDelay) {
                    if !simulateCommandV() {
                        pasteViaAppleScript()
                    }
                    targetApp = nil
                }
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
