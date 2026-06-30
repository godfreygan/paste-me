import SwiftUI
import AppKit

struct HotkeyRecorderView: View {
    @ObservedObject private var storage = StorageManager.shared
    @State private var isRecording = false

    var body: some View {
        HStack {
            Text("弹出选择面板")
            Spacer()
            Button(action: { isRecording.toggle() }) {
                Text(isRecording ? "请按下快捷键…" : storage.settings.hotkeyDisplayString)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isRecording ? Color.accentColor.opacity(0.15) : Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .background(
            HotkeyCaptureView(isRecording: $isRecording) { event in
                let modifiers = HotkeyConfiguration.carbonModifiers(from: event.modifierFlags)
                guard modifiers != 0 else { return }
                let label = HotkeyConfiguration.keyLabel(from: event)
                storage.updateHotkey(
                    keyCode: UInt32(event.keyCode),
                    modifiers: modifiers,
                    keyLabel: label
                )
                HotkeyManager.shared.registerFromSettings()
                isRecording = false
            }
        )
    }
}

private struct HotkeyCaptureView: NSViewRepresentable {
    @Binding var isRecording: Bool
    var onCapture: (NSEvent) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.update(isRecording: isRecording, onCapture: onCapture)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        private var monitor: Any?
        private var isRecording = false
        private var onCapture: ((NSEvent) -> Void)?

        func update(isRecording: Bool, onCapture: @escaping (NSEvent) -> Void) {
            self.onCapture = onCapture
            guard isRecording != self.isRecording else { return }
            self.isRecording = isRecording
            if isRecording {
                start()
            } else {
                stop()
            }
        }

        private func start() {
            stop()
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self else { return event }
                if event.keyCode == 53 {
                    self.isRecording = false
                    self.stop()
                    return nil
                }
                self.onCapture?(event)
                self.isRecording = false
                self.stop()
                return nil
            }
        }

        private func stop() {
            if let monitor {
                NSEvent.removeMonitor(monitor)
            }
            monitor = nil
        }

        deinit {
            stop()
        }
    }
}
