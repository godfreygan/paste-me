import Foundation

struct AppSettings: Codable {
    var maxHistoryCount: Int
    var hotkeyKeyCode: UInt32
    var hotkeyModifiers: UInt32
    var hotkeyKeyLabel: String
    var launchAtLogin: Bool
    var playSoundOnCopy: Bool
    
    static let `default` = AppSettings(
        maxHistoryCount: 20,
        hotkeyKeyCode: HotkeyConfiguration.defaultKeyCode,
        hotkeyModifiers: HotkeyConfiguration.defaultModifiers,
        hotkeyKeyLabel: HotkeyConfiguration.defaultKeyLabel,
        launchAtLogin: true,
        playSoundOnCopy: false
    )
    
    static let maxHistoryRange = 10...1000
    
    var hotkeyDisplayString: String {
        HotkeyConfiguration.displayString(
            keyCode: hotkeyKeyCode,
            modifiers: hotkeyModifiers,
            keyLabel: hotkeyKeyLabel
        )
    }

    enum CodingKeys: String, CodingKey {
        case maxHistoryCount
        case hotkeyKeyCode
        case hotkeyModifiers
        case hotkeyKeyLabel
        case launchAtLogin
        case playSoundOnCopy
    }

    init(
        maxHistoryCount: Int,
        hotkeyKeyCode: UInt32,
        hotkeyModifiers: UInt32,
        hotkeyKeyLabel: String,
        launchAtLogin: Bool,
        playSoundOnCopy: Bool
    ) {
        self.maxHistoryCount = maxHistoryCount
        self.hotkeyKeyCode = hotkeyKeyCode
        self.hotkeyModifiers = hotkeyModifiers
        self.hotkeyKeyLabel = hotkeyKeyLabel
        self.launchAtLogin = launchAtLogin
        self.playSoundOnCopy = playSoundOnCopy
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        maxHistoryCount = try container.decode(Int.self, forKey: .maxHistoryCount)
        launchAtLogin = try container.decode(Bool.self, forKey: .launchAtLogin)
        playSoundOnCopy = try container.decode(Bool.self, forKey: .playSoundOnCopy)

        var resolvedKeyLabel = HotkeyConfiguration.defaultKeyLabel
        if let keyCode = try? container.decode(UInt32.self, forKey: .hotkeyKeyCode) {
            hotkeyKeyCode = keyCode
        } else if let legacyKey = try? container.decode(String.self, forKey: .hotkeyKeyCode) {
            hotkeyKeyCode = HotkeyConfiguration.defaultKeyCode
            resolvedKeyLabel = legacyKey.uppercased()
        } else {
            hotkeyKeyCode = HotkeyConfiguration.defaultKeyCode
        }

        if let modifiers = try? container.decode(UInt32.self, forKey: .hotkeyModifiers) {
            hotkeyModifiers = modifiers
        } else {
            hotkeyModifiers = HotkeyConfiguration.defaultModifiers
        }

        hotkeyKeyLabel = (try? container.decode(String.self, forKey: .hotkeyKeyLabel)) ?? resolvedKeyLabel
    }
}
