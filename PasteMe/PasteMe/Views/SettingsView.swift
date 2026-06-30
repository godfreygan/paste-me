import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject private var storage = StorageManager.shared
    @State private var maxHistoryText = ""
    @Environment(\.dismiss) private var dismiss

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { storage.settings.launchAtLogin },
            set: { storage.setLaunchAtLogin($0) }
        )
    }

    private var playSoundBinding: Binding<Bool> {
        Binding(
            get: { storage.settings.playSoundOnCopy },
            set: { storage.setPlaySoundOnCopy($0) }
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("设置")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("完成") {
                    closeSettingsWindow()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Divider()
            
            Form {
                Section("历史记录") {
                    HStack {
                        Text("最大历史条数")
                        Spacer()
                        TextField("", text: $maxHistoryText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                            .onSubmit {
                                if let count = Int(maxHistoryText) {
                                    storage.updateMaxHistoryCount(count)
                                }
                            }
                        Text("条")
                            .foregroundColor(.secondary)
                    }
                    
                    Text("范围: \(AppSettings.maxHistoryRange.lowerBound) - \(AppSettings.maxHistoryRange.upperBound)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("权限") {
                    HStack {
                        Text("辅助功能")
                        Spacer()
                        if PasteSimulator.isAccessibilityTrusted {
                            Label("已授权", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Label("未授权", systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                        }
                    }

                    Text("「选中即粘贴」需要辅助功能权限。macOS 按**应用路径**记录授权；每次从 GitHub 下载新版本后，需重新勾选 PasteMe。")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("当前路径：\(Bundle.main.bundlePath)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)

                    if !PasteSimulator.isAccessibilityTrusted {
                        Button("请求授权…") {
                            PasteSimulator.requestAccessibilityPermissionIfNeeded()
                        }

                        Button("打开系统设置…") {
                            PasteSimulator.openAccessibilitySettings()
                        }
                    } else {
                        Button("打开系统设置…") {
                            PasteSimulator.openAccessibilitySettings()
                        }
                    }

                    Text("若系统设置中已勾选但仍无法粘贴：删除列表中的旧 PasteMe 条目 → 重新添加当前路径的应用 → 完全退出并重启 PasteMe。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("通用") {
                    HotkeyRecorderView()

                    Toggle("开机自启动", isOn: launchAtLoginBinding)
                    Toggle("复制时播放声音", isOn: playSoundBinding)
                }
                
                Section("数据") {
                    HStack {
                        Text("当前记录数")
                        Spacer()
                        Text("\(storage.clips.count) 条")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("置顶数")
                        Spacer()
                        Text("\(storage.pinnedClips.count) 条")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("清空所有历史记录") {
                        storage.clearAllHistory()
                    }
                    .foregroundColor(.red)
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
        }
        .frame(width: 450, height: 400)
        .onAppear {
            maxHistoryText = "\(storage.settings.maxHistoryCount)"
        }
        .onDisappear {
            if let count = Int(maxHistoryText) {
                storage.updateMaxHistoryCount(count)
            }
        }
    }

    private func closeSettingsWindow() {
        if let window = NSApp.windows.first(where: { $0.title == "PasteMe 设置" }) {
            window.close()
        } else {
            dismiss()
        }
    }
}
