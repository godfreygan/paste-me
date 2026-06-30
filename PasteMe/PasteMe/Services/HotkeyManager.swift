import AppKit
import Carbon.HIToolbox

private func pasteMeHotKeyHandler(
    nextHandler: EventHandlerCallRef?,
    theEvent: EventRef?,
    userData: UnsafeMutableRawPointer?
) -> OSStatus {
    DispatchQueue.main.async {
        HotkeyManager.shared.handleHotkeyPressed()
    }
    return noErr
}

class HotkeyManager {
    static let shared = HotkeyManager()
    
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    
    var onHotkeyPressed: (() -> Void)?
    
    private init() {}
    
    func registerFromSettings() {
        register(
            keyCode: StorageManager.shared.settings.hotkeyKeyCode,
            modifiers: StorageManager.shared.settings.hotkeyModifiers
        )
    }
    
    func register(keyCode: UInt32, modifiers: UInt32) {
        unregister()
        
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            pasteMeHotKeyHandler,
            1,
            &eventType,
            nil,
            &eventHandler
        )
        
        let hotkeyID = EventHotKeyID(signature: fourCharCode("PME "), id: 1)
        RegisterEventHotKey(
            keyCode,
            modifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }
    
    func unregister() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }
    
    fileprivate func handleHotkeyPressed() {
        onHotkeyPressed?()
    }
    
    deinit {
        unregister()
    }
}

private func fourCharCode(_ string: String) -> OSType {
    var result: UInt32 = 0
    var length = 0
    for byte in string.utf8.prefix(4) {
        result = (result << 8) | UInt32(byte)
        length += 1
    }
    for _ in length..<4 {
        result = (result << 8) | 0x20
    }
    return OSType(result)
}
