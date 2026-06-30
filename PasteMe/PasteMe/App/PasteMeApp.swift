import AppKit
import SwiftUI
import AppKit

extension Notification.Name {
    static let openPasteMeSettings = Notification.Name("openPasteMeSettings")
}

@main
struct PasteMeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Hidden bridge window must be declared before Settings so openSettings() works
        // from AppKit (menu bar context menu) via SettingsBridgeView.
        Window("", id: "settings-bridge") {
            SettingsBridgeView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1, height: 1)
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.suppressed)

        Settings {
            SettingsView()
                .onDisappear {
                    NSApp.setActivationPolicy(.accessory)
                }
        }
    }
}

private struct SettingsBridgeView: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .onReceive(NotificationCenter.default.publisher(for: .openPasteMeSettings)) { _ in
                NSApp.setActivationPolicy(.regular)
                NSApp.activate(ignoringOtherApps: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    openSettings()
                }
            }
    }
}
