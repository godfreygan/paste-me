#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

APP_NAME="PasteMe"
VERSION="1.0.0"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
ZIP_PATH="$DIST_DIR/${APP_NAME}-${VERSION}-macOS.zip"
DERIVED_DATA="$ROOT_DIR/.derivedData"
EXECUTABLE="$APP_BUNDLE/Contents/MacOS/$APP_NAME"

echo "=== PasteMe Xcode 打包脚本 ==="
echo ""

if ! xcodebuild -version &>/dev/null; then
    echo "错误: 需要完整 Xcode（不是 Command Line Tools）"
    exit 1
fi

XCODE_VERSION=$(xcodebuild -version 2>&1 | sed -n '1p')
echo "Xcode: $XCODE_VERSION"
echo ""

echo "[1/6] 校验项目..."
chmod +x scripts/validate-project.sh
./scripts/validate-project.sh

echo ""
echo "[2/6] 检查 Scheme..."
xcodebuild -list -project PasteMe.xcodeproj

echo ""
echo "[3/6] 编译 Release 版本..."
xcodebuild \
    -project PasteMe.xcodeproj \
    -scheme PasteMe \
    -configuration Release \
    -destination 'generic/platform=macOS' \
    -derivedDataPath "$DERIVED_DATA" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    ONLY_ACTIVE_ARCH=NO \
    build

BUILT_APP="$DERIVED_DATA/Build/Products/Release/$APP_NAME.app"

if [ ! -d "$BUILT_APP" ]; then
    echo "错误: 找不到编译产物 $BUILT_APP"
    exit 1
fi

echo ""
echo "[4/6] 复制 App Bundle..."
mkdir -p "$DIST_DIR"
rm -rf "$APP_BUNDLE"
cp -R "$BUILT_APP" "$APP_BUNDLE"

echo "[5/6] 验证可执行文件..."
if [ ! -f "$EXECUTABLE" ]; then
    echo "错误: 找不到可执行文件 $EXECUTABLE"
    exit 1
fi
chmod +x "$EXECUTABLE"
file "$EXECUTABLE"

echo "[6/6] 打包 ZIP..."
rm -f "$ZIP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$ZIP_PATH"

echo ""
echo "完成!"
echo "  App: $APP_BUNDLE"
echo "  ZIP: $ZIP_PATH"
echo ""
