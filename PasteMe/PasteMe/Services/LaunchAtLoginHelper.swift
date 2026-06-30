import Foundation
import ServiceManagement

enum LaunchAtLoginHelper {
    static var isEnabled: Bool {
        if #available(macOS 15.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }

    static func setEnabled(_ enabled: Bool) {
        guard #available(macOS 15.0, *) else { return }

        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("LaunchAtLogin error: \(error.localizedDescription)")
        }
    }
}
