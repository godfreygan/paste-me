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
        // Do not call AXIsProcessTrustedWithOptions(prompt: true) here — it shows the
        // system dialog on every click when trust check fails (e.g. app path changed).
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

    /// Opens System Settings. Does not show the intrusive AX prompt dialog.
    static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Only for explicit user action in Settings — shows system prompt at most once per launch.
    private static var didPromptThisSession = false

    static func requestAccessibilityPermissionIfNeeded() {
        guard !AXIsProcessTrusted(), !didPromptThisSession else { return }
        didPromptThisSession = true
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    @discardableResult
    private static func simulateCommandV() -> Bool {
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
        let script = """
        tell application "System Events"
            keystroke "v" using command down
        end tell
        """
        var error: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&error)
    }
}
