import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private let clipboardManager = ClipboardManager.shared
    private let hotkeyManager = HotkeyManager.shared
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard isSupportedMacOSVersion else {
            showUnsupportedVersionAlert()
            NSApp.terminate(nil)
            return
        }

        setupMenuBar()
        setupPopover()
        setupHotkey()
        
        // Ensure app runs as menu bar only (no dock icon)
        NSApp.setActivationPolicy(.accessory)
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "PasteMe")
            button.action = #selector(togglePopover)
            button.target = self
        }
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 450)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(rootView: MenuBarView())
    }
    
    private func setupHotkey() {
        hotkeyManager.onHotkeyPressed = { [weak self] in
            self?.showQuickAccess()
        }
        hotkeyManager.registerFromSettings()
    }
    
    @objc private func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }
    
    private func showPopover() {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            
            // Activate app to receive keyboard events
            NSApp.activate(ignoringOtherApps: true)
            
            // Focus the search field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let window = self.popover.contentViewController?.view.window {
                    window.makeKey()
                }
            }
        }
    }
    
    private func closePopover() {
        popover.performClose(nil)
    }
    
    private func showQuickAccess() {
        // Close popover if shown
        if popover.isShown {
            closePopover()
        }
        
        QuickAccessWindowController.shared.toggle()
    }

    private static let minimumMajorVersion = 15
    private static let minimumMinorVersion = 0

    private var isSupportedMacOSVersion: Bool {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        if version.majorVersion > Self.minimumMajorVersion { return true }
        if version.majorVersion < Self.minimumMajorVersion { return false }
        return version.minorVersion >= Self.minimumMinorVersion
    }

    private func showUnsupportedVersionAlert() {
        let alert = NSAlert()
        alert.messageText = "系统版本不受支持"
        alert.informativeText = "PasteMe 需要 macOS \(Self.minimumMajorVersion).\(Self.minimumMinorVersion) 或更高版本。\n当前系统：macOS \(ProcessInfo.processInfo.operatingSystemVersionString)"
        alert.alertStyle = .critical
        alert.addButton(withTitle: "好")
        alert.runModal()
    }
}
