#!/bin/bash

# TubeSavely 视图文件整合脚本
# 功能: 删除所有 *_view_unified.dart 和 *_view_ios.dart 文件
# 注意: 执行前请备份项目！

set -e

PROJECT_ROOT="/Users/Waiting/AndroidStudioProjects/TubeSavely"
MODULES_DIR="$PROJECT_ROOT/lib/app/modules"

echo "========================================="
echo "TubeSavely 视图文件整合"
echo "========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 统计变量
DELETED_UNIFIED=0
DELETED_IOS=0
TOTAL_DELETED=0

# Step 1: 创建备份
echo -e "${YELLOW}[1/3] 创建备份...${NC}"
BACKUP_DIR="$PROJECT_ROOT/views_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# 备份所有 *_view_unified.dart
find "$MODULES_DIR" -name "*_view_unified.dart" -exec cp {} "$BACKUP_DIR/" \;
echo "✓ 已备份 unified 文件到: $BACKUP_DIR"

# Step 2: 删除 *_view_unified.dart 文件
echo ""
echo -e "${YELLOW}[2/3] 删除 *_view_unified.dart 文件...${NC}"
for file in $(find "$MODULES_DIR" -name "*_view_unified.dart"); do
    echo "  删除: $file"
    rm "$file"
    ((DELETED_UNIFIED++))
done

if [ $DELETED_UNIFIED -gt 0 ]; then
    echo -e "${GREEN}✓ 已删除 $DELETED_UNIFIED 个 unified 文件${NC}"
else
    echo -e "${YELLOW}⚠ 未找到 unified 文件${NC}"
fi

# Step 3: 删除 *_view_ios.dart 文件 (可选)
echo ""
echo -e "${YELLOW}[3/3] 删除 *_view_ios.dart 文件...${NC}"
echo -e "${YELLOW}是否删除 iOS 特定文件? (y/n) ${NC}"
read -r DELETE_IOS

if [ "$DELETE_IOS" == "y" ] || [ "$DELETE_IOS" == "Y" ]; then
    for file in $(find "$MODULES_DIR" -name "*_view_ios.dart"); do
        echo "  删除: $file"
        rm "$file"
        ((DELETED_IOS++))
    done
    
    if [ $DELETED_IOS -gt 0 ]; then
        echo -e "${GREEN}✓ 已删除 $DELETED_IOS 个 iOS 文件${NC}"
    else
        echo -e "${YELLOW}⚠ 未找到 iOS 文件${NC}"
    fi
else
    echo -e "${YELLOW}⚠ 跳过删除 iOS 文件${NC}"
fi

# 计算总数
((TOTAL_DELETED = DELETED_UNIFIED + DELETED_IOS))

# 总结
echo ""
echo "========================================="
echo -e "${GREEN}整合完成！${NC}"
echo "========================================="
echo "删除统计:"
echo "  - Unified 文件: $DELETED_UNIFIED"
echo "  - iOS 文件: $DELETED_IOS"
echo "  - 总计删除: $TOTAL_DELETED 个文件"
echo ""
echo "备份位置: $BACKUP_DIR"
echo ""
echo "下一步:"
echo "1. 逐个页面重写 *_view.dart，使用 AdaptiveScaffold"
echo "2. 在 iOS 和 Android 上测试"
echo "3. 确保所有功能正常工作"
echo ""
echo -e "${YELLOW}提示: 如需恢复，请从备份目录恢复文件${NC}"
echo ""
