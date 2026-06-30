#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_DIR="$ROOT_DIR"
PBXPROJ="$PROJECT_DIR/PasteMe.xcodeproj/project.pbxproj"
SCHEME="$PROJECT_DIR/PasteMe.xcodeproj/xcshareddata/xcschemes/PasteMe.xcscheme"

echo "=== 项目结构校验 ==="

required_paths=(
    "$PROJECT_DIR/PasteMe.xcodeproj"
    "$SCHEME"
    "$PROJECT_DIR/PasteMe/Info.plist"
    "$PROJECT_DIR/PasteMe/App/PasteMeApp.swift"
    "$PROJECT_DIR/package-xcode.sh"
)

for path in "${required_paths[@]}"; do
    if [ ! -e "$path" ]; then
        echo "错误: 缺少必要文件 $path"
        exit 1
    fi
    echo "  OK  $path"
done

echo ""
echo "=== Swift 源文件与 Xcode 工程一致性 ==="

missing=0
while IFS= read -r swift_file; do
    filename=$(basename "$swift_file")
    if ! grep -q "$filename" "$PBXPROJ"; then
        echo "  错误: $filename 未加入 Xcode 工程"
        missing=1
    else
        echo "  OK  $filename"
    fi
done < <(find "$PROJECT_DIR/PasteMe" -name '*.swift' | sort)

if [ "$missing" -ne 0 ]; then
    exit 1
fi

echo ""
echo "=== 禁止使用的 API 检查 ==="

if grep -rq 'onKeyPress\|import LaunchAtLogin' "$PROJECT_DIR/PasteMe" --include '*.swift'; then
    echo "错误: 发现已知不兼容 API"
    exit 1
fi
echo "  OK  未发现 onKeyPress / LaunchAtLogin"

if grep -q 'ASSETCATALOG_COMPILER_APPICON_NAME' "$PBXPROJ"; then
    echo "错误: 仍配置了空 AppIcon"
    exit 1
fi
echo "  OK  未配置 AppIcon 编译项"

echo ""
echo "=== 全部校验通过 ==="
