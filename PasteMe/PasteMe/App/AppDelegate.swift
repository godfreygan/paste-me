import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var contextMenu: NSMenu!
    private var settingsWindow: NSWindow?
    private let hotkeyManager = HotkeyManager.shared
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard isSupportedMacOSVersion else {
            showUnsupportedVersionAlert()
            NSApp.terminate(nil)
            return
        }

        setupMenuBar()
        setupContextMenu()
        setupPopover()
        setupHotkey()

        // Start clipboard monitoring at launch (singleton is lazy — not referenced by UI alone).
        _ = ClipboardManager.shared
        
        NSApp.setActivationPolicy(.accessory)
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "PasteMe")
            button.action = #selector(statusItemClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    private func setupContextMenu() {
        contextMenu = NSMenu()

        let settingsItem = NSMenuItem(title: "设置", action: #selector(openSettings), keyEquivalent: "")
        settingsItem.target = self
        contextMenu.addItem(settingsItem)

        contextMenu.addItem(.separator())

        let quitItem = NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "")
        quitItem.target = self
        contextMenu.addItem(quitItem)
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 450)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView(onPaste: { [weak self] item in
                self?.pasteFromMenuBar(item)
            })
        )
    }
    
    private func setupHotkey() {
        hotkeyManager.onHotkeyPressed = { [weak self] in
            self?.showQuickAccess()
        }
        hotkeyManager.registerFromSettings()
    }

    private func pasteFromMenuBar(_ item: ClipItem) {
        closePopover()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            ClipboardManager.shared.copyAndPaste(item)
        }
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else {
            togglePopover()
            return
        }

        if event.type == .rightMouseUp {
            closePopover()
            contextMenu.popUp(
                positioning: nil,
                at: NSPoint(x: 0, y: sender.bounds.height + 5),
                in: sender
            )
        } else {
            togglePopover()
        }
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
            PasteSimulator.rememberTargetApp()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            
            NSApp.activate(ignoringOtherApps: true)
            
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

    @objc private func openSettings() {
        contextMenu.cancelTracking()
        closePopover()
        QuickAccessWindowController.shared.hide()

        if settingsWindow == nil {
            let hosting = NSHostingController(rootView: SettingsView())
            let window = NSWindow(contentViewController: hosting)
            window.title = "PasteMe 设置"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.center()
            settingsWindow = window
        }

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    @objc private func quitApp() {
        contextMenu.cancelTracking()
        closePopover()
        QuickAccessWindowController.shared.hide()
        NSApp.terminate(nil)
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window === settingsWindow else { return }
        NSApp.setActivationPolicy(.accessory)
    }
    
    private func showQuickAccess() {
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
