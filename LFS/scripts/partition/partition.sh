#!/bin/bash

# 分区管理脚本
# 负责处理磁盘分区与格式化操作
# 严格参照 LFS-BOOK-SYSD-12.4 文档实现

# 设置脚本执行选项
set -euo pipefail

# 全局变量定义
LFS_ROOT="$(dirname "$(dirname "$(dirname "$(pwd)")")")"
LFS_SCRIPTS="$LFS_ROOT/scripts"
LFS_LOGS="$LFS_ROOT/logs"
LFS_STATUS="$LFS_ROOT/status"

# 目标系统分区信息
LFS_PARTITION="/dev/nvme1n1p5"
LFS_MOUNT="/mnt/lfs"

# 日志文件
LOG_FILE="$LFS_LOGS/partition_$(date +%Y%m%d_%H%M%S).log"

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
    log "分区管理失败，退出执行"
    exit 1
}

# 函数：检查宿主系统软件包
check_host_packages() {
    log "检查宿主系统必要软件包..."
    
    # 检查是否安装了必要的工具
    local required_packages=("fdisk" "mkfs.ext4" "mount" "coreutils")
    
    for pkg in "${required_packages[@]}"; do
        if ! command -v "$pkg" &> /dev/null; then
            error_exit "缺少必要软件包: $pkg"
        fi
    done
    
    log "宿主系统软件包检查完成"
}

# 函数：检查分区是否存在
check_partition() {
    log "检查目标分区是否存在..."
    
    if [ ! -b "$LFS_PARTITION" ]; then
        error_exit "目标分区 $LFS_PARTITION 不存在"
    fi
    
    log "目标分区 $LFS_PARTITION 存在"
}

# 函数：格式化分区
format_partition() {
    log "格式化目标分区..."
    
    # 检查分区是否已挂载
    if mount | grep -q "$LFS_PARTITION"; then
        error_exit "目标分区 $LFS_PARTITION 已挂载，请先卸载"
    fi
    
    # 格式化分区为 ext4 文件系统
    log "执行 mkfs.ext4 命令格式化分区..."
    sudo mkfs.ext4 "$LFS_PARTITION" || error_exit "分区格式化失败"
    
    log "分区格式化完成"
}

# 函数：创建挂载点并挂载分区
mount_partition() {
    log "创建挂载点并挂载分区..."
    
    # 创建挂载点目录
    if [ ! -d "$LFS_MOUNT" ]; then
        log "创建挂载点目录 $LFS_MOUNT..."
        sudo mkdir -p "$LFS_MOUNT" || error_exit "创建挂载点失败"
    fi
    
    # 挂载分区
    log "挂载分区 $LFS_PARTITION 到 $LFS_MOUNT..."
    sudo mount "$LFS_PARTITION" "$LFS_MOUNT" || error_exit "分区挂载失败"
    
    # 设置挂载点权限
    log "设置挂载点权限..."
    sudo chmod 755 "$LFS_MOUNT" || error_exit "设置权限失败"
    
    log "分区挂载完成"
}

# 函数：验证挂载状态
verify_mount() {
    log "验证分区挂载状态..."
    
    if mount | grep -q "$LFS_PARTITION"; then
        log "分区 $LFS_PARTITION 已成功挂载到 $LFS_MOUNT"
    else
        error_exit "分区挂载验证失败"
    fi
    
    # 检查挂载点空间
    log "检查挂载点空间..."
    df -h "$LFS_MOUNT" | tee -a "$LOG_FILE"
}

# 主函数
main() {
    log "开始分区管理操作..."
    log "目标分区: $LFS_PARTITION"
    log "挂载点: $LFS_MOUNT"
    
    # 检查宿主系统软件包
    check_host_packages
    
    # 检查分区是否存在
    check_partition
    
    # 格式化分区
    if ! [ -f "$LFS_STATUS/partition_formatted" ]; then
        format_partition
        touch "$LFS_STATUS/partition_formatted"
    else
        log "分区已经格式化，跳过执行"
    fi
    
    # 创建挂载点并挂载分区
    if ! [ -f "$LFS_STATUS/partition_mounted" ]; then
        mount_partition
        verify_mount
        touch "$LFS_STATUS/partition_mounted"
    else
        log "分区已经挂载，跳过执行"
    fi
    
    log "分区管理操作完成！"
}

# 执行主函数
main
