import AppKit
import Carbon.HIToolbox
import Foundation

enum HotkeyConfiguration {
    static let defaultKeyCode: UInt32 = 9
    static let defaultModifiers: UInt32 = UInt32(cmdKey | shiftKey)
    static let defaultKeyLabel = "V"

    static func displayString(keyCode: UInt32, modifiers: UInt32, keyLabel: String) -> String {
        var parts: [String] = []
        if modifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("⌥") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("⇧") }
        if modifiers & UInt32(cmdKey) != 0 { parts.append("⌘") }
        parts.append(keyLabel)
        return parts.joined()
    }

    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var modifiers: UInt32 = 0
        if flags.contains(.command) { modifiers |= UInt32(cmdKey) }
        if flags.contains(.shift) { modifiers |= UInt32(shiftKey) }
        if flags.contains(.option) { modifiers |= UInt32(optionKey) }
        if flags.contains(.control) { modifiers |= UInt32(controlKey) }
        return modifiers
    }

    static func keyLabel(from event: NSEvent) -> String {
        if let chars = event.charactersIgnoringModifiers?.uppercased(), !chars.isEmpty {
            return chars
        }
        return "Key\(event.keyCode)"
    }
}
