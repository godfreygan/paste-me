# PasteMe - Mac 剪贴板历史管理器

一个轻量级的 macOS 剪贴板历史管理工具，帮助你轻松管理和检索复制过的内容。

## 功能特性

- **菜单栏常驻** - 点击状态栏图标快速访问剪贴板历史
- **全局快捷键** - 使用 `⌘⇧V` 快速打开搜索窗口
- **自动记录** - 自动捕获复制的文本、图片和文件路径
- **智能排序** - 按时间倒序排列，最新的在最前
- **置顶收藏** - 常用内容可置顶，不受数量限制
- **搜索功能** - 快速搜索历史内容
- **数量限制** - 默认保留最近20条，可在设置中调整（10-1000）
- **自动清理** - 超出限制时自动删除最旧的记录

## 系统要求

- macOS 15.0 (Sequoia) 或更高版本
- Xcode 15.0 或更高版本（用于编译）

## 安装方法

### 方法一：使用 Xcode 编译

1. 安装 [XcodeGen](https://github.com/yonaskolb/XcodeGen)（如果尚未安装）：
   ```bash
   brew install xcodegen
   ```

2. 生成 Xcode 项目：
   ```bash
   cd PasteMe
   xcodegen generate
   ```

3. 打开项目并编译：
   ```bash
   open PasteMe.xcodeproj
   ```
   然后在 Xcode 中按 `⌘R` 运行

### 方法二：命令行编译

```bash
cd PasteMe
xcodebuild -project PasteMe.xcodeproj -scheme PasteMe -configuration Release build
```

## 使用说明

### 基本使用

1. 启动 PasteMe 后，它会在菜单栏显示一个剪贴板图标
2. 复制任何内容（文本、图片、文件），PasteMe 会自动记录
3. 点击菜单栏图标查看历史记录
4. 点击任意历史项即可复制到剪贴板

### 快捷键

| 快捷键 | 功能 |
|--------|------|
| `⌘⇧V` | 打开快速访问窗口 |
| `↑↓` | 在快速访问窗口中导航 |
| `Enter` | 选择并复制 |
| `Esc` | 关闭窗口 |

### 置顶功能

- 鼠标悬停在历史项上，点击 📌 图标即可置顶
- 置顶内容不会被自动删除
- 再次点击可取消置顶

### 设置

点击菜单栏图标底部的 ⚙️ 图标打开设置：

- **最大历史条数**：设置保留的历史记录数量（10-1000）
- **开机自启动**：是否在登录时自动启动
- **复制声音**：复制时是否播放提示音

## 数据存储

数据存储位置：`~/Library/Application Support/PasteMe/`

```
PasteMe/
├── settings.json    # 应用设置
├── clips.json       # 历史记录
├── pinned.json      # 置顶内容
└── images/          # 图片缓存
```

## 权限说明

PasteMe 需要以下权限：

- **辅助功能权限**：用于全局快捷键功能
  - 首次使用时会提示授权
  - 也可在 系统设置 > 隐私与安全性 > 辅助功能 中手动添加

## 常见问题

### Q: 为什么复制的内容没有被记录？

A: 请检查：
1. PasteMe 是否正在运行（菜单栏是否有图标）
2. 是否有足够的权限

### Q: 如何修改快捷键？

A: 目前快捷键固定为 `⌘⇧V`，后续版本将支持自定义。

### Q: 历史记录会同步到其他设备吗？

A: 目前不支持 iCloud 同步，数据仅保存在本地。

## 开发

### 项目结构

```
PasteMe/
├── PasteMe/
│   ├── App/
│   │   ├── PasteMeApp.swift      # 应用入口
│   │   └── AppDelegate.swift     # 菜单栏管理
│   ├── Models/
│   │   ├── ClipItem.swift        # 剪贴板项模型
│   │   ├── ClipType.swift        # 类型枚举
│   │   └── AppSettings.swift     # 应用设置
│   ├── Services/
│   │   ├── ClipboardManager.swift # 剪贴板监听
│   │   ├── StorageManager.swift  # 文件存储
│   │   └── HotkeyManager.swift   # 全局快捷键
│   ├── Views/
│   │   ├── MenuBarView.swift     # 主视图
│   │   ├── QuickAccessWindow.swift # 快速访问窗口
│   │   ├── SettingsView.swift    # 设置界面
│   │   ├── ClipItemRow.swift     # 列表项
│   │   └── SearchBar.swift       # 搜索栏
│   └── Resources/
│       └── Assets.xcassets
├── project.yml                    # XcodeGen 配置
└── README.md
```

## 许可证

MIT License

## 反馈

如有问题或建议，请提交 Issue。
