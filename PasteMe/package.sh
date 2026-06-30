#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

APP_NAME="PasteMe"
VERSION="1.0.0"
BUILD_DIR="$ROOT_DIR/.build/release"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
ZIP_PATH="$DIST_DIR/${APP_NAME}-${VERSION}-macOS.zip"

echo "=== PasteMe 打包脚本 ==="
echo ""

# 1. 编译
echo "[1/4] 编译 Release 版本..."
swift build -c release

# 2. 创建 .app 目录结构
echo "[2/4] 创建 App Bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# 3. 复制二进制和资源
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "PasteMe/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
cp -R "PasteMe/Resources/Assets.xcassets" "$APP_BUNDLE/Contents/Resources/" 2>/dev/null || true

# 修正 Info.plist 中的变量
/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable $APP_NAME" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.pasteme.app" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleName $APP_NAME" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion 1" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :LSMinimumSystemVersion 15.0" "$APP_BUNDLE/Contents/Info.plist"

# 4. 打包 zip
echo "[3/4] 打包 ZIP..."
mkdir -p "$DIST_DIR"
rm -f "$ZIP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$ZIP_PATH"

echo "[4/4] 完成!"
echo ""
echo "安装包位置:"
echo "  App:  $APP_BUNDLE"
echo "  ZIP:  $ZIP_PATH"
echo ""
echo "安装方法:"
echo "  1. 解压 ZIP 文件"
echo "  2. 将 PasteMe.app 拖到「应用程序」文件夹"
echo "  3. 首次打开时，右键点击 -> 打开（绕过 Gatekeeper）"
echo "  4. 在 系统设置 -> 隐私与安全性 -> 辅助功能 中授权 PasteMe"
echo ""
