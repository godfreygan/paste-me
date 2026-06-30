# PasteMe 安装指南（无需本地 Xcode）

Mac 原生 Swift 应用必须用 **Xcode SDK** 编译，仅有 Command Line Tools 无法完成打包。  
**系统要求：macOS 15.0 (Sequoia) 或更高版本**（不支持 macOS 14 及更早版本）。

下面提供 **无需安装 Xcode** 的两种方案。

---

## 方案一：GitHub Actions 云端打包（推荐）

GitHub 提供免费的 macOS 构建环境，自带完整 Xcode。

### 步骤

**1. 初始化 Git 并推送到 GitHub**

```bash
cd /Users/godfrey/data/go/src/godfreygan/pasteMe

git init
git add .
git commit -m "Initial commit: PasteMe clipboard manager"

# 在 GitHub 上创建仓库后执行（替换为你的用户名）
git remote add origin https://github.com/YOUR_USERNAME/paste-me.git
git branch -M main
git push -u origin main
```

**2. 触发自动构建**

推送代码后，GitHub Actions 会自动运行。也可以手动触发：

- 打开 GitHub 仓库 → **Actions** 标签
- 选择 **Build PasteMe** → **Run workflow**

**3. 下载安装包**

构建完成后（约 3–5 分钟）：

- 进入该次 workflow 运行详情
- 在 **Artifacts** 区域下载 **PasteMe-macOS-installer**
- 解压得到 `PasteMe-1.0.0-macOS.zip`

**4. 安装**

```text
1. 解压 ZIP
2. 将 PasteMe.app 拖到「应用程序」文件夹
3. 首次打开见下方「无法验证开发者」说明
4. 系统设置 → 隐私与安全性 → 辅助功能 → 添加 PasteMe
```

---

## 无法验证开发者（Gatekeeper 提示）

首次打开时可能看到：

> Apple 无法验证「PasteMe.app」是否包含可能危害 Mac 安全或泄漏隐私的恶意软件。

这是正常现象。PasteMe 通过 GitHub Actions 构建，**未做 Apple 官方签名和公证**，macOS 会拦截直接双击打开，**不代表应用有毒**。

### 方法一：右键打开（推荐）

1. 在「应用程序」中找到 `PasteMe.app`
2. **按住 Control 键点击**（或右键）→ 选择 **打开**
3. 在弹窗中再次点击 **打开**
4. 之后可直接双击启动，无需重复操作

### 方法二：系统设置中允许

1. 先双击 `PasteMe.app`（会被拦截）
2. 打开 **系统设置** → **隐私与安全性**
3. 向下滚动，找到类似「已阻止 PasteMe.app」的提示
4. 点击 **仍要打开**

### 方法三：移除隔离属性（仍建议用方法一）

若从浏览器/GitHub 下载，文件可能带有隔离标记。可在终端执行：

```bash
xattr -cr /Applications/PasteMe.app
```

然后仍建议 **右键 → 打开** 首次运行。

### 如何彻底消除此提示？

需要 **Apple 开发者账号**（约 ¥688/年），对应用进行 **代码签名 + 公证（Notarization）**。个人自用通常不必，右键打开即可。

---

## 方案二：请有 Xcode 的朋友帮忙打包

把项目文件夹发给已安装 Xcode 的同事/朋友，让对方执行：

```bash
cd PasteMe
chmod +x package-xcode.sh
./package-xcode.sh
```

完成后在 `PasteMe/dist/` 目录会生成：

- `PasteMe.app` — 可直接运行的应用
- `PasteMe-1.0.0-macOS.zip` — 可分享的安装包

---

## 为什么本地无法打包？

| 工具 | 能否打包 PasteMe |
|------|------------------|
| 完整 Xcode | ✅ 可以 |
| 仅 Command Line Tools | ❌ 不行（缺少 GUI 应用 SDK） |
| GitHub Actions (macOS) | ✅ 可以（已配置好） |

若本地仅有 Command Line Tools（无完整 Xcode），推荐使用 **方案一**。

---

## 首次运行注意事项

1. **Gatekeeper**：见上文「无法验证开发者」章节，**右键 → 打开** 即可
2. **辅助功能权限**：选择面板的自动粘贴需要在 系统设置 → 隐私与安全性 → 辅助功能 中添加 PasteMe（全局快捷键 `⌘⇧V` 通常无需此权限）
3. **菜单栏图标**：启动后会在顶部状态栏显示剪贴板图标

---

## 常见问题

**Q: GitHub Actions 是免费的吗？**  
A: 公开仓库完全免费；私有仓库每月有免费额度（一般足够个人使用）。

**Q: 能否做成 .dmg 安装镜像？**  
A: 当前输出为 ZIP + .app，双击 .app 即可使用，与 DMG 效果相同。

**Q: 以后如何更新？**  
A: 修改代码后 `git push`，重新下载 Artifacts 中的最新 ZIP 即可。
