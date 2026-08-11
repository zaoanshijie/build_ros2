#!/bin/bash

# 用法: ./list_all_deps.sh <目标目录> [输出文件]
# 示例: ./list_all_deps.sh ./install deps_list.txt

# 检查参数
if [ $# -lt 1 ]; then
    echo "用法: $0 <目标目录> [输出文件]"
    echo "示例: $0 ./install deps_list.txt"
    exit 1
fi

TARGET_DIR="$1"
OUTPUT_FILE="${2:-dependencies.txt}"  # 如果未指定，默认输出到 dependencies.txt

# 检查目标目录是否存在
if [ ! -d "$TARGET_DIR" ]; then
    echo "错误: 目录 '$TARGET_DIR' 不存在"
    exit 1
fi

# 检查 ldd 命令是否可用
if ! command -v ldd &> /dev/null; then
    echo "错误: ldd 命令未找到，请安装 binutils"
    exit 1
fi

echo "正在扫描目录: $TARGET_DIR"
echo "依赖列表将保存到: $OUTPUT_FILE"
echo "开始时间: $(date)"
echo "----------------------------------------"

# 清空或创建输出文件
> "$OUTPUT_FILE"

# 记录开始信息
echo "# 依赖分析报告" >> "$OUTPUT_FILE"
echo "# 扫描目录: $TARGET_DIR" >> "$OUTPUT_FILE"
echo "# 生成时间: $(date)" >> "$OUTPUT_FILE"
echo "# ========================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 统计变量
TOTAL_FILES=0
PROCESSED_FILES=0

# 找出所有 ELF 文件（可执行文件和动态库）
echo "正在查找 ELF 文件..."
ELF_FILES=$(find "$TARGET_DIR" -type f -exec file {} \; 2>/dev/null | grep -E "ELF.*(executable|shared object)" | cut -d: -f1)

# 计算总数
if [ -n "$ELF_FILES" ]; then
    TOTAL_FILES=$(echo "$ELF_FILES" | wc -l)
else
    TOTAL_FILES=0
fi

echo "找到 $TOTAL_FILES 个 ELF 文件"

# 如果没找到任何 ELF 文件
if [ -z "$ELF_FILES" ] || [ "$TOTAL_FILES" -eq 0 ]; then
    echo "警告: 在 '$TARGET_DIR' 中没有找到 ELF 文件（可执行文件或动态库）"
    echo "请确保目录中包含编译后的二进制文件"
    exit 0
fi

# 创建临时文件用于收集所有唯一的依赖
TEMP_DEPS=$(mktemp)
TEMP_NOT_FOUND=$(mktemp)

echo "" >> "$OUTPUT_FILE"
echo "## 详细依赖信息" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 遍历每个 ELF 文件
echo "$ELF_FILES" | while read -r FILE; do
    PROCESSED_FILES=$((PROCESSED_FILES + 1))
    
    # 显示进度
    echo "[$PROCESSED_FILES/$TOTAL_FILES] 分析: $FILE"
    
    # 写入文件头
    echo "### 文件: $FILE" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    # 使用 ldd 分析依赖
    if ldd "$FILE" 2>/dev/null >> "$OUTPUT_FILE"; then
        # 提取依赖库的路径（排除 linux-vdso、ld-linux 等）
        ldd "$FILE" 2>/dev/null | grep -E "=> /" | awk '{print $3}' >> "$TEMP_DEPS"
        
        # 提取未找到的依赖
        ldd "$FILE" 2>/dev/null | grep "not found" | awk '{print $1}' >> "$TEMP_NOT_FOUND"
    else
        echo "  (无法分析此文件，可能已损坏或不是有效的 ELF 文件)" >> "$OUTPUT_FILE"
    fi
    
    echo "" >> "$OUTPUT_FILE"
done

# 生成汇总信息
echo "" >> "$OUTPUT_FILE"
echo "## ========================================" >> "$OUTPUT_FILE"
echo "## 依赖汇总" >> "$OUTPUT_FILE"
echo "## ========================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 统计所有唯一的依赖库
echo "### 所有依赖库的完整路径 (已去重)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
sort -u "$TEMP_DEPS" 2>/dev/null | while read -r LIB; do
    if [ -n "$LIB" ]; then
        echo "$LIB" >> "$OUTPUT_FILE"
    fi
done

# 统计缺失的依赖
echo "" >> "$OUTPUT_FILE"
echo "### 缺失的依赖 (在系统中未找到)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
sort -u "$TEMP_NOT_FOUND" 2>/dev/null | while read -r MISSING; do
    if [ -n "$MISSING" ]; then
        echo "$MISSING" >> "$OUTPUT_FILE"
    fi
done

# 统计信息
UNIQUE_DEPS=$(sort -u "$TEMP_DEPS" 2>/dev/null | grep -c -v "^$" 2>/dev/null || echo 0)
UNIQUE_MISSING=$(sort -u "$TEMP_NOT_FOUND" 2>/dev/null | grep -c -v "^$" 2>/dev/null || echo 0)

echo "" >> "$OUTPUT_FILE"
echo "## ========================================" >> "$OUTPUT_FILE"
echo "## 统计信息" >> "$OUTPUT_FILE"
echo "## ========================================" >> "$OUTPUT_FILE"
echo "总分析文件数: $PROCESSED_FILES" >> "$OUTPUT_FILE"
echo "唯一依赖库数: $UNIQUE_DEPS" >> "$OUTPUT_FILE"
echo "缺失依赖库数: $UNIQUE_MISSING" >> "$OUTPUT_FILE"

# 清理临时文件 - 修复了这里的变量名错误
rm -f "$TEMP_DEPS" "$TEMP_NOT_FOUND"

echo "----------------------------------------"
echo "完成!"
echo "总分析文件数: $PROCESSED_FILES"
echo "结果已保存到: $OUTPUT_FILE"
echo "结束时间: $(date)"
