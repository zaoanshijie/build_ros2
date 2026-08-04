#!/bin/bash -e
# 计算指定文件的哈希值，支持通配符和排除规则

# 显示使用帮助
show_help() {
    cat << EOF
用法: $0 [选项] [文件模式...]

计算指定文件的哈希值（MD5），支持通配符和排除规则。

选项:
  -h, --help          显示此帮助信息
  -e, --exclude PATTERN  排除匹配的文件（可多次使用）
  -m, --method METHOD 哈希算法: md5, sha1, sha256 (默认: md5)

示例:
  $0 "*.sh"
  $0 "*.sh" "*.yaml" -e "exclude.sh" -e "test_*.yaml"
  $0 Dockerfile build.sh "*.cmake"

EOF
}

# 初始化变量
EXCLUDE_PATTERNS=()
FILE_PATTERNS=()
HASH_METHOD="md5"
WORK_DIR="."

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -e|--exclude)
            EXCLUDE_PATTERNS+=("$2")
            shift 2
            ;;
        -m|--method)
            HASH_METHOD="$2"
            shift 2
            ;;
        -w|--work)
            WORK_DIR="$2"
            shift 2
            ;;
        -*)
            echo "错误: 未知选项 $1" >&2
            show_help
            exit 1
            ;;
        *)
            FILE_PATTERNS+=("$1")
            shift
            ;;
    esac
done

# 检查是否有文件模式
# if [ ${#FILE_PATTERNS[@]} -eq 0 ]; then
#     echo "错误: 至少需要一个文件模式" >&2
#     show_help
#     exit 1
# fi

# 验证哈希方法
case $HASH_METHOD in
    md5|sha1|sha256)
        ;;
    *)
        echo "错误: 不支持的哈希方法: $HASH_METHOD" >&2
        echo "支持: md5, sha1, sha256" >&2
        exit 1
        ;;
esac

# 选择哈希命令
case $HASH_METHOD in
    md5)
        HASH_CMD="md5sum"
        ;;
    sha1)
        HASH_CMD="sha1sum"
        ;;
    sha256)
        HASH_CMD="sha256sum"
        ;;
esac

# 检查哈希命令是否存在
if ! command -v $HASH_CMD &> /dev/null; then
    echo "错误: $HASH_CMD 命令不存在" >&2
    exit 1
fi

# 获取脚本自身名称（用于默认排除）
SCRIPT_NAME=$(basename "$0")

# 构建 find 命令的文件名条件
build_find_name_patterns() {
    local patterns=("$@")
    local result=""
    local first=true
    
    for pattern in "${patterns[@]}"; do
        if [ "$first" = true ]; then
            result="-name \"$pattern\""
            first=false
        else
            result="$result -o -name \"$pattern\""
        fi
    done
    
    echo "$result"
}

# 构建排除条件（包括默认排除自身）
build_exclude_patterns() {
    local patterns=("$@")
    # 默认排除自身
    local result="! -name \"$SCRIPT_NAME\""
    
    # 添加用户指定的排除规则
    for pattern in "${patterns[@]}"; do
        result="$result ! -name \"$pattern\""
    done
    
    echo "$result"
}

# 获取文件列表
get_file_list() {
    local patterns=("$@")
    local exclude_patterns=("${EXCLUDE_PATTERNS[@]}")
    
    # 构建 find 命令
    local find_cmd="find ${WORK_DIR} -type f"
    
    # 添加文件名条件
    if [ ${#patterns[@]} -gt 0 ]; then
        local name_conditions=$(build_find_name_patterns "${patterns[@]}")
        find_cmd="$find_cmd \\( $name_conditions \\)"
    fi
    
    # 添加排除条件（自动包含自身）
    local exclude_conditions=$(build_exclude_patterns "${exclude_patterns[@]}")
    find_cmd="$find_cmd $exclude_conditions"
    
    # 执行 find 并返回文件列表
    eval "$find_cmd" 2>/dev/null | sort
}

# 计算文件哈希
calculate_hash() {
    local files=("$@")
    
    if [ ${#files[@]} -eq 0 ]; then
        echo ""
        return
    fi
    
    # 计算每个文件的哈希，然后排序汇总
    local temp_file=$(mktemp)
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            $HASH_CMD "$file" 2>/dev/null >> "$temp_file"
        fi
    done
    
    # 检查是否有文件内容
    if [ ! -s "$temp_file" ]; then
        rm -f "$temp_file"
        echo ""
        return
    fi
    
    sort "$temp_file" | $HASH_CMD | cut -d' ' -f1
    rm -f "$temp_file"
}

# 主逻辑
main() {
    # 获取文件列表
    local file_list=()
    while IFS= read -r file; do
        if [ -n "$file" ]; then
            file_list+=("$file")
        fi
    done < <(get_file_list "${FILE_PATTERNS[@]}")
    
    # 检查是否找到文件
    if [ ${#file_list[@]} -eq 0 ]; then
        echo "错误: 没有找到匹配的文件" >&2
        exit 1
    fi
    
    # 计算哈希
    local hash_value=$(calculate_hash "${file_list[@]}")
    
    # 检查是否成功计算哈希
    if [ -z "$hash_value" ]; then
        echo "错误: 计算哈希失败" >&2
        exit 1
    fi
    
    # 只输出哈希值
    echo "$hash_value"
    exit 0
}

# 执行主函数
main