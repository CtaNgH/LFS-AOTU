#!/bin/bash

# 章节3构建脚本
# 负责软件包的下载与校验
# 严格参照 LFS-BOOK-SYSD-12.4 文档实现

# 设置脚本执行选项
set -euo pipefail

# 全局变量定义
LFS_ROOT="$(dirname "$(dirname "$(dirname "$(dirname "$(pwd)")")")")"
LFS_SCRIPTS="$LFS_ROOT/scripts"
LFS_PACKAGES="$LFS_ROOT/packages"
LFS_LOGS="$LFS_ROOT/logs"
LFS_STATUS="$LFS_ROOT/status"

# 下载目录
DOWNLOAD_DIR="$LFS_PACKAGES/sources"

# 日志文件
LOG_FILE="$LFS_LOGS/chapter3_$(date +%Y%m%d_%H%M%S).log"

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
    log "章节3构建失败，退出执行"
    exit 1
}

# 函数：检查下载目录
check_download_dir() {
    log "检查下载目录..."
    
    if [ ! -d "$DOWNLOAD_DIR" ]; then
        log "创建下载目录: $DOWNLOAD_DIR"
        mkdir -p "$DOWNLOAD_DIR" || error_exit "创建下载目录失败"
    fi
    
    log "下载目录检查完成"
}

# 函数：执行下载脚本
execute_download_script() {
    log "执行下载脚本..."
    
    local download_script="$LFS_SCRIPTS/download/download.sh"
    if [ ! -f "$download_script" ]; then
        error_exit "下载脚本不存在: $download_script"
    fi
    
    bash "$download_script" || error_exit "下载脚本执行失败"
    
    log "下载脚本执行完成"
}

# 函数：验证下载结果
verify_download() {
    log "验证下载结果..."
    
    # 检查下载目录中的文件数量
    local file_count=$(ls -la "$DOWNLOAD_DIR" | grep -v "^total" | grep -v "^\." | wc -l)
    log "下载目录中的文件数量: $file_count"
    
    if [ "$file_count" -eq 0 ]; then
        error_exit "下载目录为空，下载失败"
    fi
    
    log "下载结果验证完成"
}

# 主函数
main() {
    log "开始章节3构建过程..."
    log "章节3: 软件包下载与校验"
    
    # 检查下载目录
    check_download_dir
    
    # 执行下载脚本
    execute_download_script
    
    # 验证下载结果
    verify_download
    
    log "章节3构建完成！"
}

# 执行主函数
main
