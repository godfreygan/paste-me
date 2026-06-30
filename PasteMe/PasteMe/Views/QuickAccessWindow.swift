import SwiftUI
import AppKit

private let panelCornerRadius: CGFloat = 12
private let panelWidth: CGFloat = 350
private let panelHeight: CGFloat = 360

// MARK: - Backdrop (click outside to dismiss)

private final class BackdropView: NSView {
    var onClick: (() -> Void)?

    override func mouseDown(with event: NSEvent) {
        onClick?()
    }
}

// MARK: - Rounded panel container

private struct RoundedPanelContainer<Content: View>: NSViewRepresentable {
    let cornerRadius: CGFloat
    let content: Content

    init(cornerRadius: CGFloat, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    func makeNSView(context: Context) -> NSVisualEffectView {
        let effectView = NSVisualEffectView()
        effectView.material = .menu
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.wantsLayer = true
        effectView.layer?.cornerRadius = cornerRadius
        effectView.layer?.masksToBounds = true

        let hosting = NSHostingView(rootView: content)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        effectView.addSubview(hosting)

        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: effectView.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: effectView.trailingAnchor),
            hosting.topAnchor.constraint(equalTo: effectView.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: effectView.bottomAnchor),
        ])

        return effectView
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        if let hosting = nsView.subviews.first as? NSHostingView<Content> {
            hosting.rootView = content
        }
        nsView.layer?.cornerRadius = cornerRadius
    }
}

// MARK: - Window Controller

class QuickAccessWindowController {
    static let shared = QuickAccessWindowController()

    private var panelWindow: NSWindow?
    private var backdropWindow: NSWindow?
    private var isShown = false

    private init() {}

    func toggle() {
        if isShown {
            hide()
        } else {
            show()
        }
    }

    func show() {
        if panelWindow == nil {
            createWindows()
        }

        guard let panelWindow, let backdropWindow else { return }

        PasteSimulator.rememberTargetApp()
        positionPanel(panelWindow)

        backdropWindow.orderFront(nil)
        panelWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        isShown = true
    }

    func hide() {
        panelWindow?.orderOut(nil)
        backdropWindow?.orderOut(nil)
        isShown = false
    }

    private func createWindows() {
        let backdrop = NSWindow(
            contentRect: combinedScreenFrame(),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        backdrop.isOpaque = false
        backdrop.backgroundColor = .clear
        backdrop.level = .floating
        backdrop.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        backdrop.ignoresMouseEvents = false
        backdrop.isReleasedWhenClosed = false

        let backdropView = BackdropView(frame: backdrop.contentView?.bounds ?? .zero)
        backdropView.autoresizingMask = [.width, .height]
        backdropView.onClick = { [weak self] in
            self?.hide()
        }
        backdrop.contentView = backdropView

        let panel = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue + 1)
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false

        let quickView = QuickAccessView(
            onDismiss: { [weak self] in self?.hide() },
            onSelect: { [weak self] item in self?.selectItem(item) }
        )
        let container = RoundedPanelContainer(cornerRadius: panelCornerRadius) {
            quickView
        }
        panel.contentView = NSView(frame: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight))
        let hosting = NSHostingView(rootView: container)
        hosting.frame = panel.contentView!.bounds
        hosting.autoresizingMask = [.width, .height]
        panel.contentView?.addSubview(hosting)

        backdropWindow = backdrop
        panelWindow = panel
    }

    private func positionPanel(_ window: NSWindow) {
        let mouseLocation = NSEvent.mouseLocation
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero

        var origin = NSPoint(
            x: mouseLocation.x - panelWidth / 2,
            y: mouseLocation.y - panelHeight - 10
        )
        origin.x = max(screenFrame.minX, min(origin.x, screenFrame.maxX - panelWidth))
        origin.y = max(screenFrame.minY, min(origin.y, screenFrame.maxY - panelHeight))
        window.setFrameOrigin(origin)
    }

    private func combinedScreenFrame() -> NSRect {
        NSScreen.screens.reduce(.zero) { $0.union($1.frame) }
    }

    private func selectItem(_ item: ClipItem) {
        hide()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            ClipboardManager.shared.copyAndPaste(item)
        }
    }
}

// MARK: - Keyboard Monitor

private final class QuickAccessKeyMonitor {
    private var monitor: Any?
    private var selectedIndex: Binding<Int>
    private let itemProvider: () -> [ClipItem]
    private let onDismiss: () -> Void
    private let onSelect: (ClipItem) -> Void

    init(
        selectedIndex: Binding<Int>,
        itemProvider: @escaping () -> [ClipItem],
        onDismiss: @escaping () -> Void,
        onSelect: @escaping (ClipItem) -> Void
    ) {
        self.selectedIndex = selectedIndex
        self.itemProvider = itemProvider
        self.onDismiss = onDismiss
        self.onSelect = onSelect
    }

    func start() {
        stop()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            let items = self.itemProvider()
            switch event.keyCode {
            case 53:
                DispatchQueue.main.async { self.onDismiss() }
                return nil
            case 126:
                DispatchQueue.main.async {
                    if self.selectedIndex.wrappedValue > 0 {
                        self.selectedIndex.wrappedValue -= 1
                    }
                }
                return nil
            case 125:
                DispatchQueue.main.async {
                    if self.selectedIndex.wrappedValue < items.count - 1 {
                        self.selectedIndex.wrappedValue += 1
                    }
                }
                return nil
            case 36:
                DispatchQueue.main.async {
                    let index = self.selectedIndex.wrappedValue
                    guard index < items.count else { return }
                    self.onSelect(items[index])
                }
                return nil
            default:
                return event
            }
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }
}

// MARK: - Quick Access View

struct QuickAccessView: View {
    @ObservedObject private var storage = StorageManager.shared
    @State private var selectedIndex = 0
    @State private var keyMonitor: QuickAccessKeyMonitor?
    var onDismiss: () -> Void
    var onSelect: (ClipItem) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            List {
                if storage.clips.isEmpty {
                    Text("暂无复制记录")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(Array(storage.clips.enumerated()), id: \.element.id) { index, item in
                        QuickAccessRow(item: item, isSelected: index == selectedIndex)
                            .id(index)
                            .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                            .listRowBackground(Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onSelect(item)
                            }
                            .onHover { hovering in
                                if hovering {
                                    selectedIndex = index
                                }
                            }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .onChange(of: selectedIndex) { _, newIndex in
                withAnimation {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
        .frame(width: panelWidth, height: panelHeight)
        .onAppear {
            selectedIndex = 0
            let monitor = QuickAccessKeyMonitor(
                selectedIndex: $selectedIndex,
                itemProvider: { storage.clips },
                onDismiss: onDismiss,
                onSelect: onSelect
            )
            monitor.start()
            keyMonitor = monitor
        }
        .onDisappear {
            keyMonitor?.stop()
            keyMonitor = nil
        }
    }
}

// MARK: - Quick Access Row

struct QuickAccessRow: View {
    let item: ClipItem
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.type.icon)
                .font(.system(size: 14))
                .foregroundColor(isSelected ? .white.opacity(0.85) : .secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayContent)
                    .font(.system(size: 13))
                    .lineLimit(2)

                Text(item.formattedTime)
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? .white.opacity(0.75) : .secondary)
            }

            Spacer()

            if item.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? .white : .orange)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor : Color.clear)
        )
        .foregroundColor(isSelected ? .white : .primary)
    }
}
