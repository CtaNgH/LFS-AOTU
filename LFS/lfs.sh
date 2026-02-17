#!/bin/bash

# LFS 构建主控制脚本
# 负责整体流程调度与环境管理
# 严格参照 LFS-BOOK-SYSD-12.4 文档实现

# 设置脚本执行选项
set -euo pipefail

# 全局变量定义
LFS_ROOT="$(pwd)"
LFS_SCRIPTS="$LFS_ROOT/scripts"
LFS_PACKAGES="$LFS_ROOT/packages"
LFS_LOGS="$LFS_ROOT/logs"
LFS_CONFIG="$LFS_ROOT/config"
LFS_STATUS="$LFS_ROOT/status"

# 目标系统分区信息
LFS_PARTITION="/dev/nvme1n1p5"
LFS_MOUNT="/mnt/lfs"

# 日志文件
LOG_FILE="$LFS_LOGS/build_$(date +%Y%m%d_%H%M%S).log"

# 状态标记文件目录
mkdir -p "$LFS_STATUS"

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
    log "构建过程失败，退出执行"
    exit 1
}

# 函数：检查状态
check_status() {
    local step="$1"
    if [ -f "$LFS_STATUS/$step" ]; then
        log "步骤 $step 已经完成，跳过执行"
        return 0
    else
        return 1
    fi
}

# 函数：标记状态
mark_status() {
    local step="$1"
    touch "$LFS_STATUS/$step"
    log "步骤 $step 执行完成，标记状态"
}

# 函数：检查宿主系统
check_host_system() {
    log "检查宿主系统环境..."
    
    # 检查是否为 Ubuntu 24.04.4 LTS
    if ! grep -q "Ubuntu 24.04.4 LTS" /etc/issue && ! grep -q "Ubuntu 24.04.4 LTS" /etc/os-release; then
        error_exit "当前系统不是 Ubuntu 24.04.4 LTS"
    fi
    
    # 检查硬件架构
    if [ "$(uname -m)" != "x86_64" ]; then
        error_exit "当前系统架构不是 x86_64"
    fi
    
    # 检查必要的软件包
    log "检查必要的宿主系统软件包..."
    
    # 这里需要根据 LFS 文档要求检查必要的软件包版本
    # 暂时跳过具体检查，后续会在分区管理脚本中实现
    
    log "宿主系统检查完成"
}

# 函数：分区管理
partition_management() {
    log "执行分区管理操作..."
    
    # 检查分区管理脚本是否存在
    if [ ! -f "$LFS_SCRIPTS/partition/partition.sh" ]; then
        error_exit "分区管理脚本不存在"
    fi
    
    # 执行分区管理脚本
    bash "$LFS_SCRIPTS/partition/partition.sh" || error_exit "分区管理失败"
    
    mark_status "partition_management"
}

# 函数：软件包下载
package_download() {
    log "执行软件包下载操作..."
    
    # 检查下载脚本是否存在
    if [ ! -f "$LFS_SCRIPTS/download/download.sh" ]; then
        error_exit "下载脚本不存在"
    fi
    
    # 执行下载脚本
    bash "$LFS_SCRIPTS/download/download.sh" || error_exit "软件包下载失败"
    
    mark_status "package_download"
}

# 函数：章节构建
chapter_build() {
    local chapter="$1"
    log "执行章节 $chapter 构建操作..."
    
    # 检查章节脚本是否存在
    if [ ! -f "$LFS_SCRIPTS/chapters/$chapter/build.sh" ]; then
        error_exit "章节 $chapter 构建脚本不存在"
    fi
    
    # 执行章节构建脚本
    bash "$LFS_SCRIPTS/chapters/$chapter/build.sh" || error_exit "章节 $chapter 构建失败"
    
    mark_status "chapter_$chapter"
}

# 函数：显示帮助信息
show_help() {
    echo "LFS 构建系统帮助信息"
    echo "===================="
    echo "Usage: bash lfs.sh [options]"
    echo ""
    echo "Options:"
    echo "  --help              显示帮助信息"
    echo "  --host-check        仅检查宿主系统"
    echo "  --partition         仅执行分区管理"
    echo "  --download          仅执行软件包下载"
    echo "  --chapter N         仅执行章节 N 构建"
    echo "  --clean             清理构建状态"
    echo ""
    echo "Example:"
    echo "  bash lfs.sh              # 执行完整构建过程"
    echo "  bash lfs.sh --chapter 6   # 仅执行章节 6 构建"
}

# 主函数
main() {
    log "开始 LFS 构建过程..."
    log "构建根目录: $LFS_ROOT"
    
    # 处理命令行参数
    if [ $# -gt 0 ]; then
        case "$1" in
            --help) 
                show_help
                exit 0
                ;;
            --host-check) 
                check_host_system
                mark_status "host_check"
                exit 0
                ;;
            --partition) 
                partition_management
                exit 0
                ;;
            --download) 
                package_download
                exit 0
                ;;
            --chapter) 
                if [ $# -lt 2 ]; then
                    echo "错误: 缺少章节编号"
                    show_help
                    exit 1
                fi
                chapter_build "chapter$2"
                exit 0
                ;;
            --clean) 
                log "清理构建状态..."
                rm -rf "$LFS_STATUS"/*
                log "构建状态清理完成"
                exit 0
                ;;
            *) 
                echo "错误: 未知选项 $1"
                show_help
                exit 1
                ;;
        esac
    fi
    
    # 检查宿主系统
    if ! check_status "host_check"; then
        check_host_system
        mark_status "host_check"
    fi
    
    # 分区管理
    if ! check_status "partition_management"; then
        partition_management
    fi
    
    # 软件包下载
    if ! check_status "package_download"; then
        package_download
    fi
    
    # 按章节构建
    # 按照文档顺序执行构建
    chapters=("2" "3" "4" "5" "6" "7" "8" "9")
    
    for chapter in "${chapters[@]}"; do
        if ! check_status "chapter_$chapter"; then
            chapter_build "chapter$chapter"
        fi
    done
    
    log "LFS 构建过程完成！"
}

# 执行主函数
main "$@"
