#!/bin/bash

# 软件包下载脚本
# 负责软件包的自动下载与校验
# 严格参照 LFS-BOOK-SYSD-12.4 文档实现

# 设置脚本执行选项
set -euo pipefail

# 全局变量定义
LFS_ROOT="$(dirname "$(dirname "$(dirname "$(pwd)")")")"
LFS_SCRIPTS="$LFS_ROOT/scripts"
LFS_PACKAGES="$LFS_ROOT/packages"
LFS_LOGS="$LFS_ROOT/logs"
LFS_STATUS="$LFS_ROOT/status"

# 下载目录
DOWNLOAD_DIR="$LFS_PACKAGES/sources"

# 日志文件
LOG_FILE="$LFS_LOGS/download_$(date +%Y%m%d_%H%M%S).log"

# CSV文件路径
CSV_FILE="$LFS_PACKAGES/packages.csv"

# 函数：记录日志
log() {
    local message="$1"
    local timestamp="$(date +%Y-%m-%d %H:%M:%S)"
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

# 函数：错误处理
error_exit() {
    local message="$1"
    log "ERROR: $message"
    log "下载过程失败，退出执行"
    exit 1
}

# 函数：检查必要工具
check_tools() {
    log "检查必要的下载工具..."
    
    local required_tools=("wget" "md5sum" "awk" "sed")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            error_exit "缺少必要工具: $tool"
        fi
    done
    
    log "必要工具检查完成"
}

# 函数：创建下载目录
create_download_dir() {
    log "创建下载目录..."
    
    if [ ! -d "$DOWNLOAD_DIR" ]; then
        mkdir -p "$DOWNLOAD_DIR" || error_exit "创建下载目录失败"
    fi
    
    log "下载目录创建完成: $DOWNLOAD_DIR"
}

# 函数：从CSV文件读取软件包信息
read_packages() {
    log "从CSV文件读取软件包信息..."
    
    if [ ! -f "$CSV_FILE" ]; then
        error_exit "CSV文件不存在: $CSV_FILE"
    fi
    
    # 跳过表头，读取所有软件包信息
    packages=()
    while IFS=, read -r name version url md5 type || [ -n "$name" ]; do
        # 跳过表头
        if [ "$name" = "name" ]; then
            continue
        fi
        # 跳过空行
        if [ -z "$name" ]; then
            continue
        fi
        packages+=("$name:$version:$url:$md5:$type")
    done < "$CSV_FILE"
    
    log "读取到 ${#packages[@]} 个软件包"
}

# 函数：下载软件包
download_package() {
    local package_info="$1"
    IFS=":" read -r name version url md5 type <<< "$package_info"
    
    log "开始下载软件包: $name-$version"
    
    # 构建文件名
    local filename=$(basename "$url")
    local filepath="$DOWNLOAD_DIR/$filename"
    
    # 检查文件是否已存在
    if [ -f "$filepath" ]; then
        log "文件已存在: $filename，跳过下载"
        return 0
    fi
    
    # 执行下载
    log "下载地址: $url"
    wget --continue --output-document="$filepath" "$url" || {
        log "下载失败: $name-$version"
        # 删除部分下载的文件
        if [ -f "$filepath" ]; then
            rm -f "$filepath"
        fi
        return 1
    }
    
    log "下载完成: $filename"
    return 0
}

# 函数：校验软件包
verify_package() {
    local package_info="$1"
    IFS=":" read -r name version url md5 type <<< "$package_info"
    
    # 构建文件名
    local filename=$(basename "$url")
    local filepath="$DOWNLOAD_DIR/$filename"
    
    # 检查文件是否存在
    if [ ! -f "$filepath" ]; then
        log "文件不存在: $filename，跳过校验"
        return 1
    fi
    
    # 如果没有MD5值，跳过校验
    if [ -z "$md5" ] || [ "$md5" = "" ]; then
        log "没有MD5值，跳过校验: $filename"
        return 0
    fi
    
    log "开始校验软件包: $filename"
    
    # 计算MD5值
    local calculated_md5=$(md5sum "$filepath" | awk '{print $1}')
    
    # 比较MD5值
    if [ "$calculated_md5" = "$md5" ]; then
        log "校验成功: $filename"
        return 0
    else
        log "校验失败: $filename"
        log "期望MD5: $md5"
        log "实际MD5: $calculated_md5"
        # 删除校验失败的文件
        rm -f "$filepath"
        return 1
    fi
}

# 主函数
main() {
    log "开始软件包下载过程..."
    log "下载目录: $DOWNLOAD_DIR"
    
    # 检查必要工具
    check_tools
    
    # 创建下载目录
    create_download_dir
    
    # 读取软件包信息
    read_packages
    
    # 下载并校验每个软件包
    local success_count=0
    local fail_count=0
    
    for package in "${packages[@]}"; do
        if download_package "$package" && verify_package "$package"; then
            success_count=$((success_count + 1))
        else
            fail_count=$((fail_count + 1))
        fi
        echo "" >> "$LOG_FILE"
    done
    
    log "软件包下载与校验完成"
    log "成功: $success_count 个"
    log "失败: $fail_count 个"
    
    if [ "$fail_count" -gt 0 ]; then
        error_exit "部分软件包下载或校验失败"
    fi
    
    log "所有软件包下载与校验成功"
}

# 执行主函数
main
